#!/usr/bin/env bash
set -euo pipefail

CLAIMS_DIR="docs/claims"
MANIFEST="$CLAIMS_DIR/index.json"

shopt -s nullglob
changed=0

ts_now="$(date -u +%Y%m%dT%H%M%SZ)"

for f in "$CLAIMS_DIR"/*.json; do
  base="$(basename "$f")"
  [[ "$base" == "index.json" ]] && continue
  tx_from_name="${base%.json}"

  # normalize alan adları; eksikse dosya adına göre doldur; ts boşsa şimdiki zaman
  tmp="$f.tmp"
  jq --arg tx "$tx_from_name" --arg tsnow "$ts_now" '
    .tx       = (.tx       // $tx) |
    .rc       = (.rc       // .receiptCommitment // "") |
    .nul      = (.nul      // .nullifier         // "") |
    .pub      = (.pub      // .publicInputHash   // "") |
    .campaign = (.campaign // .contract          // "") |
    .ts       = (.ts       // $tsnow)
  ' "$f" > "$tmp"

  if ! cmp -s "$f" "$tmp"; then
    mv "$tmp" "$f"
    changed=1
  else
    rm -f "$tmp"
  fi
done

# Manifesti baştan üret (tx, ts, cid, campaign, from, file)
tmp_list="$(mktemp)"
for f in "$CLAIMS_DIR"/*.json; do
  base="$(basename "$f")"; [[ "$base" == "index.json" ]] && continue
  tx="$(jq -r '.tx' "$f")"
  ts="$(jq -r '.ts' "$f")"
  campaign="$(jq -r '.campaign // ""' "$f")"
  from="$(jq -r '.from // ""' "$f")"
  cid="sha256:$(sha256sum "$f" | awk '{print $1}')"
  jq -n --arg file "$base" --arg tx "$tx" --arg ts "$ts" \
        --arg cid "$cid" --arg campaign "$campaign" --arg from "$from" \
        '{file:$file, tx:$tx, ts:$ts, cid:$cid, campaign:$campaign, from:$from}' >> "$tmp_list"
done

jq -s 'sort_by(.ts) | reverse' "$tmp_list" > "$MANIFEST"
rm -f "$tmp_list"

echo "✓ fixup tamamlandı ve manifest yenilendi: $MANIFEST"
exit 0
