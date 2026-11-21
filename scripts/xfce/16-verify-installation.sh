#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Verify Installation
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 16/18] VERIFY INSTALLATION${C_NC}"
echo "------------------------------------------------------------"

echo "::group::[CHECK] System"
uname -a
echo "::endgroup::"

echo "::group::[CHECK] XFCE session (direct exec, no wrapper)"
xfce4-session --version 2>/dev/null | head -n 1 || true
xfwm4 --version 2>/dev/null | head -n 1 || true
echo "--- session file ---"
cat /home/runner/.chrome-remote-desktop-session || true
echo "--- no Xsession/lightdm wrapper allowed ---"
if grep -q "Xsession\|lightdm" /home/runner/.chrome-remote-desktop-session; then
  echo "[FAIL] session file masih pakai wrapper!"
  exit 1
fi
echo "[OK] session file direct exec, bersih"
grep -q "exec /usr/bin/xfce4-session" /home/runner/.chrome-remote-desktop-session \
  || { echo "[FAIL] exec line tidak sesuai harapan!"; exit 1; }
if command -v xfce4-notifyd >/dev/null 2>&1; then
  echo -e "${C_GREEN}[OK] xfce4-notifyd ada di PATH ($(command -v xfce4-notifyd)).${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] xfce4-notifyd tidak ada di PATH (notifikasi dilewati).${C_NC}"
fi
echo "::endgroup::"

echo "::group::[CHECK] xfconf channels (compositor off + panel + session)"
XFCONF_DIR=/home/runner/.config/xfce4/xfconf/xfce-perchannel-xml
ls -l "$XFCONF_DIR" || true
echo "--- compositing setting ---"
grep -o 'name="use_compositing" type="bool" value="[a-z]*"' "$XFCONF_DIR/xfwm4.xml" || true
if grep -q 'name="use_compositing" type="bool" value="false"' "$XFCONF_DIR/xfwm4.xml"; then
  echo -e "${C_GREEN}[OK] xfwm4 compositor dimatikan di config.${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] setting compositor tidak ditemukan di xfwm4.xml.${C_NC}"
fi
echo "--- panel plugins ---"
grep -o 'value="[a-z-]*"/>' "$XFCONF_DIR/xfce4-panel.xml" | head -n 12 || true
echo "--- session clients ---"
grep -o '<value type="string" value="[a-z0-9-]*"/>' "$XFCONF_DIR/xfce4-session.xml" || true
echo "::endgroup::"

echo "::group::[CHECK] screensaver/lock disabled"
cat /etc/dconf/db/local.d/99-crd-no-lock || true
for pkg in xfce4-screensaver light-locker xscreensaver xfce4-power-manager; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo -e "${C_YELLOW}[WARN] Paket $pkg seharusnya tidak terpasang.${C_NC}"
  else
    echo -e "${C_GREEN}[OK] $pkg tidak terpasang.${C_NC}"
  fi
done
echo "::endgroup::"

echo "::group::[CHECK] Catppuccin theme (macchiato + mauve)"
THEME_DIR="/home/runner/.themes/catppuccin-macchiato-mauve-standard+default"
ls -d "$THEME_DIR" || true
ls -d "$THEME_DIR/gtk-3.0" 2>/dev/null || true
ls -d "$THEME_DIR/xfwm4" 2>/dev/null || true
ls -d /home/runner/.icons/catppuccin-macchiato-mauve-cursors || true
ls /home/runner/.config/gtk-4.0/gtk.css 2>/dev/null || true
ls /home/runner/.local/share/fonts/JetBrainsMonoNerd/ 2>/dev/null | head -n 3 || true
ls -l /home/runner/.config/xfce4/terminal/terminalrc || true
echo "--- xsettings ---"
grep -E "ThemeName|IconThemeName|CursorThemeName|FontName|EnableAnimations" "$XFCONF_DIR/xsettings.xml" || true
if [ -d "$THEME_DIR/gtk-3.0" ]; then
  echo -e "${C_GREEN}[OK] Tema Catppuccin terpasang (GTK/xfwm4/ikon/kursor/font/terminal).${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] Tema Catppuccin tidak lengkap.${C_NC}"
