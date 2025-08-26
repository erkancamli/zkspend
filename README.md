[![CI](https://github.com/erkancamli/zkspend/actions/workflows/ci.yml/badge.svg)](https://github.com/erkancamli/zkspend/actions)

# zkSpend – Private Receipt → On-Chain Reward (0G Galileo Testnet)

## Canlı Adresler
- **Factory:** `0x8712b078774df0988bC89f7939154E0D72fCf6f2`
- **Campaign (0.1 ETH ödül):** `0x8bbac06bd634f12250079fd1470c2016157f6bd8`
- **Campaign (0.002 ETH ödül):** `0xd35116e3984b9e7564079750ab726aa4c1d7e77d`

## Örnek İşlemler
- **Büyük claim:** `0x7dbec97a84a4b5e624585374d9233fe08b26de3212bb53bfbc46850b2dc8c79e`
- **Küçük claim 1:** `0x9c0f423899a4887117f7aa0bed0c96da94f698cc12a7f885a318d1762f470ea2`
- **Küçük claim 2:** `0x8dd2514a09212e2f73fe3dd2289bb2cbdca1002151604259f3761268fc8941ca`

## Hızlı Demo
```bash
# Ortam
source ~/zkspend/scripts/env.local
export CAMPAIGN=0xd35116e3984b9e7564079750ab726aa4c1d7e77d
export FROM=0x63798AD4eb791a8247Bb522bCE38062E41F7CE26

# Tek tık claim
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png

# Doğrulama
cast balance $CAMPAIGN
cast receipt 0x8dd2514a09212e2f73fe3dd2289bb2cbdca1002151604259f3761268fc8941ca --json | jq .
```

## Ne Gösteriyoruz?
- Fişten PII sızdırmadan **koşul sağlandı** kanıtı (ZK mimari).
- **Otomatik ödül** transferi (kontrat öder).
- **Double-spend** koruması (aynı nullifier → `spent`).

## Kurulum (lokalde)
```bash
# Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Kontratlar
cd contracts
forge install
forge build

# Worker
cd ../worker
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

## Pitch (1 dakikalık özet)
- **Problem:** Mağaza fişleri, kişisel veriyi sızdırmadan Web3 ödüllerine dönüştürülemiyor.
- **Çözüm:** zkSpend, fişi (lokalde) işler → ZK-benzeri özetler (RC/NUL/PUB) üretir → kontrat koşulu sağlanırsa **otomatik ödül** öder.
- **Gizlilik:** Fiş içeriği zincire veya üçüncü tarafa gönderilmez; yalnızca taahhütler ve nullifier on-chain.
- **Kullanım:** Kampanya → fonla → `claim_once.sh` ile fişten ödül al.
- **Anti-abuse:** Aynı nullifier tekrar kullanılırsa kontrat `spent` ile revert.
- **Durum:** 0G Galileo üzerinde canlı; adresler ve örnek işlemler README’de.
- **Gelecek:** Tarayıcı içi worker (WASM), çoklu kampanya kuralları (tarih/toplam tutar/mağaza), gerçek ZKP entegrasyonu.

