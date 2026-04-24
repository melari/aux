#!/usr/bin/env bash

set -e

if command -v jq >/dev/null 2>&1; then
  exit 0
fi

echo "Installing jq..."

case "$(uname)" in
  Darwin)
    brew install jq
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y jq
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm jq
    elif command -v apk >/dev/null 2>&1; then
      apk add --no-cache jq
    else
      echo "Error: unsupported Linux distribution. Please install jq manually."
      exit 1
    fi
    ;;
  *)
    echo "Error: unsupported OS '$(uname)'. Please install jq manually."
    exit 1
    ;;
esac
