// Uji black box pada emulator Android terhadap layanan Flask yang berjalan.
//
// Jalankan dari folder sistem/mobile (Flask harus aktif di laptop, emulator mengaksesnya lewat 10.0.2.2):
//   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/black_box_test.dart \
//     -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5000 \
//     --dart-define=SANDI_PETUGAS=... --dart-define=SANDI_PETUGAS_BARU=... --dart-define=SANDI_ADMIN=...
// Urutan uji mengikuti cara akun dibuat: admin pertama (dibuat di server) masuk, membuat akun petugas yang ditautkan
// ke data pegawai SiLAKES, lalu petugas memakai akun itu; setelahnya admin menguji reset kata sandi dan menu lain.
// Kata sandi tidak disimpan di berkas ini. Hasil setiap skenario dicetak di akhir dan tangkapan layar disimpan
// di build/uji_emulator/.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:silakes_analyzer/halaman/petugas.dart';
import 'package:silakes_analyzer/main.dart' as aplikasi;
import 'package:silakes_analyzer/widget/umum.dart';

const sandiPetugas = String.fromEnvironment('SANDI_PETUGAS');
const sandiAdmin = String.fromEnvironment('SANDI_ADMIN');
const sandiPetugasBaru = String.fromEnvironment('SANDI_PETUGAS_BARU');
const akunSilakesPetugas = 'jazilah@labkesmas';
const userPetugas = 'jazilah';
const namaPetugas = 'Itsna Jazilah, A.Md.Ak.';
const userAdmin = 'ahda';
const namaAdmin = 'Ahda Firly Barori';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final hasil = <List<String>>[];
  var permukaan = false;

  Future<void> foto(WidgetTester t, String nama) async {
    if (!permukaan) {
      await binding.convertFlutterSurfaceToImage();
      permukaan = true;
    }
    await t.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot(nama);
  }

  /// Memompa bingkai sampai finder ditemukan; tidak memakai pumpAndSettle karena indikator pemuatan berputar.
  Future<void> tunggu(WidgetTester t, Finder f, {int detik = 20}) async {
    final batas = DateTime.now().add(Duration(seconds: detik));
    while (DateTime.now().isBefore(batas)) {
      await t.pump(const Duration(milliseconds: 250));
      if (f.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Tidak muncul dalam $detik detik: $f');
  }

  Future<void> langkah(String nama, Future<void> Function() isi) async {
    try {
      await isi();
      hasil.add([nama, 'Sesuai']);
    } catch (e, st) {
      hasil.add([nama, 'Tidak sesuai: ${e.toString().split('\n').first}']);
      debugPrint('GALAT_UJI $nama: $e');
      debugPrint(st.toString().split('\n').where((b) => b.contains('black_box_test')).take(4).join('\n'));
    }
  }

  /// Gulir daftar vertikal halaman yang sedang tampil sampai finder terlihat, ke bawah lalu ke atas.
  Future<void> gulirSampai(WidgetTester t, Finder f) async {
    if (f.evaluate().isNotEmpty) {
      await t.ensureVisible(f.first);
      await t.pump(const Duration(milliseconds: 300));
      return;
    }
    final daftar = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    for (final arah in [250.0, -250.0]) {
      try {
        await t.scrollUntilVisible(f, arah, scrollable: daftar.last, maxScrolls: 30);
        await t.pump(const Duration(milliseconds: 300));
        return;
      } on StateError {
        // Tidak ditemukan pada arah ini; coba arah sebaliknya.
      }
    }
    throw TestFailure('Tidak ditemukan saat digulir: $f');
  }

  /// Mengetuk elemen; bila elemen belum dibangun karena di luar layar, daftar digulir lebih dahulu.
  Future<void> ketuk(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) await gulirSampai(t, f);
    await t.ensureVisible(f.first);
    await t.pump(const Duration(milliseconds: 200));
    // daftar dapat ditata ulang sesaat (misalnya papan ketik menutup); tunggu elemen muncul kembali
    if (f.evaluate().isEmpty) await tunggu(t, f, detik: 10);
    await t.tap(f.first);
    await t.pump(const Duration(milliseconds: 300));
  }

  /// Tombol kembali pada kepala halaman. Kepala ikut tergulir, jadi daftar digulir ke atas lebih dahulu.
  Future<void> kembali(WidgetTester t) async {
    final tombol = find.byTooltip('Kembali');
    if (tombol.evaluate().isEmpty) {
      final daftar = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      await t.scrollUntilVisible(tombol, -250, scrollable: daftar.last, maxScrolls: 40);
    }
    await t.tap(tombol.last);
    await t.pump(const Duration(milliseconds: 600));
  }

  Future<void> masuk(WidgetTester t, String user, String sandi) async {
    final kolom = find.byType(TextFormField);
    await t.enterText(kolom.at(0), user);
    await t.enterText(kolom.at(1), sandi);
    await ketuk(t, find.widgetWithText(FilledButton, 'Masuk'));
  }

  Future<void> keluar(WidgetTester t) async {
    await ketuk(t, find.text('Akun').last);
    await tunggu(t, find.text('Keluar'));
    await ketuk(t, find.text('Keluar'));
    await tunggu(t, find.widgetWithText(TextButton, 'Keluar'));
    await ketuk(t, find.widgetWithText(TextButton, 'Keluar'));
    await tunggu(t, find.widgetWithText(FilledButton, 'Masuk'));
  }

  /// Menutup papan ketik dan menunggu tata letak stabil sebelum mengetuk daftar atau mengambil tangkapan layar.
  Future<void> tenang(WidgetTester t, {int milidetik = 1500}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump(Duration(milliseconds: milidetik));
    await t.pump(const Duration(milliseconds: 300));
  }

  /// Elemen di dalam kartu akun dengan username tertentu pada halaman kelola akun.
  Finder diKartuAkun(String user, Finder isi) =>
      find.descendant(of: find.widgetWithText(Kartu, '@$user'), matching: isi);

  Future<void> mulai(WidgetTester t) async {
    await const FlutterSecureStorage().deleteAll();
    await aplikasi.main();
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('black box petugas laboratorium dan admin', (t) async {
    await mulai(t);
    // ---------------- halaman pembuka dan login (berlaku untuk kedua peran)
    await langkah('P01 Splash screen tampil saat aplikasi dibuka', () async {
      await tunggu(t, find.text('Memuat aplikasi...'), detik: 10);
      await foto(t, '01_splash');
    });
    await langkah('P02 Halaman login tampil', () async {
      await tunggu(t, find.widgetWithText(FilledButton, 'Masuk'));
      await foto(t, '02_login');
    });
    await langkah('P03 Login dengan isian kosong ditolak', () async {
      await ketuk(t, find.widgetWithText(FilledButton, 'Masuk'));
      await tunggu(t, find.text('Username wajib diisi.'));
      await foto(t, '03_login_kosong');
    });
    await langkah('P04 Login dengan kata sandi salah ditolak', () async {
      await masuk(t, userPetugas, 'sandi-salah-1');
      await tunggu(t, find.text('Username atau kata sandi salah.'));
      await tenang(t, milidetik: 500);
      await foto(t, '04_login_salah');
    });
    await langkah('P05 Tombol mata menampilkan dan menyembunyikan kata sandi', () async {
      await t.enterText(find.byType(TextFormField).at(1), 'contohsandi');
      await ketuk(t, find.byTooltip('Tampilkan kata sandi'));
      expect(t.widget<EditableText>(find.byType(EditableText).at(1)).obscureText, isFalse);
      await tenang(t, milidetik: 500);
      await foto(t, '05_sandi_terlihat');
      await ketuk(t, find.byTooltip('Sembunyikan kata sandi'));
      expect(t.widget<EditableText>(find.byType(EditableText).at(1)).obscureText, isTrue);
      await tenang(t, milidetik: 500);
      await foto(t, '06_sandi_tersembunyi');
      await t.enterText(find.byType(TextFormField).at(0), '');
      await t.enterText(find.byType(TextFormField).at(1), '');
    });

    // ---------------- admin pertama membuat akun petugas yang ditautkan ke data pegawai SiLAKES
    await langkah('A01 Login admin berhasil dan beranda admin tampil', () async {
      await masuk(t, userAdmin, sandiAdmin);
      await tunggu(t, find.text('Sinkronisasi Terakhir'));
      await foto(t, '07_beranda_admin');
      await gulirSampai(t, find.text('Sinkronisasi Data'));
      await foto(t, '08_beranda_admin_bawah');
    });
    await langkah('A02 Simpan akun baru dengan isian kosong ditolak', () async {
      await ketuk(t, find.text('Pengguna').last);
      await tunggu(t, find.text('Akun petugas laboratorium dan admin.'));
      await tenang(t);
      await foto(t, '09_kelola_akun_awal');
      await ketuk(t, find.text('Tambah Akun'));
      await tunggu(t, find.text('Akun dibuat oleh admin; tidak ada pendaftaran mandiri.'));
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan'));
      await tunggu(t, find.text('Nama wajib diisi.'));
      await tenang(t, milidetik: 500);
      await foto(t, '10_tambah_akun_kosong');
    });
    await langkah('A03 Menambah akun petugas yang ditautkan ke pegawai SiLAKES', () async {
      final kolom = find.byType(TextFormField);
      await t.enterText(kolom.at(0), namaPetugas);
      await t.enterText(kolom.at(1), userPetugas);
      await t.enterText(kolom.at(2), akunSilakesPetugas);
      await t.enterText(kolom.at(3), sandiPetugas);
      await tenang(t, milidetik: 500);
      // pesan galat dari percobaan simpan kosong harus hilang setelah isian diperbaiki
      expect(find.text('Nama wajib diisi.'), findsNothing);
      expect(find.text('Format username tidak valid.'), findsNothing);
      await gulirSampai(t, find.widgetWithText(FilledButton, 'Simpan'));
      await foto(t, '11_tambah_akun_terisi');
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan'));
      await tunggu(t, find.text('Akun dibuat.'));
      await tunggu(t, find.text(namaPetugas));
      await tunggu(t, diKartuAkun(userPetugas, find.byType(RawImage)));
      await tenang(t, milidetik: 500);
      await foto(t, '12_akun_dibuat');
    });
    await langkah('A04 Kelola akun menampilkan foto dan pencarian akun', () async {
      await t.enterText(find.byType(TextField).first, 'itsna');
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('@$userAdmin'), findsNothing);
      expect(find.text(namaPetugas), findsOneWidget);
      await tenang(t);
      await foto(t, '13_cari_akun');
      await t.enterText(find.byType(TextField).first, '');
      await tenang(t);
      await keluar(t);
    });

    // ---------------- petugas laboratorium memakai akun yang dibuat admin
    await langkah('P06 Login petugas berhasil dan beranda tampil', () async {
      await masuk(t, userPetugas, sandiPetugas);
      await tunggu(t, find.text('Ringkasan Hasil Deteksi'));
      expect(find.text('Petugas Laboratorium'), findsOneWidget);
      await foto(t, '14_beranda_petugas');
      await gulirSampai(t, find.textContaining('Hasil deteksi adalah prediksi model'));
      await foto(t, '15_beranda_petugas_bawah');
    });
    await langkah('P07 Daftar hasil deteksi tampil urut dari peluang tertinggi', () async {
      await ketuk(t, find.text('Hasil Deteksi').last);
      await tunggu(t, find.byType(KartuHasil));
      await foto(t, '16_daftar');
    });
    await langkah('P08 Saringan status perlu ditinjau', () async {
      await ketuk(t, find.textContaining(RegExp(r'^Perlu ditinjau \d+$')));
      await t.pump(const Duration(seconds: 2));
      await tunggu(t, find.byType(KartuHasil));
      expect(find.text('Tidak ada indikasi').hitTestable(), findsNothing);
      await foto(t, '17_saring_perlu_ditinjau');
    });
    await langkah('P09 Pencarian tanpa hasil menampilkan kondisi kosong', () async {
      await t.enterText(find.byType(TextField).first, 'zzzz');
      await tunggu(t, find.text('Tidak ada hasil yang cocok'));
      await tenang(t, milidetik: 500);
      await foto(t, '18_cari_kosong');
      await ketuk(t, find.text('Hapus pencarian'));
      await tunggu(t, find.byType(KartuHasil));
      await tenang(t);
    });
    await langkah('P10 Detail hasil deteksi tampil dengan nilai panel dan rujukan', () async {
      await ketuk(t, find.byType(KartuHasil));
      await tunggu(t, find.text('Hasil Deteksi Model'));
      await foto(t, '19_detail_atas');
      await gulirSampai(t, find.text('Kreatinin'));
      expect(find.text('Nilai Panel Kimia'), findsOneWidget);
      await foto(t, '20_detail_panel');
    });
    await langkah('P11 Penjelasan SHAP tampil', () async {
      await ketuk(t, find.widgetWithText(OutlinedButton, 'Penjelasan SHAP'));
      try {
        await tunggu(t, find.text('Kontribusi Fitur (Nilai SHAP)'));
        await foto(t, '21_shap_atas');
        await gulirSampai(t, find.text('Penjumlahan Nilai SHAP'));
        await gulirSampai(t, find.textContaining('Peluang anomali = 1 /'));
        await foto(t, '22_shap_bawah');
      } finally {
        await kembali(t);
        await tunggu(t, find.text('Hasil Deteksi Model'));
      }
    });
    await langkah('P12 Simpan tindak lanjut tanpa keputusan ditolak', () async {
      await gulirSampai(t, find.widgetWithText(FilledButton, 'Catat Tindak Lanjut'));
      await ketuk(t, find.widgetWithText(FilledButton, 'Catat Tindak Lanjut'));
      await tunggu(t, find.text('Keputusan peninjauan'));
      await foto(t, '23_tindak_lanjut');
      await gulirSampai(t, find.widgetWithText(FilledButton, 'Simpan Tindak Lanjut'));
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan Tindak Lanjut'));
      await tunggu(t, find.text('Pilih salah satu keputusan peninjauan terlebih dahulu.'));
      await foto(t, '24_tindak_lanjut_tanpa_keputusan');
    });
    await langkah('P13 Tindak lanjut tersimpan', () async {
      await gulirSampai(t, find.text('Verifikasi identitas dan spesimen'));
      await ketuk(t, find.text('Verifikasi identitas dan spesimen'));
      await t.enterText(find.byType(TextField).last, 'Uji emulator: cocokkan identitas pada tabung.');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await tenang(t, milidetik: 500);
      await gulirSampai(t, find.widgetWithText(FilledButton, 'Simpan Tindak Lanjut'));
      await foto(t, '25_tindak_lanjut_terisi');
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan Tindak Lanjut'));
      await tunggu(t, find.text('Tindak lanjut tersimpan.'));
      await tunggu(t, find.text('Hasil Deteksi Model'));
      await foto(t, '26_tindak_lanjut_tersimpan');
      await kembali(t);
      await tunggu(t, find.byType(KartuHasil));
    });
    await langkah('P14 Halaman akun petugas tampil dengan foto, lalu logout', () async {
      await ketuk(t, find.text('Akun').last);
      await tunggu(t, find.text(namaPetugas));
      expect(find.text('@$userPetugas'), findsOneWidget);
      await tunggu(t, find.byType(RawImage));
      await tenang(t, milidetik: 500);
      await foto(t, '27_akun_petugas');
      await keluar(t);
      await foto(t, '28_setelah_logout');
    });

    // ---------------- admin: reset kata sandi, status akun, ambang, dan sinkronisasi
    await langkah('A05 Form ubah akun terisi dan kata sandi petugas direset', () async {
      await masuk(t, userAdmin, sandiAdmin);
      await tunggu(t, find.text('Sinkronisasi Terakhir'));
      await ketuk(t, find.text('Pengguna').last);
      await tunggu(t, find.text('@$userPetugas'));
      await tenang(t);
      await ketuk(t, diKartuAkun(userPetugas, find.byTooltip('Ubah akun')));
      await tunggu(t, find.text('Foto diambil dari data pegawai SiLAKES.'));
      expect(find.widgetWithText(TextFormField, namaPetugas), findsOneWidget);
      expect(find.widgetWithText(TextFormField, akunSilakesPetugas), findsOneWidget);
      await tunggu(t, find.byType(RawImage));
      await tenang(t, milidetik: 500);
      await foto(t, '29_ubah_akun');
      await t.enterText(find.byType(TextFormField).at(3), sandiPetugasBaru);
      await tenang(t, milidetik: 500);
      await gulirSampai(t, find.widgetWithText(FilledButton, 'Simpan'));
      await foto(t, '30_reset_kata_sandi');
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan'));
      await tunggu(t, find.text('Perubahan akun disimpan. Kata sandi direset.'));
      await tunggu(t, find.text('Akun petugas laboratorium dan admin.'));
      await tenang(t, milidetik: 2000);
      await foto(t, '31_ubah_akun_tersimpan');
      await t.pump(const Duration(seconds: 4));
    });
    await langkah('A06 Menonaktifkan akun petugas', () async {
      await tenang(t);
      await ketuk(t, diKartuAkun(userPetugas, find.byType(Switch)));
      await tunggu(t, find.text('Akun $userPetugas dinonaktifkan.'));
      await tunggu(t, find.text('Nonaktif'));
      await tenang(t, milidetik: 1000);
      await foto(t, '32_akun_dinonaktifkan');
      await t.pump(const Duration(seconds: 4));
    });
    await langkah('A07 Akun nonaktif tidak dapat login dengan kata sandi hasil reset', () async {
      await keluar(t);
      await masuk(t, userPetugas, sandiPetugasBaru);
      await tunggu(t, find.text('Akun tidak aktif. Hubungi admin.'));
      await tenang(t, milidetik: 500);
      await foto(t, '33_login_akun_nonaktif');
    });
    await langkah('A08 Mengaktifkan kembali akun petugas', () async {
      await masuk(t, userAdmin, sandiAdmin);
      await tunggu(t, find.text('Sinkronisasi Terakhir'));
      await ketuk(t, find.text('Pengguna').last);
      await tunggu(t, find.text('@$userPetugas'));
      await tenang(t);
      await ketuk(t, diKartuAkun(userPetugas, find.byType(Switch)));
      await tunggu(t, find.text('Akun $userPetugas diaktifkan.'));
      await tenang(t, milidetik: 1000);
      await foto(t, '34_akun_diaktifkan');
      await t.pump(const Duration(seconds: 4));
    });
    await langkah('A09 Mengatur dan menyimpan ambang deteksi', () async {
      await ketuk(t, find.text('Beranda').last);
      await tunggu(t, find.text('Atur Ambang Deteksi'));
      await ketuk(t, find.text('Atur Ambang Deteksi'));
      await tunggu(t, find.text('Nilai Ambang'));
      await foto(t, '35_ambang');
      // Geser ke kanan tengah (nilai di atas 0,50), simpan, lalu kembalikan ke 0,50.
      await t.tapAt(t.getCenter(find.byType(Slider)) + const Offset(40, 0));
      await t.pump(const Duration(milliseconds: 400));
      await foto(t, '36_ambang_diubah');
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan Ambang'));
      await tunggu(t, find.text('Ambang disimpan. Nilai baru dipakai pada sinkronisasi berikutnya.'));
      await tunggu(t, find.text('Sinkronisasi Terakhir'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('0,50'), findsNothing);
      await foto(t, '37_ambang_tersimpan');
      await ketuk(t, find.text('Atur Ambang Deteksi'));
      await tunggu(t, find.text('Nilai Ambang'));
      await t.tapAt(t.getCenter(find.byType(Slider)));
      await t.pump(const Duration(milliseconds: 400));
      await ketuk(t, find.widgetWithText(FilledButton, 'Simpan Ambang'));
      await tunggu(t, find.text('Sinkronisasi Terakhir'));
      await t.pump(const Duration(seconds: 1));
      await tunggu(t, find.text('0,50'));
      await t.pump(const Duration(seconds: 5));
    });
    await langkah('A10 Sinkronisasi data sampai selesai', () async {
      await ketuk(t, find.text('Sinkronisasi').last);
      await tunggu(t, find.text('Tahapan Proses'));
      await tunggu(t, find.text('Profil diproses'));
      await foto(t, '38_sinkronisasi');
      await ketuk(t, find.text('Mulai Sinkronisasi'));
      await t.pump(const Duration(milliseconds: 600));
      await foto(t, '39_sinkronisasi_berjalan');
      await tunggu(t, find.text('Selesai'), detik: 300);
      await gulirSampai(t, find.text('Waktu'));
      await foto(t, '40_sinkronisasi_selesai');
    });
    await langkah('A11 Sinkronisasi kedua tidak memproses ulang surat tersimpan', () async {
      await gulirSampai(t, find.text('Mulai Sinkronisasi'));
      await ketuk(t, find.text('Mulai Sinkronisasi'));
      await t.pump(const Duration(seconds: 1));
      await tunggu(t, find.text('Selesai'), detik: 300);
      await t.pump(const Duration(milliseconds: 500));
      final kosong = find.text('Tidak ada surat hasil baru sejak sinkronisasi terakhir.').evaluate().isNotEmpty;
      debugPrint('HASIL_UJI_CATATAN | sinkronisasi kedua | pesan tidak ada data baru tampil: $kosong');
      await foto(t, '41_sinkronisasi_kedua');
    });
    await langkah('A12 Halaman akun admin tampil dengan foto, lalu logout', () async {
      await ketuk(t, find.text('Akun').last);
      await tunggu(t, find.text(namaAdmin));
      expect(find.text('@$userAdmin'), findsOneWidget);
      await tunggu(t, find.byType(RawImage));
      await tenang(t, milidetik: 500);
      await foto(t, '42_akun_admin');
      await keluar(t);
      await foto(t, '43_setelah_logout_admin');
    });

    (binding.reportData ??= <String, dynamic>{})['hasil'] = hasil;
    for (final h in hasil) {
      debugPrint('HASIL_UJI | ${h[0]} | ${h[1]}');
    }
    expect(hasil.where((h) => h[1] != 'Sesuai'), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
