#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Install Catppuccin Theme (Macchiato + Mauve)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 13/18] INSTALL CATPPUCCIN THEME (MACCHIATO + MAUVE)${C_NC}"
echo "------------------------------------------------------------"

FLAVOR="macchiato"
ACCENT="mauve"
GTK_THEME="catppuccin-${FLAVOR}-${ACCENT}-standard+default"
CURSOR_THEME="catppuccin-${FLAVOR}-${ACCENT}-cursors"
RUSER="runner"
RHOME="/home/${RUSER}"

# Versi aset di-pin agar build reproducible.
GTK_THEME_VERSION="v1.0.3"
CURSOR_VERSION="v2.0.0"
FONT_VERSION="v3.5.1"

# ---- 1. Ikon Papirus + folder warna Catppuccin ----
echo -e "${C_YELLOW}[INFO] Installing Papirus icon theme + Catppuccin folders...${C_NC}"
# Papirus sudah terpasang di STEP 02, jadi di sini hanya installing kalau
# somehow belum ada (fallback). Jangan `apt-get install` unconditional:
# kalau index paket sudah dibersihkan, apt gagal dengan "Unable to locate
# package" dan `set -e`/workflow ikut gagal.
if ! dpkg -s papirus-icon-theme >/dev/null 2>&1; then
  echo -e "${C_YELLOW}[INFO] papirus-icon-theme belum ada; apt-get update lalu install...${C_NC}"
  sudo apt-get update -qq || true
  sudo NEEDRESTART_MODE=l apt-get install -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    -o Dpkg::Use-Pty=0 \
    papirus-icon-theme
else
  echo -e "${C_GREEN}[OK] papirus-icon-theme sudah terpasang (dari STEP 02).${C_NC}"
fi

rm -rf /tmp/papirus-folders
git clone --depth 1 https://github.com/catppuccin/papirus-folders.git /tmp/papirus-folders
wget -qO /tmp/papirus-folders-bin \
  https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders
sudo install -m 0755 /tmp/papirus-folders-bin /usr/local/bin/papirus-folders
sudo cp -r /tmp/papirus-folders/src/. /usr/share/icons/Papirus/
sudo papirus-folders -C "cat-${FLAVOR}-${ACCENT}" --theme Papirus || true
sudo papirus-folders -C "cat-${FLAVOR}-${ACCENT}" --theme Papirus-Dark || true

# ---- 2. Tema GTK (GTK2/3/4 + xfwm4) ----
# ZIP Catppuccin GTK v1.0.3 berisi folder xfwm4/ -> tema window manager
# XFCE bisa memakai paket yang sama (tanpa unduhan tambahan).
# Nama aset mengandung '+', jadi di URL di-encode ke %2B.
echo -e "${C_YELLOW}[INFO] Downloading Catppuccin GTK theme ($GTK_THEME)...${C_NC}"
sudo -u "$RUSER" mkdir -p "$RHOME/.themes" "$RHOME/.icons"
wget -qO /tmp/cat-gtk.zip \
  "https://github.com/catppuccin/gtk/releases/download/${GTK_THEME_VERSION}/${GTK_THEME//+/%2B}.zip"
sudo -u "$RUSER" unzip -qo /tmp/cat-gtk.zip -d "$RHOME/.themes/"

# Override libadwaita: gtk.css + assets ke ~/.config/gtk-4.0 supaya
# aplikasi GTK4/libadwaita (Settings, Calculator, dll) ikut bertema.
if [ -d "$RHOME/.themes/$GTK_THEME/gtk-4.0" ]; then
  sudo -u "$RUSER" mkdir -p "$RHOME/.config/gtk-4.0"
  sudo -u "$RUSER" cp -r "$RHOME/.themes/$GTK_THEME/gtk-4.0/." "$RHOME/.config/gtk-4.0/"
fi

# ---- 3. Kursor Catppuccin ----
echo -e "${C_YELLOW}[INFO] Downloading Catppuccin cursors...${C_NC}"
wget -qO /tmp/cat-cursors.zip \
  "https://github.com/catppuccin/cursors/releases/download/${CURSOR_VERSION}/${CURSOR_THEME}.zip"
sudo -u "$RUSER" unzip -qo /tmp/cat-cursors.zip -d "$RHOME/.icons/"

