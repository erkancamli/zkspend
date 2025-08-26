#!/usr/bin/env bash
set -euo pipefail

echo "› zkSpend bootstrap starting…"
# 0) Dizine geç / varsa klonla
REPO_DIR="${REPO_DIR:-$HOME/zkspend}"
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "› Cloning repo to $REPO_DIR"
  git clone https://github.com/erkancamli/zkspend.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# 1) Foundry (forge/cast)
if ! command -v cast >/dev/null 2>&1; then
  echo "› Installing Foundry (forge/cast)…"
  curl -L https://foundry.paradigm.xyz | bash
  source "$HOME/.bashrc" 2>/dev/null || true
  source "$HOME/.zshrc"  2>/dev/null || true
  foundryup
fi

# 2) Python venv + worker deps
echo "› Python venv kuruluyor…"
python3 -m venv worker/.venv
source worker/.venv/bin/activate
pip install -U pip
pip install -r worker/requirements.txt

# 3) env dosyası
mkdir -p scripts receipts
if [ ! -f scripts/env.local ]; then
  cp scripts/env.sample scripts/env.local
  cat <<'TIP'

────────────────────────────────────────
✅ Kurulum tamam.
→ Lütfen scripts/env.local dosyasını açıp şu alanları doldurun:
   RPC_URL=…
   PRIVATE_KEY=…
   FROM=0x…           # sizin adresiniz
   CAMPAIGN=0x…       # claim yapacağınız kampanya
────────────────────────────────────────
Sonra tek tık claim:
  ~/zkspend/scripts/claim_once.sh receipts/receipt_3.png
TIP
else
  echo "› env.local bulundu. Test claim için:"
  echo "  $REPO_DIR/scripts/claim_once.sh receipts/receipt_3.png"
fi
