#!/usr/bin/env bash
# Usage: uploader_0g_stub.sh <file>
# Returns a "CID-like" pointer to stdout.

set -euo pipefail
FILE="${1:?usage: uploader_0g_stub.sh <file>}"

# Eğer gerçek bir uploader komutu verirsen onu kullan:
#   export OG_STORAGE_UPLOAD_CMD="og-cli put"
if [ "${OG_STORAGE_UPLOAD_CMD:-}" != "" ]; then
  # Örn: $OG_STORAGE_UPLOAD_CMD "$FILE" -> "bafy..."
  CID="$($OG_STORAGE_UPLOAD_CMD "$FILE")"
else
  # Şimdilik dosya hash’i ile deterministik bir pseudo-CID üretelim
  if command -v sha256sum >/dev/null 2>&1; then
    H=$(sha256sum "$FILE" | awk '{print $1}')
  else
    H=$(shasum -a 256 "$FILE" | awk '{print $1}')
  fi
  CID="sha256:$H"
fi

# Bir gateway/pin servis adresi ayarlıysa URL döndür (opsiyonel)
if [ "${OG_STORAGE_GATEWAY:-}" != "" ]; then
  echo "${OG_STORAGE_GATEWAY%/}/$CID"
else
  echo "$CID"
fi
