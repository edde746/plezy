#!/usr/bin/env bash
set -euo pipefail

key_dir="${XDG_CONFIG_HOME:-$HOME/.config}/plezy-labs"
private_key="$key_dir/updater-private.pem"

if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is required." >&2
  exit 1
fi

mkdir -p "$key_dir"
chmod 700 "$key_dir"

if [[ -e "$private_key" ]]; then
  echo "Refusing to overwrite $private_key" >&2
  exit 1
fi

seed_file=$(mktemp)
pkcs8_file=$(mktemp)
trap 'rm -f "$seed_file" "$pkcs8_file"' EXIT

# auto_updater's signer intentionally stores the raw 32-byte Ed25519 seed in
# PEM, rather than OpenSSL's 48-byte PKCS#8 representation.
openssl rand 32 > "$seed_file"
{
  echo '-----BEGIN ED25519 PRIVATE KEY-----'
  openssl base64 -A < "$seed_file"
  echo
  echo '-----END ED25519 PRIVATE KEY-----'
} > "$private_key"
chmod 600 "$private_key"

# Construct a temporary PKCS#8 wrapper only to ask OpenSSL for the matching
# public key. DER prefix: Ed25519 PrivateKeyInfo containing a 32-byte seed.
printf '302e020100300506032b657004220420' | xxd -r -p > "$pkcs8_file"
dd if="$seed_file" bs=32 count=1 >> "$pkcs8_file" 2>/dev/null
public_key=$(openssl pkey -inform DER -in "$pkcs8_file" -pubout -outform DER | tail -c 32 | openssl base64 -A)

echo "Created the Plezy Labs updater private key at:"
echo "  $private_key"
echo
echo "Back this file up securely. Never commit it."
echo
echo "GitHub repository variable LABS_UPDATE_PUBLIC_KEY:"
echo "  $public_key"
echo
echo "Configure GitHub without printing the private key:"
echo "  gh secret set LABS_SPARKLE_PRIVATE_KEY < $private_key"
echo "  gh variable set LABS_UPDATE_PUBLIC_KEY --body '$public_key'"
