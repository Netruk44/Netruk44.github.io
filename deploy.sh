#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="./public"

# Remove public folder if it exists
if [ -d "$PUBLIC_DIR" ]; then
  rm -rf "$PUBLIC_DIR"
fi

# Build site with Hugo
hugo --minify

# Sync generated site to remote server
rclone sync "$PUBLIC_DIR" storage:/home/nginx/personal_site/ --progress