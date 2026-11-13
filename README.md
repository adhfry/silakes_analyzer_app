# SiLAKES Analyzer (aplikasi Android)

Aplikasi Flutter ini dipakai oleh dua peran:

- petugas laboratorium, yang meninjau hasil deteksi dan mencatat tindak lanjut;
- admin, yang mengelola akun, ambang deteksi, dan sinkronisasi.

Semua data berasal dari layanan Flask di `sistem/api`. Tata letak setiap halaman mengikuti *wireframe* pada subbab Desain *User Interface* BAB III, dan arah visual mengikuti `DESIGN.md`, yaitu warna, huruf, dan logo yang dipakai SiLAKES. Aplikasi tidak memuat fungsi di luar batasan masalah skripsi.

## Menjalankan

```bash
D:/flutter/bin/flutter pub get
D:/flutter/bin/flutter build apk --release                                   # produksi
D:/flutter/bin/flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5000   # uji lokal
```

- Alamat layanan bawaan adalah layanan produksi, `https://analyzer.silakes.labkesdasumenep.id`. Untuk pengujian, alamat ditimpa saat aplikasi dibangun melalui `--dart-define=API_URL`. Halaman masuk tidak memiliki pengaturan alamat server, karena fungsi itu tidak termasuk rancangan.
- `10.0.2.2` adalah alamat laptop dilihat dari dalam emulator Android.
- Token JWT disimpan di penyimpanan aman Android (`flutter_secure_storage`). Keluar akun menghapus token itu.
- Build rilis hanya memakai HTTPS. HTTP tanpa enkripsi (`usesCleartextTraffic`) hanya diizinkan pada build debug dan profile (`android/app/src/debug`, `android/app/src/profile`) untuk pengujian ke layanan lokal.
- Build rilis ditandatangani kunci dari `android/key.properties` (berisi `storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Berkas itu dan berkas `.jks` tidak masuk repo. Tanpa `key.properties`, build rilis memakai kunci debug.
- `android/gradle.properties` memuat `kotlin.incremental=false`. Pengaturan ini mencegah galat cache Kotlin di Windows saat proyek (drive D:) dan cache paket (drive C:) berada di drive berbeda.

Emulator yang dipakai: `matrix_pixel`, profil Pixel 7, Android 15 (API 35), 1080 × 2400 piksel, 420 dpi, RAM 3 GB.

## Halaman

| Peran | Halaman |
|---|---|
| Umum | Splash (logo, nama, subjudul, indikator memuat), Masuk (ikon mata untuk melihat/menyembunyikan kata sandi, hak cipta skripsi di bagian bawah), Akun (foto pegawai SiLAKES, nama, username, peran, keluar) |
| Petugas | Beranda (ringkasan status dan tiga profil perlu ditinjau terbaru), Hasil Deteksi (cari, cip status dengan jumlah, urutan peluang, rentang tanggal), Detail (identitas, lingkaran peluang terhadap ambang, tabel No/Parameter/Hasil/Satuan/Rujukan/Ket), Penjelasan SHAP (batang kontribusi delapan fitur dan penjumlahan nilai dasar sampai peluang), Catat Tindak Lanjut (tiga pilihan keputusan dan catatan) |
| Admin | Beranda (model aktif, ambang, sinkronisasi terakhir, menu), Kelola Akun (foto, cari, tambah, ubah, aktif/nonaktif), Form Akun (username pegawai SiLAKES untuk foto, reset kata sandi dengan ikon mata), Atur Ambang (0 sampai 1, aturan peluang > ambang), Sinkronisasi (enam tahap dan ringkasan hasil) |

Akun tidak dibuat lewat website SiLAKES. Admin pertama dibuat di server (`flask buat-admin`), lalu admin membuat akun petugas di aplikasi (menu Pengguna, Tambah Akun) dan mengisi username pegawai SiLAKES agar foto pegawai terambil. Petugas yang lupa kata sandi meminta admin meresetnya di form ubah akun.

Setiap halaman data memiliki kondisi memuat, kosong, dan galat. Setiap kondisi menyebut penyebabnya dan tindakan berikutnya.

## Logo dan splash

- Logo memakai lambang Kabupaten Sumenep (`assets/images/logo.png`). Berkas ini sama dengan `public/logo/Sumenep-logo.png` yang dipakai SiLAKES pada halaman hasil (`reviewHasil.vue` dan `viewPDFHasil.vue`).
- Ikon peluncur, ikon adaptif, dan splash Android 12 ke atas (`values-v31`) memakai lambang yang sama dengan latar putih.
- Splash Flutter menunggu bingkai pertama tergambar, lalu tampil paling sedikit 1,2 detik sambil memuat sesi. Tanpa penantian ini, splash hampir tidak terlihat saat aplikasi dibuka dari keadaan mati (temuan uji nomor 6 pada BAB IV).

## Pengujian

| Jenis | Perintah | Hasil terakhir |
|---|---|---|
| Analisis statis | `flutter analyze` | tidak ada temuan |
| Uji widget | `flutter test test/widget_test.dart` | 3 lulus (format angka, kartu hasil, kondisi galat) |
| Black box di emulator | `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/black_box_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5000 --dart-define=SANDI_PETUGAS=... --dart-define=SANDI_PETUGAS_BARU=... --dart-define=SANDI_ADMIN=...` | 26 dari 26 skenario sesuai (P01 sampai P14, A01 sampai A12), 11 November 2026 pukul 17.22.24 sampai 17.25.17 WIB |

- Skenario black box sama dengan Tabel Rencana Pengujian di BAB III dan Tabel Hasil Pengujian di BAB IV. Urutannya mengikuti cara akun dibuat: halaman login (P01 sampai P05), admin Ahda Firly Barori membuat akun petugas Itsna Jazilah, A.Md.Ak. (A01 sampai A04), petugas memakai akun itu (P06 sampai P14), lalu admin menguji reset kata sandi dan menu lain (A05 sampai A12).
- Basis data uji dibuat baru oleh `bukti_pengujian/siapkan_basis_data_uji.sh` sebelum setiap uji resmi.
- Kata sandi uji diberikan lewat `--dart-define` dan tidak disimpan di repositori. Log yang dilampirkan sudah disamarkan.
- Seluruh uji resmi dan pengumpulan bukti dijalankan oleh `bukti_pengujian/uji_resmi.sh`. Hasilnya:
  - `hasil_black_box_emulator.txt`;
  - `log_flutter_drive.txt`;
  - `log_flutter_analyze.txt`;
  - `log_flutter_test.txt`;
  - `log_kegiatan_uji.txt` (urutan kegiatan beserta waktunya);
  - 46 tangkapan layar di `bukti_pengujian/layar_emulator/`, dengan keterangan di `daftar_tangkapan_layar.tsv`.
- Kontras WCAG semua pasangan teks dan latar memenuhi AA:
  - status perlu ditinjau 6,37;
  - status tidak ada indikasi 4,84;
  - galat 6,68;
  - teks keterangan 6,92;
  - teks putih di atas biru SiLAKES 9,34.
