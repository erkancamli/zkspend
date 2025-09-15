#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
OUT="docs/claims/index.json"
TMP="$(mktemp)"
echo "[]" > "$TMP"

for f in docs/claims/0x*.json; do
  base=$(basename "$f")
  tx=$(jq -r '.tx // .transactionHash // empty' "$f")
  camp=$(jq -r '.campaign // .contract // empty' "$f")
  from=$(jq -r '.from // empty' "$f")
  ts=$(jq -r '.ts // empty' "$f")
  sum=$(sha256sum "$f" | awk '{print $1}')
  cid="sha256:${sum}"

  # ts yoksa şimdi koy (son çare)
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    ts=$(date -u +%Y%m%dT%H%M%SZ)
  fi

  jq --arg file "$base" --arg tx "$tx" --arg ts "$ts" \
     --arg cid "$cid" --arg camp "$camp" --arg from "$from" \
     '. + [{file:$file, tx:$tx, ts:$ts, cid:$cid, campaign:$camp, from:$from}]' \
     "$TMP" > "${TMP}.2" && mv "${TMP}.2" "$TMP"
done

# ts alanına göre sırala (yoksa tx)
jq 'sort_by(.ts // .tx)' "$TMP" > "$OUT"
rm -f "$TMP"
echo "wrote $OUT"
