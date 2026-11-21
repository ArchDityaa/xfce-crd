# Troubleshooting

Panduan lengkap untuk masalah yang sering terjadi pada workflow `xfce.yml`
(XFCE 24.04 + Chrome Remote Desktop).

---

## 1. Workflow tidak muncul di tab Actions

**Penyebab:** GitHub menonaktifkan workflow pada repo hasil fork.

**Solusi:**

1. Buka repo fork Anda → **Settings** → **Actions** → **General**.
2. Pilih **Allow all actions and reusable workflows**.
3. Klik **Save**.
4. Kembali ke tab **Actions**, workflow **XFCE 24.04** sudah muncul.

---

## 2. URL form otorisasi tidak muncul / error Cloudflare

**Gejala:** step **Authorize & Register Chrome Remote Desktop (Web UI)** gagal, log
tidak menampilkan `[OK] FORM OTORISASI SIAP`.

**Penyebab & solusi:**

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| `[FAIL] Cloudflare quick tunnel tidak bisa dibuat` | Tunnel gagal dibuat | Jalankan ulang workflow (cache `.deb` terpakai). |
| Error 1033 / 502 di browser | Tunnel sedang warm-up | Tunggu ±15 detik lalu refresh. |
| Tunnel berhenti setelah URL tampil | Koneksi ke Cloudflare putus | Workflow otomatis restart tunnel (sampai 3×) dan menampilkan URL baru. |
| Tidak ada form maupun fallback | Semua jalur gagal | Re-run workflow; jalankan dengan `crd_host_command` terisi sebagai fallback kalau punya perintah yang masih valid. |

---

## 3. Registrasi CRD gagal / kode auth bermasalah

**Penyebab:** kode OAuth `--code=...` bersifat sekali pakai dan cepat kedaluwarsa.

**Solusi:**

1. Buka kembali [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless).
2. Ambil **perintah baru**.
3. Submit lagi ke **form yang sama** — tidak perlu re-run workflow selama window
   30 menit masih berjalan.
4. Workflow mencoba registrasi maksimal 3× per perintah.

Kalau window sudah habis, jalankan ulang workflow. Cache `.deb` membuat build ulang
jauh lebih cepat.

---

## 4. Workflow "READY" tapi device tidak muncul di Remote Access

**Solusi:**

