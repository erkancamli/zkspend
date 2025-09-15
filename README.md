# zkSpend — Private Receipt → On-Chain Reward (0G Galileo)

**One-liner:** Fiş/receipt verisini **özel olarak** ZK ile işler, 0G (Galileo) üzerinde ödül talebine dönüştürür.  
Yerel Python worker → `rc`/`nul`/`pub` üretir; **Kişisel veri (PII) cihazdan çıkmaz.**  
Akıllı kontrat Foundry ile; talep “tek komut” script’iyle zincire gider.

- **Dashboard (Live Claims):** https://erkancamli.github.io/zkspend/  
- **TX Viewer:** https://erkancamli.github.io/zkspend/tx.html  
- **Claims manifest (JSON):** https://erkancamli.github.io/zkspend/docs/claims/index.json

---

## Bu repo neleri içerir?

- **Contracts (Foundry):** `contracts/` (Campaign + Factory, 0G Galileo testnet)  
- **Worker (Python):** `worker/` (lokalde ZK stub → `rc`, `nul`, `pub`, `proof`)  
- **Tek komut claim:** `scripts/claim_once.sh` (güvenli gas ayarı, JSON-RPC fallback)  
- **Storage stub:** `scripts/store_claim_stub.sh` → claim JSON’unu `docs/claims/` içine yazar, `index.json`’ı günceller  
- **Docs/Pages:** hafif dashboard `docs/index.html` (live claims), TX viewer `docs/tx.html`  
- **Doğrulama:** `scripts/validate_claims.sh` → JSON ↔ zincir tutarlılığı & manifest yeniden inşa

---

## Ağ & Adresler (0G Galileo Testnet)

- **Chain ID:** `16601`  
- **Explorer:** https://evm-testnet.0g.ai/  
- **Public RPC (örnek):** `https://evmrpc-testnet.0g.ai`  
- **Campaign (0.11 ETH reward):** `0xd35116e3984b9e7564079750ab726aa4c1d7e77d`  
- **Demo cüzdan (FROM):** `0x63798AD4eb791a8247Bb522bCE38062E41F7CE26`

> Kendi RPC’n ile denemek istersen QuickNode/Infura benzeri endpoint kullanabilirsin.

---

## Quick Start (3 adım)

> Linux/macOS üzerinde sorunsuz; temiz bir sunucuda Foundry & Python kurulumunu yapar, .env doldurmanı ister.

### 1) Bootstrap
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/erkancamli/zkspend/main/scripts/bootstrap.sh)"

2) Konfigürasyon
~/zkspend/scripts/configure.sh
# İstenecek alanlar:
#   RPC_URL, PRIVATE_KEY, FROM, CAMPAIGN
3) Tek komut ile claim
~/zkspend/scripts/claim_once.sh ~/zkspend/receipts/receipt_3.png
# Çıktı:
#  - TX hash (zincirde)
#  - rc / nul / pub (lokalde)
#  - docs/claims/<TX>.json ve docs/claims/index.json güncellenir
#  - GitHub Pages’e push edersen dashboard otomatik güncellenir
Hızlı bağlantı:

Live claims: https://erkancamli.github.io/zkspend/

Son claim JSON: docs/claims/<TX>.json
Doğrulama (optional)
# Manifest ve tekil JSON’ları zincire göre doğrular, gerekiyorsa index.json’u yeniden kurar
~/zkspend/scripts/validate_claims.sh
Storage Roadmap

v0.1: JSON artefact’lar GitHub Pages altında tutuluyor (kanıt izi).

v0.2: 0G Storage (CLI/SDK) ile upload; manifest’te CID/hash koruma.

v0.3: Zincirde ZK doğrulama + 0G Storage pointer (tam uçtan-uca kanıt zinciri).
Roadmap & Next

Gerçek ZK proof (Groth16/Plonk) entegre (stub yerine)

Web Claim UI (tek sayfa): upload → lokalde rc/nul/pub → zincire gönder

Multi-campaign seçim & parametre görünümü

Mobile (kamera ile receipt scan)

0G Storage prod entegrasyon (CID/pointer’lı claim kaydı)

Watcher/Explorer (event decoder, analytics)

Testler, edge-case’ler, JSON-RPC fallback’ler
Latest demo TX
0x51ad231e20976681553fca4f660cd474b2cec8c1112363c6feead30536840672


Explorer’da aratarak zincir üzerindeki log’u görebilirsiniz.
Örnek .env
# scripts/env.local
RPC_URL=https://evmrpc-testnet.0g.ai
PRIVATE_KEY=0x........................................................
FROM=0x....................................
CAMPAIGN=0xd35116e3984b9e7564079750ab726aa4c1d7e77d

Lisans

MIT
