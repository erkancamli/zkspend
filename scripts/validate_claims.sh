#!/usr/bin/env bash
set -euo pipefail
RPC="${RPC_URL:-https://evmrpc-testnet.0g.ai}"
TOPIC_CLAIMED="0xcbcb845d94d59960a0c6e8b3a1f47ad81bb57269de43e89ff4f0fa656246f5f6"

jsonrpc () {
  local method="$1"; shift
  local params="$1"; shift || true
  curl -sS -H 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"${method}\",\"params\":${params}}" \
    "$RPC"
}
hex_lc(){ tr 'A-F' 'a-f' <<<"${1:-}"; }
strip0x(){ local x="${1:-}"; [[ "$x" == 0x* ]] && echo "${x:2}" || echo "$x"; }

fail=0
shopt -s nullglob
# Sadece 0x ile başlayan claim dosyaları (index.json hariç)
CLAIMS=(docs/claims/0x*.json)

for f in "${CLAIMS[@]}"; do
  echo "→ checking $(basename "$f")"
  tx=$(jq -r '.tx // .transactionHash // empty' "$f")
  rc=$(jq -r '.rc // .receiptCommitment // empty' "$f")
  nul=$(jq -r '.nul // .nullifier // empty' "$f")
  pub=$(jq -r '.pub // .publicInputHash // empty' "$f")
  camp=$(jq -r '.campaign // .contract // empty' "$f")

  if [ -z "$tx" ] || [ -z "$rc" ] || [ -z "$nul" ]; then
    echo "  ! missing tx/rc/nul in $f"; fail=1; continue
  fi

  R=$(jsonrpc "eth_getTransactionReceipt" "[\"$tx\"]" | jq -r '.result')
  if [ "$R" = "null" ] || [ -z "$R" ]; then
    echo "  ! receipt not found for $tx"; fail=1; continue
  fi

  # Logu bul (topic0 eşleşmeli, adres varsa ona göre filtrele)
  if [ -n "$camp" ] && [ "$camp" != "null" ]; then
    log=$(jq -r --arg a "$(hex_lc "$camp")" --arg t "$TOPIC_CLAIMED" \
      '.logs[] | select((.address|ascii_downcase)==$a and .topics[0]==$t)' <<<"$R")
  else
    log=$(jq -r --arg t "$TOPIC_CLAIMED" '.logs[] | select(.topics[0]==$t)' <<<"$R")
  fi
  if [ -z "$log" ]; then
    echo "  ! claimed event not found"; fail=1; continue
  fi

  data=$(jq -r '.data' <<<"$log"); dhex=$(strip0x "$data")
  rc_on="0x${dhex:0:64}"
  nul_on="0x${dhex:64:64}"

  if [ "$(hex_lc "$rc")" != "$(hex_lc "$rc_on")" ]; then
    echo "  ! RC mismatch: file=$rc onchain=$rc_on"; fail=1
  fi
  if [ "$(hex_lc "$nul")" != "$(hex_lc "$nul_on")" ]; then
    echo "  ! NUL mismatch: file=$nul onchain=$nul_on"; fail=1
  fi

  # Manifest CID kontrolü (varsa)
  if [ -f docs/claims/index.json ]; then
    fn=$(basename "$f")
    cid=$(jq -r --arg fn "$fn" --arg t "$tx" \
      'map(select(.file==$fn or .tx==$t)) | .[0].cid // empty' docs/claims/index.json)
    if [ -n "$cid" ]; then
      sum=$(sha256sum "$f" | awk '{print $1}')
      want="sha256:${sum}"
      if [ "$cid" != "$want" ]; then
        echo "  ! CID mismatch in manifest: have=$cid want=$want"; fail=1
      fi
    fi
  fi

  echo "  ✓ ok ($tx)"
done

if [ $fail -ne 0 ]; then
  echo "Some checks failed."; exit 1
else
  echo "All claims validated successfully."
fi
