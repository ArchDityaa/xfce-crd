# Changelog

Semua perubahan penting pada repo ini didokumentasikan di sini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/).

## [Unreleased]

### Added

- `.github/workflows/xfce.yml` — workflow utama **XFCE 24.04** di runner
  `ubuntu-24.04`: XFCE 4.18 (X11, `xfce4-session`), device CRD `xfce`,
  sesi 6 jam, dan watchdog yang memulihkan sesi secara otomatis.
- `scripts/xfce/` — 18 skrip, satu per step workflow (ekstraksi 1:1,
  `set -euo pipefail`), plus helper `set-resolution.sh`, `set-wallpaper.sh`,
  `xfce-performance-guard.sh`, dan `scripts/xfce/lib/metrics.sh`.
- `assets/xfce/` — isi statis: pin apt, konfigurasi xfconf
  (`xfwm4`, `xfce4-panel`, `xfce4-session`, `xfce4-desktop`, `xsettings`),
  template sesi CRD, autostart `.desktop`, shortcut Desktop, `terminalrc`,
  dan keyfile dconf anti-lock.
- **Mode performa XFCE**: compositor `xfwm4` dimatikan, animasi GTK dimatikan,
  event sound dimatikan, autostart dipangkas (tanpa `Thunar --daemon`,
  power-manager, screensaver, clipman), dan plugin panel polling tidak
  dipasang.
- **Paket desktop dipangkas**: `--no-install-recommends`, tanpa
  `ubuntu-desktop`, tanpa display manager, tanpa `xfce4-goodies`,
  tanpa `tumbler`, tanpa font Noto berat.
- **Hardening sesi**: `apt-daily`/`unattended-upgrades`/`motd-news`/`man-db`
  dimask, service tak terpakai (cups, avahi, bluetooth, ModemManager, apport,
  fwupd) dimask, `needrestart` dimatikan, paket locker tidak di-install,
  `SaveOnExit=false`.
- **Resolusi 1280x720** memakai jalur resmi Chrome Remote Desktop:
  systemd drop-in `chrome-remote-desktop@.service.d/10-desktop-size.conf` +
  `~/.profile` dengan `CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=1280x720`,
  plus helper `xrandr` (CVT + `--newmode`/`--addmode`) sebagai jaring
  pengaman dan fallback ke mode native 1024x768.
- **Paksa X11 murni di sesi CRD**: variabel Wayland dari environment runner
  dibersihkan (`unset WAYLAND_DISPLAY`, `GDK_BACKEND=x11`,
  `XDG_SESSION_TYPE=x11`) supaya XFCE tidak memilih sesi Wayland/labwc yang
  tidak bisa menggambar panel dengan benar.
- **Benchmark otomatis** (`17-smoke-test-and-benchmark.sh`): smoke test sesi
  XFCE di bawah Xvfb (membuktikan `xfwm4` + `xfce4-panel` benar-benar start
  dengan konfigurasi seed) + tabel metrik build yang ditulis ke Job Summary.
- **Metrik runtime sesi** di step Keep Alive: jumlah proses, total RSS, RAM,
  CPU idle, load average, status compositor, resolusi aktif, renderer OpenGL.
- `scripts/crd-web-auth.py` — server form otorisasi Chrome Remote Desktop
  berbasis Python stdlib (token 128-bit, bind `127.0.0.1`, validasi ketat,
  status live, satu perintah pada satu waktu), diadaptasi untuk XFCE.
- `scripts/safe-upgrade.sh` — helper upgrade paket yang tidak memutus sesi.
- Tema **Catppuccin Macchiato + Mauve**: GTK + **xfwm4**, ikon Papirus dengan
  folder Catppuccin, kursor, JetBrainsMono Nerd Font, palet `xfce4-terminal`,
  dan wallpaper "black unicat".
- `docs/performance.md` — metodologi pengukuran performa + target desain.
- `docs/architecture.md` — peta komponen, lapisan konfigurasi XFCE, guard
  runtime, model keamanan, dan alur otorisasi.
- `docs/faq.md`, `docs/troubleshooting.md`, `docs/adding-screenshots.md`.
- README Bahasa Indonesia (`README.md`) + English (`README.en.md`), banner SVG,
  diagram alur workflow (ID/EN), badge sosial.
- `.github/workflows/lint.yml` — CI: `actionlint` (checksum diverifikasi),
  `yamllint`, `bash -n`, `shellcheck`, dan `py_compile`.
- `.github/ISSUE_TEMPLATE/` — template bug report khusus XFCE.
- `.shellcheckrc`, `.yamllint.yml`, `.gitignore`, `.github/dependabot.yml`.

### Security

- URL form otorisasi memakai token acak 128-bit dan **tidak boleh dibagikan**;
  form hanya menerima perintah `start-host` dengan allowlist karakter.
- `CRD_PIN` opsional lewat secret Actions (default `123456`, **sangat
  disarankan diganti**).
- Perintah dan kode OAuth tidak pernah disimpan di browser.

[Unreleased]: https://github.com/ArchDityaa/xfce-crd/compare/v0.1.0...HEAD
