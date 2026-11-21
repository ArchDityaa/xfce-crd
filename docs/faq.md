# FAQ

Pertanyaan yang paling sering masuk tentang `xfce-crd`.

---

## Apakah ini benar-benar gratis?

Ya. Repo ini memakai **GitHub-hosted runner** (Ubuntu 24.04, 4 vCPU / 16 GB RAM).
Runner publik tidak menghabiskan menit Actions Anda, dan tidak perlu kartu kredit,
server, atau self-hosted runner. Yang dibutuhkan hanya akun GitHub dan akun Google.

## Berapa lama sesi bisa hidup?

Maksimal **6 jam** per run — itu adalah batas job GitHub-hosted. Setelah itu VM
dimatikan otomatis oleh workflow.

## Apakah data saya tersimpan?

Tidak. Setiap run adalah lingkungan sekali pakai: begitu workflow selesai, semua
berkas hilang. Simpan hasil kerja Anda ke GitHub, cloud, atau unduh sebelum sesi
berakhir.

## Bolehkah saya memakainya untuk mining / hosting / komputasi umum?

Tidak. GitHub Actions hanya boleh dipakai untuk *production, testing, deployment,
atau publication* software. Repo ini ditujukan untuk eksperimen dan pengujian
tools GUI.

## Kenapa XFCE, bukan GNOME atau Cinnamon?

Karena fokus repo ini adalah **kecepatan, stabilitas, dan jejak resource kecil**:

| | GNOME | Cinnamon | XFCE (repo ini) |
| --- | --- | --- | --- |
| Compositor | Mutter (Wajib untuk animasi) | Muffin | **Mati** (tidak ada composite pass) |
| Animasi | Perlu ekstensi khusus agar hidup di software rendering | Mati otomatis di llvmpipe | **Mati** (pilihan sadar) |
| Ukuran paket desktop | ±2 GB | ±1,5 GB | **±600 MB** |
| Build time | 20–40 menit | 15–30 menit | **Target < 15 menit** |

Semua angka diukur otomatis oleh workflow — lihat [`docs/performance.md`](performance.md).
Tidak ada klaim tanpa bukti.

## Bisakah saya memasang software sendiri di dalam sesi?

Bisa. Anda punya `sudo` penuh (user `runner`, password `root`).

**Gunakan `sudo safe-upgrade`**, bukan `sudo apt upgrade -y` polos. `apt upgrade`
bisa me-restart service (termasuk `chrome-remote-desktop@runner`) dan memutus
sesi Anda.

## Kenapa `snap` tidak ada?

Snap di runner Ubuntu sering macet saat transisi paket (mis. firefox/thunderbird),
dan `snapd` menahan service serta RAM. Repo ini membuangnya sebelum upgrade dan
men-*hold* paketnya agar tidak terpasang lagi.

## Bagaimana cara mengubah PIN?

Buat secret `CRD_PIN` di **Settings → Secrets and variables → Actions → New
repository secret**. Nilai harus minimal 6 digit. Kalau tidak diisi, PIN default
`123456` dipakai — **sangat disarankan menggantinya**.

## Kenapa nama device-nya "xfce"?

Agar mudah dibedakan dari device GNOME/Cinnamon milik repo lain di akun Google
yang sama, dan agar konsisten dengan nama workflow. Nama device bisa diubah di
`scripts/xfce/15-authorize-register-chrome-remote-desktop-web-ui.sh`
(variabel `--name`).

## Kenapa kode auth baru diminta setelah desktop siap?

Kode OAuth `--code=...` dari Google bersifat **sekali pakai** dan cepat kedaluwarsa.
Kalau diminta di awal workflow, kodenya sudah basi sebelum instalasi selesai.
Karena itu repo ini membuka form web **setelah** desktop siap, sehingga kode yang
baru dibuat langsung dipakai.

## Bagaimana cara authorize di workflow XFCE?

1. Tunggu log menampilkan `[OK] FORM OTORISASI SIAP`.
2. Buka URL form yang muncul di log (dan Job Summary).
3. Di tab lain: [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless)
   → **Begin → Next → Authorize**.
4. Copy **seluruh** perintah "Debian Linux".
5. Paste ke form → submit.

## Fitur apa saja yang ada di form web?

- Tema **grayscale monokrom** dengan mode *Auto / Light / Dark*.
- Toggle bahasa **ID / EN** (disimpan di `localStorage`).
- Layout dua kolom responsif.
- Panduan 4 langkah, badge status, hitung mundur, progress bar.
- Validasi format perintah di browser, tombol salin/tempel, shortcut Ctrl/Cmd+Enter.
- Panel sukses setelah registrasi.

Perintah dan kode OAuth **tidak** disimpan di browser — hanya preferensi bahasa/tema.

## Kalau kode auth gagal, apakah harus re-run workflow?

Tidak. Selama window 30 menit masih berjalan, ambil kode **baru** dari halaman
headless lalu submit lagi ke form yang sama. Re-run hanya perlu dilakukan kalau
window 30 menit sudah habis.

