#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Configure XFCE Performance
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 10/18] CONFIGURE XFCE PERFORMANCE${C_NC}"
echo "------------------------------------------------------------"

# ============================================================
# 1. COMPOSITOR OFF (lever terbesar)
#
# xfwm4 tanpa compositor:
#   - tidak ada composite pass tiap frame,
#   - tidak ada GL shadow/alpha (tidak perlu llvmpipe untuk blur),
#   - CPU idle turun drastis di runner tanpa GPU,
#   - CRD menangkap frame X11 yang lebih murah.
#
# Nilai ini sudah di-seed lewat xfwm4.xml, tapi step iniMENJADIKAN
# guard runtime: ada helper yang memaksa nilainya tiap kali sesi start
# (xfwm4 bisa me-reset sebagian setting saat start).
# ============================================================
echo -e "${C_YELLOW}[INFO] Installing performance guard (compositor off enforcement)...${C_NC}"
sudo install -m 0755 "$REPO_ROOT/scripts/xfce/xfce-performance-guard.sh" /usr/local/bin/xfce-performance-guard.sh
sudo -u runner mkdir -p /home/runner/.config/autostart
sudo install -m 0644 -o runner -g runner \
  "$REPO_ROOT/assets/xfce/autostart/xfce-performance-guard.desktop" \
  /home/runner/.config/autostart/xfce-performance-guard.desktop

# ============================================================
# 2. MATIKAN TIMER & SERVICE LATAR
#
# Timer apt-daily / unattended-upgrades bisa berjalan DI TENGAH sesi dan
# melakukan burst CPU + lock dpkg. Itu pemutus sesi yang tidak terlihat.
# Service printer/avahi/bluetooth/modem tidak pernah dipakai di runner
# tapi tetap menahan RAM dan occasionally melakukan multicast/DHCP scan.
# ============================================================
echo -e "${C_YELLOW}[INFO] Masking background timers + unused services...${C_NC}"
mask_unit() {
  local unit="$1"
  if systemctl list-unit-files 2>/dev/null | grep -q "^${unit}"; then
    sudo systemctl mask --now "$unit" > /dev/null 2>&1 || true
    echo -e "    masked: ${unit}"
  fi
}

# Timer yang bisa berjalan di tengah sesi.
for unit in \
  apt-daily.timer \
  apt-daily-upgrade.timer \
  apt-daily.service \
  apt-daily-upgrade.service \
  unattended-upgrades.service \
  motd-news.timer \
  man-db.timer \
  man-db.service \
  update-notifier-download.timer \
  update-notifier.service \
  e2scrub_all.timer \
  e2scrub_all.service \
  sysstat-collect.timer \
  fstrim.timer \
  ; do
  mask_unit "$unit"
done

# Service yang tidak pernah dipakai di runner headless.
for unit in \
  cups.service \
  cups-browsed.service \
  avahi-daemon.service \
  avahi-daemon.socket \
  bluetooth.service \
  ModemManager.service \
  whoopsie.service \
  apport.service \
  kerneloops.service \
  fwupd.service \
  ; do
  mask_unit "$unit"
done

# ============================================================
# 3. AUTOSTART XFCE LEBIH RINGAN
#
# Whiskermenu + panel + xfsettingsd + xfdesktop + xfce4-notifyd
# sudah cukup. Plugin polling (systemload/weather/netload) sengaja
# tidak dipasang karena menarik data berkala.
# ============================================================
echo -e "${C_YELLOW}[INFO] Ensuring no polling panel plugins installed...${C_NC}"
for pkg in xfce4-systemload-plugin xfce4-weather-plugin xfce4-netload-plugin; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo -e "${C_YELLOW}[WARN] Plugin polling $pkg terpasang; dilepas.${C_NC}"
    sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge "$pkg" > /dev/null 2>&1 || true
  fi
done

# ============================================================
# 4. BERSIHKAN CACHE APT + PAGE CACHE
#
# Cache .deb sudah disalin ke /home/runner/apt-archives (untuk cache
# GitHub, disimpan di STEP 07), jadi /var/cache/apt/archives boleh dibuang:
# menghemat ~1GB disk dan mengurangi tekanan page cache.
#
# PENTING: /var/lib/apt/lists TIDAK dihapus di sini. STEP 13 masih
# memakai `apt-get install` (fallback ikon Papirus). Index paket juga
# dibutuhkan `sudo safe-upgrade` di dalam sesi CRD. Daftar paket hanya
# berukuran beberapa десяan MB, jadi tidak sebanding risikonya.
# ============================================================
echo -e "${C_YELLOW}[INFO] Cleaning apt archives + dropping page cache...${C_NC}"
sudo apt-get clean || true
sudo sync || true
if [ -w /proc/sys/vm/drop_caches ]; then
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
fi

# ============================================================
# 5. LIMITASI RESOURCE UNTUK SERVICE NON-DESKTOP
#
# Memberi CPUWeight rendah ke service yang tidak boleh mengambil
# sumber daya dari sesi desktop CRD.
# ============================================================
echo -e "${C_YELLOW}[INFO] Lowering CPU priority of background services...${C_NC}"
for unit in \
  libvirtd.service \
  virtqemud.service \
  polkit.service \
  NetworkManager.service \
  systemd-resolved.service \
  ; do
  if systemctl list-unit-files 2>/dev/null | grep -q "^${unit}"; then
    sudo systemctl set-property --runtime "$unit" CPUWeight=20 > /dev/null 2>&1 || true
  fi
done

echo -e "${C_GREEN}[OK] Tuning performa XFCE selesai (compositor off, timer dimatikan, service ringan).${C_NC}"
