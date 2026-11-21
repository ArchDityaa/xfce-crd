#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Configure CRD XFCE Session
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 08/18] CONFIGURE CRD XFCE SESSION${C_NC}"
echo "------------------------------------------------------------"

echo -e "${C_YELLOW}[INFO] Detecting available XFCE session...${C_NC}"
ls /usr/share/xsessions/*.desktop || true
grep -h "^Exec=" /usr/share/xsessions/*.desktop || true
ls -l /usr/bin/xfce4-session* /usr/bin/startxfce4 2>/dev/null || true
ls /usr/share/xfce4/sessions/ 2>/dev/null || true

echo -e "${C_YELLOW}[INFO] Fail-fast: binary wajib harus ada...${C_NC}"
for bin in /usr/bin/xfce4-session /usr/bin/xfwm4 /usr/bin/xfce4-panel /usr/bin/xfce4-settings /usr/bin/xfdesktop; do
  test -x "$bin" || { echo -e "${C_RED}[FAIL] $bin missing.${C_NC}"; exit 1; }
done
test -f /usr/share/xsessions/xfce.desktop || { echo -e "${C_RED}[FAIL] xsessions/xfce.desktop missing.${C_NC}"; exit 1; }

# ============================================================
# NOTIFYD BINARY DI PATH
#
# Paket xfce4-notifyd di Ubuntu placing daemon-nya di:
#   /usr/lib/<triplet>/xfce4/notifyd/xfce4-notifyd
# (hanya xfce4-notifyd-config yang ada di /usr/bin). Akibatnya client
# sesi "xfce4-notifyd" gagal start dengan:
#   Unable to launch "xfce4-notifyd": No such file or directory
#
# Fix: symlink ke /usr/local/bin (selalu ada di PATH).
# ============================================================
echo -e "${C_YELLOW}[INFO] Linking xfce4-notifyd into PATH...${C_NC}"
NOTIFYD_BIN="$(find /usr/lib -type f -name xfce4-notifyd -perm -u+x 2>/dev/null | head -n1 || true)"
if [ -n "$NOTIFYD_BIN" ]; then
  sudo ln -sf "$NOTIFYD_BIN" /usr/local/bin/xfce4-notifyd
  echo -e "${C_GREEN}[OK] xfce4-notifyd -> $NOTIFYD_BIN${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] Binary xfce4-notifyd tidak ditemukan; notifikasi desktop dilewati.${C_NC}"
fi

RUNNER_UID=$(id -u runner)
echo -e "${C_YELLOW}[INFO] runner UID=$RUNNER_UID${C_NC}"
sudo mkdir -p "/run/user/$RUNNER_UID"
sudo chown runner:runner "/run/user/$RUNNER_UID"
sudo chmod 700 "/run/user/$RUNNER_UID"

# ============================================================
# SEED xfconf
#
# Konfigurasi XFCE disimpan sebagai XML per-channel di:
#   ~/.config/xfce4/xfconf/xfce-perchannel-xml/<channel>.xml
#
# Menulis XML langsung (bukan lewat xfconf-query) deliberate: saat build
# time tidak ada sesi X/dbus, jadi xfconf-query tidak bisa menulis ke
# dconf user dengan aman. XML yang ditulis di sini langsung dipakai
# xfce4-session/xfsettingsd saat sesi CRD start.
# ============================================================
XFCONF_DIR=/home/runner/.config/xfce4/xfconf/xfce-perchannel-xml
echo -e "${C_YELLOW}[INFO] Seeding xfconf channels (xfwm4, panel, session, desktop, xsettings)...${C_NC}"
sudo -u runner mkdir -p "$XFCONF_DIR"
for xml in xfwm4 xfce4-panel xfce4-session xfce4-desktop xsettings; do
  sudo install -m 0644 -o runner -g runner \
    "$REPO_ROOT/assets/xfce/xfconf/${xml}.xml" \
    "$XFCONF_DIR/${xml}.xml"
done

# ============================================================
# RESOLUSI 1280x720 (JALUR RESMI CRD)
#
# Chrome Remote Desktop modern (>= 120) membaca environment variable:
#   CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=WIDTHxHEIGHT
# dan mendaftarkan mode tersebut di RandR, lalu menjadikannya initial mode.
#
# Cara paling bersih: systemd drop-in untuk unit CRD. Jalur kedua
# (~/.profile) dipakai untuk versi CRD lama yang membaca profile user.
# Jalur ketiga (helper xrandr) tetap dipasang sebagai jaring pengaman.
# ============================================================
echo -e "${C_YELLOW}[INFO] Configuring CRD desktop size (1280x720)...${C_NC}"
CRD_SIZES="1280x720"

sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/systemd/10-desktop-size.conf" \
  /etc/systemd/system/chrome-remote-desktop@.service.d/10-desktop-size.conf

# Unit multi-process host (versi CRD baru) - pasang juga bila ada.
if systemctl list-unit-files 2>/dev/null | grep -q '^chrome-remote-desktop-x11-session@.service'; then
  sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/systemd/10-desktop-size.conf" \
    /etc/systemd/system/chrome-remote-desktop-x11-session@.service.d/10-desktop-size.conf
fi

sudo systemctl daemon-reload || true

# Jalur kedua: ~/.profile (dipakai CRD versi lama yang membaca profile user).
if ! grep -q 'CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES' /home/runner/.profile 2>/dev/null; then
  echo "export CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=$CRD_SIZES" \
    | sudo tee -a /home/runner/.profile > /dev/null
fi

# ============================================================
# HELPER RESOLUSI + WALLPAPER
# ============================================================
echo -e "${C_YELLOW}[INFO] Installing resolution + wallpaper helpers...${C_NC}"
sudo install -m 0755 "$REPO_ROOT/scripts/xfce/set-resolution.sh" /usr/local/bin/set-resolution.sh
sudo install -m 0755 "$REPO_ROOT/scripts/xfce/set-wallpaper.sh" /usr/local/bin/set-wallpaper.sh
sudo -u runner mkdir -p /home/runner/.config/autostart
sudo install -m 0644 -o runner -g runner \
  "$REPO_ROOT/assets/xfce/autostart/set-resolution.desktop" \
  /home/runner/.config/autostart/set-resolution.desktop
sudo install -m 0644 -o runner -g runner \
  "$REPO_ROOT/assets/xfce/autostart/set-wallpaper.desktop" \
  /home/runner/.config/autostart/set-wallpaper.desktop

# ============================================================
# FILE SESI CRD
# Direct exec ke /usr/bin/xfce4-session (tanpa Xsession/lightdm).
# ============================================================
echo -e "${C_YELLOW}[INFO] Writing .chrome-remote-desktop-session (direct absolute-path exec)...${C_NC}"
sed -e "s|@RUNNER_UID@|$RUNNER_UID|g" \
  "$REPO_ROOT/assets/xfce/session/chrome-remote-desktop-session.in" \
  | sudo -u runner tee /home/runner/.chrome-remote-desktop-session > /dev/null

sudo chown runner:runner /home/runner/.chrome-remote-desktop-session
sudo chmod +x /home/runner/.chrome-remote-desktop-session

# ============================================================
# FINAL CHECK: tidak boleh ada wrapper Xsession/lightdm.
# Wrapper seperti ini notorious memutus sesi CRD saat paket di-upgrade.
# ============================================================
echo "------------------------------------------------------------"
cat /home/runner/.chrome-remote-desktop-session || true
echo "------------------------------------------------------------"
echo -e "${C_YELLOW}[INFO] Final check: no Xsession/lightdm wrapper allowed...${C_NC}"
if grep -q "Xsession\|lightdm" /home/runner/.chrome-remote-desktop-session; then
  echo -e "${C_RED}[FAIL] session file masih mengandung Xsession/lightdm.${C_NC}"
  exit 1
fi
grep -q "exec /usr/bin/xfce4-session" /home/runner/.chrome-remote-desktop-session \
  || { echo -e "${C_RED}[FAIL] exec line bukan xfce4-session.${C_NC}"; exit 1; }

sudo chown -R runner:runner /home/runner/.config /home/runner/.cache 2>/dev/null || true

echo -e "${C_GREEN}[OK] XFCE session configured for CRD (X11, direct exec, no compositor).${C_NC}"
