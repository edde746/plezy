#!/bin/bash
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  cd /opt/plezy/x64 && exec ./plezy "$@" ;;
  aarch64) cd /opt/plezy/arm64 && exec ./plezy "$@" ;;
  *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac
