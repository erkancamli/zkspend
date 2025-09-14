#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.local"
: "${RPC_URL:?}"; : "${PRIVATE_KEY:?}"
if [ $# -lt 2 ]; then echo "Kullanım: $0 <CAMPAIGN_ADDR> <ETH_MIKTAR>" ; exit 1; fi
C=$1; AMT=$2
cast send "$C" --value "$AMT"ether --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY"
echo -n "Yeni bakiye: "; cast balance "$C"