fi
echo "::endgroup::"

echo "::group::[CHECK] resolution target (1280x720, fallback 1024x768)"
grep -n "WANT_W=1280\|WANT_H=720\|FALLBACK_MODE" /usr/local/bin/set-resolution.sh || true
grep -n "1280x720" /home/runner/.chrome-remote-desktop-session || true
echo "--- CRD desktop size env ---"
grep -r "CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES" \
  /etc/systemd/system/chrome-remote-desktop@.service.d/ 2>/dev/null || true
grep "CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES" /home/runner/.profile 2>/dev/null || true
if grep -q "WANT_W=1280" /usr/local/bin/set-resolution.sh; then
  echo -e "${C_GREEN}[OK] target resolusi 1280x720 dengan fallback 1024x768.${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] target resolusi tidak konsisten.${C_NC}"
fi
echo "::endgroup::"

echo "::group::[CHECK] timezone (Asia/Jakarta)"
cat /etc/timezone || true
ls -l /etc/localtime || true
date || true
if [ "$(cat /etc/timezone 2>/dev/null)" = "Asia/Jakarta" ] && [ "$(date +%z)" = "+0700" ]; then
  echo -e "${C_GREEN}[OK] timezone WIB (Asia/Jakarta, +0700).${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] timezone bukan Asia/Jakarta.${C_NC}"
fi
echo "::endgroup::"

echo "::group::[CHECK] safe-upgrade helper"
which safe-upgrade || true
ls -l /usr/local/bin/safe-upgrade || true
safe-upgrade --help || true
ls -l /home/runner/Desktop/SafeUpgrade.desktop || true
echo "::endgroup::"

echo "::group::[CHECK] Desktop shortcuts"
ls -l /home/runner/Desktop/ || true
echo "::endgroup::"

echo "::group::[CHECK] Remote user"
id runner
echo "::endgroup::"

echo "::group::[CHECK] KVM / Virtualization"
ls -l /dev/kvm || true
getent group kvm libvirt || true
if sudo -u runner test -r /dev/kvm && sudo -u runner test -w /dev/kvm; then
  echo -e "${C_GREEN}[OK] runner dapat mengakses /dev/kvm.${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] runner tidak bisa akses /dev/kvm - instalasi tetap OK; KVM off di runner ini (lihat README, bagian KVM).${C_NC}"
fi
command -v qemu-system-x86_64 || echo "[WARN] qemu-system-x86_64 missing"
command -v virsh || echo "[WARN] virsh missing"
command -v virt-manager || echo "[WARN] virt-manager missing"

if sudo -u runner env HOME=/home/runner XDG_RUNTIME_DIR="/run/user/$(id -u runner)" \
     virsh capabilities 2>/dev/null | grep -q "domain type='kvm'"; then
  echo -e "${C_GREEN}[OK] libvirt default URI: KVM guest tersedia.${C_NC}"
else
  echo -e "${C_YELLOW}[WARN] virsh capabilities tidak menemukan KVM guest (cek uri_default).${C_NC}"
fi
systemctl is-enabled libvirtd 2>/dev/null || true
systemctl is-active libvirtd 2>/dev/null || true
echo "::endgroup::"

echo "::group::[CHECK] Snap removed"
command -v snap >/dev/null 2>&1 && echo -e "${C_YELLOW}[WARN] snap masih terpasang.${C_NC}" || echo -e "${C_GREEN}[OK] snap / snapd removed.${C_NC}"
apt-mark showhold | grep -qx snapd && echo -e "${C_GREEN}[OK] snapd held (tidak akan re-install).${C_NC}" || echo -e "${C_YELLOW}[WARN] snapd tidak di-hold.${C_NC}"
echo "::endgroup::"

echo "::group::[CHECK] Chrome Remote Desktop package"
dpkg-query -W -f='${Package} ${Version}\n' chrome-remote-desktop 2>/dev/null || true
command -v google-chrome || echo "[WARN] google-chrome missing"
command -v opencode || echo "[WARN] opencode missing"
echo "::endgroup::"

echo ""
echo -e "${C_GREEN}[OK] Installation verification completed.${C_NC}"
