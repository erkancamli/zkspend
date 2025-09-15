#!/usr/bin/env bash
set -euo pipefail
: "${RPC_URL:?set RPC_URL}"; : "${CAMPAIGN:?set CAMPAIGN}"

mkdir -p docs/badges docs/claims

# Claims sayısı
claims=0
[ -f docs/claims/index.json ] && claims="$(jq 'length' docs/claims/index.json)"

# Campaign bakiyesi (wei hex) → ETH
bal_hex="$(curl -s -H 'content-type: application/json' -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$CAMPAIGN\",\"latest\"],\"id\":1}" "$RPC_URL" | jq -r '.result // "0x0"')"
bal_eth="$(python3 - <<PY
import decimal,sys
h = "${bal_hex}"
n = int(h,16) if h.startswith("0x") else int(h)
d = decimal.Decimal(n)/decimal.Decimal(10**18)
print(f"{d:.4f}")
PY
)"

cat > docs/badges/claims.json <<JSON
{"schemaVersion":1,"label":"claims","message":"${claims}","color":"blue"}
JSON

cat > docs/badges/balance.json <<JSON
{"schemaVersion":1,"label":"campaign balance","message":"${bal_eth} ETH","color":"brightgreen"}
JSON

echo "✓ badges updated: docs/badges/{claims,balance}.json"
