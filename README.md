<p align="center">
  <img src="docs/images/banner.svg" alt="RICH LINUX — XFCE di Chrome Remote Desktop" width="900">
</p>

<p align="center">
  <a href="https://github.com/ArchDityaa/xfce-crd/actions/workflows/lint.yml"><img src="https://github.com/ArchDityaa/xfce-crd/actions/workflows/lint.yml/badge.svg" alt="Lint"></a>
  <a href="https://github.com/ArchDityaa/xfce-crd/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/runner-ubuntu--24.04-E95420.svg" alt="Runner: ubuntu-24.04 (XFCE 4.18)">
  <img src="https://img.shields.io/badge/session-maks%206%20jam-orange.svg" alt="Session: maks 6 jam">
  <img src="https://img.shields.io/badge/desktop-XFCE-4A86CF.svg" alt="Desktop: XFCE">
  <img src="https://img.shields.io/badge/compositor-OFF-111827.svg" alt="Compositor: off">
  <img src="https://img.shields.io/badge/resolusi-1280x720-111827.svg" alt="Resolusi: 1280x720">
  <img src="https://img.shields.io/badge/access-Chrome%20Remote%20Desktop-4285F4.svg" alt="Access: Chrome Remote Desktop">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome">
</p>

Jalankan **desktop XFCE yang ringan** di cloud, gratis, hanya dengan **fork repo ini**.
Akses dari browser lewat Chrome Remote Desktop — tanpa install apa pun di komputer Anda.

[English version →](README.en.md)

> ⚡ **Dibuat untuk kecepatan:** tanpa compositor, animasi dimatikan, service latar
> dimatikan, dan paket desktop dipangkas. Semua angka performa diukur otomatis oleh
> workflow dan ditulis ke Job Summary — detailnya di
> [**docs/performance.md**](docs/performance.md).

## Daftar Isi

