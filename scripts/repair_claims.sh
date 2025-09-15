#!/usr/bin/env bash
set -euo pipefail

for b in jq cast; do command -v "$b" >/dev/null || { echo "missing: $b"; exit 1; }; done

# RPC_URL için: scripts/env.local varsa yükle, yoksa OG_RPC_URL secret ile aynı RPC'yi export et
if [ -f scripts/env.local ]; then
  # shellcheck disable=SC1091
  source scripts/env.local
fi
: "${RPC_URL:?set RPC_URL (same as OG_RPC_URL)}"
export ETH_RPC_URL="$RPC_URL"

CLAIMS_DIR="docs/claims"
MANIFEST="$CLAIMS_DIR/index.json"
TOPIC="0xcbcb845d94d59960a0c6e8b3a1f47ad81bb57269de43e89ff4f0fa656246f5f6"

fix_one() {
  f="$1"
  base="$(basename "$f")"
  [ "$base" = "index.json" ] && return 0

  # Eksikse onarılacak mı?
  if jq -e '
      (.tx // "" )     != "" and
      ((.rc  // .receiptCommitment // "") != "" ) and
      ((.nul // .nullifier         // "") != "" ) and
      ((.campaign // .contract     // "") != "" )
    ' "$f" >/dev/null; then
    echo "✓ already ok: $base"
    return 0
  fi

  tx="$(jq -r '.tx // empty' "$f")"
  [ -z "$tx" ] && tx="${base%.json}"

  # Manifestten campaign/from/ts çek
  rec="$(jq -er --arg tx "$tx" '.[] | select(.tx==$tx)' "$MANIFEST")" || {
    echo "  ! no manifest record for $base"; return 1; }
  campaign="$(jq -r '.campaign // empty' <<<"$rec")"
  fromaddr="$(jq -r '.from // empty'      <<<"$rec")"
  ts="$(jq -r '.ts // empty'              <<<"$rec")"

  # Receipt → event data
  rjson="$(cast receipt "$tx" --json)"
  data_hex="$(jq -r --arg addr "${campaign,,}" --arg topic "$TOPIC" \
      '.logs[]? | select((.address|ascii_downcase)==$addr and .topics[0]==$topic) | .data' \
      <<<"$rjson" | head -n1)"
  if [ -z "$data_hex" ]; then echo "  ! event not found in receipt ($base)"; return 1; fi

  rc="0x${data_hex:2:64}"
  nul="0x${data_hex:66:64}"

  pub="$(jq -r '.pub // .publicInputHash // empty' "$f")"
  proof="$(jq -r '.proof // empty' "$f")"
  [ -z "$proof" ] && proof="0x"
  storage_json="$(jq -c '.storage // {}' "$f")"

  # Yeni JSON’u yaz
  jq -n \
    --arg ts "$ts" --arg tx "$tx" --arg rc "$rc" --arg nul "$nul" \
    --arg pub "$pub" --arg proof "$proof" \
    --arg campaign "$campaign" --arg from "$fromaddr" \
    --argjson storage "$storage_json" '
      (if $ts=="" then {} else {ts:$ts} end) +
      {tx:$tx, rc:$rc, nul:$nul} +
      (if $pub=="" then {} else {pub:$pub} end) +
      {proof:$proof, campaign:$campaign, from:$from} +
      (if ($storage|type)=="object" and ($storage|length)>0 then {storage:$storage} else {} end)
    ' | tee "$f.tmp" >/dev/null
  mv "$f.tmp" "$f"
  echo "✓ fixed: $base"
}

# Bozuk olanları tespit et ve onar
shopt -s nullglob
for f in "$CLAIMS_DIR"/*.json; do
  [ "$(basename "$f")" = "index.json" ] && continue
  if ! jq -e '
      (.tx // "" )     != "" and
      ((.rc  // .receiptCommitment // "" ) != "" ) and
      ((.nul // .nullifier         // "" ) != "" ) and
      ((.campaign // .contract     // "" ) != "" )
    ' "$f" >/dev/null; then
    fix_one "$f" || true
  fi
done
