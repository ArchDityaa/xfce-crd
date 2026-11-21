#!/usr/bin/env bash
# Set wallpaper Catppuccin untuk sesi XFCE (xfdesktop).
#
# Nama monitor pada driver dummy Xorg bisa berbeda antar runner
# (mis. "monitor0", "default", atau "DP-1"), jadi path properti xfconf
# untuk wallpaper dideteksi saat runtime lewat xfconf-query, bukan
# ditebak di build time.
set -uo pipefail

WALLPAPER="${1:-/home/runner/Pictures/wallpaper.png}"

if [ ! -f "$WALLPAPER" ]; then
  echo "[set-wallpaper] Wallpaper tidak ditemukan: $WALLPAPER" >&2
  exit 0
fi

# xfconf-query hanya tersedia di dalam sesi (butuh dbus + channel dibuat).
command -v xfconf-query >/dev/null 2>&1 || exit 0

PROPS="$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/backdrop/.*/workspace[0-9]*/last-image$' || true)"

if [ -z "$PROPS" ]; then
  echo "[set-wallpaper] Channel xfce4-desktop belum siap; wallpaper dilewati." >&2
  exit 0
fi

while IFS= read -r prop; do
  [ -n "$prop" ] || continue
  xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER" 2>/dev/null || true
  # Gaya gambar: 5 = zoom (scaled).
  style_prop="${prop%/last-image}/image-style"
  xfconf-query -c xfce4-desktop -p "$style_prop" -s 5 2>/dev/null || true
done <<< "$PROPS"

echo "[set-wallpaper] Wallpaper diterapkan: $WALLPAPER" >&2
exit 0
