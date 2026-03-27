#!/bin/bash

BARE_REPO="./bare_repo.git"

if [ ! -d "$BARE_REPO" ] || ! git -C "$BARE_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Initializing bare git repository in $BARE_REPO..."
  git init --bare "$BARE_REPO"
fi

