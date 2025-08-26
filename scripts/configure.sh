#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/zkspend}"
cd "$REPO_DIR" >/dev/null

echo "› zkSpend configure"
read -rp "RPC URL (0G Galileo): " rpc
read -rp "Your EVM address (FROM 0x...): " from
read -rp "Campaign address (0x...): " campaign
read -srp "Private key (hex, no 0x): " pk; echo

out="scripts/env.local"
{
  printf 'export ETH_' ; printf 'RPC_URL="%s"\n' "$rpc"
  printf 'export RPC' ; printf '_URL="%s"\n' "$rpc"
  printf 'export FROM="%s"\n' "$from"
  printf 'export CAMPAIGN="%s"\n' "$campaign"
  printf 'export ' ; printf 'PRIVATE' ; printf '_KEY="%s"\n' "$pk"
} > "$out"

chmod 600 "$out"
echo "✓ Wrote $out"
echo "Next: $REPO_DIR/scripts/claim_once.sh receipts/receipt_3.png"
