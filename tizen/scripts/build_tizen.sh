#!/usr/bin/env bash

# Build a signed Tizen TPK for distribution.
#
# Local dev usage (uses your active Tizen Studio profile):
#   ./tizen/scripts/build_tizen.sh
#
# CI usage (set these env vars from secrets before running):
#   TIZEN_AUTHOR_CERT_BASE64    - base64-encoded author .p12 certificate
#   TIZEN_AUTHOR_CERT_PASSWORD  - author certificate password
#   TIZEN_DIST_CERT_BASE64      - base64-encoded distributor .p12 certificate
#   TIZEN_DIST_CERT_PASSWORD    - distributor certificate password
#
# TIZEN_BUILD=true is always injected so the compiled TPK has the correct
# platform branches regardless of how flutter-tizen was invoked.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROFILE_NAME="tizen_signing"

# Sync tizen-manifest.xml version from pubspec.yaml (e.g. "2.2.0+100" -> "2.2.0").
PUBSPEC_VERSION="$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | sed 's/+.*//' | tr -d '[:space:]')"
if [[ -n "$PUBSPEC_VERSION" ]]; then
	sed -i "s/\(<manifest[^>]* version=\"\)[^\"]*\"/\1$PUBSPEC_VERSION\"/" "$REPO_ROOT/tizen/tizen-manifest.xml"
	echo "Tizen manifest version set to $PUBSPEC_VERSION"
fi

MODE="--release"
EXTRA_ARGS=()
for arg in "$@"; do
	if [[ "$arg" == "--debug" ]]; then
		MODE="--debug"
	else
		EXTRA_ARGS+=("$arg")
	fi
done

# If CI credentials are present, write the certificate profile so flutter-tizen
# can pick it up.
if [[ -n "${TIZEN_AUTHOR_CERT_BASE64:-}" ]]; then
	: "${TIZEN_AUTHOR_CERT_PASSWORD:?Missing TIZEN_AUTHOR_CERT_PASSWORD}"
	: "${TIZEN_DIST_CERT_BASE64:?Missing TIZEN_DIST_CERT_BASE64}"
	: "${TIZEN_DIST_CERT_PASSWORD:?Missing TIZEN_DIST_CERT_PASSWORD}"
	# Resolve the SDK data directory from sdk.info (set at install time).
	TIZEN_SDK_DATA_PATH="$(grep 'TIZEN_SDK_DATA_PATH' "$HOME/tizen-studio/sdk.info" | cut -d= -f2 | tr -d '[:space:]')"
	: "${TIZEN_SDK_DATA_PATH:?Could not read TIZEN_SDK_DATA_PATH from sdk.info}"

	CERT_DIR="$TIZEN_SDK_DATA_PATH/keystore/signing/$PROFILE_NAME"
	mkdir -p "$CERT_DIR"

	echo "$TIZEN_AUTHOR_CERT_BASE64" | base64 --decode >"$CERT_DIR/author.p12"
	echo "$TIZEN_DIST_CERT_BASE64" | base64 --decode >"$CERT_DIR/distributor.p12"

	# tizen security-profiles add stores passwords in GNOME keyring and writes
	# password="" in profiles.xml. The tz signing tool reads from the keyring at
	# build time. Writing plain-text passwords directly into profiles.xml causes
	# "wrong crypted size" because tz always expects either an encrypted value or
	# an empty string (keyring lookup).
	tizen security-profiles add \
		-n "$PROFILE_NAME" \
		-a "$CERT_DIR/author.p12" \
		-p "$TIZEN_AUTHOR_CERT_PASSWORD" \
		-d "$CERT_DIR/distributor.p12" \
		-dp "$TIZEN_DIST_CERT_PASSWORD" \
		-A -f
	echo "Certificate profile '$PROFILE_NAME' registered via tizen security-profiles"
fi

flutter-tizen build tpk \
	$MODE \
	--dart-define=TIZEN_BUILD=true \
	"${EXTRA_ARGS[@]}"
