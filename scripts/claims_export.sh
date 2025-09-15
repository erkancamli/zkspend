#!/usr/bin/env bash
set -euo pipefail

CLAIMS_DIR="docs/claims"
MANIFEST="$CLAIMS_DIR/index.json"
NDJSON="$CLAIMS_DIR/claims.ndjson"
CSV="$CLAIMS_DIR/claims.csv"

# Manifest yoksa boş dizi ver
MAN_FILE="$MANIFEST"
if [[ ! -f "$MANIFEST" ]]; then
  MAN_FILE="$(mktemp)"; echo '[]' > "$MAN_FILE"
fi

# NDJSON üret
: > "$NDJSON"
shopt -s nullglob
for f in "$CLAIMS_DIR"/*.json; do
  base="$(basename "$f")"; [[ "$base" == "index.json" ]] && continue
  jq -c --argfile man "$MAN_FILE" --arg file "$base" '
    def cid_for(tx):
      ( ($man|type=="array") as $ok |
        if $ok then ($man[]? | select(.tx==tx) | .cid) else empty end );

    { file:$file,
      tx:(.tx // ""),
      ts:(.ts // ""),
      rc:(.rc // .receiptCommitment // ""),
      nul:(.nul // .nullifier // ""),
      pub:(.pub // .publicInputHash // ""),
      campaign:(.campaign // .contract // ""),
      from:(.from // "")
    }
    | .cid = (cid_for(.tx) // "")
  ' "$f" >> "$NDJSON"
done

# CSV (ts'e göre desc)
jq -s -r '
  ["tx","ts","rc","nul","pub","campaign","from","cid","file"],
  ( sort_by(.ts) | reverse[] | [ .tx,.ts,.rc,.nul,.pub,.campaign,.from,.cid,.file ] | @csv )
' "$NDJSON" > "$CSV"

echo "✓ exports yazıldı:"
echo "  - $NDJSON"
echo "  - $CSV"