# ---- 4. Font JetBrainsMono Nerd Font ----
echo -e "${C_YELLOW}[INFO] Downloading JetBrainsMono Nerd Font...${C_NC}"
sudo -u "$RUSER" mkdir -p "$RHOME/.local/share/fonts/JetBrainsMonoNerd"
wget -qO /tmp/cat-font.zip \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/JetBrainsMono.zip"
sudo -u "$RUSER" unzip -qo /tmp/cat-font.zip -d "$RHOME/.local/share/fonts/JetBrainsMonoNerd"
sudo -u "$RUSER" fc-cache -f "$RHOME/.local/share/fonts" >/dev/null 2>&1 || true

# ---- 5. Terapkan tema via xfconf (XML) ----
# Ditulis sebagai XML per-channel supaya langsung dipakai xfsettingsd
# saat sesi CRD start (tidak butuh dbus saat build time).
echo -e "${C_YELLOW}[INFO] Applying theme via xfconf XML (user: $RUSER)...${C_NC}"
XFCONF_DIR="$RHOME/.config/xfce4/xfconf/xfce-perchannel-xml"
sudo -u "$RUSER" mkdir -p "$XFCONF_DIR"

sudo install -m 0644 -o "$RUSER" -g "$RUSER" \
  "$REPO_ROOT/assets/xfce/xfconf/xsettings.xml" "$XFCONF_DIR/xsettings.xml"

# xfwm4 theme: ganti placeholder nama tema di xfwm4.xml.
sudo sed "s|catppuccin-macchiato-mauve-standard+default|${GTK_THEME}|g" \
  "$REPO_ROOT/assets/xfce/xfconf/xfwm4.xml" \
  | sudo install -m 0644 -o "$RUSER" -g "$RUSER" /dev/stdin "$XFCONF_DIR/xfwm4.xml"

# ---- 6. Terminal XFCE (palet Catppuccin) ----
echo -e "${C_YELLOW}[INFO] Installing Catppuccin palette for xfce4-terminal...${C_NC}"
sudo -u "$RUSER" mkdir -p "$RHOME/.config/xfce4/terminal"
sudo install -m 0644 -o "$RUSER" -g "$RUSER" \
  "$REPO_ROOT/assets/xfce/terminal/terminalrc" "$RHOME/.config/xfce4/terminal/terminalrc"

# ---- 7. Cache ikon untuk tema baru ----
sudo gtk-update-icon-cache -f -t /usr/share/icons/Papirus 2>/dev/null || true

# ---- 8. Bersihkan unduhan sementara ----
rm -f /tmp/cat-gtk.zip /tmp/cat-cursors.zip /tmp/cat-font.zip /tmp/papirus-folders-bin
rm -rf /tmp/papirus-folders

sudo chown -R "$RUSER:$RUSER" \
  "$RHOME/.themes" "$RHOME/.icons" "$RHOME/.config" "$RHOME/.local" 2>/dev/null || true

echo "------------------------------------------------------------"
echo "--- themes (runner) ---"; ls "$RHOME/.themes" || true
echo "--- cursors (runner) ---"; ls "$RHOME/.icons" || true
echo "--- xfwm4 theme dir ---"; ls "$RHOME/.themes/$GTK_THEME/xfwm4" 2>/dev/null || true
echo "--- terminalrc ---"; ls -l "$RHOME/.config/xfce4/terminal/terminalrc" || true
echo "--- fonts ---"; ls "$RHOME/.local/share/fonts/JetBrainsMonoNerd" 2>/dev/null | head -n 3 || true
echo "------------------------------------------------------------"

if [ ! -d "$RHOME/.themes/$GTK_THEME/gtk-3.0" ]; then
  echo -e "${C_RED}[FAIL] Tema GTK Catppuccin tidak terpasang.${C_NC}"
  exit 1
fi
if [ ! -d "$RHOME/.themes/$GTK_THEME/xfwm4" ]; then
  echo -e "${C_YELLOW}[WARN] Aset xfwm4 tidak ada di paket tema; window manager pakai tema bawaan.${C_NC}"
fi

echo -e "${C_GREEN}[OK] Catppuccin $FLAVOR + $ACCENT terpasang (GTK, xfwm4, ikon, kursor, font, terminal).${C_NC}"
