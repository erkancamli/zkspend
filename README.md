# zkSpend — Private Receipt → On-Chain Reward (0G Galileo)

[![Live Demo (GitHub Pages)](https://img.shields.io/badge/demo-live-0G%20Galileo)](https://erkancamli.github.io/zkspend/)
[![CI: Validate Claims](https://github.com/erkancamli/zkspend/actions/workflows/validate-claims.yml/badge.svg)](https://github.com/erkancamli/zkspend/actions/workflows/validate-claims.yml)
[![Pages Deploy](https://github.com/erkancamli/zkspend/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/erkancamli/zkspend/actions)

**One-liner:** Turn receipts into on-chain rewards — **privately** — on 0G (Galileo).  
Local Python worker → commitments/nullifier on-chain → contract pays out. **No PII leaves your machine.**

---

## Live

- **Dashboard:** https://erkancamli.github.io/zkspend/
- **Claims list:** https://erkancamli.github.io/zkspend/claims.html

---

## What this repo includes

- **Contracts (Foundry):** `contracts/` (Campaign + Factory, 0G Galileo testnet)
- **Worker (Python):** `worker/worker.py` creates `{RC, NUL, PUB, proof}` from a *local* receipt image
- **One-click script:** `scripts/claim_once.sh` (safe gas, dry-run, EIP-1559 fallback)
- **Storage stub:** `scripts/store_claim_stub.sh` → writes JSON artifacts to `docs/claims/` and updates `index.json`
- **Docs (Pages):** lightweight dashboard (`docs/index.html`) + claims viewer (`docs/claims.html`)
- **CI:** `.github/workflows/validate-claims.yml` validates claims & auto-rebuilds `docs/claims/index.json`

---

## Network & addresses (0G Galileo Testnet)

- **Chain ID:** `16601`
- **Explorer:** https://evm-testnet.0g.ai
- **Public RPC (example):** `https://evmrpc-testnet.0g.ai`
- **Factory:** `0x8712b078774df0988bC89f7939154E0D72fCf6f2`
- **Campaign (0.1 ETH reward):** `0x8bbac06bd634f12250079fd1470c2016157f6bd8`
- **Campaign (0.002 ETH reward):** `0xd35116e3984b9e7564079750ab726aa4c1d7e77d`

> You can fund a new campaign yourself; helper scripts are included (see **Create & fund a campaign**).

---

## Quick Start (3 steps)

> Works on Linux/macOS. On a clean server, this installs Foundry & Python venv, then guides you to set env.

1) **Bootstrap**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"
Configure

bash
Kodu kopyala
# This asks for RPC_URL, PRIVATE_KEY, FROM, CAMPAIGN and writes scripts/env.local
~/zkspend/scripts/configure.sh
One-click claim

bash
Kodu kopyala
# Use any local receipt image (PNG/JPG). Example file is provided.
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png
What happens:

Worker computes {RC, NUL, PUB} locally (no image leaves your machine).

Script dry-runs the call; if ok, submits on-chain tx to the Campaign.

On success, stores a JSON artifact under docs/claims/ and updates docs/claims/index.json.

You can then git add + commit + push to publish on GitHub Pages.

Verifying your claim
bash
Kodu kopyala
# Replace with your TX hash from the script output
TX=0x...your_tx_hash...
cast receipt $TX --json | jq .

# Or open in explorer:
# https://evm-testnet.0g.ai/tx/<TX>
Create & fund a campaign (optional)
Use these if you want your own campaign (instead of the demo).

bash
Kodu kopyala
# 1) Create campaign (defaults to ~0.002 ETH reward)
~/zkspend/scripts/create_campaign.sh

# 2) Fund it (send e.g. 0.02 ETH to the campaign)
~/zkspend/scripts/fund_campaign.sh <CAMPAIGN_ADDR> 0.02
Claims artifacts & CI
Each successful claim writes a file: docs/claims/<TX>.json and updates docs/claims/index.json.

The Claims Viewer reads index.json and shows TX/RC/NUL/CID:
https://erkancamli.github.io/zkspend/claims.html

CI: On every push, GitHub Actions:

Runs scripts/validate_claims.sh to check RC/NUL against on-chain logs

Rebuilds the manifest (scripts/rebuild_manifest.sh)

Commits changes to docs/claims/index.json if needed

Optional: 0G Storage (roadmap hook)
Out-of-the-box we publish artifacts via GitHub Pages.
We also ship a stub to integrate 0G storage:

Set in scripts/env.local:

ini
Kodu kopyala
STORE_BACKEND=pages          # default
# STORE_BACKEND=0g
# OG_STORAGE_URL=http://<your-og-storage-gateway>:8080/api/v1
When STORE_BACKEND=0g, store_claim_stub.sh can POST the artifact to your gateway and include a storage.url in the JSON.

Note: If you’re testing the public ZGS nodes and see timeouts, switch back to STORE_BACKEND=pages (fully functional for demos/hackathons).

Folder layout
bash
Kodu kopyala
zkspend/
├─ contracts/                # Foundry contracts (Campaign, Factory, tests)
├─ worker/                   # Python image worker
│  ├─ .venv/                 # local venv
│  ├─ requirements.txt
│  └─ worker.py
├─ scripts/
│  ├─ bootstrap.sh           # one-line setup
│  ├─ configure.sh           # creates scripts/env.local
│  ├─ claim_once.sh          # one-click claim
│  ├─ store_claim_stub.sh    # publish artifact (Pages or 0G)
│  ├─ create_campaign.sh     # helper: deploy campaign via Factory
│  └─ fund_campaign.sh       # helper: fund a campaign
├─ docs/
│  ├─ index.html             # live dashboard (balance + recent claims)
│  ├─ claims.html            # claims table (reads docs/claims/index.json)
│  ├─ .nojekyll
│  └─ claims/
│     ├─ <TX>.json
│     └─ index.json
└─ .github/workflows/
   └─ validate-claims.yml    # CI: validate + rebuild manifest
Troubleshooting
cast: command not found
Run: source ~/.bashrc (or open a fresh shell). If needed: foundryup.

Tx revert: spent
You tried re-using a nullifier. Re-run with a new salt (the script already does this each time).

“null response” or gas issues
The script will retry using EIP-1559. You can also bump GAS_LIMIT or use a more reliable RPC.

Pages shows 404 for claim links
Wait for Pages to deploy (GitHub Action “pages-build-deployment”). Refresh claims.html.

Security notes
Never commit secrets. scripts/env.local is git-ignored.

The worker processes images locally; only commitments/nullifiers go on-chain.

This is a hackathon prototype; no production guarantees.

Roadmap
Real ZK proofs (Groth16/Plonk) instead of verifier stub

In-browser (WASM) worker + mobile scan UX

Rich campaign rules (date/merchant/amount)

0G storage integration by default (artifact distribution off-chain)

License
MIT
