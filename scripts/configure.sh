#!/usr/bin/env bash
set -euo pipefail

echo ">>> zkSpend configure (creates scripts/env.local)"

read -rp "RPC_URL (e.g. https://evmrpc-testnet.0g.ai or your QuickNode): " RPC_URL
read -rp "PRIVATE_KEY (0x...): " PRIVATE_KEY
read -rp "FROM address (0x...): " FROM
read -rp "CAMPAIGN address (0x...): " CAMPAIGN

mkdir -p scripts
cat > scripts/env.local <<ENV
# zkSpend local config (gitignored)
export RPC_URL="${RPC_URL}"
export ETH_RPC_URL="${RPC_URL}"
export PRIVATE_KEY="${PRIVATE_KEY}"
export FROM="${FROM}"
export CAMPAIGN="${CAMPAIGN}"
ENV

chmod 600 scripts/env.local
echo "✓ scripts/env.local written."
echo "test: cast chain-id --rpc-url \"\$RPC_URL\""
