#!/usr/bin/env bash
# Set resolusi layar sesi CRD.
#
# Target: 1280x720 (16:9). Driver dummy Xorg pada runner biasanya hanya
# menyediakan mode native 1024x768, jadi mode 1280x720 dibuat sendiri
# memakai timing CVT (xrandr --newmode / --addmode).
#
# Kalau creation gagal (kernel lama, driver menolak), script ini jatuh ke
# mode native 1024x768 yang selalu ada.
#
# Dipakai dua kali:
#   1) Dari .chrome-remote-desktop-session (sebelum xfce4-session start).
#   2) Dari autostart (fallback, kalau xfwm4 mereset mode saat start).
set -uo pipefail

WANT_W=1280
WANT_H=720
FALLBACK_MODE="1024x768"

detect_display() {
  local disp="" out="" try d o
  for try in 1 2 3 4 5 6 7 8 9 10; do
    for d in "${DISPLAY:-}" :20 :21 :22 :0; do
      [ -n "$d" ] || continue
      o="$(xrandr --display "$d" 2>/dev/null | grep " connected" | awk '{print $1}' | head -n1)"
      if [ -n "$o" ]; then
        disp="$d"
        out="$o"
        break
      fi
    done
    [ -n "$out" ] && break
    sleep 1
  done
  echo "$disp|$out"
}

existing_mode() {
  local disp="$1"
  xrandr --display "$disp" 2>/dev/null \
    | grep -oE "${WANT_W}x${WANT_H}(_[0-9.]+)?" | head -n1
}

create_mode() {
  local disp="$1" out="$2" line="" name="" args=()

  command -v cvt >/dev/null 2>&1 || return 1

  line="$(cvt "$WANT_W" "$WANT_H" 60 2>/dev/null | grep -i 'Modeline' | head -n1)"
  [ -n "$line" ] || return 1

  # Buang kata "Modeline" dan tanda kutip di sekitar nama mode.
  line="$(printf '%s' "$line" | sed -e 's/.*Modeline //' -e 's/^"//' -e 's/"$//')"
  [ -n "$line" ] || return 1

  read -r -a args <<< "$line"
  [ "${#args[@]}" -ge 2 ] || return 1
  name="${args[0]}"

  xrandr --display "$disp" --newmode "$name" "${args[@]:1}" 2>/dev/null || return 1
  xrandr --display "$disp" --addmode "$out" "$name" 2>/dev/null || return 1

  echo "$name"
}

RESULT="$(detect_display)"
DISP="${RESULT%%|*}"
OUTPUT="${RESULT##*|}"

if [ -z "$DISP" ] || [ -z "$OUTPUT" ]; then
  echo "[set-resolution] Tidak ada output X yang terdeteksi; dibiarkan apa adanya." >&2
  exit 0
fi

MODE="$(existing_mode "$DISP")"

if [ -z "$MODE" ]; then
  MODE="$(create_mode "$DISP" "$OUTPUT" || true)"
fi

if [ -z "$MODE" ]; then
  MODE="$FALLBACK_MODE"
  echo "[set-resolution] Mode ${WANT_W}x${WANT_H} tidak bisa dibuat, fallback ke ${FALLBACK_MODE}." >&2
fi

xrandr --display "$DISP" --output "$OUTPUT" --mode "$MODE" 2>/dev/null \
  || xrandr --display "$DISP" --output "$OUTPUT" --auto 2>/dev/null \
  || true

echo "[set-resolution] Mode aktif: $MODE (display $DISP, output $OUTPUT)" >&2
exit 0
