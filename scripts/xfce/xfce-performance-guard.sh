#!/usr/bin/env bash
# Guard performa sesi XFCE.
#
# Dipanggil sebagai autostart (setelah xfsettingsd/xfwm4 start) untuk
# MEMAKSA setting kunci XFCE:
#   - xfwm4 compositor OFF (lever performa terbesar)
#   - animasi GTK OFF (tidak ada redraw berulang di software rendering)
#   - event sound OFF (tidak ada delay audio saat klik)
#
# Nilai yang sama sudah di-seed di ~/.config/xfce4/xfconf/... saat build,
# tetapi xfwm4/xfsettingsd kadang me-reset sebagian nilai saat start.
# Guard ini menutup celah itu.
set -uo pipefail

sleep 2

if ! command -v xfconf-query >/dev/null 2>&1; then
  exit 0
fi

# xfwm4: matikan compositor.
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

# xsettings: matikan animasi + event sound.
xfconf-query -c xsettings -p /Gtk/EnableAnimations -s false 2>/dev/null || true
xfconf-query -c xsettings -p /Net/EnableEventSounds -s false 2>/dev/null || true
xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -s false 2>/dev/null || true

# xfce4-session: jangan pernah menahan sesi dengan dialog simpan sesi.
xfconf-query -c xfce4-session -p /general/SaveOnExit -s false 2>/dev/null || true

echo "[xfce-performance-guard] compositor off, animations off, event sounds off" >&2
exit 0
