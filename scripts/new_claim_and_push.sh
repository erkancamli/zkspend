#!/usr/bin/env bash
command -v cast >/dev/null || export PATH="$HOME/.foundry/bin:$PATH"
set -euo pipefail

# Kullanım: scripts/new_claim_and_push.sh <receipt-image>
# Örn:     scripts/new_claim_and_push.sh ./receipts/receipt_3.png

RECEIPT="${1:-}"
[ -n "$RECEIPT" ] || { echo "usage: $0 <receipt-image>"; exit 1; }
[ -f "$RECEIPT" ] || { echo "file not found: $RECEIPT"; exit 1; }

# env yükle (RPC_URL, PRIVATE_KEY, CAMPAIGN vb. burada)
[ -f scripts/env.local ] && source scripts/env.local || true

./scripts/claim_once.sh "$RECEIPT"

# artefact + manifest ekle & push
git add docs/claims/*.json
git commit -m "docs(claims): add claim $(date -u +%Y%m%dT%H%M%SZ)"
git push

echo "✓ yeni claim push edildi. Dashboard: https://erkancamli.github.io/zkspend/"
