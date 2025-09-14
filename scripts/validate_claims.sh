#!/usr/bin/env bash
set -euo pipefail

# Gerekenler: jq, cast, ETH_RPC_URL veya scripts/env.local
if [ -f scripts/env.local ]; then source scripts/env.local; fi
: "${ETH_RPC_URL:=${RPC_URL:-}}"

printf "%-66s  %-6s  %-5s  %-5s  %-s\n" "TX" "STAT" "RC" "NUL" "NOTE"
printf "%-66s  %-6s  %-5s  %-5s  %-s\n" "==" "====" "==" "===" "===="

for f in docs/claims/*.json; do
  TX=$(jq -r '.tx // empty' "$f")
  RC=$(jq -r '.rc // .receiptCommitment // empty' "$f")
  NUL=$(jq -r '.nul // .nullifier // empty' "$f")
  PUB=$(jq -r '.pub // .publicInputHash // empty' "$f")
  CAMPAIGN=$(jq -r '.campaign // .contract // empty' "$f")

  note=""
  ok_rc="FAIL"; ok_nul="FAIL"; stat="FAIL"

  if [ -z "${TX}" ]; then
    printf "%-66s  %-6s  %-5s  %-5s  %s\n" "(no-tx in $f)" "FAIL" "-" "-" "missing tx"
    continue
  fi

  # TX receipt
  if ! RJSON=$(cast receipt "$TX" --json 2>/dev/null); then
    printf "%-66s  %-6s  %-5s  %-5s  %s\n" "$TX" "FAIL" "-" "-" "no receipt"
    continue
  fi

  S=$(jq -r '.status' <<< "$RJSON")
  if [ "$S" = "0x1" ]; then stat="OK"; else stat="FAIL"; fi

  # kampanya adresi ve log’u yakala
  if [ -n "${CAMPAIGN:-}" ]; then
    L=$(jq -r --arg C "$(echo "$CAMPAIGN" | awk '{print tolower($0)}')" \
      '.logs[] | select((.address|ascii_downcase)==$C)' <<< "$RJSON")
  else
    L=$(jq -r '.logs[0]' <<< "$RJSON")
  fi

  if [ -z "$L" ] || [ "$L" = "null" ]; then
    printf "%-66s  %-6s  %-5s  %-5s  %s\n" "$TX" "$stat" "-" "-" "no log"
    continue
  fi

  DATA=$(jq -r '.data' <<< "$L")
  HEX="${DATA#0x}"
  RC_ON="0x${HEX:0:64}"
  NUL_ON="0x${HEX:64:64}"

  [ -n "$RC" ]  && [ "$(awk '{print tolower($0)}' <<< "$RC")"  = "$(awk '{print tolower($0)}' <<< "$RC_ON")" ] && ok_rc="OK"
  [ -n "$NUL" ] && [ "$(awk '{print tolower($0)}' <<< "$NUL")" = "$(awk '{print tolower($0)}' <<< "$NUL_ON")" ] && ok_nul="OK"

  if [ "$ok_rc" != "OK" ] || [ "$ok_nul" != "OK" ]; then
    note="mismatch RC/NUL"
  fi

  printf "%-66s  %-6s  %-5s  %-5s  %s\n" "$TX" "$stat" "$ok_rc" "$ok_nul" "$note"
done
