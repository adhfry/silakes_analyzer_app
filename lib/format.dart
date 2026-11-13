import 'package:intl/intl.dart';

const labelFitur = {
  'kolesterol_total': 'Kolesterol total',
  'hdl': 'HDL',
  'ldl': 'LDL',
  'trigliserida': 'Trigliserida',
  'urea': 'Urea',
  'kreatinin': 'Kreatinin',
  'jenis_kelamin': 'Jenis kelamin',
  'umur': 'Umur',
};

/// Label fitur di tengah kalimat: huruf awal kecil, kecuali singkatan seperti HDL dan LDL.
String labelDalamKalimat(String fitur) {
  final l = labelFitur[fitur] ?? fitur;
  return l == l.toUpperCase() ? l : l[0].toLowerCase() + l.substring(1);
}

const labelStatus = {
  'perlu_ditinjau': 'Perlu ditinjau',
  'tidak_ada_indikasi': 'Tidak ada indikasi',
};

const labelKeputusan = {
  'hasil_sesuai': 'Hasil sesuai',
  'verifikasi_identitas_spesimen': 'Verifikasi identitas dan spesimen',
  'pemeriksaan_ulang': 'Pemeriksaan ulang',
};

const keteranganKeputusan = {
  'hasil_sesuai': 'Tidak diperlukan tindakan lanjutan',
  'verifikasi_identitas_spesimen': 'Periksa kesesuaian identitas pasien dan sampel',
  'pemeriksaan_ulang': 'Sampel diperiksa ulang sesuai prosedur',
};

/// Kode pasien samaran ditampilkan pendek seperti pada wireframe, misalnya 98FE-90.
/// Kode lengkap tetap tampil pada halaman detail.
String kodePendek(String kode) => '${kode.substring(0, 4)}-${kode.substring(4, 6)}'.toUpperCase();

String avatarKode(String kode) => kode.substring(0, 2).toUpperCase();

String inisial(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
  if (kata.isEmpty) return '?';
  return (kata.length == 1 ? kata[0].substring(0, 1) : kata[0][0] + kata[1][0]).toUpperCase();
}

String tanggalPendek(String? iso) => iso == null ? '-' : DateFormat('d MMM', 'id_ID').format(DateTime.parse(iso));

String jam(String? iso) => iso == null ? '-' : DateFormat('HH.mm', 'id_ID').format(DateTime.parse(iso));

/// Rentang tanggal seperti "28–29 Sep 2026" atau "30 Sep – 2 Okt 2026".
String rentangTanggal(String? awal, String? akhir) {
  if (awal == null || akhir == null) return '-';
  final a = DateTime.parse(awal), b = DateTime.parse(akhir);
  if (a == b) return tanggal(awal);
  if (a.year == b.year && a.month == b.month) return '${a.day}–${tanggal(akhir)}';
  if (a.year == b.year) return '${DateFormat('d MMM', 'id_ID').format(a)} – ${tanggal(akhir)}';
  return '${tanggal(awal)} – ${tanggal(akhir)}';
}

String angka(num nilai, [int desimal = 2]) {
  final f = NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: desimal);
  return f.format(nilai);
}

/// Nilai hasil tanpa nol di belakang: 0,90 ditulis 0,9 dan 200,00 ditulis 200.
String nilaiHasil(num nilai) {
  final f = NumberFormat('#,##0.##', 'id_ID');
  return f.format(nilai);
}

String peluang(num nilai) => angka(nilai, 2);

String jenisKelamin(String? jk) => jk == 'L' ? 'Laki-laki' : (jk == 'P' ? 'Perempuan' : '-');

String tanggal(String? iso) {
  if (iso == null) return '-';
  return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(iso));
}

String waktu(String? iso) {
  if (iso == null) return '-';
  return DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(DateTime.parse(iso));
}
