# zkSpend – Private Receipt → On-Chain Reward (0G Galileo)

Turn receipts into on-chain rewards — **privately** — on 0G (Galileo). Foundry contracts + local Python worker. **No PII.**

## Quick Start
```bash
# 1) Bootstrap (Foundry + Python venv)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"

# 2) Configure env (creates scripts/env.local)
~/zkspend/scripts/configure.sh

# 3) One-click claim (example)
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png
Live TX viewer: https://erkancamli.github.io/zkspend/tx.html?tx=
<TX_HASH>

Live Contracts (0G Galileo)

Factory: 0x8712b078774df0988bC89f7939154E0D72fCf6f2

Campaign (default, 0.002 ETH reward): 0xd35116e3984b9e7564079750ab726aa4c1d7e77d

Campaign (0.1 ETH reward): 0x8bbac06bd634f12250079fd1470c2016157f6bd8

Example TXs

0x9c0f423899a4887117f7aa0bed0c96da94f698cc12a7f885a318d1762f470ea2

0x8dd2514a09212e2f73fe3dd2289bb2cbdca1002151604259f3761268fc8941ca

How it works

Local worker (Python): receipt + salt → RC (receiptCommitment), NUL (nullifier), PUB (publicInputHash).

Contract: checks NUL (spent?), transfers reward, emits Claimed(RC,NUL).

Privacy: the receipt content never leaves the user’s machine.

Scripts

scripts/claim_once.sh – one-click claim (new salt each run)

scripts/create_campaign.sh – deploy new campaign

scripts/fund_campaign.sh – fund a campaign

⚠️ Testnet only. Don’t commit secrets. scripts/env.local is git-ignored.
