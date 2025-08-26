#!/usr/bin/env bash
set -euo pipefail

echo "› zkSpend bootstrap starting…"
REPO_DIR="${REPO_DIR:-$HOME/zkspend}"

# Clone if repo missing
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "› Cloning repo to $REPO_DIR"
  git clone https://github.com/erkancamli/zkspend.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# Foundry (forge/cast)
if ! command -v cast >/dev/null 2>&1; then
  echo "› Installing Foundry (forge/cast)…"
  curl -L https://foundry.paradigm.xyz | bash
  . "$HOME/.bashrc" 2>/dev/null || true
  . "$HOME/.zshrc"  2>/dev/null || true
  foundryup
fi

# Python venv + deps
echo "› Creating Python venv and installing worker deps…"
python3 -m venv worker/.venv
. worker/.venv/bin/activate
pip install -U pip
pip install -r worker/requirements.txt

mkdir -p scripts receipts
echo "✓ Bootstrap done. Next: ~/zkspend/scripts/configure.sh"
