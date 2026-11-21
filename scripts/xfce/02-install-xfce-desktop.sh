#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Install XFCE Desktop
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 02/18] INSTALL XFCE DESKTOP${C_NC}"
echo "------------------------------------------------------------"

echo -e "${C_YELLOW}[INFO] Installing XFCE desktop (lean: no recommends, no display manager)...${C_NC}"

# XFCE ada di universe. Image runner biasanya sudah punya universe,
# tetapi guard ini membuat workflow tetap jalan di image minimal.
if ! apt-cache show xfce4 >/dev/null 2>&1; then
  echo -e "${C_YELLOW}[INFO] Paket xfce4 belum terlihat; mengaktifkan universe...${C_NC}"
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y universe
  sudo apt-get update
fi

# Slim font: beberapa metapackage desktop merekomendasikan font
# raksasa (fonts-noto-cjk 61MB, cjk-extra 145MB, extra 78.5MB) yang
# tidak dibutuhkan. Pin negative membuat apt melewatinya
# (safe: hanya Recommends, bukan Depends). Pin dihapus setelah install.
sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/apt/99-no-noto-heavy.pref" /etc/apt/preferences.d/99-no-noto-heavy

# XFCE tidak membutuhkan snap. Blokir snapd + deb transisi
# (thunderbird/firefox -> snap) agar apt tidak menariknya lewat
# Recommends paket lain. Pin dihapus setelah install.
sudo install -D -m 0644 "$REPO_ROOT/assets/xfce/apt/99-no-snap.pref" /etc/apt/preferences.d/99-no-snap.pref

# ============================================================
#  DAFTAR PAKET
#
#  Prinsip: seminimal mungkin yang tetap berupa desktop environment utuh.
#  - `--no-install-recommends` mencegah paket media/ekstra yang tidak dipakai.
#  - TIDAK ada `xfce4-goodies` (plugin berat, tidak dipakai).
#  - TIDAK ada `xfce4-power-manager` (DPMS dimatikan lewat xset).
#  - TIDAK ada `xfce4-screensaver` / `light-locker` (tidak ada lock).
#  - TIDAK ada `tumbler` (thumbnailer = CPU mahal saat browse file).
#  - TIDAK ada display manager (CRD menjalankan sesi langsung).
#  - `xserver-xorg-video-dummy` WAJIB: driver dummy dipakai Xorg CRD
#    (tidak otomatis ikut terpasang lewat paket `xorg`).
# ============================================================
sudo NEEDRESTART_MODE=l DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  -o Dpkg::Use-Pty=0 \
  xfce4 \
  xfce4-terminal \
  xfce4-notifyd \
  xfce4-clipman-plugin \
  xfce4-whiskermenu-plugin \
  xfce4-taskmanager \
  xfce4-screenshooter \
  thunar \
  thunar-archive-plugin \
  thunar-volman \
  mousepad \
  ristretto \
  xarchiver \
  mate-polkit \
  xorg \
  xserver-xorg-video-dummy \
  x11-xserver-utils \
  x11-utils \
  dbus-x11 \
  dbus-user-session \
  dconf-cli \
  libgl1-mesa-dri \
  libglx-mesa0 \
  mesa-utils \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-user-dirs \
  pipewire \
  pipewire-pulse \
  wireplumber \
  pavucontrol \
  libcanberra-pulse \
  sound-theme-freedesktop \
  adwaita-icon-theme \
  fonts-cantarell \
  fonts-liberation \
  papirus-icon-theme \
  gnome-calculator \
  xclip \
  neofetch \
  qemu-system-x86 \
  qemu-utils \
  libvirt-daemon-system \
  libvirt-clients \
  virtinst \
  virt-manager \
  virt-viewer \
  gir1.2-spiceclientgtk-3.0 \
  xvfb

sudo rm -f /etc/apt/preferences.d/99-no-snap.pref

# Hapus permanen snapd + deb transisi thunderbird/firefox. Tidak ada
# paket yang hard-Depends ke snapd di graph install ini, jadi aman.
# Hold mencegah re-install oleh operasi apt berikutnya.
sudo apt-get purge -y snapd thunderbird firefox || true
sudo apt-mark hold snapd thunderbird firefox
sudo rm -rf /snap /var/snap /var/lib/snapd /root/snap /home/runner/snap 2>/dev/null || true
command -v snap >/dev/null 2>&1 && echo -e "${C_YELLOW}[WARN] snap masih ada.${C_NC}" || echo -e "${C_GREEN}[OK] snap dihapus permanen.${C_NC}"

sudo rm -f /etc/apt/preferences.d/99-no-noto-heavy
echo -e "${C_GREEN}[OK] Heavy Noto fonts (cjk / cjk-extra / extra) skipped (~285MB saved).${C_NC}"

# ============================================================
# CACHE GTK & SCHEMA
#
# Cache ikon GTK dan schema GSettings di advance SEBELUM sesi
# started, supaya aplikasi tidak melakukan scanning ribet saat pertama
# kali dibuka (delay ini terasa di remote lewat jaringan).
# ============================================================
echo -e "${C_YELLOW}[INFO] Compiling GSettings schemas + GTK icon caches...${C_NC}"
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ || true
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
sudo gtk-update-icon-cache -f -t /usr/share/icons/Papirus 2>/dev/null || true

echo "------------------------------------------------------------"
dpkg-query -W -f='${Package} ${Version}\n' \
  xfce4 xfce4-session xfce4-panel xfce4-settings xfce4-terminal \
  xfwm4 xfdesktop4 xfconf thunar 2>/dev/null || true
ls /usr/share/xsessions/xfce.desktop || true
ls /usr/lib/xorg/modules/drivers/dummy_drv.so 2>/dev/null || \
  ls /usr/lib/xorg/modules/drivers/dummy.so 2>/dev/null || true
echo "------------------------------------------------------------"

# Fail-fast: binary yang WAJIB ada untuk sesi CRD.
for bin in /usr/bin/xfce4-session /usr/bin/xfwm4 /usr/bin/xfce4-panel; do
  if [ ! -x "$bin" ]; then
    echo -e "${C_RED}[FAIL] Binary wajib hilang: $bin${C_NC}"
    exit 1
  fi
done

echo -e "${C_GREEN}[OK] XFCE installed (lean).${C_NC}"
