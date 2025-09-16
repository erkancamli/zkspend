#!/usr/bin/env bash
set -euo pipefail
export RPC_URL="${RPC_URL:-https://evmrpc-testnet.0g.ai}"
export CHAIN_ID="${CHAIN_ID:-16601}"

# Foundry (path sorun olursa tam yoldan dener)
if command -v cast >/dev/null 2>&1; then
  cast chain-id --rpc-url "$RPC_URL"
else
  ~/.foundry/bin/cast chain-id --rpc-url "$RPC_URL"
fi | grep -q '^16601$' && echo "ChainId OK ✅"

jq -c . docs/claims/index.json >/dev/null
for f in docs/claims/*.json; do jq -c . "$f" >/dev/null; done
echo "JSON ok ✅"

bash scripts/validate_claims.sh
echo "validate_claims.sh OK ✅"
