#!/usr/bin/env bash
# Tries 0G storage first; on failure writes to GitHub Pages (docs/claims)
set -euo pipefail

TX="${1:-}"; RC="${2:-}"; NUL="${3:-}"; PUB="${4:-}"
[ -z "$TX" ] && { echo "usage: $0 <tx> <rc> <nul> <pub>"; exit 1; }

REPO_DIR="${REPO_DIR:-$HOME/zkspend}"
ENV_FILE="$REPO_DIR/scripts/env.local"
[ -f "$ENV_FILE" ] && source "$ENV_FILE" || true

STORE_BACKEND="${STORE_BACKEND:-hybrid}"           # hybrid | 0g | pages
OG_STORAGE_URL="${OG_STORAGE_URL:-http://127.0.0.1:8080}"
OG_UPLOAD="${OG_STORAGE_URL%/}/api/v1/upload"
OG_DOWNLOAD_BASE="${OG_STORAGE_URL%/}/api/v1/download"

# -------- helper: write artifact to docs/claims --------
write_pages() {
  local CID="${1:-}"; local URL="${2:-}"
  mkdir -p "$REPO_DIR/docs/claims"
  local TS="$(date -u +%Y%m%dT%H%M%SZ)"
  local OUT="$REPO_DIR/docs/claims/$TX.json"

  jq -n --arg ts "$TS" --arg tx "$TX" --arg rc "$RC" --arg nul "$NUL" --arg pub "$PUB" \
        --arg cid "$CID" --arg url "$URL" --arg campaign "${CAMPAIGN:-}" --arg from "${FROM:-}" '
    {
      ts:$ts, tx:$tx, rc:$rc, nul:$nul, pub:$pub,
      proof:"0x",
      campaign:$campaign, from:$from,
      storage:{ cid:$cid, url: ( $url // null ) }
    }' > "$OUT"

  # manifest
  local SHASUM
  SHASUM="$(sha256sum "$OUT" | awk '{print $1}')"
  local MANI="$REPO_DIR/docs/claims/index.json"
  touch "$MANI"
  if ! jq . "$MANI" >/dev/null 2>&1; then echo "[]" > "$MANI"; fi
  tmp="$(mktemp)"
  jq --arg f "$(basename "$OUT")" \
     --arg tx "$TX" \
     --arg ts "$TS" \
     --arg cid "sha256:$SHASUM" \
     --arg campaign "${CAMPAIGN:-}" \
     --arg from "${FROM:-}" \
     '. += [{"file":$f,"tx":$tx,"ts":$ts,"cid":$cid,"campaign":$campaign,"from":$from}]' \
     "$MANI" > "$tmp" && mv "$tmp" "$MANI"

  echo "✓ claim stored: $OUT"
  echo "✓ manifest updated: $MANI"
}

# -------- try 0G first (if hybrid/0g) --------
if [ "$STORE_BACKEND" = "hybrid" ] || [ "$STORE_BACKEND" = "0g" ]; then
  if command -v curl >/dev/null 2>&1; then
    echo "→ Trying 0G storage upload… $OG_UPLOAD"
    # küçük, deterministik bir içerik yolla: claim özet JSON (rc/nul/pub/tx)
    payload="$(jq -n --arg tx "$TX" --arg rc "$RC" --arg nul "$NUL" --arg pub "$PUB" '{tx:$tx,rc:$rc,nul:$nul,pub:$pub}')"
    og_resp="$(mktemp)"
    if curl -fsS -m 30 -X POST \
         -F "file=@-;filename=claim_${TX}.json;type=application/json" \
         "$OG_UPLOAD" <<<"$payload" | tee "$og_resp" >/dev/null
    then
      # response: { root_hash: "..."} or {rootHash:"..."}
      RH="$(jq -r '..|.root_hash?,.rootHash? // empty' "$og_resp" | head -n1)"
      if [ -n "$RH" ] && [ "$RH" != "null" ]; then
        echo "✓ 0G upload ok: root_hash=$RH"
        write_pages "$RH" "$OG_DOWNLOAD_BASE/$RH"
        exit 0
      else
        echo "⚠ 0G upload responded but no root_hash. Falling back."
      fi
    else
      echo "⚠ 0G upload failed (timeout/conn). Falling back to Pages."
    fi
  fi
fi

# -------- fallback: GitHub Pages only --------
write_pages "" ""
exit 0
