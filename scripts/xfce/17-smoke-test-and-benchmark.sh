#!/usr/bin/env bash
# Extracted 1:1 from .github/workflows/xfce.yml -- step: Smoke Test & Build Benchmark
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_NC='\033[0m'

# shellcheck source=scripts/xfce/lib/metrics.sh
source "$SCRIPT_DIR/lib/metrics.sh"

echo ""
echo "------------------------------------------------------------"
echo -e "${C_CYAN}[STEP 17/18] SMOKE TEST & BUILD BENCHMARK${C_NC}"
echo "------------------------------------------------------------"

# ============================================================
# 1. SMOKE TEST SESI XFCE (Xvfb, HOME terisolasi)
#
# Menjalankan xfce4-session sungguhan di bawah Xvfb memakai config yang
# kita seed. Tujuannya: menangkap error XML panel/tema/session SEBELUM
# user menghabiskan waktu untuk otorisasi CRD.
#
# Kegagalan smoke test hanya PERINGATAN, bukan fatal: build produksi
# memakai Xorg milik CRD, dan beberapa hal (wallpaper, ukuran panel) bisa
# berbeda di headless Xvfb.
# ============================================================
echo -e "${C_YELLOW}[INFO] Running XFCE session smoke test under Xvfb...${C_NC}"

SMOKE_DIR=/tmp/xfce-smoke
SMOKE_HOME="$SMOKE_DIR/home"
SMOKE_RUNTIME="$SMOKE_DIR/runtime"
SMOKE_DISPLAY=":99"

# Bersihkan sisa proses smoke test sebelumnya (panel/wm bisa menahan mount
# gvfs, jadi rm -rf tidak selalu bersih).
pkill -u "$(id -u)" -x xfce4-session 2>/dev/null || true
pkill -u "$(id -u)" -x xfwm4 2>/dev/null || true
pkill -u "$(id -u)" -x xfce4-panel 2>/dev/null || true
sleep 1
rm -rf "$SMOKE_DIR" 2>/dev/null || true
mkdir -p "$SMOKE_HOME/.config" "$SMOKE_HOME/.cache" "$SMOKE_HOME/.local/share" \
         "$SMOKE_HOME/.themes" "$SMOKE_HOME/.icons" "$SMOKE_RUNTIME"
chmod 700 "$SMOKE_RUNTIME"

# Salin config + tema milik user 'runner' ke HOME terisolasi.
cp -a /home/runner/.config/xfce4 "$SMOKE_HOME/.config/" 2>/dev/null || true
cp -a /home/runner/.themes/. "$SMOKE_HOME/.themes/" 2>/dev/null || true
cp -a /home/runner/.icons/. "$SMOKE_HOME/.icons/" 2>/dev/null || true

SMOKE_OK=0
SMOKE_NOTE="tidak dijalankan"

