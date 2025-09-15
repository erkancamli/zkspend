# zkSpend — Private Receipt → On-Chain Reward (0G Galileo)

[![GitHub Pages](https://img.shields.io/badge/demo-live-0G%20Galileo)](https://erkancamli.github.io/zkspend/)
[![CI](https://github.com/erkancamli/zkspend/actions/workflows/pages/pages-build-deployment/badge.svg)](../../actions)

**One-liner**  
Turn receipts into on-chain rewards — **privately** — on 0G (Galileo). Foundry contracts + local Python worker. **No PII leaves your machine.**

- **Dashboard:** https://erkancamli.github.io/zkspend/
- **Claims list:** https://erkancamli.github.io/zkspend/claims.html

---

## What this repo includes

- **Contracts (Foundry):** `contracts/` (Campaign + Factory, 0G Galileo testnet)
- **Worker (Python):** `worker/` (creates **RC**, **NUL**, **PUB**, **proof** (stub) from a local receipt image)
- **One-click claim:** `scripts/claim_once.sh` (safe gas, dry-run, EIP-1559 fallback)
- **Storage stub:** `scripts/store_claim_stub.sh` → writes JSON artifacts to `docs/claims/*` and updates `docs/claims/index.json`
- **Docs/Pages:** lightweight dashboard (`docs/index.html`) + claims viewer (`docs/claims.html`)
- **Validator:** `scripts/validate_claims.sh` validates claims & auto-rebuilds `docs/claims/index.json`

---

## Network & addresses (0G Galileo Testnet)

```text
Chain ID      : 16601
Explorer      : https://evm-testnet.0g.ai
Public RPC    : https://evmrpc-testnet.0g.ai

Factory       : 0x8712b078774df0988bC89f7939154E0D72fCf6f2
Campaign (0.10): 0x8bbac06bd634f12250079fd1470c2016157f6bd8
Campaign (0.002): 0xd35116e3984b9e7564079750ab726aa4c1d7e77d
You can fund a new campaign yourself; helper scripts are included (see Create & fund a campaign).

Quick Start (3 steps)
Works on Linux/macOS. On a clean server, this installs Foundry & Python, then guides you to set env.

1) Bootstrap

bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"

2) Configure

# guided config
~/zkspend/scripts/configure.sh

# or edit manually
nano ~/zkspend/scripts/env.local
# set at least:
# RPC_URL=...
# PRIVATE_KEY=0x...
# FROM=0x...
# CAMPAIGN=0x...

3) One-click claim

# sample image included
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png
Worker computes RC, NUL, PUB locally (image never leaves your machine).

Contract emits the claim event (on 0G Galileo).

A JSON artifact is written under docs/claims/ and the manifest docs/claims/index.json is updated.

Publish artifacts to Pages (optional but recommended):

git add docs/claims/*.json
git commit -m "docs(claims): add latest"
git push

Create & fund a campaign (scripts)

# deploy a new campaign from Factory (edit params inside as needed)
./scripts/create_campaign.sh

# fund an existing campaign
./scripts/fund_campaign.sh
Storage roadmap (0G integration)
v0.1: Public JSON artifacts (GitHub Pages, docs/claims/*)

v0.2: Push artifacts to 0G Storage (CLI/SDK or gateway), keep CID/hash in claim record

v0.3: ZK verifier emits storage pointer; end-to-end verifiable proof trail

Validate / audit artifacts

./scripts/validate_claims.sh

# verifies each docs/claims/*.json against on-chain RC/NUL and manifest CID

Troubleshooting

forge/cast not found → source ~/.bashrc  (or open a new shell)
Pages 404 on new JSON → wait for “pages-build-deployment” workflow to finish
Re-run validator → ./scripts/validate_claims.sh

Dev notes
Foundry: forge --version && cast --version

Python venv: source worker/.venv/bin/activate

Env: source scripts/env.local

PRs & issues welcome. Let’s make private receipts useful ✨

---

## Latest demo TX

0x51ad231e20976681553fca4f660cd474b2cec8c1112363c6feead30536840672

> Görmek için explorer’da TX hash’ini aratın (0G Galileo Testnet).

---

## Example `.env` (quick reference)

```ini
# scripts/env.local (örnek)
RPC_URL=https://evmrpc-testnet.0g.ai
PRIVATE_KEY=0x........................................................
FROM=0x....................................
CAMPAIGN=0xd35116e3984b9e7564079750ab726aa4c1d7e77d

Known limitations
Şu an ZK proof zincire stub olarak gidiyor; gizlilik akışı lokal çalışıyor.

Storage v0.1: JSON artefact’lar GitHub Pages’a yazılıyor (0G Storage entegrasyonu roadmap’te).

Contact / Pitch
DM: @erkancamli

Pitch: “Zero-knowledge ile fiş/receipt → on-chain ödül; PII asla makinenizden çıkmaz.”

License
MIT
