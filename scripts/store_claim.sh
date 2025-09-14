#!/usr/bin/env bash
set -euo pipefail
# Usage: store_claim.sh <TX> <RC> <NUL> <PUB>
TX="${1:?tx}"
RC="${2:?rc}"
NUL="${3:?nul}"
PUB="${4:?pub}"

REPO_DIR="${REPO_DIR:-$HOME/zkspend}"
OUT_DIR="$REPO_DIR/docs/claims"
mkdir -p "$OUT_DIR"

# backend seçimi
BACKEND="${STORE_BACKEND:-pages}"     # pages | 0g | custom

# 1) JSON hazırla (tekil claim dosyası formatı)
tmp="$(mktemp)"
jq -n --arg tx "$TX" --arg rc "$RC" --arg nul "$NUL" --arg pub "$PUB" \
  '{tx:$tx, receiptCommitment:$rc, nullifier:$nul, publicInputHash:$pub}' > "$tmp"

# içerik hash'i (kanıt zinciri için işimize yarar)
CID_SHA="sha256:$(sha256sum "$tmp" | awk "{print \$1}")"
POINTER="$CID_SHA"

# 2) Backend'ler
case "$BACKEND" in
  pages)
    # mevcut davranış: GH Pages altında claim dosyasını yayınla
    ;;
  0g)
    # Basit bir örnek akışı: OG_STORAGE_URL varsa, dosyayı HTTP ile yüklemeyi dene.
    # (Kendi OG endpoint’ine göre uyarlayacaksın)
    # Örn: curl -fsS -X POST "$OG_STORAGE_URL/upload" -F file=@"$tmp"
    if [[ -n "${OG_STORAGE_URL:-}" ]]; then
      # Aşağıdaki satır "varsayım" API; kendi node’unun upload endpoint’ine göre değiştir.
      RESP="$(curl -fsS -X POST "$OG_STORAGE_URL/upload" -F file=@\"$tmp\" || true)"
      # RESP içinden kök hash / cid yakala (örnek: {"cid":"<root>"} kabul edelim)
      CID_FROM_RESP="$(echo "$RESP" | jq -r 'try .cid // empty' 2>/dev/null || true)"
      if [[ -n "$CID_FROM_RESP" && "$CID_FROM_RESP" != "null" ]]; then
        POINTER="og://${OG_STORAGE_URL#http://}/${CID_FROM_RESP}"
      fi
    fi
    ;;
  custom)
    # Kendi komutunu ENV ile ver:
    #   export OG_UPLOAD_CMD='my_uploader {{FILE}}'
    if [[ -n "${OG_UPLOAD_CMD:-}" ]]; then
      CMD="${OG_UPLOAD_CMD//'{{FILE}}'/$tmp}"
      CID_FROM_CMD="$($CMD || true)"
      if [[ -n "$CID_FROM_CMD" ]]; then
        POINTER="$CID_FROM_CMD"
      fi
    fi
    ;;
  *)
    echo "Unknown STORE_BACKEND=$BACKEND (pages|0g|custom bekleniyor)"; exit 1;;
esac

# 3) GH Pages output'u her durumda yaz (demo UI çalışsın)
dst="$OUT_DIR/$TX.json"
jq --arg cid "$POINTER" \
  '. + {cid:$cid}' "$tmp" > "$dst"

# 4) manifest güncelle
MAN="$OUT_DIR/index.json"
if [[ ! -f "$MAN" ]]; then echo "[]" > "$MAN"; fi
# aynı tx varsa önce silip tekrar ekleyelim (son hali en üste gelsin)
jq --arg f "$(basename "$dst")" 'map(select(.file != $f))' "$MAN" > "$MAN.tmp" && mv "$MAN.tmp" "$MAN"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
jq --arg f "$(basename "$dst")" --arg t "$TX" --arg ts "$TS" \
   --arg cid "$POINTER" \
   --arg camp "${CAMPAIGN:-}" --arg from "${FROM:-}" \
  '. |= ([{file:$f, tx:$t, ts:$ts, cid:$cid, campaign:$camp, from:$from}] + .)' "$MAN" > "$MAN.tmp" && mv "$MAN.tmp" "$MAN"

echo "✓ claim stored: $dst"
echo "✓ manifest updated: $MAN"
