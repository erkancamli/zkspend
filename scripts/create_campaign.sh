#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.local"
: "${RPC_URL:?}"; : "${PRIVATE_KEY:?}"; : "${TREASURY:=$FROM}"
FACTORY=0x8712b078774df0988bC89f7939154E0D72fCf6f2
ROOT=0x0000000000000000000000000000000000000000000000000000000000000001
START=$(date +%s)
END=$(( START + 30*24*60*60 ))
REWARD_WEI=${1:-2000000000000000}   # default 0.002 ETH
cast send --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" \
  "$FACTORY" \
  "createCampaign((bytes32,uint256,uint64,uint64,address,uint256,address))" \
  "($ROOT,20000,$START,$END,0x0000000000000000000000000000000000000000,$REWARD_WEI,$TREASURY)"
