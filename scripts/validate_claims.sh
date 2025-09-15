#!/usr/bin/env bash
set -euo pipefail

# Bağımlılıklar
for bin in jq sha256sum; do
  command -v "$bin" >/dev/null 2>&1 || { echo "missing: $bin"; exit 1; }
done
command -v cast >/dev/null 2>&1 || { echo "missing: cast (Foundry)"; exit 1; }

# RPC kaynağı: env.local varsa yükle; yoksa çevre değişkeni bekle
if [ -f scripts/env.local ]; then
  # shellcheck disable=SC1091
  source scripts/env.local
fi
: "${RPC_URL:?RPC_URL is required (export RPC_URL=...)}"
export ETH_RPC_URL="$RPC_URL"

CLAIMS_DIR="docs/claims"
MANIFEST="$CLAIMS_DIR/index.json"
TOPIC="0xcbcb845d94d59960a0c6e8b3a1f47ad81bb57269de43e89ff4f0fa656246f5f6"  # Claimed(address,bytes32,bytes32)

if [ ! -d "$CLAIMS_DIR" ]; then
  echo "no $CLAIMS_DIR directory"
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  echo "no $MANIFEST (skip manifest checks)"
fi

errors=0
is_array() { jq -e 'type=="array"' "$1" >/dev/null 2>&1; }

shopt -s nullglob
for f in "$CLAIMS_DIR"/*.json; do
  base=$(basename "$f")
  [ "$base" = "index.json" ] && continue

  echo "→ checking $base"

  # Eski/yeni alan adlarını destekle
  tx=$(jq -r '.tx // empty' "$f")
  rc=$(jq -r '.rc // .receiptCommitment // empty' "$f")
  nul=$(jq -r '.nul // .nullifier // empty' "$f")
  pub=$(jq -r '.pub // .publicInputHash // empty' "$f")
  campaign=$(jq -r '.campaign // .contract // empty' "$f")

  if [ -z "$tx" ] || [ -z "$rc" ] || [ -z "$nul" ] || [ -z "$campaign" ]; then
    echo "  ! missing required fields (tx/rc/nul/campaign)"
    errors=$((errors+1)); continue
  fi

  # Dosya CID'i vs manifest
  have_cid="sha256:$(sha256sum "$f" | awk '{print $1}')"
  if [ -f "$MANIFEST" ] && is_array "$MANIFEST"; then
    want_cid=$(jq -r --arg tx "$tx" '.[] | select(.tx==$tx) | .cid // empty' "$MANIFEST")
    if [ -n "$want_cid" ] && [ "$want_cid" != "$have_cid" ]; then
      echo "  ! CID mismatch in manifest: have=$have_cid want=$want_cid"
      errors=$((errors+1))
    fi
  fi

  # On-chain event'ten RC/NUL çıkar
  rec_json=$(cast receipt "$tx" --json 2>/dev/null || true)
  if [ -z "$rec_json" ]; then
    echo "  ! tx receipt not found"
    errors=$((errors+1)); continue
  fi

  data_hex=$(jq -r --arg addr "$(printf '%s' "$campaign" | tr '[:upper:]' '[:lower:]')" --arg topic "$TOPIC" '
    .logs[]? | select((.address|ascii_downcase)==$addr and .topics[0]==$topic) | .data
  ' <<<"$rec_json" | head -n1)

  if [ -z "$data_hex" ] || [ "$data_hex" = "null" ]; then
    echo "  ! claimed event not found for campaign"
    errors=$((errors+1)); continue
  fi

  hex=${data_hex#0x}
  rc_on="0x${hex:0:64}"
  nul_on="0x${hex:64:64}"

  if [ "${rc,,}" != "${rc_on,,}" ]; then
    echo "  ! RC mismatch: file=$rc onchain=$rc_on"
    errors=$((errors+1))
  fi
  if [ "${nul,,}" != "${nul_on,,}" ]; then
    echo "  ! NUL mismatch: file=$nul onchain=$nul_on"
    errors=$((errors+1))
  fi

  echo "  ✓ ok ($tx)"
done

if [ $errors -gt 0 ]; then
  echo "✗ validation failed ($errors error/s)"
  exit 1
fi
echo "✓ all claims validated successfully."
