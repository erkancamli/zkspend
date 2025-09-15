#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 1 ]; then echo "Usage: $0 <TX_HASH>"; exit 1; fi
TX="$1"
RPC="${RPC_URL:-https://evmrpc-testnet.0g.ai}"
TOPIC_CLAIMED="0xcbcb845d94d59960a0c6e8b3a1f47ad81bb57269de43e89ff4f0fa656246f5f6"
F="docs/claims/${TX}.json"
[ -f "$F" ] || { echo "not found: $F"; exit 1; }

jsonrpc () {
  local method="$1"; shift
  local params="$1"; shift || true
  curl -sS -H 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"${method}\",\"params\":${params}}" \
    "$RPC"
}
strip0x(){ local x="${1:-}"; [[ "$x" == 0x* ]] && echo "${x:2}" || echo "$x"; }

camp=$(jq -r '.campaign // .contract // empty' "$F")
from=$(jq -r '.from // empty' "$F")
pub=$(jq -r '.pub // .publicInputHash // empty' "$F")
proof=$(jq -r '.proof // "0x"' "$F")
ts=$(jq -r '.ts // empty' "$F")

R=$(jsonrpc "eth_getTransactionReceipt" "[\"$TX\"]" | jq -r '.result')
[ "$R" != "null" ] || { echo "receipt missing"; exit 1; }

if [ -n "$camp" ] && [ "$camp" != "null" ]; then
  LOG=$(jq -r --arg a "$(echo "$camp" | tr A-Z a-z)" --arg t "$TOPIC_CLAIMED" \
    '.logs[] | select((.address|ascii_downcase)==$a and .topics[0]==$t)' <<<"$R")
else
  LOG=$(jq -r --arg t "$TOPIC_CLAIMED" '.logs[] | select(.topics[0]==$t)' <<<"$R")
fi
[ -n "$LOG" ] || { echo "claimed log not found"; exit 1; }

DATA=$(jq -r '.data' <<<"$LOG"); HEX=$(strip0x "$DATA")
RC_ON="0x${HEX:0:64}"
NUL_ON="0x${HEX:64:64}"

# ts yoksa blok zamanını al
if [ -z "$ts" ] || [ "$ts" = "null" ]; then
  bh=$(jq -r '.blockHash' <<<"$R")
  B=$(jsonrpc "eth_getBlockByHash" "[\"$bh\", false]" | jq -r '.result')
  ts_hex=$(jq -r '.timestamp' <<<"$B")
  if [ -n "$ts_hex" ] && [ "$ts_hex" != "null" ]; then
    ts=$(date -u -d "@$((16#${ts_hex:2}))" +%Y%m%dT%H%M%SZ)
  fi
fi

tmp="$(mktemp)"
jq --arg tx "$TX" \
   --arg rc "$RC_ON" \
   --arg nul "$NUL_ON" \
   --arg pub "${pub:-}" \
   --arg proof "${proof:-0x}" \
   --arg camp "${camp:-}" \
   --arg from "${from:-}" \
   --arg ts "${ts:-}" \
  '{
     ts: ($ts // .ts),
     tx: $tx,
     rc: $rc,
     nul: $nul,
     pub: ($pub // .pub // .publicInputHash),
     proof: ($proof // .proof // "0x"),
     campaign: ($camp // .campaign // .contract),
     from: ($from // .from)
   }' "$F" > "$tmp" && mv "$tmp" "$F"

echo "refreshed: $F"