1. Tunggu log `[OK] CHROME REMOTE DESKTOP READY`.
2. Refresh halaman [remotedesktop.google.com/access](https://remotedesktop.google.com/access).
3. Cek service dari terminal runner (atau lewat Actions → step Keep Alive):

```bash
systemctl status chrome-remote-desktop@runner
journalctl -u chrome-remote-desktop@runner -n 50 --no-pager
```

4. Kalau service mati, jalankan:

```bash
sudo systemctl restart chrome-remote-desktop@runner
```

---

## 5. Tidak bisa connect / PIN ditolak

**Penyebab & solusi:**

| Penyebab | Solusi |
| --- | --- |
| PIN default `123456` tapi Anda memakai PIN lain | PIN yang dipakai workflow = secret `CRD_PIN` (kalau diisi), kalau tidak `123456`. |
| Device dengan nama sama dari run lain | Hapus device lama di [Remote Access](https://remotedesktop.google.com/access), lalu connect ulang. |
| Sesi belum siap | Tunggu beberapa detik setelah `[OK] CHROME REMOTE DESKTOP READY`. |

---

## 6. Sesi putus tiba-tiba

**Penyebab umum:**

1. **Update paket** → Anda memakai `apt upgrade` polos. Pakai `sudo safe-upgrade`.
2. **OOM kill** → proses besar (Chrome + banyak tab) di runner 16 GB. Tutup tab.
3. **Crash Xorg / xfwm4** → watchdog di STEP 18 biasanya memulihkan otomatis; tunggu
   ±1–2 menit lalu reconnect.

**Cek log:**

```bash
journalctl -u chrome-remote-desktop@runner -n 100 --no-pager
tail -n 100 ~/.xsession-errors
dmesg | tail -n 50
```

---

## 7. Sesi berakhir sendiri setelah beberapa jam

Normal — batas job GitHub-hosted adalah **6 jam**. Setelah itu workflow selesai
dan VM dimatikan. Simpan hasil kerja Anda sebelum waktu habis.

---

## 8. Resolusi layar aneh / terlalu kecil

Repo ini memakai **1280x720** lewat environment variable resmi CRD
(`CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES`). Kalau driver dummy menolak mode
tersebut, sistem otomatis fallback ke **1024x768** — itu normal, bukan error.

**Cek mode aktif:**

```bash
xrandr --current
```

**Cek konfigurasi CRD:**

```bash
grep -r CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES \
  /etc/systemd/system/chrome-remote-desktop@.service.d/
grep CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES ~/.profile
```

**Paksa ulang:**

```bash
/usr/local/bin/set-resolution.sh
```

Kalau tetap 1024x768, buka issue dengan output `xrandr --current` dan
`cvt 1280 720 60`.

---

## 9. `virt-manager` bermasalah

**Gejala:** `virt-manager` gagal membuat VM atau menampilkan "No KVM!".

**Solusi:**

```bash
# Pastikan URI libvirt per-user = session
grep uri_default ~/.config/libvirt/libvirt.conf

# Cek KVM
ls -l /dev/kvm
virsh -c qemu:///session capabilities | grep "domain type='kvm'"
```

Kalau `virsh capabilities` (tanpa `-c`) gagal tapi `-c qemu:///session` berhasil,
itu masalah default URI. Repo ini sudah menulis
`uri_default = "qemu:///session"` di `~/.config/libvirt/libvirt.conf`.

---

## 10. Panel XFCE hilang atau tidak muncul

**Gejala:** desktop terlihat tapi tidak ada panel atas.

**Solusi (di dalam sesi):**

```bash
xfce4-panel &
```

**Cek log XFCE:**

```bash
tail -n 100 ~/.xsession-errors
```

**Cek config panel:**

```bash
xfconf-query -c xfce4-panel -l
```

Kalau file `xfce4-panel.xml` rusak, kembalikan ke default:

```bash
rm -f ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
xfce4-panel -r
```

---

## 11. Tema / ikon tidak berubah

**Cek status:**

```bash
xfconf-query -c xsettings -p /Net/ThemeName
xfconf-query -c xsettings -p /Net/IconThemeName
xfconf-query -c xfwm4 -p /general/theme
ls ~/.themes/
```

Kalau `use_compositing` ternyata `true`, jalankan guard manual:

```bash
/usr/local/bin/xfce-performance-guard.sh
```

---

## 12. Compositor ternyata aktif (desktop berat)

Target repo ini adalah compositor **mati**.

```bash
xfconf-query -c xfwm4 -p /general/use_compositing
```

Kalau hasilnya `true`:

```bash
xfconf-query -c xfwm4 -p /general/use_compositing -s false
```

Nilai ini juga dipaksa ulang oleh `xfce-performance-guard.sh` saat sesi start.

---

## 13. Cara mengambil log untuk laporan issue

1. Buka **Actions** → run yang bermasalah → klik step yang gagal.
2. Klik ikon **Download log** (atau salin manual).
3. **Jangan sertakan:** URL form otorisasi, isi `crd_host_command`, kode OAuth
   (`--code=...`), atau PIN Anda.
4. Sertakan juga **run ID** dan output:

```bash
xfconf-query -c xfwm4 -p /general/use_compositing
glxinfo -B
xrandr --current
free -m
```

---

## 14. Re-run cepat vs. run dari nol

- **Re-run dengan cache**: `.deb` tersimpan di cache GitHub (key harian). Setelah
  run pertama, build ulang jauh lebih cepat.
- Cache disimpan **sebelum** step registrasi, jadi gagal di tahap auth pun tidak
  membuat cache hilang.
- Kalau key harian sudah dipakai, cache tidak bisa ditimpa → pakai `restore-keys`,
  dan `continue-on-error` agar job tidak gagal.

---

## 15. Lambat / build terlalu lama

| Penyebab | Solusi |
| --- | --- |
| Cache belum terisi (run pertama) | Normal. Run berikutnya jauh lebih cepat. |
| `apt` mengulang unduhan | Cek `Acquire::Retries` dan `Acquire::Languages "none"` sudah aktif (`/etc/apt/apt.conf.d/99-speed`). |
| `needrestart` menahan apt | Sudah dimatikan di STEP 01; kalau muncul banner "Scanning processes...", cek `/etc/needrestart/needrestart.conf.d/99-no-restart.conf`. |

---

## 16. Audio tidak terdengar

1. Cek mixer di panel (plugin PulseAudio).
2. Cek service:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
pactl info | head -n 20
```

3. Pastikan **tidak** muted di sisi klien CRD (ikon audio di browser).

---

## 17. Smoke test gagal tapi sesi tetap bisa dipakai

Step **Smoke Test & Build Benchmark** menjalankan sesi XFCE di bawah Xvfb. Kegagalan
di sini **tidak fatal** karena build produksi memakai Xorg milik CRD.

**Yang perlu dicek jika smoke test gagal:**

```bash
tail -n 50 /tmp/xfce-smoke/session.log   # log hanya ada selama job berjalan
```

Gejala umum: `xfwm4` butuh beberapa detik lebih lama di Xvfb. Smoke test menunggu
maks 25 detik, jadi environment yang sangat lambat bisa gagal terdeteksi.

---

## 18. English summary

Most issues fall into four buckets: Actions not enabled on the fork, the Cloudflare
tunnel not being ready, an expired OAuth code (just fetch a new command), and
packages being upgraded with plain `apt upgrade` (use `sudo safe-upgrade`). XFCE
specific issues are usually a missing panel (run `xfce4-panel &`) or the compositor
being re-enabled (`xfconf-query -c xfwm4 -p /general/use_compositing -s false`).
