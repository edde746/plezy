#!/bin/sh
set -eu

SEED_ROOT=/opt/plezy-demo
SEED_CONFIG="${SEED_ROOT}/seed-config"
SEED_CACHE="${SEED_ROOT}/seed-cache"
JELLYFIN_PID=""

stop_jellyfin() {
  if [ -n "${JELLYFIN_PID}" ] && kill -0 "${JELLYFIN_PID}" 2>/dev/null; then
    kill -TERM "${JELLYFIN_PID}"
    wait "${JELLYFIN_PID}" || true
  fi
}

on_exit() {
  exit_status=$?
  if [ "${exit_status}" -ne 0 ] && [ -f "${SEED_ROOT}/seed-jellyfin.log" ]; then
    cat "${SEED_ROOT}/seed-jellyfin.log" >&2
  fi
  stop_jellyfin
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "${SEED_CONFIG}/config" "${SEED_CONFIG}/log" "${SEED_CACHE}"
JELLYFIN_DATA_DIR="${SEED_CONFIG}" \
JELLYFIN_CONFIG_DIR="${SEED_CONFIG}/config" \
JELLYFIN_LOG_DIR="${SEED_CONFIG}/log" \
JELLYFIN_CACHE_DIR="${SEED_CACHE}" \
XDG_CACHE_HOME="${SEED_CACHE}" \
JELLYFIN_PublishedServerUrl="http://127.0.0.1:8096" \
  /jellyfin/jellyfin >"${SEED_ROOT}/seed-jellyfin.log" 2>&1 &
JELLYFIN_PID=$!

python3 "${SEED_ROOT}/maestro_real_jellyfin.py" bootstrap \
  --url http://127.0.0.1:8096 \
  --timeout 180 \
  --include-codecs

stop_jellyfin
JELLYFIN_PID=""
rm -rf "${SEED_CONFIG}/log" "${SEED_CACHE}" "${SEED_ROOT}/seed-jellyfin.log"
printf '%s\n' 'Plezy Jellyfin demo seed v1' >"${SEED_CONFIG}/.plezy-demo-seed"
trap - EXIT INT TERM
