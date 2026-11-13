import 'package:flutter/material.dart';

import '../format.dart' as fmt;
import '../main.dart';
import '../tema.dart';

(Color, Color) warnaStatus(String status) => status == 'perlu_ditinjau'
    ? (Warna.ditinjauTeks, Warna.ditinjauLatar)
    : (Warna.amanTeks, Warna.amanLatar);

/// Logo: lambang yang dipakai SiLAKES pada halaman hasil pemeriksaan (public/logo/Sumenep-logo.png).
class Logo extends StatelessWidget {
  const Logo({super.key, this.ukuran = 44});
  final double ukuran;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo.png', width: ukuran, height: ukuran, semanticLabel: 'Logo');
}

/// Kepala halaman utama sesuai wireframe: logo, nama aplikasi, subjudul, dan tombol akun.
class KepalaUtama extends StatelessWidget {
  const KepalaUtama({super.key, this.keAkun});
  final VoidCallback? keAkun;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(children: [
        const Logo(),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SiLAKES Analyzer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Warna.brand900)),
            Text('Deteksi Anomali Pra-Analitik', style: TextStyle(fontSize: 13, color: Warna.bodyLemah)),
          ]),
        ),
        if (keAkun != null)
          IconButton(
            tooltip: 'Akun',
            onPressed: keAkun,
            icon: const Icon(Icons.account_circle_outlined, size: 30, color: Warna.brand700),
          ),
      ]),
    );
  }
}

/// Kepala halaman turunan sesuai wireframe: tombol kembali, nama aplikasi, dan nama halaman.
class KepalaSub extends StatelessWidget {
  const KepalaSub(this.halaman, {super.key, this.kembali});
  final String halaman;
  final VoidCallback? kembali;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(children: [
        IconButton(
          tooltip: 'Kembali',
          onPressed: kembali ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: Warna.brand900),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SiLAKES Analyzer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Warna.brand900)),
            Text(halaman, style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
          ]),
        ),
      ]),
    );
  }
}

class JudulHalaman extends StatelessWidget {
  const JudulHalaman(this.judul, this.keterangan, {super.key, this.subjudul});
  final String judul;
  final String? subjudul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(judul, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Warna.brand900, height: 1.2)),
        if (subjudul != null)
          Text(subjudul!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Warna.brand900)),
        const SizedBox(height: 4),
        Text(keterangan, style: const TextStyle(fontSize: 14, color: Warna.bodyLemah)),
      ]),
    );
  }
}

/// Kartu putih bergaris tepi tipis, tanpa bayangan (DESIGN.md).
class Kartu extends StatelessWidget {
  const Kartu({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.tebal = false});
  final Widget child;
  final EdgeInsets padding;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tebal ? Warna.brand700 : Warna.garis, width: tebal ? 2 : 1),
      ),
      child: child,
    );
  }
}

class JudulKartu extends StatelessWidget {
  const JudulKartu(this.judul, {super.key, this.ikon, this.kanan});
  final String judul;
  final IconData? ikon;
  final Widget? kanan;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (ikon != null) ...[Icon(ikon, size: 20, color: Warna.brand700), const SizedBox(width: 8)],
      Expanded(child: Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Warna.brand900))),
      ?kanan,
    ]);
  }
}

/// Lingkaran berisi dua karakter awal kode pasien atau inisial nama.
class Avatar extends StatelessWidget {
  const Avatar(this.teks, {super.key, this.ukuran = 40, this.foto});
  final String teks;
  final double ukuran;

  /// Foto akun dari data pegawai SiLAKES. Bila kosong atau gagal dimuat, inisial yang ditampilkan.
  final ImageProvider? foto;

  @override
  Widget build(BuildContext context) {
    final inisial = Text(teks, style: TextStyle(fontSize: ukuran * 0.33, fontWeight: FontWeight.w700, color: Warna.brand900));
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Warna.brand50, border: Border.all(color: Warna.brand700)),
      child: foto == null
          ? inisial
          : Image(
              image: foto!,
              width: ukuran,
              height: ukuran,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              // selama foto dimuat, inisial tetap tampil agar avatar tidak kosong
              frameBuilder: (_, gambar, bingkai, sinkron) => sinkron || bingkai != null ? gambar : Center(child: inisial),
              errorBuilder: (_, _, _) => inisial,
            ),
    );
  }
}

