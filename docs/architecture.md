# Arsitektur

Dokumen ini menjelaskan cara `xfce-crd` menyusun sesi desktop remote-nya: apa yang
dijalankan, dalam urutan apa, dan mengapa setiap bagian ada.

---

## 1. Peta komponen

```text
GitHub Actions runner (ubuntu-24.04)
│
├── 18 build step scripts        scripts/xfce/01..18-*.sh
│   └── menghasilkan:
│       ├── /home/runner/.chrome-remote-desktop-session   (file sesi CRD)
│       ├── ~/.config/xfce4/xfconf/xfce-perchannel-xml/*  (konfigurasi xfconf)
│       ├── ~/.config/autostart/*.desktop                 (helper saat sesi start)
│       ├── /usr/local/bin/{set-resolution,set-wallpaper,xfce-performance-guard}.sh
│       └── paket: xfce4, chrome, CRD, opencode, KVM, tema
│
├── chrome-remote-desktop@runner.service   (daemon CRD)
│   └── menjalankan file sesi di atas
│       └── exec /usr/bin/xfce4-session
│           ├── xfwm4            (window manager, compositor OFF)
│           ├── xfsettingsd      (XSettings: tema, ikon, kursor, font)
│           ├── xfce4-panel      (panel atas)
│           ├── xfdesktop        (wallpaper + ikon Desktop)
│           └── xfce4-notifyd    (notifikasi aplikasi)
│
└── scripts/crd-web-auth.py       (server form otorisasi, hanya saat STEP 15)
    └── diekspos lewat Cloudflare quick tunnel
```

## 2. Why direct `exec` (bukan Xsession)

`gnome-crd` memakai `/usr/bin/gnome-session` langsung; repo ini memakai
`/usr/bin/xfce4-session` langsung. Alasannya sama:

- `Xsession`/`lightdm`/`startxfce4` adalah wrapper yang bisa gagal diam-diam saat
  paket di-upgrade → sesi putus tanpa pesan jelas.
- Direct `exec` + env eksplisit (`XDG_CURRENT_DESKTOP`, `XDG_SESSION_TYPE`, ...)
  membuat perilaku sesi bisa ditebak dan diverifikasi.

File sesi resides di `~/.chrome-remote-desktop-session` dan **divalidasi** di STEP 16:
grep memastikan tidak ada `Xsession`/`lightdm`, dan memastikan ada baris
`exec /usr/bin/xfce4-session`.

## 3. Lapisan konfigurasi XFCE

XFCE membaca konfigurasi dari beberapa tempat, berurutan dari yang paling umum
ditimpa:

1. `/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/` (default sistem)
2. `~/.config/xfce4/xfconf/xfce-perchannel-xml/` (user)
3. Penulisan runtime via `xfconf-query` (guard saat start)

Repo ini mengisi lapis (2) dengan file XML:

| Channel | Isi | Efek |
| --- | --- | --- |
| `xfwm4` | `use_compositing=false`, shadow off, tema Catppuccin | **Lever performa utama** |
| `xfce4-panel` | Satu panel atas, plugin minimal | Panel Consistency, tanpa polling |
| `xfce4-session` | Client list failsafe, `SaveOnExit=false` | Autostart minimal, tanpa dialog |
| `xfce4-desktop` | Wallpaper + ikon Desktop | Tampilan, bukan performa |
| `xsettings` | Tema/ikon/kursor/font, `EnableAnimations=false` | Tampilan + sedikit performa |

Kenapa XML dan bukan `xfconf-query` saat build? Karena saat build **belum ada** sesi
X maupun dbus user, jadi `xfconf-query` tidak punya channel tujuan yang stabil.
Menulis XML langsung dijamin terbaca saat sesi start.

## 4. Guard runtime

`xfce4-panel`/`xfwm4` kadang me-reset sebagian nilai saat start. Karena itu ada
`/usr/local/bin/xfce-performance-guard.sh` yang dijalankan lewat autostart 2 detik
setelah sesi start, dan memaksa:

- `xfwm4 /general/use_compositing = false`
- `xsettings /Gtk/EnableAnimations = false`
- `xsettings /Net/EnableEventSounds = false`
- `xfce4-session /general/SaveOnExit = false`

## 5. Resolusi

Runner tidak punya GPU, jadi Xorg CRD memakai driver **dummy**.

Ada **tiga jalur**, berurutan dari yang paling resmi:

