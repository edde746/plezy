#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rpm-path>" >&2
  exit 2
fi

if [[ -z "${RPM_SIGNING_PRIVATE_KEY:-}" ]]; then
  echo "RPM_SIGNING_PRIVATE_KEY is required to sign release RPMs." >&2
  exit 1
fi

rpm_path=$1
if [[ ! -f "$rpm_path" ]]; then
  echo "RPM file not found: $rpm_path" >&2
  exit 1
fi

signing_root=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/plezy-rpm-signing.XXXXXX")
cleanup() {
  rm -rf -- "$signing_root"
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

export GNUPGHOME="$signing_root/gnupg"
mkdir -m 700 "$GNUPGHOME"

private_key_path="$signing_root/private-key.asc"
(umask 077 && printf '%s' "$RPM_SIGNING_PRIVATE_KEY" > "$private_key_path")
unset RPM_SIGNING_PRIVATE_KEY

if ! gpg --batch --quiet --import "$private_key_path" >/dev/null 2>&1; then
  echo "Could not import RPM signing key." >&2
  exit 1
fi

rm -f -- "$private_key_path"

secret_key_listing=$(gpg --batch --with-colons --list-secret-keys --fingerprint)
mapfile -t primary_fingerprints < <(
  awk -F: '
    $1 == "sec" { need_fingerprint = 1; next }
    need_fingerprint && $1 == "fpr" { print $10; need_fingerprint = 0 }
  ' <<< "$secret_key_listing"
)

if [[ ${#primary_fingerprints[@]} -ne 1 ]]; then
  echo "RPM signing key must contain exactly one primary private key." >&2
  exit 1
fi

fingerprint=${primary_fingerprints[0]}
primary_record=$(awk -F: '$1 == "sec" { print; exit }' <<< "$secret_key_listing")
IFS=: read -r -a primary_fields <<< "$primary_record"
validity=${primary_fields[1]}
capabilities=${primary_fields[11]}
if [[ "$validity" =~ [erdi] || "${capabilities,,}" != *s* ]]; then
  echo "RPM signing key was invalid." >&2
  exit 1
fi

public_key_path="$signing_root/public-key.asc"
gpg --batch --armor --export "$fingerprint" > "$public_key_path"
if [[ ! -s "$public_key_path" ]]; then
  echo "Could not export RPM signing public key." >&2
  exit 1
fi

gpg_binary=$(command -v gpg)
rpmsign \
  --addsign \
  --define "__gpg $gpg_binary" \
  --define "_gpg_path $GNUPGHOME" \
  --define "_gpg_name $fingerprint" \
  --define "_openpgp_sign_id $fingerprint" \
  "$rpm_path"

rpm_db="$signing_root/rpmdb"
mkdir -m 700 "$rpm_db"
rpm --dbpath "$rpm_db" --initdb
rpm --dbpath "$rpm_db" --import "$public_key_path"

if ! verification_output=$(rpm --dbpath "$rpm_db" --checksig "$rpm_path"); then
  echo "RPM signature verification failed." >&2
  exit 1
fi

if [[ "$verification_output" != *"signatures OK"* || "$verification_output" == *"NOKEY"* || "$verification_output" == *"NOT OK"* ]]; then
  echo "RPM signature verification failed." >&2
  exit 1
fi

printf '%s\n' "$verification_output"
