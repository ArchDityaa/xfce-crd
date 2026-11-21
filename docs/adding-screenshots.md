# Menambahkan screenshot ke README

ScreenshotXFCE sangat membantu orang deciding apakah repo ini cocok untuk
kebutuhannya. Dokumen ini menjelaskan cara mengambil dan mengirimkannya.

---

## 1. Ambil screenshot di dalam sesi CRD

### Cara A — Xfce Screenshooter (paling mudah)

Shortcut **Settings**/ikon screenshot di panel, atau:

```bash
xfce4-screenshooter
```

Screenshooter bisa menangkap **wilayah tertentu**, **jendela aktif**, atau **layar
penuh**, lalu menyalin hasilnya ke clipboard.

### Cara B — dari Chrome di dalam sesi

1. Buka Chrome di sesi CRD.
2. Akses situs screenshot (mis. [`screenshotone`](https://screenshotone.com/) atau
   [`flameshot`](https://flameshot.org/) versi web).
3. Ambil screenshot, lalu unduh.

> Cara ini berguna kalau tampilan yang ingin ditampilkan adalah browser, bukan
> desktop XFCE-nya.

---

## 2. Bawa keluar dari sesi CRD

### Cara A — lewat Chrome di dalam sesi (paling mudah, tanpa token)

1. Upload file ke hosting gambar / GitHub gist / Google Drive.
2. Salin URL publik.
3. Kirim URL-nya ke maintainer repo.

### Cara B — lewat git + Personal Access Token

Di dalam sesi:

```bash
cd /tmp
git clone https://github.com/<user>/<repo>.git
cd repo
cp /path/ke/screenshot.png docs/images/
git add docs/images/screenshot.png
git commit -m "docs: add XFCE screenshot"
git push
```

Buat **Personal Access Token** (scope `repo`) di GitHub → **Settings → Developer
settings → Personal access tokens**, lalu pakai saat push:

```bash
git remote set-url origin https://<TOKEN>@github.com/<user>/<repo>.git
git push
```

> Jangan pernah commit token. Setelah push, kembalikan URL remote:
> `git remote set-url origin https://github.com/<user>/<repo>.git`

### Cara C — kirim ke pemelihara repo

Kirim file lewat issue (kebijakan GitHub mengizinkan upload gambar ke issue) atau
via kontak pada README.

---

## 3. Standar gambar

| Aturan | Nilai |
| --- | --- |
| Format | PNG |
| Lebar | 1280–1920 px (sesuai resolusi sesi) |
| Rasio | Jangan dipotong |
| Ukuran file | < 2 MB (kompres bila perlu) |
| Kompresi | `pngquant` atau `optipng` |
|GDPR | Pastikan tidak ada data sensitif, nama akun, atau token di layar |

Contoh kompresi:

```bash
pngquant --quality=70-85 --speed 1 --strip --force --output=screenshot.png screenshot-original.png
```

---

## 4. Aktifkan slot di README

Folder tujuan: `docs/images/`.

Sebutan di README (file `README.md` dan `README.en.md`):

```html
<p align="center">
  <img src="docs/images/xfce-proof-YYYY-MM-DD.png" alt="XFCE 4.18 di Chrome Remote Desktop" width="900">
</p>
```

---

## 5. Tangkapan layar

| Nama file | Isi |
| --- | --- |
| `xfce-proof-YYYY-MM-DD.png` | Bukti desktop XFCE aktif (panel, tema, terminal). |

---

## 6. Checklist sebelum commit

- [ ] Screenshot benar-benar dari sesi **XFCE + Chrome Remote Desktop** repo ini.
- [ ] Tidak ada PIN, kode OAuth, atau URL form otorisasi yang terlihat.
- [ ] Nama file memakai format `xfce-proof-YYYY-MM-DD.png`.
- [ ] Gambar sudah dikompres (< 2 MB).
- [ ] Slot di `README.md` **dan** `README.en.md` sudah diisi.
- [ ] `CHANGELOG.md` sudah diberi entri.

---

## English summary

Take the screenshot inside the CRD session (Xfce Screenshooter or a browser-based
tool), then upload it through Chrome, push it with git, or attach it to an issue.
Compress it, never show secrets (PIN, OAuth code, form URL), place it in
`docs/images/`, and reference it from both README files.
