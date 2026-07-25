#!/usr/bin/env bash
# Install / update personal Cursor skill from this repo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.cursor/skills/local-cicd"

mkdir -p "${HOME}/.cursor/skills"
rsync -a --delete \
  --exclude '.git' \
  --exclude 'README.md' \
  --exclude 'install.sh' \
  "$ROOT/" "$DEST/"

chmod +x "$DEST"/scripts/*.sh
printf 'Installed local-cicd → %s\n' "$DEST"
ls -la "$DEST/scripts"