1. **Environment variable CRD (jalur utama).** Chrome Remote Desktop modern
   membaca `CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES` (format
   `WIDTHxHEIGHT[,WIDTHxHEIGHT...]`). Repo ini memasang systemd drop-in
   `chrome-remote-desktop@.service.d/10-desktop-size.conf` dengan nilai
   `1280x720`. CRD lalu mendaftarkan mode itu di RandR (output `DUMMY0`)
   dan menjadikannya initial mode.
2. **`~/.profile`.** Jalur cadangan untuk versi CRD lama yang membaca profile
   user (`export CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=1280x720`).
3. **Helper xrandr (`/usr/local/bin/set-resolution.sh`).** Jaring pengaman
   terakhir: memakai mode yang sudah ada, atau membuat mode baru dari timing
   **CVT** (`cvt 1280 720 60` + `xrandr --newmode`/`--addmode`), atau
   fallback ke `1024x768` (mode native driver dummy).

Helper yang sama dipasang sebagai autostart untuk menerapkan ulang mode setelah
`xfwm4` start (beberapa WM me-reset mode saat start).

## 6. Model keamanan

| Lapisan | Proteksi |
| --- | --- |
| Form otorisasi | Token acak 128-bit di path URL; server bind ke `127.0.0.1` saja |
| Input perintah | Allowlist karakter; maksimal 1 perintah diproses pada satu waktu |
| Token | `openssl rand -hex 16`; ditampilkan sebagai `::add-mask::` di log |
| PIN | Secret `CRD_PIN` opsional; default `123456` (sangat disarankan diganti) |
| Tunnel | Cloudflare quick tunnel tanpa akun; URL bersifat sementara (±30 menit) |
| Repo publik | Log + Job Summary terlihat siapa saja selama run berlangsung → gunakan fork private bila perlu |

## 7. Stabilitas sesi

### 7.1 Watchdog (STEP 18)

Setiap 5 menit:

1. `systemctl is-active chrome-remote-desktop@runner`
2. `pgrep -u runner -x xfce4-session`
3. Jika daemon mati **atau** sesi hilang 2 cek berturut-turut → restart daemon,
   maksimal 1x per 2 menit (anti tight-loop).
4. Sisa waktu dihitung dari `JOB_START_EPOCH` supaya tidak menabrak timeout job.

Restart daemon CRD membuat sesi X baru otomatis — inilah yang membuat sesi bisa
dipulihkan **tanpa re-run workflow**.

### 7.2 Anti-matte

- `apt-daily*`, `unattended-upgrades`, `motd-news`, `man-db` → dimatikan (mask).
- `cups`, `avahi`, `bluetooth`, `ModemManager`, `apport`, `fwupd` → dimatikan (mask).
- `needrestart` dimatikan total → `apt` tidak pernah me-restart service diam-diam.
- `xfce4-screensaver` / `light-locker` **tidak di-install** → tidak ada dialog lock.
- `SaveOnExit=false` → logout tidak memunculkan dialog "save session?".

## 8. Upgrade paket dengan aman

`/usr/local/bin/safe-upgrade` (dari `scripts/safe-upgrade.sh`) menjalankan apt dengan:

- `NEEDRESTART_MODE=l`, `NEEDRESTART_SUSPEND=1`
- `Dpkg::Options=--force-confdef --force-confold --force-unsafe-io`
- `Dpkg::Use-Pty=0`

Artinya paket boleh di-upgrade, tapi **tidak ada service yang di-restart** dan tidak
ada prompt yang menggantung karena tidak ada TTY. Paket yang butuh restart/reboot
hanya **dilaporkan**.

## 9. Alur otorisasi

1. STEP 15 menjalankan `scripts/crd-web-auth.py` di `127.0.0.1:8787`.
2. `cloudflared` membuat quick tunnel; URL di-publish ke log + Job Summary.
3. User mengotorisasi di `remotedesktop.google.com/headless` dan paste perintah.
4. Server memvalidasi perintah, workflow mengeksekusinya sebagai user `runner`
   dengan `--name="xfce"` dan `--pin="$CRD_PIN"`.
5. Registrasi dicoba maksimal 3× (retry untuk error transien).
6. Kalau gagal, user boleh submit kode baru **tanpa re-run** selama window 30 menit.

## 10. English summary

The workflow builds a trimmed XFCE stack, seeds the XFCE configuration as XML under
the user's `xfconf` directory, and writes a direct-exec session file for Chrome
Remote Desktop. The session starts `xfce4-session` with the compositor disabled, a
single minimal panel, and no locker or background daemons. A watchdog restarts the
CRD daemon when the desktop session dies, and every run publishes measured build and
runtime metrics to the Job Summary.
