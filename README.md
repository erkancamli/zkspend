# zkSpend — Private Receipt → On-Chain Reward (0G Galileo)

[![GitHub Pages](https://img.shields.io/badge/demo-live-0G%20Galileo)](https://erkancamli.github.io/zkspend/)
[![CI](https://github.com/erkancamli/zkspend/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/erkancamli/zkspend/actions)

**One-liner**  
Turn receipts into on-chain rewards — **privately** — on 0G (Galileo). Foundry contracts + local Python worker. **No PII leaves your machine.**

---

## Quick Start

```bash
# 1) Bootstrap (Foundry + Python venv + folders)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"

# 2) Configure (writes scripts/env.local)
~/zkspend/scripts/configure.sh
# Fill: RPC_URL, PRIVATE_KEY, FROM, CAMPAIGN

# 3) One-click claim (example; use your own image path)
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png

Live (0G Galileo Testnet)

Factory: 0x8712b078774df0988bC89f7939154E0D72fCf6f2

Campaign (0.1 ETH reward): 0x8bbac06bd634f12250079fd1470c2016157f6bd8

Campaign (0.002 ETH reward): 0xd35116e3984b9e7564079750ab726aa4c1d7e77d

Latest Demo TX:
0x19d3c1c937f99a38141cce94f02632cfbbfaaab741bea8e631f21e8467594f99

How it works

Local worker turns a receipt image into 3 values: receiptCommitment (RC), nullifier (NUL), publicInputHash (PUB).

Smart contract checks conditions and pays the reward (no receipt data on-chain).

Double-spend protection: same nullifier → spent revert.

Web Demo

Live page (balance + recent claims): https://erkancamli.github.io/zkspend/

Useful scripts

scripts/bootstrap.sh → sets up Foundry, Python venv, folders.

scripts/configure.sh → guides you to create scripts/env.local.

scripts/claim_once.sh → generates (RC,NUL,PUB) and submits a claim tx.

Has built-in dry-run and gas fallbacks (legacy / EIP-1559).

Troubleshooting

xfer failed → Fund the campaign:

cast balance $CAMPAIGN
cast send $CAMPAIGN --value 0.02ether --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY"


server returned a null response → Script retries with EIP-1559 automatically.

spent → That nullifier was already used.

Security & Notes

This is a hackathon demo (Verifier is a stub). Don’t use with real funds.

All secrets stay in scripts/env.local (git-ignored).

License

MIT

---

### Storage Roadmap
- **v0.1**: Public JSON artifacts (GitHub Pages under `docs/claims/`)
- **v0.2**: Push artifacts to **0G Storage** (CLI/SDK), keep CID/hash in claim record
- **v0.3**: ZK verifier emits storage pointer; end-to-end verifiable proof trail


**Claims (JSON artifacts):**  
Public proof artifacts are published under GitHub Pages:  
`https://erkancamli.github.io/zkspend/claims/<FILE>.json`


### Storage Roadmap
- **v0.1:** Public JSON artifacts (GitHub Pages under `docs/claims/`)
- **v0.2:** Push artifacts to **0G Storage** (CLI/SDK), keep CID/hash in claim record *(stubbed now: see `scripts/uploader_0g_stub.sh`)*  
- **v0.3:** ZK verifier emits storage pointer; end-to-end verifiable proof trail