/// Foto akun `p` (peta pengguna dari API) bila akun memilikinya.
ImageProvider? fotoAkun(BuildContext context, Map<String, dynamic> p) {
  if (p['ada_foto'] != true) return null;
  final api = SesiScope.of(context).api;
  return NetworkImage(api.urlFoto(p['id_pengguna'] as int), headers: api.kepalaToken);
}

class LencanaStatus extends StatelessWidget {
  const LencanaStatus(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (teks, latar) = warnaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(99)),
      child: Text(fmt.labelStatus[status] ?? status, style: TextStyle(color: teks, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class Lencana extends StatelessWidget {
  const Lencana(this.teks, {super.key, this.isi = false});
  final String teks;
  final bool isi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isi ? Warna.brand700 : Warna.permukaan,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: isi ? Warna.brand700 : Warna.garisTegas),
      ),
      child: Text(teks, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isi ? Colors.white : Warna.body)),
    );
  }
}

/// Kotak keterangan bergaris putus-putus sesuai wireframe.
class KotakInfo extends StatelessWidget {
  const KotakInfo(this.teks, {super.key, this.ikon = Icons.info_outline});
  final String teks;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GarisPutus(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ikon, size: 20, color: Warna.brand700),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 13, color: Warna.body, height: 1.4))),
        ]),
      ),
    );
  }
}

class _GarisPutus extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cat = Paint()
      ..color = Warna.garisTegas
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final jalur = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(radius)));
    for (final m in jalur.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), cat);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarisNilai extends StatelessWidget {
  const BarisNilai(this.label, this.nilai, {super.key, this.garis = true, this.tebal = false});
  final String label;
  final String nilai;
  final bool garis;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: garis ? const Border(bottom: BorderSide(color: Warna.garis)) : null),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 8),
        Text(nilai,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14, fontWeight: tebal ? FontWeight.w700 : FontWeight.w600, fontFeatures: angkaTabular)),
      ]),
    );
  }
}

/// Kondisi kosong, galat, atau memuat: selalu menyebut penyebab dan tindakan berikutnya.
class Kondisi extends StatelessWidget {
  const Kondisi.memuat({super.key, this.pesan = 'Memuat data...'})
      : ikon = null,
        judul = null,
        tombol = null,
        onTombol = null,
        memuat = true;
  const Kondisi.kosong({super.key, required this.judul, required this.pesan, this.tombol, this.onTombol})
      : ikon = Icons.inbox_outlined,
        memuat = false;
  const Kondisi.galat({super.key, required this.pesan, this.onTombol, this.tombol = 'Coba lagi'})
      : ikon = Icons.error_outline,
        judul = 'Data tidak dapat dimuat',
        memuat = false;

  final IconData? ikon;
  final String? judul;
  final String pesan;
  final String? tombol;
  final VoidCallback? onTombol;
  final bool memuat;

  @override
  Widget build(BuildContext context) {
    final galat = ikon == Icons.error_outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (memuat) const CircularProgressIndicator(color: Warna.brand700),
          if (ikon != null) Icon(ikon, size: 40, color: galat ? Warna.galatTeks : Warna.bodyLemah),
          const SizedBox(height: 12),
          if (judul != null)
            Text(judul!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: Warna.bodyLemah)),
          if (tombol != null && onTombol != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: 200, child: OutlinedButton(onPressed: onTombol, child: Text(tombol!))),
          ],
        ]),
      ),
    );
  }
}

/// Memuat data sekali, menampilkan kondisi memuat dan galat, dan bisa dimuat ulang dengan tarik ke bawah.
class Pemuat<T> extends StatefulWidget {
  const Pemuat({super.key, required this.ambil, required this.isi});
  final Future<T> Function() ambil;
  final Widget Function(BuildContext context, T data, Future<void> Function() muatUlang) isi;

  @override
  State<Pemuat<T>> createState() => PemuatState<T>();
}

class PemuatState<T> extends State<Pemuat<T>> {
  late Future<T> _masa = widget.ambil();

  Future<void> muatUlang() async {
    final baru = widget.ambil();
    setState(() {
      _masa = baru;
    });
    try {
      await baru;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _masa,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return const Kondisi.memuat();
        if (s.hasError) return Kondisi.galat(pesan: '${s.error}', onTombol: muatUlang);
        return RefreshIndicator(color: Warna.brand700, onRefresh: muatUlang, child: widget.isi(context, s.data as T, muatUlang));
      },
    );
  }
}

void pesan(BuildContext context, String teks, {bool galat = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(teks, style: TextStyle(color: galat ? Warna.galatTeks : Colors.white)),
      backgroundColor: galat ? Warna.galatLatar : Warna.brand900,
    ));
}
