#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Prepare System
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 01/18] PREPARE SYSTEM${C_NC}"
echo "------------------------------------------------------------"

# Simpan waktu mulai job. Dipakai STEP 18 (Keep Alive) untuk menghitung
# sisa waktu, supaya sleep tidak menabrak timeout job 360 menit.
echo "JOB_START_EPOCH=$(date +%s)" >> "$GITHUB_ENV"

# ============================================================
# TIMEZONE -> ASIA/JAKARTA (WIB, UTC+7)
#
# Runner GitHub default-nya UTC, jadi jam di desktop/CRD meleset 7 jam
# dari waktu Indonesia. Di-set sedini mungkin di step ini supaya
# semua log, timestamp file, dan jam desktop sesi CRD langsung WIB.
#
# Catatan penting: `timedatectl set-timezone` memperbarui
# /etc/localtime + state systemd, TAPI TIDAK memperbarui
# /etc/timezone. Tool lama (dpkg/tzdata dsb.) membaca /etc/timezone,
# jadi keduanya harus disamakan supaya tidak "balik" ke UTC.
# ============================================================
TZ_TARGET="Asia/Jakarta"

echo -e "${C_YELLOW}[INFO] Setting timezone to $TZ_TARGET (WIB, UTC+7)...${C_NC}"

if [ ! -e "/usr/share/zoneinfo/$TZ_TARGET" ]; then
  echo -e "${C_RED}[FAIL] zoneinfo $TZ_TARGET tidak tersedia.${C_NC}"
  exit 1
fi

# 1) Cara utama (systemd). Gagal pun tidak masalah -> ada fallback.
sudo timedatectl set-timezone "$TZ_TARGET" 2>/dev/null || true

# 2) Fallback/jaminan: /etc/timezone + symlink /etc/localtime
#    (cara ini juga benar untuk environment tanpa systemd).
echo "$TZ_TARGET" | sudo tee /etc/timezone > /dev/null
sudo ln -sf "/usr/share/zoneinfo/$TZ_TARGET" /etc/localtime

# 3) Sinkronkan metadata debconf tzdata agar tidak ditanya lagi dan
#    tidak kembali ke UTC saat package tzdata di-upgrade nanti.
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1 || true

# 4) tegaskan ulang symlink sesudah reconfigure, lalu verifikasi.
sudo ln -sf "/usr/share/zoneinfo/$TZ_TARGET" /etc/localtime
if [ "$(cat /etc/timezone 2>/dev/null)" != "$TZ_TARGET" ] || [ "$(date +%z)" != "+0700" ]; then
  echo -e "${C_RED}[FAIL] timezone tidak ter-set ke $TZ_TARGET.${C_NC}"
  cat /etc/timezone || true
  ls -l /etc/localtime || true
  date || true
  exit 1
fi
echo -e "${C_GREEN}[OK] Timezone: $(date +'%Z %z') | $(date)${C_NC}"

__prepare_start=$(date +%s)

# ============================================================
# NON-INTERACTIVE + NO SERVICE RESTART
#
# needrestart memindai proses dan me-restart service yang memakai
# library lama. Di runner CI itu buang-buang waktu DAN berisiko
# menyentuh service yang sedang dipakai sesi CRD. Dimatikan total.
# ============================================================
echo -e "${C_YELLOW}[INFO] Disabling needrestart entirely (no noisy logs, no auto-restart)...${C_NC}"
sudo rm -f /etc/apt/apt.conf.d/99needrestart || true
sudo rm -f /etc/apt/apt.conf.d/20needrestart || true
sudo mkdir -p /etc/needrestart/needrestart.conf.d || true
echo '$nrconf{restart} = '"'"'l'"'"';' | sudo tee /etc/needrestart/needrestart.conf.d/99-no-restart.conf > /dev/null
echo '$nrconf{kernelhints} = 0;' | sudo tee -a /etc/needrestart/needrestart.conf.d/99-no-restart.conf > /dev/null
echo '$nrconf{check} = 0;' | sudo tee -a /etc/needrestart/needrestart.conf.d/99-no-restart.conf > /dev/null

# ============================================================
# APT TUNING UNTUK KECEPATAN BUILD
# - Retries 5 + pipeline depth 10: unduhan lebih tahan gangguan.
# - Languages none: tidak mengunduh index terjemahan Multiarch.
# ============================================================
echo -e "${C_YELLOW}[INFO] Tuning apt for speed (retries, pipelining, minimal index languages)...${C_NC}"
sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/apt/99-speed.conf" /etc/apt/apt.conf.d/99-speed

# Pakai .deb dari cache GitHub (jika ada) agar upgrade/install
# tidak mengunduh ulang (hemat ~1GB saat re-run setelah gagal register).
echo -e "${C_YELLOW}[INFO] Seeding /var/cache/apt/archives from GitHub apt cache...${C_NC}"
sudo mkdir -p /var/cache/apt/archives/partial
sudo cp -a /home/runner/apt-archives/. /var/cache/apt/archives/ 2>/dev/null || true

echo -e "${C_YELLOW}[INFO] Updating package lists...${C_NC}"
sudo apt-get update

echo -e "${C_YELLOW}[INFO] Removing unnecessary packages...${C_NC}"
sudo apt-get remove -y --purge \
  man-db \
  firewalld \
  ufw \
  || true

sudo apt-get autoremove -y || true

# Hapus snapd + paket transisi snap SEBELUM upgrade. Image runner
# Ubuntu membawa firefox/snapd; upgrade paket transisi firefox bisa
# memicu "Installing the firefox snap" dan menunggu snap store lama.
# Hold mencegah paket ini ikut terpasang lagi oleh apt berikutnya.
echo -e "${C_YELLOW}[INFO] Removing snapd + snap transitional packages before upgrade...${C_NC}"
sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
sudo apt-get purge -y snapd thunderbird firefox || true
sudo apt-mark hold snapd thunderbird firefox
sudo rm -rf /snap /var/snap /var/lib/snapd /root/snap /home/runner/snap 2>/dev/null || true
command -v snap >/dev/null 2>&1 && echo -e "${C_YELLOW}[WARN] snap masih ada sebelum upgrade.${C_NC}" || echo -e "${C_GREEN}[OK] snapd dihapus sebelum upgrade.${C_NC}"

# Full upgrade di BUILD-TIME (aman, sebelum CRD/session jalan).
# Jangan `apt upgrade` manual dari dalam sesi CRD - itu me-restart
# chrome-remote-desktop/xfce4-session/systemd dan memutus sesi.
# Untuk upgrade dari dalam sesi, pakai `safe-upgrade` (scripts/safe-upgrade.sh).
echo -e "${C_YELLOW}[INFO] Full upgrade at build-time (fast unpack, no dpkg fsync)...${C_NC}"
sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
  -o Dpkg::Options::="--force-unsafe-io" \
  -o Dpkg::Use-Pty=0

__prepare_end=$(date +%s)
echo -e "${C_GREEN}[OK] System prepared. (Elapsed: $((__prepare_end-__prepare_start))s)${C_NC}"
