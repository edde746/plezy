#!/bin/sh
set -eu

SEED_CONFIG=/opt/plezy-demo/seed-config
SEED_MARKER=.plezy-demo-seed

if [ ! -f "/config/${SEED_MARKER}" ]; then
  existing="$(find /config -mindepth 1 -maxdepth 1 -print -quit)"
  if [ -n "${existing}" ]; then
    echo "Refusing to overwrite a non-demo Jellyfin configuration in /config." >&2
    echo "Start this image with a new or empty /config volume." >&2
    exit 1
  fi
  cp -a "${SEED_CONFIG}/." /config/
fi

exec /jellyfin/jellyfin "$@"
