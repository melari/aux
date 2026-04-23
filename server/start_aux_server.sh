#!/bin/bash

SSH_KEY="/home/appuser/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "Generating SSH keypair..."
  ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"
  echo "Public key:"
  cat "${SSH_KEY}.pub"
fi

BARE_REPO="./bare_repo.git"

if [ ! -d "$BARE_REPO" ] || ! git -C "$BARE_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Initializing bare git repository in $BARE_REPO..."
  git init --bare "$BARE_REPO"
fi

while true; do
  sleep 60
  { aux sync-all 2>&1 || true; } | sed 's/^/[aux sync-all] /'
done &

exec bundle exec ruby /app/app.rb
