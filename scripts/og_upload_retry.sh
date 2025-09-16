#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?usage: og_upload_retry.sh <file> [mime] }"
MIME="${2:-application/octet-stream}"
URL="${OG_CLIENT_URL:-http://127.0.0.1:8080/api/v1/upload}"
SRV_LOG="${OG_SERVER_LOG:-$HOME/zkspend/0g-storage-go-starter-kit/server.log}"

attempt=0
max_attempts="${OG_MAX_ATTEMPTS:-8}"
base_ms="${OG_BACKOFF_BASE_MS:-1500}"
max_ms="${OG_BACKOFF_MAX_MS:-15000}"

echo ">>> Uploading $FILE to $URL (max $max_attempts attempts, base ${base_ms}ms)"

grab_tx() {
  tac "$SRV_LOG" | awk '/txHash=0x/{print $0; exit}' | sed -n 's/.*txHash=\(0x[0-9a-fA-F]\+\).*/\1/p'
}

while : ; do
  attempt=$((attempt+1))
  echo "— attempt $attempt"
  RESP="$(curl -sS -X POST -F "file=@${FILE};type=${MIME}" "$URL" || true)"
  RH="$(jq -r '..|.root_hash?,.rootHash? // empty' <<<"$RESP" | head -n1 || true)"

  if [[ -n "$RH" && "$RH" != "null" ]]; then
    echo "✓ success. root_hash: $RH"
    printf '%s\n' "$RH" > /tmp/og_root_hash.txt
    exit 0
  fi

  # 500 vb. durumlarda: sunucu logundan en son txHash’i yakalayıp pending olarak raporla
  TX="$(grab_tx || true)"
  if [[ -n "$TX" ]]; then
    echo "… ZGS pending. txHash: $TX"
    printf '%s\n' "$TX" > /tmp/og_txhash.txt
  fi

  if (( attempt >= max_attempts )); then
    echo "✗ all attempts failed (pending_tx=${TX:-none})"
    exit 1
  fi

  pow=$((1<<(attempt-1)))
  sleep_ms=$(( base_ms * pow ))
  (( sleep_ms > max_ms )) && sleep_ms="$max_ms"
  jitter=$(( RANDOM % 400 ))
  sleep_ms=$(( sleep_ms + jitter ))
  sleep_s=$(awk -v ms="$sleep_ms" 'BEGIN{printf "%.3f", ms/1000}')
  echo "  retry in ${sleep_s}s …"
  sleep "$sleep_s"
done
