#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Set Wallpaper
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 12/18] SET WALLPAPER${C_NC}"
echo "------------------------------------------------------------"

echo -e "${C_YELLOW}[INFO] Downloading Catppuccin 'black unicat' wallpaper...${C_NC}"
sudo -u runner mkdir -p /home/runner/Pictures
sudo -u runner wget -q -O /home/runner/Pictures/wallpaper.png \
  "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/minimalistic/black5_unicat.png" \
  || { echo -e "${C_RED}[FAIL] Gagal mengunduh wallpaper.${C_NC}"; exit 1; }
sudo chown runner:runner /home/runner/Pictures/wallpaper.png

echo -e "${C_YELLOW}[INFO] Applying wallpaper via xfconf (xfdesktop)...${C_NC}"
# Nama monitor pada driver dummy bisa berbeda, jadi wallpaper FINAL
# diterapkan oleh helper runtime /usr/local/bin/set-wallpaper.sh
# (autostart). Di sini kita hanya memastikan file + helper siap.
sudo install -m 0755 "$REPO_ROOT/scripts/xfce/set-wallpaper.sh" /usr/local/bin/set-wallpaper.sh
sudo -u runner mkdir -p /home/runner/.config/autostart
sudo install -m 0644 -o runner -g runner \
  "$REPO_ROOT/assets/xfce/autostart/set-wallpaper.desktop" \
  /home/runner/.config/autostart/set-wallpaper.desktop

# Seed nilai default di xfconf (akan di-refine runtime oleh helper).
sudo -u runner mkdir -p /home/runner/.config/xfce4/xfconf/xfce-perchannel-xml
sudo install -m 0644 -o runner -g runner \
  "$REPO_ROOT/assets/xfce/xfconf/xfce4-desktop.xml" \
  /home/runner/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

echo "------------------------------------------------------------"
ls -l /home/runner/Pictures/wallpaper.png || true
sudo -u runner file /home/runner/Pictures/wallpaper.png || true
echo "------------------------------------------------------------"

echo -e "${C_GREEN}[OK] Wallpaper installed for runner.${C_NC}"
