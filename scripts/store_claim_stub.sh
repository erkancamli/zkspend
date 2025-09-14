#!/usr/bin/env bash
# Bu script, /tmp/claim_auto.json verisini ve son TX bilgisini alır,
# docs/claims/ içine ayrıntılı bir JSON yazıp bir manifest (index.json) günceller.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAIM_TMP_JSON="/tmp/claim_auto.json"
OUT_DIR="$REPO_ROOT/docs/claims"
MANIFEST="$OUT_DIR/index.json"

# ENV ile gelenler:
TX="${TX:-}"                  # claim_once.sh içinde export edilecek
CAMPAIGN="${CAMPAIGN:-}"
FROM="${FROM:-}"

mkdir -p "$OUT_DIR"

if [ ! -s "$CLAIM_TMP_JSON" ]; then
  echo "claim json not found: $CLAIM_TMP_JSON" >&2
  exit 1
fi

# Dosya adı (TX varsa onu kullan, yoksa timestamp)
TS="$(date -u +%Y%m%dT%H%M%SZ)"
BASENAME="${TX:-claim-$TS}"
OUT_JSON="$OUT_DIR/$BASENAME.json"

# İlk JSON’u oku
RC=$(jq -r .receiptCommitment "$CLAIM_TMP_JSON")
NUL=$(jq -r .nullifier "$CLAIM_TMP_JSON")
PUB=$(jq -r .publicInputHash "$CLAIM_TMP_JSON")
PROOF=$(jq -r '.proof // "0x"' "$CLAIM_TMP_JSON")

# Kayıt gövdesi (CID eklemeden önce geçici)
jq -n \
  --arg ts "$TS" \
  --arg tx "$TX" \
  --arg rc "$RC" \
  --arg nul "$NUL" \
  --arg pub "$PUB" \
  --arg proof "$PROOF" \
  --arg campaign "$CAMPAIGN" \
  --arg from "$FROM" \
'{
  ts: $ts,
  tx: $tx,
  rc: $rc,
  nul: $nul,
  pub: $pub,
  proof: $proof,
  campaign: $campaign,
  from: $from,
  storage: { cid: null, url: null }
}' > "$OUT_JSON"

# Bu kaydı uploader stub’a da basalım (gerçek 0G SDK buraya entegre edilecek)
CID="$(scripts/uploader_0g_stub.sh "$OUT_JSON")" || CID=""
# URL ise url, değilse cid alanına yaz
if [[ "$CID" == http*://* ]]; then
  jq --arg url "$CID" '.storage.url = $url' "$OUT_JSON" > "${OUT_JSON}.tmp" && mv "${OUT_JSON}.tmp" "$OUT_JSON"
else
  jq --arg cid "$CID" '.storage.cid = $cid' "$OUT_JSON" > "${OUT_JSON}.tmp" && mv "${OUT_JSON}.tmp" "$OUT_JSON"
fi

# Manifest (index.json) güncelle
if [ ! -f "$MANIFEST" ]; then
  echo '[]' > "$MANIFEST"
fi

jq --arg file "$(basename "$OUT_JSON")" \
   --arg tx "$TX" \
   --arg ts "$TS" \
   --arg cid "$CID" \
   --arg campaign "$CAMPAIGN" \
   --arg from "$FROM" \
   '. += [{file:$file, tx:$tx, ts:$ts, cid:$cid, campaign:$campaign, from:$from}]' \
   "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"

echo "✓ claim stored: $OUT_JSON"
echo "✓ manifest updated: $MANIFEST"
