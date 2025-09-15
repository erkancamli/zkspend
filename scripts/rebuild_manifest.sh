#!/usr/bin/env bash
set -euo pipefail
DIR=docs/claims
tmp="$(mktemp)"
jq -n '[]' > "$tmp"
shopt -s nullglob
for f in "$DIR"/*.json; do
  b="$(basename "$f")"
  [ "$b" = "index.json" ] && continue
  tx="$(jq -r '.tx // empty' "$f")"
  ts="$(jq -r '.ts // empty' "$f")"
  cid="sha256:$(sha256sum "$f" | awk '{print $1}')"
  jq --arg file "$b" --arg tx "$tx" --arg ts "$ts" --arg cid "$cid" \
     '. + [{file:$file, tx:$tx, ts:$ts, cid:$cid}]' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
done
jq 'sort_by(.ts)' "$tmp" > "$DIR/index.json"
rm -f "$tmp"
echo "Wrote $DIR/index.json"
