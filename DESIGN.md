# DESIGN.md: SiLAKES Analyzer (aplikasi Android petugas laboratorium)

Arah visual ditetapkan penulis pada 6 November 2026: **mengikuti warna SiLAKES**. Isi berkas ini adalah data yang dibaca dari konfigurasi frontend SiLAKES produksi (`tailwind.config.ts` dan kelas status di `src/`), bukan selera agen.

## Identitas

- **Nama aplikasi:** SiLAKES Analyzer. Nama ini sesuai *wireframe* splash dan masuk pada BAB III.
- **Logo:** lambang Kabupaten Sumenep, ditetapkan penulis pada 11 November 2026. Berkasnya diambil dari `public/logo/Sumenep-logo.png` milik SiLAKES, yaitu logo yang dicetak SiLAKES pada halaman hasil (`reviewHasil.vue`, `viewPDFHasil.vue`). Logo `logo-sm` dan `logo-dark` di SiLAKES tidak dipakai karena masih logo bawaan templat Tailwick. Lambang tidak digambar ulang atau diberi efek; ia tampil di atas latar putih pada splash, halaman masuk, ikon peluncur, dan splash Android 12.
- **Pengguna:**
  - petugas laboratorium (ATLM), yang meninjau hasil deteksi;
  - admin, yang mengelola akun, ambang, dan sinkronisasi.
- **Kepribadian:** alat kerja harian yang tenang dan tegas. Petugas membuka aplikasi untuk satu keputusan: profil mana yang perlu ditinjau lebih dulu.

## Palet (dari SiLAKES)

| Token | Nilai | Sumber SiLAKES | Dipakai untuk |
|---|---|---|---|
| brand-700 | `#224097` | `brand.700`, komentar "Biru tua SiLAKES" | Warna utama: bilah atas, tombol utama, tautan |
| brand-900 | `#1B2F63` | `brand.900` | Teks judul di atas latar terang |
| brand-50 | `#EEF2FB` | `brand.50` | Latar baris terpilih |
| body | `#1E293B` | `body` = slate-800 | Teks isi |
| body-bg | `#F1F5F9` | `body-bg` = slate-100 | Latar halaman |
| permukaan | `#FFFFFF` | `body-bordered` = white | Latar kartu dan daftar |
| perlu ditinjau | teks `#92400E` di atas `#FEF3C7` | kelas status *pending*: amber | Status deteksi "Perlu ditinjau" (satu-satunya aksen peringatan) |
| tidak ada indikasi | teks `#047857` di atas `#D1FAE5` | kelas status *approved*: emerald | Status "Tidak ada indikasi" |
| galat | teks `#9F1239` di atas `#FFE4E6` | kelas status *rejected*: rose | Pesan galat dan validasi |

Kontras setiap pasangan teks dan latar diperiksa dengan rumus WCAG sebelum aplikasi diserahkan.

## Tipografi

- **Public Sans**, huruf yang dipakai SiLAKES (`fontFamily.public`).
- Petugas sudah membaca angka hasil di SiLAKES dengan huruf ini, sehingga tampilan aplikasi terasa berasal dari sistem yang sama.
- Angka hasil pemeriksaan memakai angka tabular agar kolom nilai sejajar.

## Dial

`Dial: ENERGY 1 / RHYTHM 1 / MOTION 1`

**Design Read:** aplikasi kerja peninjauan hasil laboratorium untuk petugas laboratorium, dalam bahasa visual SiLAKES (biru tua `#224097`, Public Sans, latar slate-100).

**Alasan:** aplikasi dibuka berulang kali dalam jam kerja. Konsistensi dan kecepatan membaca lebih penting daripada kejutan visual. Gerak dibatasi pada transisi bawaan navigasi dan umpan balik sentuh.

## Motif identitas

Setiap profil ditampilkan sebagai **baris hasil dengan peluang anomali di kanan**. Angka peluangnya besar dan tabular, berlatar warna status. Motif ini dipakai di daftar, detail, dan beranda, sehingga petugas selalu menemukan angka keputusan di tempat yang sama.

## Pola halaman (dari *wireframe* BAB III)

- **Kepala halaman utama:** bilah berisi logo, nama aplikasi, dan pintasan ke Akun. Dipakai pada Beranda petugas, Hasil Deteksi, dan Beranda admin.
- **Kepala halaman turunan:** tombol kembali (tooltip "Kembali") dan judul halaman. Dipakai pada Detail, Penjelasan SHAP, Catat Tindak Lanjut, dan halaman admin yang dibuka dari menu.
- **Navigasi bawah:** petugas memiliki Beranda, Hasil Deteksi, dan Akun; admin memiliki Beranda, Pengguna, Sinkronisasi, dan Akun. Atur Ambang dibuka dari kartu menu di Beranda admin.
- **Tombol aksi di Detail:** "Penjelasan SHAP" dan "Catat Tindak Lanjut" bersebelahan dengan lebar sama. Tombol Catat Tindak Lanjut hanya muncul untuk petugas.
- **Hak cipta:** bagian bawah halaman masuk memuat identitas skripsi (nama, NIM, program studi, fakultas, universitas). Halaman masuk tidak memuat kotak informasi lain.

## Aturan komponen

- **Sudut:** radius 8 dp untuk kartu dan bidang masukan; tombol memakai radius yang sama. Tidak ada bentuk pil, kecuali lencana status yang memang menandai keadaan.
- **Bayangan:** tidak dipakai pada daftar. Kartu dipisahkan dengan latar putih di atas slate-100.
- **Ikon:** hanya ikon Material yang maknanya langsung (kembali, cari, keluar, sinkron). Tidak ada ikon dekoratif.
- **Kondisi tampilan:** setiap halaman data memiliki kondisi kosong, memuat, dan galat, beserta penyebab dan tindakan berikutnya.
- **Avatar akun:** foto pegawai dari SiLAKES dalam lingkaran berbingkai biru; selama foto dimuat atau bila akun belum ditautkan, inisial nama yang tampil.
- **Kolom kata sandi:** selalu memiliki ikon mata (tooltip "Tampilkan kata sandi" / "Sembunyikan kata sandi"), di halaman masuk maupun form akun.
- **Pesan galat form:** sesudah percobaan simpan pertama, pesan diperbarui setiap kali isian diubah, sehingga pesan lama tidak tertinggal.
- **Data contoh:** tidak ada. Semua angka berasal dari layanan Flask.
