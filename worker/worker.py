# zkSpend worker (stub)
# - Ingest receipt image/PDF
# - OCR -> extract {merchantId, amount, date}
# - Canonicalize JSON and compute commitment (keccak256)
# - Compute perceptual hash (pHash) to mitigate duplicate uploads
# - (Later) Run zk program to attest conditions and output proof + publicInputHash

import hashlib, json, argparse, os
from datetime import datetime

def canonical_commitment(payload: dict) -> bytes:
    # Canonical JSON (sorted keys, no spaces) -> keccak256-like stand-in using sha3_256 here
    s = json.dumps(payload, sort_keys=True, separators=(',',':')).encode()
    return hashlib.sha3_256(s).digest()

def demo_extract_fields(path: str):
    # TODO: integrate PaddleOCR / EasyOCR
    # For MVP, pretend we recognized following (replace with real OCR)
    return {
        "merchantId": "MERCHANT_X",   # map from OCR merchant name -> deterministic ID
        "amountCents": 24500,         # 245.00
        "timestamp": int(datetime.now().timestamp())
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--user", required=True, help="wallet address (checksum)")
    ap.add_argument("--salt", default="0x01")
    args = ap.parse_args()

    fields = demo_extract_fields(args.file)
    minimal = {
        "merchantId": fields["merchantId"],
        "amountCents": fields["amountCents"],
        "timestamp": fields["timestamp"],
        "salt": args.salt
    }
    commitment = canonical_commitment(minimal).hex()
    # public input hash prototype (should match on-chain expectation)
    public_input_fields = {
        "merchantRoot": "0x00..", "minAmount": 20000, "startTime": 0, "endTime": 4102444800,
        "receiptCommitment": commitment, "nullifier": hashlib.sha3_256((args.user+commitment).encode()).hexdigest(),
        "claimer": args.user
    }
    public_hash = canonical_commitment(public_input_fields).hex()

    out = {
        "receiptCommitment": "0x"+commitment,
        "nullifier": "0x"+public_input_fields["nullifier"],
        "publicInputHash": "0x"+public_hash,
        "proof": "0x"  # placeholder
    }
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
