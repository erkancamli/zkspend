#!/usr/bin/env bash
set -euo pipefail

# --- Ayarlar ---
RPC="${RPC_URL:-https://evmrpc-testnet.0g.ai}"   # secret yoksa public RPC
CHAIN_ID_EXPECTED=16601
STEP_TIMEOUT=60                                   # her ağ çağrısı için saniye

# timeout helper
tmo() { timeout --preserve-status "${STEP_TIMEOUT}s" "$@"; }

echo "RPC: $RPC"

# 1) RPC canlı mı?
tmo curl -fsS -m 10 "$RPC" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' >/dev/null \
  || { echo "❌ RPC ulaşılamıyor"; exit 2; }

# 2) Chain ID doğru mu?
CID=$(tmo cast chain-id --rpc-url "$RPC" || echo "")
echo "ChainId: ${CID:-<empty>}"
[[ "$CID" == "$CHAIN_ID_EXPECTED" ]] || { echo "❌ Beklenen chainId $CHAIN_ID_EXPECTED, gelen: ${CID:-<empty>}"; exit 3; }

# 3) JSON'lar parse ediliyor mu?
jq -c . docs/claims/index.json >/dev/null
for f in docs/claims/*.json; do jq -c . "$f" >/dev/null; done

# 4) Asıl doğrulamalar (mevcut scriptin yaptığı her şey)
bash scripts/validate_claims.sh

echo "✅ validate_claims_wrapper tamamlandı"
