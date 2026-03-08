#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE="root@212.132.75.249"
SSH_KEY="$HOME/.ssh/id_edde"
REMOTE_DIR="/opt/plezy-relay"
SSH="ssh -i $SSH_KEY $REMOTE"

cd "$SCRIPT_DIR"

echo "Syncing files to $REMOTE:$REMOTE_DIR..."
rsync -avz --exclude='plezy-relay' --exclude='plezy-server-linux-amd64' \
  -e "ssh -i $SSH_KEY" \
  . "$REMOTE:$REMOTE_DIR/"

echo "Deploying..."
$SSH "cd $REMOTE_DIR && docker compose up -d --build"

echo "Done."
