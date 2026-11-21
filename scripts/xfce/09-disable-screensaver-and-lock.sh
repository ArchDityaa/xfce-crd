#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Disable Screensaver and Lock
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 09/18] DISABLE SCREENSAVER AND LOCK${C_NC}"
echo "------------------------------------------------------------"

# ============================================================
# STRATEGI 3 LAPIS
#
# Lapisan 1 (paling penting): paket locker TIDAK DIINSTALL sama sekali.
#   - xfce4-screensaver, light-locker, xscreensaver, xfce4-power-manager
#   Hasil: XFCE tidak punya apa pun untuk mengunci layar.
#
# Lapisan 2: konfigurasi xfconf/session.
#   - SaveOnExit=false (tidak ada dialog "save session?" saat logout)
#   - idle-delay=0 (tidak ada idle blanking)
#
# Lapisan 3: X11 level + dconf system-wide untuk aplikasi GTK/GNOME.
#   - xset s off -dpms s noblank
#   - org.gnome.desktop.screensaver lock-enabled=false
# ============================================================

echo -e "${C_YELLOW}[INFO] Memastikan paket locker/screensaver tidak terpasang...${C_NC}"
for pkg in xfce4-screensaver light-locker xscreensaver xfce4-power-manager mate-screensaver; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo -e "${C_YELLOW}[WARN] Paket $pkg terpasang; dilepas (bukan dibutuhkan untuk CRD).${C_NC}"
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge "$pkg" > /dev/null 2>&1 || true
  fi
done

echo -e "${C_YELLOW}[INFO] Menulis konfigurasi lock system-wide (dconf)...${C_NC}"
sudo mkdir -p /etc/dconf/db/local.d || true
sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/dconf/99-crd-no-lock" /etc/dconf/db/local.d/99-crd-no-lock
sudo dconf update || true

# Fallback per-user gsettings (jalan saat sesi aktif; abaikan bila dbus belum ada).
sudo -u runner dbus-launch --exit-with-session gsettings set org.gnome.desktop.screensaver lock-enabled false || true
sudo -u runner dbus-launch --exit-with-session gsettings set org.gnome.desktop.screensaver idle-activation-enabled false || true
sudo -u runner dbus-launch --exit-with-session gsettings set org.gnome.desktop.session idle-delay 0 || true
sudo -u runner dbus-launch --exit-with-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' || true
sudo chown -R runner:runner /home/runner/.config || true

echo -e "${C_YELLOW}[INFO] Memastikan xfconf tidak menyimpan lock/session...${C_NC}"
# xfce4-session: jangan pernah menahan sesi dengan dialog.
sudo -u runner dbus-run-session -- xfconf-query -c xfce4-session -p /general/SaveOnExit -s false 2>/dev/null || true
sudo chown -R runner:runner /home/runner/.config || true

echo -e "${C_GREEN}[OK] Screensaver, lock, dan suspend dimatikan.${C_NC}"