if command -v Xvfb >/dev/null 2>&1; then
  Xvfb "$SMOKE_DISPLAY" -screen 0 1280x720x24 -nolisten tcp \
    > "$SMOKE_DIR/xvfb.log" 2>&1 &
  XVFB_PID=$!
  sleep 2

  if kill -0 "$XVFB_PID" 2>/dev/null; then
    (
      export DISPLAY="$SMOKE_DISPLAY"
      export HOME="$SMOKE_HOME"
      export XDG_RUNTIME_DIR="$SMOKE_RUNTIME"
      export XDG_CONFIG_HOME="$SMOKE_HOME/.config"
      export XDG_CACHE_HOME="$SMOKE_HOME/.cache"
      export XDG_DATA_HOME="$SMOKE_HOME/.local/share"
      export LIBGL_ALWAYS_SOFTWARE=1
      export NO_AT_BRIDGE=1
      dbus-run-session -- xfce4-session
    ) > "$SMOKE_DIR/session.log" 2>&1 &
    SESSION_PID=$!

    # Tunggu sampai xfwm4 + xfce4-panel benar-benar hidup (maks 25 detik).
    for _ in $(seq 1 25); do
      if pgrep -x xfwm4 > /dev/null 2>&1 && pgrep -x xfce4-panel > /dev/null 2>&1; then
        SMOKE_OK=1
        break
      fi
      sleep 1
    done

    # Pastikan proses smoke test dibersihkan (tidak boleh mengganggu runner).
    kill "$SESSION_PID" 2>/dev/null || true
    pkill -u "$(id -u)" -x xfce4-session 2>/dev/null || true
    pkill -u "$(id -u)" -x xfwm4 2>/dev/null || true
    pkill -u "$(id -u)" -x xfce4-panel 2>/dev/null || true
    sleep 1
    kill "$XVFB_PID" 2>/dev/null || true
    wait "$XVFB_PID" 2>/dev/null || true

    if [ "$SMOKE_OK" -eq 1 ]; then
      SMOKE_NOTE="OK (xfwm4 + xfce4-panel start)"
      echo -e "${C_GREEN}[OK] Smoke test: xfwm4 + xfce4-panel start dengan config seed.${C_NC}"
    else
      SMOKE_NOTE="GAGAL (xfwm4/xfce4-panel tidak start)"
      echo -e "${C_YELLOW}[WARN] Smoke test tidak melihat xfwm4/xfce4-panel start.${C_NC}"
      echo "------------------------------------------------------------"
      tail -n 30 "$SMOKE_DIR/session.log" 2>/dev/null || true
      echo "------------------------------------------------------------"
    fi
  else
    SMOKE_NOTE="GAGAL (Xvfb tidak start)"
    echo -e "${C_YELLOW}[WARN] Xvfb gagal start; smoke test dilewati.${C_NC}"
  fi
else
  echo -e "${C_YELLOW}[WARN] Xvfb tidak tersedia; smoke test dilewati.${C_NC}"
fi

# ============================================================
# 2. BENCHMARK BUILD
# ============================================================
echo -e "${C_YELLOW}[INFO] Collecting build metrics...${C_NC}"

ELAPSED="$(metric_build_elapsed)"

metric_header "Metrik build (XFCE, runner ubuntu-24.04)"
metric_row "Waktu sejak job start" "$(metric_elapsed_human "$ELAPSED")"
metric_row "Paket terpasang" "$(metric_package_count)"
metric_row "Berat disk (/usr /opt /var)" "$(metric_disk_usage)"
metric_row "RAM sistem" "$(metric_memory)"
metric_row "CPU idle (sampel 5 detik)" "$(metric_cpu_idle)"
metric_row "Load average" "$(metric_loadavg)"
metric_row "Compositor xfwm4 (harus false)" "$(metric_compositor)"
metric_row "Smoke test sesi XFCE" "$SMOKE_NOTE"
metric_footer

echo "------------------------------------------------------------"
echo "Waktu build  : $(metric_elapsed_human "$ELAPSED")"
echo "Paket        : $(metric_package_count)"
echo "Disk         : $(metric_disk_usage)"
echo "RAM          : $(metric_memory)"
echo "CPU idle     : $(metric_cpu_idle)"
echo "Compositor   : $(metric_compositor)"
echo "Smoke test   : $SMOKE_NOTE"
echo "------------------------------------------------------------"

# Ringkasan singkat di log job.
echo ""
echo "=============================================================="
echo -e "${C_GREEN}      [OK] BUILD XFCE SELESAI${C_NC}"
echo "=============================================================="
echo -e "      [INFO] Build time   : $(metric_elapsed_human "$ELAPSED")"
echo -e "      [INFO] Packages     : $(metric_package_count)"
echo -e "      [INFO] RAM terpakai : $(metric_memory)"
echo -e "      [INFO] Compositor   : $(metric_compositor) (false = mode performa)"
echo "=============================================================="
echo ""
