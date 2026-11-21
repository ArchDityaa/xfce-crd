#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Sync apt cache for GitHub save
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

sudo mkdir -p /home/runner/apt-archives
sudo cp -a /var/cache/apt/archives/. /home/runner/apt-archives/ || true
sudo chown -R runner:runner /home/runner/apt-archives || true

echo "------------------------------------------------------------"
du -sh /home/runner/apt-archives 2>/dev/null || true
ls /home/runner/apt-archives 2>/dev/null | head -n 10 || true
echo "------------------------------------------------------------"