- [Cocok untuk](#cocok-untuk)
- [Alur singkat](#alur-singkat)
- [Apa yang Anda dapatkan](#apa-yang-anda-dapatkan)
- [Kenapa XFCE (dan kenapa lebih ringan)](#kenapa-xfce-dan-kenapa-lebih-ringan)
- [Varian desktop](#varian-desktop)
- [Persyaratan](#persyaratan)
- [Cara pakai (5 langkah)](#cara-pakai-5-langkah)
- [Setelah terhubung](#setelah-terhubung)
- [Batasan & catatan penting](#batasan--catatan-penting)
- [Troubleshooting singkat](#troubleshooting-singkat)
- [Struktur repo](#struktur-repo)
- [Kontribusi](#kontribusi)
- [Kredit](#kredit)
- [Pengembang](#pengembang)

---

## Cocok untuk

- Menjalankan **desktop environment XFCE** penuh di cloud untuk eksperimen.
- Menguji / menjalankan **tools GUI** (Chrome, terminal, editor, xarchiver, Thunar).
- Belajar Linux dan desktop environment tanpa mengorbankan mesin sendiri.
- Butuh **VM di dalam VM** (KVM + virt-manager tersedia).
- Sesi **ringan dan stabil**: resource kecil, build cepat, watchdog otomatis.

## Alur singkat

[![Alur workflow: fork repo, aktifkan Actions, run workflow, form URL, authorize, paste perintah, device terdaftar, connect, desktop aktif](docs/images/workflow-id.svg)](docs/images/workflow-id.svg)

> **Penting:** kode auth Chrome Remote Desktop **tidak lagi diambil di awal**. Workflow
> menunggu desktop siap, baru menampilkan form web. Kode yang Anda buat setelah itu
> langsung dipakai, jadi tidak kedaluwarsa selama instalasi.

---

## Apa yang Anda dapatkan

Satu virtual machine **Ubuntu** (4 vCPU / 16 GB RAM) dengan desktop **XFCE 4.18** yang
sudah dikonfigurasi, hidup sampai **6 jam**, lalu otomatis mati. Setiap run adalah
lingkungan bersih — selesai, hilang.

| Sudah Terpasang | Keterangan |
| --- | --- |
| **XFCE Desktop** | Sesi penuh `xfce4-session` (X11), bukan sekadar WM — tanpa lightdm, tanpa GNOME, tanpa Mutter |
| **Tanpa compositor** | `xfwm4` compositing **off**: tidak ada composite pass, tidak ada GL shadow, CPU idle rendah |
| **Google Chrome** | Bisa langsung dipakai login akun Google |
| **OpenCode CLI** | Terseedia system-wide (`/usr/local/bin/opencode`) + shortcut Desktop |
| **Chrome Remote Desktop** | Jalur akses utamanya |
| **xfce4-terminal + Thunar** | Terminal dan file manager bawaan XFCE |
| **virt-manager + libvirt/QEMU** | Untuk menjalankan VM di dalamnya (nested) |
| **Catppuccin Macchiato + Mauve** | Tema GTK + **xfwm4**, ikon Papirus, kursor, font JetBrainsMono Nerd Font, palet terminal |
| **1280x720** | Di-set lewat env resmi CRD (`CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES`), fallback otomatis ke 1024x768 |
| **safe-upgrade** | Pengganti `apt upgrade` yang tidak memutus sesi |

Plus: timezone **WIB (Asia/Jakarta)**, screensaver & lock **tidak dipasang sama sekali**,
serta timer/service latar yang bisa mengganggu sesi dimatikan.

## Kenapa XFCE (dan kenapa lebih ringan)

Repo ini lahir dari satu tujuan: **desktop remote yang tetap ringan dan stabil**.
Berikut levers yang dipakai:

| Lever | Dampak |
| --- | --- |
| **Compositor off** (`xfwm4`) | Tidak ada composite pass per frame, tidak ada llvmpipe untuk shadow/alpha. CPU idle turun, capture frame CRD lebih murah. |
| **Animasi GTK off** | Tidak ada redraw berulang saat membuka menu/jendela di software rendering. |
| **Paket desktop dipangkas** | Tanpa `xfce4-goodies`, power-manager, screensaver, tumbler, panel plugin polling. |
| **Autostart minimal** | Hanya `xfwm4`, `xfsettingsd`, `xfce4-panel`, `xfdesktop`, `xfce4-notifyd`. Tanpa `Thunar --daemon`. |
| **Timer & service dimatikan** | `apt-daily`, `unattended-upgrades`, `motd-news`, `man-db` — sumber utama "sesi matt" di tengah jalan. |
| **Lock dihapus total** | Paket locker tidak di-install, jadi tidak ada dialog yang bisa menggantung sesi. |
| **Build tanpa display manager** | Tidak ada lightdm/GDM yang menambah service dan startup time. |
| **Cache `.deb` GitHub** | Re-run setelah gagal jauh lebih cepat karena tidak mengunduh ulang ~1 GB. |
| **Watchdog + metrics** | Sesi dipulihkan otomatis; performa tiap run terukur otomatis. |

> Angka konkret (waktu build, RAM idle, CPU idle, jumlah paket) **diukur** oleh
> workflow dan ditulis ke **Job Summary** setiap run. Lihat
> [`docs/performance.md`](docs/performance.md) untuk metodologi dan cara membacanya.

## Varian desktop

| | **XFCE 24.04** |
| --- | --- |
| Workflow | `.github/workflows/xfce.yml` |
| Runner | `ubuntu-24.04` |
| Desktop | XFCE 4.18 (X11, `xfce4-session`) |
| Device CRD | `xfce` |
| File manager | Thunar |
| Resolusi | 1280x720 (fallback 1024x768) |
| Compositor | Mati |

## Persyaratan

- Akun **GitHub** (gratis). Runner publik = menit Actions tidak terbatas.
- Akun **Google** (untuk Chrome Remote Desktop).
- Browser Chrome/Chromium (untuk membuka halaman Remote Access).
- Tidak perlu akun Cloudflare — tunnel quick dibuat otomatis oleh workflow.

Tidak perlu kartu kredit, tidak perlu server, tidak perlu self-hosted runner.

---

## Cara pakai (5 langkah)

### 1. Fork repo ini

Klik tombol **Fork** di kanan atas → **Create fork**.

### 2. Aktifkan Actions di fork Anda

> **Ini langkah yang paling sering terlewat.** GitHub menonaktifkan workflow pada repo hasil fork.

> **Settings** → **Actions** → **General** → pilih **Allow all actions and reusable workflows** → **Save**.

### 3. Jalankan workflow (tanpa input auth)

1. Buka tab **Actions** di fork Anda.
2. Pilih **XFCE 24.04** di sidebar kiri.
3. Klik **Run workflow** (kanan atas).
4. Biarkan kolom **crd_host_command** **kosong** — kolom itu hanya fallback.
5. Klik **Run workflow** (hijau).

**Opsional — ganti PIN:** buat secret `CRD_PIN` di **Settings → Secrets and variables → Actions → New repository secret** (nilai: minimal 6 digit). Kalau tidak diisi, PIN default `123456`.

### 4. Buka form otorisasi & authorize

Setelah instalasi selesai (**±8–15 menit**), log akan menampilkan:

```
[OK] FORM OTORISASI SIAP
```

URL form juga muncul di **Job Summary** run tersebut. Buka URL itu (bisa dari HP atau jaringan lain). Kalau muncul error Cloudflare **1033/502**, tunggu ±15 detik lalu refresh — tunnel sedang warm-up.

Lalu:

1. Di tab lain, buka [https://remotedesktop.google.com/headless](https://remotedesktop.google.com/headless) dan login akun Google Anda.
2. Klik **Begin** → **Next** → **Authorize**.
3. Di bagian **"Set up another computer" / "Debian Linux"**, copy **SELURUH** perintah yang muncul. Bentuknya seperti:

```
DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0Ab..." --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
```

4. Paste perintah itu ke form, lalu submit.

Form menampilkan status secara live. Kalau registrasi gagal (kode salah, kedaluwarsa, atau sudah terpakai), **ambil kode BARU** di halaman headless lalu submit lagi ke form yang sama — **tidak perlu re-run workflow** selama window 30 menit masih berjalan.

Tampilan form: layout dua kolom yang responsif, tema **grayscale monokrom** dengan mode *Auto / Light / Dark*, toggle bahasa **ID / EN**, panduan 4 langkah, hitung mundur, progress bar, dan validasi format perintah. Perintah dan kode OAuth **tidak** disimpan di browser.

> **Jangan bagikan URL form.** URL itu mengandung token acak dan berlaku sebagai kredensial sementara selama ±30 menit.

### 5. Tunggu & connect

Setelah log menunjukkan:

```
[OK] CHROME REMOTE DESKTOP READY
```

buka [https://remotedesktop.google.com/access](https://remotedesktop.google.com/access), pilih device bernama **xfce**, lalu masukkan PIN.

|  |  |
| --- | --- |
| **User** | `runner` (password: `root`) |
| **PIN** | `123456` (atau secret `CRD_PIN` Anda) |
| **Device** | `xfce` |
| **Durasi** | sampai ±6 jam, lalu VM dimatikan otomatis |

---

## Setelah terhubung

- **Terminal:** `Ctrl+Alt+T`, atau klik ikon terminal di panel, atau shortcut **Terminal** di Desktop.
- **File manager:** **Thunar** (ikon folder di panel atau shortcut **File Manager** di Desktop).
- **Application launcher:** `Super` (Whisker Menu) atau `Super+P` (Application Finder).
- **OpenCode CLI:** shortcut **OpenCode** di Desktop, atau jalankan `opencode` di terminal.
- **Upgrade paket dengan aman:**

```
sudo safe-upgrade
```

  Ada juga shortcut **Safe Upgrade** di Desktop. **Jangan** pakai `sudo apt upgrade -y` polos — itu bisa me-restart Chrome Remote Desktop dan memutus sesi Anda.

- **Menjalankan VM (KVM):** buka `virt-manager` dari menu aplikasi. Runner x86 punya KVM, jadi VM berjalan dengan akselerasi hardware.
- **Pengaturan desktop:** shortcut **Settings** di Desktop (Xfce Settings Manager).
- **Tema:** Catppuccin Macchiato + Mauve sudah aktif (GTK + xfwm4 + ikon + kursor + font + terminal).

> ⚠ **Peringatan Keamanan Penting**

> URL form otorisasi mengandung **token acak 128-bit** yang berlaku sebagai kredensial sementara selama ±30 menit. Siapa pun yang membuka URL tersebut dapat mengirim perintah registrasi ke desktop Anda. **Jangan bagikan URL form** kepada siapa pun, dan tutup tab form setelah selesai. Jika Anda menggunakan repo **publik**, log dan Job Summary juga terlihat oleh siapa selama run berlangsung. Gunakan **fork private** jika ini menjadi masalah.

## Batasan & catatan penting

- **Maksimal 6 jam per run.** Ini batas job GitHub-hosted. Rencanakan pekerjaan Anda; simpan hasil ke GitHub/cloud, karena VM akan hilang setelahnya.
- **Instance sekali pakai.** Tidak ada penyimpanan permanen antar-run.
- **Tidak ada compositor.** Ini disengaja (performa), tapi artinya: tidak ada efek blur/shadow transparan pada panel dan window. Window manager memakai tema Catppuccin dengan bayangan dimatikan.
- **Animasi dimatikan.** Menu dan jendela langsung tampil, tanpa transisi. Ini pilihan performa.
- **Window otorisasi 30 menit.** Setelah desktop siap, form web hanya menerima perintah selama 30 menit. Kalau habis, workflow gagal dan perlu dijalankan ulang (cache `.deb` membuat re-run lebih cepat).
- **Cloudflare quick tunnel tidak punya SLA.** URL-nya acak dan bisa perlu di-refresh saat pertama dibuka. Kalau tunnel mati, workflow mencoba restart hingga 3 kali dan menampilkan URL baru.
- **Audio** berjalan lewat PipeWire (PulseAudio compatibility layer). Mixer ada di panel.
- **Gunakan sesuai ToS GitHub Actions.** Repo ini ditujukan untuk *eksperimen dan pengujian tools*; jangan dipakai sebagai hosting/komputasi umum atau untuk penambangan kripto.
- **Hemat:** repo hasil fork tidak akan menerima update otomatis. Gunakan tombol **Sync fork** di GitHub untuk mengambil perbaikan terbaru.

## Troubleshooting singkat

| Masalah | Penyebab & solusi |
| --- | --- |
| Workflow tidak muncul di tab Actions | Fork belum meng-*enable* Actions → **Settings → Actions → General → Allow all actions**. |
| URL form tidak muncul | Cek log step **Authorize & Register Chrome Remote Desktop (Web UI)**. Cache `.deb` terpakai, jadi re-run jauh lebih cepat. |
| Halaman form menampilkan error Cloudflare 1033/502 | Tunnel sedang warm-up. Tunggu ±15 detik lalu refresh. |
| Registrasi via form gagal | Kode OAuth sudah kedaluwarsa/terpakai. Ambil perintah **baru** di [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless), submit lagi ke form yang sama. |
| Window 30 menit habis | Workflow berhenti. Jalankan ulang; cache `.deb` membuat instalasi jauh lebih cepat. |
| Desktop kosong / panel hilang | `xfce4-panel` mungkin gagal start. Cek `~/.xsession-errors` atau jalankan `xfce4-panel &` di terminal. |
| Resolusi tetap 1024x768 | Driver dummy menolak mode 1280x720 → fallback otomatis ke 1024x768 (normal, tidak fatal). |
| Sesi terputus saat update paket | Anda memakai `apt upgrade` polos. Pakai `sudo safe-upgrade`. |
| `virt-manager`: "Permission denied" pada libvirt | Log-out lalu log-in ulang di sesi desktop, atau jalankan `virsh -c qemu:///session`. |
| `Cannot access KVM` | KVM tersedia di runner x86. Cek `ls -l /dev/kvm`; jika ada tapi tetap gagal, tulis issue dengan log run. |

Panduan lengkap: [`docs/troubleshooting.md`](docs/troubleshooting.md) · Pertanyaan umum: [`docs/faq.md`](docs/faq.md) · Metrik performa: [`docs/performance.md`](docs/performance.md) · Arsitektur: [`docs/architecture.md`](docs/architecture.md)

---

## Struktur repo

```
.
├── .github/
│   ├── workflows/
│   │   ├── xfce.yml             # workflow utama XFCE (Ubuntu 24.04, X11)
│   │   └── lint.yml             # CI: actionlint + yamllint + shellcheck
│   ├── ISSUE_TEMPLATE/
│   └── dependabot.yml
├── scripts/
│   ├── xfce/                    # 1 skrip per step workflow
│   │   ├── 01-prepare-system.sh
│   │   ├── 02-install-xfce-desktop.sh
│   │   ├── ...
│   │   ├── 18-keep-alive.sh
│   │   ├── set-resolution.sh    # helper resolusi 1280x720 (fallback 1024x768)
│   │   ├── set-wallpaper.sh     # helper wallpaper runtime
│   │   ├── xfce-performance-guard.sh  # paksa compositor/animasi off saat start
│   │   └── lib/metrics.sh       # helper pengumpulan metrik
│   ├── crd-web-auth.py          # server form otorisasi (token + status)
│   └── safe-upgrade.sh          # helper anti-putus-sesi
├── assets/xfce/                 # isi statis: apt pin, xfconf, sesi, autostart, systemd, .desktop, terminalrc
├── docs/
│   ├── images/banner.svg
│   ├── images/workflow-id.svg
│   ├── images/workflow-en.svg
│   ├── images/badges/           # ikon sosial (Simple Icons, CC0)
│   ├── faq.md
│   ├── troubleshooting.md
│   ├── performance.md
│   ├── architecture.md
│   └── adding-screenshots.md
├── .yamllint.yml                # konfigurasi linter YAML
├── README.md                    # dokumen ini (ID)
├── README.en.md                 # English
├── CHANGELOG.md
└── LICENSE
```

Setiap blok `run:` substantif di workflow hanya memanggil satu skrip di `scripts/xfce/`.
Isi statis seperti pin apt, konfigurasi xfconf, template sesi, `.desktop`, dan `terminalrc`
disimpan di `assets/xfce/` supaya YAML tetap ringkas dan mudah dibaca.

## Kontribusi

Pull request sangat diterima. Semua YAML, workflow, dan skrip divalidasi otomatis oleh CI **Lint** pada setiap push ke `main` dan setiap pull request.

Jalankan linter yang sama secara lokal sebelum push:

```
pip install yamllint
yamllint .
# shellcheck membaca aturan repo dari .shellcheckrc (SC2016/SC2034/SC2012
# memang disengaja); -x mengikuti file yang di-source.
find scripts assets -name '*.sh' -print0 | xargs -0 shellcheck -x
python3 -m py_compile scripts/crd-web-auth.py
# actionlint: https://github.com/rhysd/actionlint
actionlint -ignore SC2016 -ignore SC2034 -ignore SC2012
```

## Kredit

- [Catppuccin](https://github.com/catppuccin) — theme GTK/xfwm4, kursor, terminal, wallpaper
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — icon theme
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) — JetBrainsMono
- Google Chrome Remote Desktop
- [Simple Icons](https://simpleicons.org/) — ikon sosial (CC0)

## Pengembang

### ArchDityaa

Developer & maintainer · [masadityaaa.vercel.app](https://masadityaaa.vercel.app) (Portfolio: masadityaaa.vercel.app)

[![ArchDityaa](https://github.com/ArchDityaa.png?size=100)](https://github.com/ArchDityaa "GitHub: ArchDityaa") [![Instagram](docs/images/badges/instagram.svg)](https://www.instagram.com/aaaditz_ "Instagram: aaaditz_") [![TikTok](docs/images/badges/tiktok.svg)](https://www.tiktok.com/@kiraadityaa "TikTok: kiraadityaa") [![WhatsApp](docs/images/badges/whatsapp.svg)](https://wa.me/6281553362795 "WhatsApp: 0815-5336-2795")

© ArchDityaa · [MIT License](LICENSE) · [Kembali ke atas ↑](#daftar-isi)
