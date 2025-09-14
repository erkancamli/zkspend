#!/usr/bin/env bash
set -euo pipefail
fail=0
for f in docs/claims/*.json; do
  [ -e "$f" ] || continue
  ok=$(jq -e 'has("tx") and has("rc") and has("nul") and has("pub") and has("storage")' "$f" >/dev/null 2>&1 && echo ok || echo fail)
  if [ "$ok" = "ok" ]; then echo "✔ $f"; else echo "✖ $f"; fail=1; fi
done
exit $fail
