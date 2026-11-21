#!/usr/bin/env bash
# Helper metrik performa untuk repo xfce-crd.
#
# Dipakai oleh STEP 17 (benchmark build) dan STEP 18 (metrik sesi runtime).
# Semua fungsi aman dipanggil tanpa session dbus/X11.
#
# Cara pakai:
#   source "$(dirname "$0")/lib/metrics.sh"
#   metric_header "Metrik build"
#   metric_row "Waktu build" "$(metric_build_elapsed)"
#   metric_footer

# Direktori output summary (Job Summary GitHub Actions).
METRICS_SUMMARY="${GITHUB_STEP_SUMMARY:-}"

metric_header() {
  [ -n "$METRICS_SUMMARY" ] || return 0
  {
    echo ""
    echo "## ${1:-Metrik}"
    echo ""
    echo "| Metrik | Nilai |"
    echo "| --- | --- |"
  } >> "$METRICS_SUMMARY"
}

metric_row() {
  [ -n "$METRICS_SUMMARY" ] || return 0
  printf '| %s | %s |\n' "$1" "$2" >> "$METRICS_SUMMARY"
}

metric_footer() {
  [ -n "$METRICS_SUMMARY" ] || return 0
  {
    echo ""
    echo "_Diukur otomatis oleh workflow xfce.yml. Angka adalah kondisi runner, bukan jaminan performa jaringan._"
    echo ""
  } >> "$METRICS_SUMMARY"
}

# Waktu sejak job dimulai (detik).
metric_build_elapsed() {
  local start="${JOB_START_EPOCH:-}"
  case "$start" in
    ''|*[!0-9]*) echo "n/a"; return 0 ;;
  esac
  echo "$(( $(date +%s) - start ))"
}

# Waktu tempuh dari install desktop (STEP 02) sampai sekarang.
metric_elapsed_human() {
  local sec="${1:-}"
  case "$sec" in
    ''|*[!0-9]*) echo "n/a"; return 0 ;;
  esac
  printf '%dm %02ds' $(( sec / 60 )) $(( sec % 60 ))
}

# Jumlah paket terpasang.
metric_package_count() {
  dpkg-query -W -f='${Package}\n' 2>/dev/null | wc -l | tr -d ' '
}

# Berat disk direktori utama (MB).
metric_disk_usage() {
  du -sx --block-size=1M /usr /opt /var 2>/dev/null \
    | awk '{gsub("/", "", $2); printf "%s=%sMB ", $2, $1}'
}

# Total RAM terpakai sistem.
metric_memory() {
  free -m 2>/dev/null | awk '/^Mem:/ {printf "%sMB terpakai / %sMB total", $3, $2; exit}'
}

# Rata-rata CPU idle selama beberapa detik.
metric_cpu_idle() {
  if ! command -v vmstat >/dev/null 2>&1; then
    echo "n/a"
    return 0
  fi
  vmstat 1 6 2>/dev/null \
    | awk 'NR > 2 { idle += $15; n++ } END { if (n > 0) printf "%.1f%%", (idle / n); else print "n/a" }'
}

# Beban sistem (1/5/15 menit).
metric_loadavg() {
  awk '{printf "%s / %s / %s", $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "n/a"
}

# Jumlah proses milik user runner (sesi desktop).
metric_process_count() {
  local user="${1:-runner}"
  pgrep -u "$user" 2>/dev/null | wc -l | tr -d ' '
}

# Total RSS proses milik user runner (MB).
metric_session_rss() {
  local user="${1:-runner}"
  ps -u "$user" -o rss= 2>/dev/null \
    | awk '{ s += $1 } END { if (s > 0) printf "%.0f MB", (s / 1024); else print "n/a" }'
}

# Setting compositor xfwm4 (harus false untuk mode performa).
metric_compositor() {
  local val="n/a"
  if command -v xfconf-query >/dev/null 2>&1; then
    val="$(xfconf-query -c xfwm4 -p /general/use_compositing 2>/dev/null || echo "n/a")"
  fi
  [ -n "$val" ] || val="n/a"
  echo "$val"
}

# Resolusi aktif (butuh X display).
metric_resolution() {
  command -v xrandr >/dev/null 2>&1 || { echo "n/a"; return 0; }
  xrandr --current 2>/dev/null \
    | awk '/ connected/ { print $1" "$4 }' | head -n1 || echo "n/a"
}

# Renderer OpenGL aktif (llvmpipe di runner tanpa GPU).
metric_renderer() {
  command -v glxinfo >/dev/null 2>&1 || { echo "n/a"; return 0; }
  glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL renderer/ {print $2; exit}' || echo "n/a"
}
