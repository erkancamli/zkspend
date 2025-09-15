#!/usr/bin/env bash
set -euo pipefail

# cast varsa PATH'e ekle
command -v cast >/dev/null || export PATH="$HOME/.foundry/bin:$PATH"

# RPC (Actions'ta secrets.OG_RPC_URL gelir; lokalde scripts/env.local da olabilir)
[[ -f scripts/env.local ]] && . scripts/env.local || true
RPC="${OG_RPC_URL:-${RPC_URL:-}}"
if [[ -n "$RPC" ]]; then export ETH_RPC_URL="$RPC"; fi

CLAIMS_DIR="docs/claims"
BADGE_DIR="docs/badges"
mkdir -p "$BADGE_DIR"

# 1) claims sayısı
COUNT=0
if [[ -f "$CLAIMS_DIR/index.json" ]]; then
  COUNT="$(jq 'length' "$CLAIMS_DIR/index.json")"
fi
jq -n --arg msg "$COUNT" \
  '{"schemaVersion":1,"label":"claims","message":$msg,"color":"brightgreen"}' \
  > "$BADGE_DIR/claims.json"

# 2) campaign balance
CAMPAIGN="0xD35116e3984B9e7564079750aB726AA4c1d7e77d"
BAL_WEI="0"
if command -v cast >/dev/null && [[ -n "${ETH_RPC_URL:-}" ]]; then
  BAL_WEI="$(cast balance "$CAMPAIGN" 2>/dev/null || echo 0)"
fi
# shell/awk ile 1e18'e böl
BAL_ETH="$(awk -v w="$BAL_WEI" 'BEGIN{printf "%.3f", w/1e18}')"

# renk eşiği: >=0.02 yeşil, 0.01–0.02 sarı, altı kırmızı
COLOR="red"
awk -v x="$BAL_ETH" 'BEGIN{exit !(x>=0.02)}' && COLOR="brightgreen" || true
if [[ "$COLOR" != "brightgreen" ]]; then
  awk -v x="$BAL_ETH" 'BEGIN{exit !(x>=0.01)}' && COLOR="yellow" || COLOR="red"
fi

jq -n --arg msg "${BAL_ETH} ETH" --arg color "$COLOR" \
  '{"schemaVersion":1,"label":"campaign","message":$msg,"color":$color}' \
  > "$BADGE_DIR/balance.json"

echo "✓ badges yazıldı: $BADGE_DIR/{claims.json,balance.json}"
