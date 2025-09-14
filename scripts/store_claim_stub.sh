#!/usr/bin/env bash
set -euo pipefail
# Kullanım: store_claim_stub.sh <TX_HASH> <JSON_PATH>
TX="${1:?tx hash gerekli}"
JSON="${2:?json path gerekli}"
OUT="docs/claims/${TX}.json"
mkdir -p docs/claims
cp "$JSON" "$OUT"
echo "Wrote $OUT  (TODO: push to 0G Storage in future)"