## Apa itu form web dan Cloudflare quick tunnel? Perlu akun Cloudflare?

Tidak perlu akun. Workflow menjalankan server form kecil di `127.0.0.1` lalu
memexposnya lewat **quick tunnel** Cloudflare (URL acak `*.trycloudflare.com`).
Quick tunnel tidak punya SLA, jadi URL bisa mati — workflow mencoba restart
tunnel sampai 3 kali dan menampilkan URL baru.

## Apakah form web aman? Siapa yang bisa submit?

- URL form memakai **token acak 128-bit**. Siapa pun yang punya URL itu bisa
  mengirim perintah registrasi.
- Server hanya bind ke `127.0.0.1`; tidak ada akses dari luar selain lewat URL
  bertoken.
- Input divalidasi ketat (hanya `start-host`, karakter terlarang diblokir).
- **Jangan bagikan URL form**, dan tutup tab setelah selesai.

## Apakah orang lain bisa masuk ke desktop saya?

Tidak, selama:

1. Anda memakai PIN kuat (ubah lewat secret `CRD_PIN`).
2. Repo/log/Job Summary tidak dibagikan ke publik saat run berlangsung.
3. URL form otorisasi tidak dibagikan.

Akses CRD selalu butuh login akun Google Anda **dan** PIN.

## Bisakah menjalankan lebih dari satu sesi sekaligus?

Bisa, dengan batas kuota runner GitHub. Tiap run memakai device name `xfce`,
jadi kalau beberapa run aktif bersamaan, device akan tampil lebih dari satu —
pastikan PIN masing-masing agar tidak tertukar.

## Kenapa resolusi 1280x720, bukan 1920x1080?

Runner tidak punya GPU, jadi semua render memakai **llvmpipe** (software).
Resolusi lebih besar berarti lebih banyak piksel yang harus dirender dan di-capture
oleh CRD. 1280x720 memberi rasio 16:9 dengan beban hanya ±13% lebih besar dari
1024x768.

Repo ini memakai jalur resmi Chrome Remote Desktop:
`CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=1280x720` (systemd drop-in +
`~/.profile`), plus helper `xrandr` sebagai jaring pengaman. Kalau driver dummy
menolak mode tersebut, sistem otomatis jatuh ke 1024x768.

## Kenapa animasi dimatikan?

Karena di software rendering, animasi memicu redraw berulang yang.visible jelas
menuruk fluidity, sementara hasilnya hampir tidak terlihat lewat koneksi
remote. Compositor dan animasi adalah dua-"hot spot" terbesar biaya CPU — mematikan
keduanya adalah cara paling efektif membuat sesi remote terasa ringan.

## Kenapa panel XFCE sangat sederhana?

Plugin polling (systemload, netload, weather, cpugraph) mengambil data secara
berkala. Di runner tanpa GPU, ini menambah beban CPU idle tanpa manfaat nyata.
Panel repo ini hanya berisi: Whisker Menu, tasklist, separator, tray, mixer,
jam, show-desktop, dan tombol logout.

## Audio di sesi XFCE?

Berjalan melalui **PipeWire** dengan compatibility layer PulseAudio. Mixer ada di
panel. Chromium Remote Desktop mengambil audio dari PulseAudio/PipeWire, jadi
browser di klien bisa mengeluarkan suara sesi.

## Sesi saya putus saat menjalankan `apt upgrade`, kenapa?

`apt upgrade` polos bisa me-restart `chrome-remote-desktop@runner` atau service
lain, dan tanpa TTY prosesnya bisa menggantung. Pakai:

```
sudo safe-upgrade
```

Script itu menonaktifkan restart service, menghindari prompt, dan hanya
**melaporkan** paket yang butuh restart/reboot.

## Apakah bisa diakses lewat VNC/RDP, bukan Chrome Remote Desktop?

Repo ini sengaja fokus Chrome Remote Desktop (tanpa password server tambahan,
hanya PIN). Environment XFCE-nya sendiri biasa bisa diakses lewat VNC/RDP bila
Anda memasang server tambahan secara manual di dalam sesi — tapi itu di luar
scope repo ini.

## Kenapa build pertama lama?

Unduhan paket (~1 GB: XFCE, Chrome, CRD, QEMU/libvirt, tema) + compile cache. Run
kedua dan seterusnya jauh lebih cepat karena `.deb` tersimpan di **cache GitHub**.
Kalau run gagal di tengah, cache tetap tersimpan (save dilakukan sebelum step
registrasi), jadi re-run tidak mengunduh ulang.

## Bagaimana memperbarui fork saya dengan perbaikan terbaru?

Klik **Sync fork** di halaman repo GitHub Anda, lalu jalankan workflow lagi.

## English summary

XFCE is used here because it is the lightest of the three desktops compared: no
compositor, no mandatory animations, and a much smaller package footprint. Every
performance figure quoted by this project is measured by the workflow itself and
published in the Job Summary. Use `sudo safe-upgrade` instead of plain
`sudo apt upgrade -y` so package updates never drop your remote session.
