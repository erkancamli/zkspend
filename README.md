# zkSpend — Private Receipt → On-Chain Reward (0G Galileo)

[![GitHub Pages](https://img.shields.io/badge/demo-live-0G%20Galileo)](https://erkancamli.github.io/zkspend/)
[![CI](https://github.com/erkancamli/zkspend/actions/workflows/pages/pages-build-deployment/badge.svg)](../../actions)

**One-liner**  
Turn receipts into on-chain rewards—**privately**—on 0G (Galileo). Foundry contracts + local Python worker. **No PII leaves your machine.**

## Quick Start
```bash
# 1) Bootstrap (Foundry + Python venv)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"

# 2) Fill env
# edit scripts/env.local  (RPC_URL, PRIVATE_KEY, FROM, CAMPAIGN)

# 3) One-click claim (example)
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png

## Latest Demo TX
- `0x19d3c1c937f99a38141cce94f02632cfbbfaaab741bea8e631f21e8467594f99`
