# Metrik Performa — XFCE + Chrome Remote Desktop

Dokumen ini menjelaskan **bagaimana** repo `xfce-crd` mengukur dirinya sendiri, dan
**cara membaca** angkanya. Tidak ada angka priori di sini: semua nilai berasal dari
run workflow yang nyata.

---

## 1. Prinsip

> **Tidak ada klaim performa tanpa bukti.**

Repo ini tidak berisi tabel "XFCE 2× lebih cepat dari GNOME" yang tidak bisa
diverifikasi. Sebagai gantinya:

1. Setiap run workflow **mengukur** kondisinya sendiri.
2. Hasilnya ditulis otomatis ke **Job Summary** run tersebut.
3. Angka yang bisa direproduksi (versi paket, setting compositor, renderer) ikut
   dicatat sebagai **bukti konfigurasi**, bukan cuma angka.

## 2. Di mana angkanya

| Lokasi | Isi |
| --- | --- |
| **Job Summary** run `xfce.yml` | Tabel metrik build + metrik runtime sesi (otomatis, tiap run) |
| Log step **Smoke Test & Build Benchmark** | Ringkasan metrik yang sama dalam bentuk teks |
| Log step **Keep Alive** | Heartbeat + metrik runtime sesi |

Buka: **Actions → XFCE 24.04 → run tertentu → Job Summary**.

## 3. Metrik yang diukur

### 3.1 Metrik build (STEP 17)

| Metrik | Cara ukur | Untuk apa |
| --- | --- | --- |
| Waktu sejak job start | `JOB_START_EPOCH` → timestamp sekarang | Mengukur total biaya setup |
| Jumlah paket terpasang | `dpkg-query -W | wc -l` | Ukuran jejak software |
| Berat disk | `du -sx --block-size=1M /usr /opt /var` | Ukuran environment |
| RAM sistem | `free -m` | Beban memori saat build |
| CPU idle | `vmstat 1 6` (rata-rata kolom `id`) | Beban background saat build |
| Load average | `/proc/loadavg` | Queue CPU |
| Compositor xfwm4 | `xfconf-query -c xfwm4 -p /general/use_compositing` | **Bukti** mode performa aktif |
| Smoke test sesi | `xfwm4` + `xfce4-panel` start di Xvfb | **Bukti** konfigurasi sesi valid |

### 3.2 Metrik runtime sesi (STEP 18)

| Metrik | Cara ukur | Untuk apa |
| --- | --- | --- |
| Proses user `runner` | `pgrep -u runner | wc -l` | Berapa banyak proses desktop hidup |
| Total RSS sesi | `ps -u runner -o rss=` (dijumlahkan) | Memori yang dipakai desktop |
| RAM sistem | `free -m` | Memori total terpakai |
| CPU idle | `vmstat 1 6` | Beban idle sesi desktop |
| Load average | `/proc/loadavg` | Queue CPU saat sesi hidup |
| Compositor | `xfconf-query ... use_compositing` | Otomatis **false** = target tercapai |
| Resolusi aktif | `xrandr --current` | Mode yang benar-benar dipakai |
| Renderer OpenGL | `glxinfo -B` | `llvmpipe` = software rendering |
| `xfwm4` berjalan | `pgrep -u runner -x xfwm4` | Window manager hidup |

> **Catatan resolusi:** mode desktop virtual ditentukan CRD lewat
> `CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES=1280x720` (systemd drop-in +
> `~/.profile`). Helper `xrandr` hanya jaring pengaman; kalau driver dummy
> menolak mode tersebut, sesi jatuh ke `1024x768` — dan angka `Resolusi aktif`
> di tabel akan menunjukkan itu apa adanya.

### 3.3 Smoke test sesi (STEP 17)

Sebelum user melakukan otorisasi, workflow menjalankan `xfce4-session` sungguhan di
bawah **Xvfb** dengan `HOME` terisolasi, lalu memastikan `xfwm4` dan `xfce4-panel`
benar-benar start dengan konfigurasi yang di-seed.

Tujuannya: menangkap error XML panel/tema **sebelum**	user-Guided spend time
mengotorisasi CRD. Kegagalan smoke test hanya **peringatan**, bukan kegagalan build,
karena build produksi memakai Xorg milik CRD.

## 4. Target desain

Target ini adalah **design goal**, bukan jaminan. Validasi sebenarnya = angka di
Job Summary run Anda.

| Metrik | Target | Alasan |
| --- | --- | --- |
| Build cold | ≤ 12 menit | Total unduhan + install paket desktop |
| Build warm cache | ≤ 6 menit | Cache `.deb` GitHub terpakai |
| RAM idle sesi | ≤ 550 MB | Desktop XFCE tanpa compositor |
| CPU idle | ≤ 2% | Tanpa composite pass + tanpa plugin polling |
| Disk DE | ≤ 600 MB | Paket dipangkas (`--no-install-recommends`) |
| Proses sesi | ≤ 22 | Autostart minimal |
| Startup sesi | ≤ 15 detik | Setelah connect sampai panel siap |

## 5. Cara membandingkan dengan repo lain

Agar perbandingan jujur, bandingkan dengan **metode yang sama**:

1. Jalankan workflow `xfce-crd` dan workflow GNOME/Cinnamon pada repo lain **pada
   kondisi runner yang sama** (`ubuntu-24.04`, tanpa GPU).
2. Catat **waktu build** dari log kedua repo.
3. Buka Job Summary keduanya, lalu bandingkan tabel metrik runtime sesi.
4. Catat **run ID** keduanya — tanpa itu, perbandingan tidak bisa diaudit.

Kondition yang harus sama:

- Runner image identik (`ubuntu-24.04`).
- Cache dalam keadaan sama (cold atau warm).
- Tidak ada aplikasi berat lain yang dibuka di sesi.
- Pengukuran diambil pada waktu yang relatif sama setelah desktop aktif.

## 6. Apa yang **tidak** diukur di sini

- **FPS video di sisi klien.** Codec dan frame rate CRD ditentukan oleh Google
  Chrome Remote Desktop dan kondisi jaringan, bukan oleh DE. Yang bisa diukur di sisi
  server adalah "berapa mahal frame yang harus di-capture" — dan itulah yang
  dikurangi dengan mematikan compositor.
- **Latency input.** terpengaruh jaringan dan sisi klien.
- **Kualitas audio.**-tergantung codec dan jitter jaringan.

## 7. Cara mendapatkan angka untuk issues / PR

Saat membuka issue performa, sertakan:

1. **Run ID** workflow.
2. Tabel metrik dari **Job Summary** (build + runtime).
3. Output `xfconf-query -c xfwm4 -p /general/use_compositing`.
4. Output `glxinfo -B` (renderer).
5. Output `xrandr --current`.

> **Jangan pernah** sertakan URL form otorisasi, kode OAuth (`--code=...`), atau PIN.

## 8. English summary

Every workflow run measures itself and writes the numbers to the **Job Summary**:
build time, package count, disk usage, RAM, idle CPU, compositor state, active
resolution, and the OpenGL renderer. A session smoke test under Xvfb proves that the
seeded panel/window-manager configuration actually starts.

Design targets are listed above, but they are goals — the real evidence is the
measured output of your own run. Use the same methodology (same runner image, same
cache state, same timing) when comparing against other desktops.
