#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Kullanım: $0 /path/to/receipt.(png|jpg)"
  exit 1
fi
IMG="$1"

# Env
source "$(dirname "$0")/env.local"
: "${RPC_URL:?}"; : "${PRIVATE_KEY:?}"; : "${CAMPAIGN:?}"; : "${FROM:?}"
export ETH_RPC_URL="$RPC_URL"

# Opsiyonel 0G storage ayarları (varsa doldur)
OG_UPLOAD="${OG_UPLOAD:-0}"            # 1 yaparsan upload dener
OG_PUT_URL="${OG_PUT_URL:-}"           # Örn: https://<your-0g-storage>/upload
OG_PUBLIC_BASE="${OG_PUBLIC_BASE:-}"    # Örn: https://<your-0g-storage>/objects

# Worker (RC/NUL/PUB)
source "$HOME/zkspend/worker/.venv/bin/activate"
SALT=0x$(openssl rand -hex 8)
OUT=$(python "$HOME/zkspend/worker/worker.py" "$IMG" --user "$FROM" --salt "$SALT")
echo "$OUT" | tee /tmp/claim_auto.json
PUB=$(echo "$OUT" | jq -r .publicInputHash)
RC=$(echo "$OUT" | jq -r .receiptCommitment)
NUL=$(echo "$OUT" | jq -r .nullifier)

# (Opsiyonel) Şifrele + 0G storage'a yükle
URI_HEX="0x"  # default: boş bytes
if [ "$OG_UPLOAD" = "1" ] && [ -n "$OG_PUT_URL" ] && [ -n "$OG_PUBLIC_BASE" ]; then
  KEYHEX=$(openssl rand -hex 32)
  IVHEX=$(openssl rand -hex 12)
  ENC="/tmp/rc-$(echo $RC | cut -c1-10).enc"

  # AES-256-GCM ile şifrele
  openssl enc -aes-256-gcm -K "$KEYHEX" -iv "$IVHEX" -in "$IMG" -out "$ENC" -nopad -nosalt

  # Upload (örnek: basit HTTP PUT/POST – kendi endpoint’ine göre değiştir)
  # Aşağıdaki satırı kendi 0G storage API’ne uyarlaman gerebilir:
  #   - PUT/POST yolu
  #   - Auth header’ları vs.
  OBJ="rc-$(echo $RC | cut -c3-).enc"
  curl -fsS -X PUT "$OG_PUT_URL/$OBJ" --data-binary @"$ENC"

  # Kamuya açık erişim URI
  URI="$OG_PUBLIC_BASE/$OBJ"
  # URI'yi bytes'a çevir (utf8 -> hex)
  URI_HEX=$(printf '%s' "$URI" | xxd -p -c 99999 | sed 's/^/0x/')
  echo "Uploaded to 0G Storage: $URI"
fi

# Hızlı dry-run (revert kontrol)
set +e
DRY=$(cast call "$CAMPAIGN" 'claim(bytes,bytes32,bytes32,bytes32)' "$URI_HEX" "$PUB" "$RC" "$NUL" --from "$FROM" 2>&1)
set -e
if echo "$DRY" | grep -qi 'spent'; then echo "Bu nullifier zaten kullanılmış. Yeni salt ile tekrar deneyin."; exit 2; fi
if echo "$DRY" | grep -qi 'xfer failed'; then echo "Kampanya bakiyesi yetersiz."; exit 3; fi

# Nonce + gaz
NONCE=$(cast nonce "$FROM")
GAS_LIMIT=250000
GAS_PRICE=$(cast gas-price 2>/dev/null || echo 1000000000)

# Gönder (legacy)
set +e
SEND_OUT=$(cast send \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --chain-id 16601 \
  --from "$FROM" \
  --nonce "$NONCE" \
  --legacy --gas-price "$GAS_PRICE" --gas-limit "$GAS_LIMIT" \
  "$CAMPAIGN" \
  "claim(bytes,bytes32,bytes32,bytes32)" \
  "$URI_HEX" "$PUB" "$RC" "$NUL" \
  -vvvv 2>&1)
STAT=$?
set -e
echo "$SEND_OUT"

# Gerekirse 1559 fallback
if [ $STAT -ne 0 ] || echo "$SEND_OUT" | grep -qi 'null response'; then
  echo "EIP-1559 ile yeniden deneniyor..."
  NONCE2=$(($NONCE + 1))
  SEND_OUT=$(cast send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --chain-id 16601 \
    --from "$FROM" \
    --nonce "$NONCE2" \
    --gas-limit "$GAS_LIMIT" \
    --max-fee-per-gas 3000000000 \
    --max-priority-fee-per-gas 0 \
    "$CAMPAIGN" \
    "claim(bytes,bytes32,bytes32,bytes32)" \
    "$URI_HEX" "$PUB" "$RC" "$NUL" \
    -vvvv 2>&1)
  echo "$SEND_OUT"
fi

TX=$(echo "$SEND_OUT" | awk '/transactionHash/ {print $2}' | tail -n1)
echo "TX: $TX"

# Event doğrulama
DATA_HEX=$(cast receipt "$TX" --json | jq -r '.logs[] | select(.address=="'"$CAMPAIGN"'") | .data')
HEX=${DATA_HEX#0x}
RC_ON=0x$(echo "$HEX" | cut -c1-64)
NUL_ON=0x$(echo "$HEX" | cut -c65-128)
echo "RC on-chain:  $RC_ON"
echo "NUL on-chain: $NUL_ON"

echo -n "Campaign balance: "
cast balance "$CAMPAIGN"
