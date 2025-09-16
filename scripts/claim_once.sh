#!/usr/bin/env bash
command -v cast >/dev/null || export PATH="$HOME/.foundry/bin:$PATH"
command -v cast >/dev/null || export PATH="$HOME/.foundry/bin:$PATH"
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Kullanım: $0 /path/to/receipt.png"
  exit 1
fi
IMG="$1"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Env
source "$REPO_DIR/scripts/env.local"
: "${RPC_URL:?RPC_URL yok}"
: "${PRIVATE_KEY:?PRIVATE_KEY yok}"
: "${CAMPAIGN:?CAMPAIGN yok}"
: "${FROM:?FROM yok}"
export ETH_RPC_URL="$RPC_URL"

# Worker venv
source "$REPO_DIR/worker/.venv/bin/activate"

# ZK-benzeri özetler (stub)
SALT=0x$(openssl rand -hex 8)
OUT=$(python "$REPO_DIR/worker/worker.py" "$IMG" --user "$FROM" --salt "$SALT")
echo "$OUT" | tee /tmp/claim_auto.json
PUB=$(echo "$OUT" | jq -r .publicInputHash)
RC=$(echo "$OUT" | jq -r .receiptCommitment)
NUL=$(echo "$OUT" | jq -r .nullifier)

# Dry-run (hızlı hata kontrolü)
set +e
DRY=$(cast call "$CAMPAIGN" 'claim(bytes,bytes32,bytes32,bytes32)' "0x" "$PUB" "$RC" "$NUL" --from "$FROM" 2>&1)
set -e
if echo "$DRY" | grep -qi 'spent'; then echo "Bu nullifier zaten kullanılmış. Yeni salt ile tekrar deneyin."; exit 2; fi
if echo "$DRY" | grep -qi 'xfer failed'; then echo "Kampanya bakiyesi yetersiz."; exit 3; fi

# Nonce & gaz
NONCE=$(cast nonce "$FROM")
GAS_LIMIT=250000
GAS_PRICE=$(cast gas-price 2>/dev/null || echo 1000000000)

# Gönderim (legacy), başarısız olursa 1559 fallback
set +e
SEND_OUT=$(cast send \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --chain-id $(cast chain-id --rpc-url "$RPC_URL") \
  --from "$FROM" \
  --nonce "$NONCE" \
  --legacy --gas-price "$GAS_PRICE" --gas-limit "$GAS_LIMIT" \
  "$CAMPAIGN" \
  "claim(bytes,bytes32,bytes32,bytes32)" \
  "0x" "$PUB" "$RC" "$NUL" \
  -vvvv 2>&1)
STAT=$?
set -e
echo "$SEND_OUT"

if [ $STAT -ne 0 ] || echo "$SEND_OUT" | grep -qi 'null response'; then
  echo "EIP-1559 ile yeniden deneniyor..."
  NONCE2=$(($NONCE + 1))
  SEND_OUT=$(cast send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --chain-id $(cast chain-id --rpc-url "$RPC_URL") \
    --from "$FROM" \
    --nonce "$NONCE2" \
    --gas-limit "$GAS_LIMIT" \
    --max-fee-per-gas 3000000000 \
    --max-priority-fee-per-gas 0 \
    "$CAMPAIGN" \
    "claim(bytes,bytes32,bytes32,bytes32)" \
    "0x" "$PUB" "$RC" "$NUL" \
    -vvvv 2>&1)
  echo "$SEND_OUT"
fi

TX=$(echo "$SEND_OUT" | awk '/transactionHash/ {print $2}' | tail -n1)
echo "TX: $TX"

# Event'ten RC/NUL doğrula
DATA_HEX=$(cast receipt "$TX" --json | jq -r '.logs[] | select(.address=="'"$CAMPAIGN"'") | .data')
HEX=${DATA_HEX#0x}
RC_ON=0x$(echo "$HEX" | cut -c1-64)
NUL_ON=0x$(echo "$HEX" | cut -c65-128)
echo "RC on-chain:  $RC_ON"
echo "NUL on-chain: $NUL_ON"

echo -n "Campaign balance: "
cast balance "$CAMPAIGN"

# >>> Yeni: claim'i dosyaya kaydet (Pages / ileride 0G Storage)
"$REPO_DIR/scripts/store_claim.sh" "$TX" "$RC" "$NUL" "$PUB" || true
