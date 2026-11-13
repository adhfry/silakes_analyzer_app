import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart' as fmt;
import '../main.dart';
import '../tema.dart';
import '../widget/umum.dart';
import 'akun.dart';

/// Menu petugas laboratorium sesuai use case petugas: dashboard, daftar hasil deteksi, detail dan
/// kontribusi fitur (SHAP), catat tindak lanjut, serta akun untuk logout.
class ShellPetugas extends StatefulWidget {
  const ShellPetugas({super.key});

  @override
  State<ShellPetugas> createState() => _ShellPetugasState();
}

class _ShellPetugasState extends State<ShellPetugas> {
  int _menu = 0;
  final _versi = [0, 0, 0];

  void _pilih(int i) => setState(() {
        _menu = i;
        _versi[i]++;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _menu, children: [
          BerandaPetugas(key: ValueKey('b${_versi[0]}'), keDaftar: () => _pilih(1), keAkun: () => _pilih(2)),
          DaftarDeteksi(key: ValueKey('d${_versi[1]}'), keAkun: () => _pilih(2)),
          HalamanAkun(kembali: () => _pilih(0)),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _menu,
        onDestinationSelected: _pilih,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Hasil Deteksi'),
          NavigationDestination(
              icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Akun'),
        ],
      ),
    );
  }
}

void bukaDetail(BuildContext context, int id) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetail(idDeteksi: id)));
}

class BerandaPetugas extends StatelessWidget {
  const BerandaPetugas({super.key, required this.keDaftar, required this.keAkun});
  final VoidCallback keDaftar;
  final VoidCallback keAkun;

  @override
  Widget build(BuildContext context) {
    final api = SesiScope.of(context).api;
    return Pemuat<Json>(
      ambil: api.ringkasan,
      isi: (context, d, muatUlang) {
        final terbaru = (d['terbaru_perlu_ditinjau'] as List).cast<Json>();
        final sinkron = d['sinkronisasi_terakhir'] as Json?;
        return ListView(children: [
          KepalaUtama(keAkun: keAkun),
          const JudulHalaman('Selamat datang,', 'Tinjau profil hasil pemeriksaan yang ditandai model.',
              subjudul: 'Petugas Laboratorium'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Kartu(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const JudulKartu('Ringkasan Hasil Deteksi', ikon: Icons.query_stats),
                  const SizedBox(height: 2),
                  Text(
                    sinkron == null
                        ? 'Belum ada sinkronisasi data.'
                        : 'Sinkronisasi terakhir: ${fmt.waktu(sinkron['waktu_selesai'] as String?)}',
                    style: const TextStyle(fontSize: 13, color: Warna.bodyLemah),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    _Angka(d['total'], 'Profil\ndideteksi'),
                    _Angka(d['perlu_ditinjau'], 'Perlu\nditinjau', warna: Warna.ditinjauTeks),
                    _Angka(d['tidak_ada_indikasi'], 'Tidak ada\nindikasi', warna: Warna.amanTeks),
                    _Angka(d['sudah_ditindaklanjuti'], 'Sudah\nditindaklanjuti'),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              Kartu(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  JudulKartu('Perlu Ditinjau Terbaru',
                      ikon: Icons.priority_high,
                      kanan: TextButton(onPressed: keDaftar, child: const Text('Lihat semua'))),
                  if (terbaru.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Belum ada profil berstatus perlu ditinjau. Hasil baru muncul setelah admin '
                          'menjalankan sinkronisasi data.', style: TextStyle(color: Warna.bodyLemah)),
                    )
                  else
                    for (final h in terbaru) ...[
                      const Divider(),
                      _BarisRingkas(h, onTap: () => bukaDetail(context, h['id_deteksi'] as int)),
                    ],
                ]),
              ),
              const SizedBox(height: 12),
              const KotakInfo('Hasil deteksi adalah prediksi model sebagai bahan peninjauan dan tidak menggantikan '
                  'verifikasi petugas laboratorium.'),
              const SizedBox(height: 16),
            ]),
          ),
        ]);
      },
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.nilai, this.label, {this.warna});
  final Object? nilai;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text('$nilai',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: warna ?? Warna.brand900, fontFeatures: angkaTabular)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Warna.bodyLemah, height: 1.3)),
      ]),
    );
  }
}

/// Baris profil pada beranda: avatar, kode pasien, jenis kelamin, umur, tanggal, dan peluang di kanan.
class _BarisRingkas extends StatelessWidget {
  const _BarisRingkas(this.h, {required this.onTap});
  final Json h;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = h['profil'] as Json;
    final kode = p['kode_pasien'] as String;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Avatar(fmt.avatarKode(kode)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pasien ${fmt.kodePendek(kode)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(
                  '${fmt.jenisKelamin(p['jenis_kelamin'] as String?)}, ${p['umur']} th · '
                  '${fmt.tanggalPendek(p['tanggal_periksa'] as String?)}',
                  style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Peluang', style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
            Text(fmt.peluang(h['peluang_anomali'] as num),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Warna.ditinjauTeks, fontFeatures: angkaTabular)),
          ]),
        ]),
      ),
    );
  }
}

class DaftarDeteksi extends StatefulWidget {
  const DaftarDeteksi({super.key, required this.keAkun});
  final VoidCallback keAkun;

  @override
  State<DaftarDeteksi> createState() => _DaftarDeteksiState();
}

class _DaftarDeteksiState extends State<DaftarDeteksi> {
  final _cari = TextEditingController();
  final _gulir = ScrollController();
  Timer? _jeda;
  String _status = '';
  final List<Json> _data = [];
  Json _jumlah = const {};
  List<dynamic> _rentang = const [null, null];
  int _total = 0;
  int _halaman = 0;
  bool _memuat = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _gulir.addListener(() {
      if (_gulir.position.pixels > _gulir.position.maxScrollExtent - 300) _muatBerikut();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatUlang());
  }

  @override
  void dispose() {
    _jeda?.cancel();
    _gulir.dispose();
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _data.clear();
      _halaman = 0;
      _total = 0;
      _galat = null;
    });
    await _muatBerikut(paksa: true);
  }

  Future<void> _muatBerikut({bool paksa = false}) async {
    if (_memuat || (!paksa && _data.length >= _total)) return;
    setState(() => _memuat = true);
    try {
      final r =
          await SesiScope.of(context).api.daftarDeteksi(status: _status, cari: _cari.text.trim(), halaman: _halaman + 1);
      if (!mounted) return;
      setState(() {
        _halaman = r['halaman'] as int;
        _total = r['total'] as int;
        _jumlah = r['jumlah_status'] as Json;
        _rentang = r['rentang_tanggal'] as List<dynamic>;
        _data.addAll((r['data'] as List).cast<Json>());
      });
    } on ApiGalat catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _ubahCari(String _) {
    _jeda?.cancel();
    _jeda = Timer(const Duration(milliseconds: 400), _muatUlang);
  }

  Widget _cip(String nilai, String label) {
    final pilih = _status == nilai;
    final n = _jumlah[nilai.isEmpty ? 'semua' : nilai];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(n == null ? label : '$label $n'),
        selected: pilih,
        showCheckmark: false,
        selectedColor: Warna.brand700,
        backgroundColor: Warna.permukaan,
        side: BorderSide(color: pilih ? Warna.brand700 : Warna.garisTegas),
        labelStyle: TextStyle(color: pilih ? Colors.white : Warna.body, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        onSelected: (_) {
          setState(() => _status = nilai);
          _muatUlang();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kepala = <Widget>[
      KepalaUtama(keAkun: widget.keAkun),
      const JudulHalaman('Daftar Hasil Deteksi', 'Profil hasil pemeriksaan yang telah diproses model.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          TextField(
            controller: _cari,
            onChanged: _ubahCari,
            decoration: const InputDecoration(hintText: 'Cari kode pasien / nomor surat', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _cip('', 'Semua'),
              _cip('perlu_ditinjau', 'Perlu ditinjau'),
              _cip('tidak_ada_indikasi', 'Tidak ada indikasi'),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Urutkan: ', style: TextStyle(fontSize: 13, color: Warna.bodyLemah)),
            const Text('Peluang tertinggi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined, size: 15, color: Warna.bodyLemah),
            const SizedBox(width: 4),
            Text(fmt.rentangTanggal(_rentang[0] as String?, _rentang[1] as String?),
                style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    ];

    Widget? kondisi;
    if (_galat != null && _data.isEmpty) {
      kondisi = Kondisi.galat(pesan: _galat!, onTombol: _muatUlang);
    } else if (_memuat && _data.isEmpty) {
      kondisi = const Kondisi.memuat();
    } else if (_data.isEmpty) {
      final adaSaring = _cari.text.isNotEmpty || _status.isNotEmpty;
      kondisi = Kondisi.kosong(
        judul: adaSaring ? 'Tidak ada hasil yang cocok' : 'Belum ada hasil deteksi',
        pesan: adaSaring
            ? 'Periksa kembali kode pasien atau nomor surat, atau pilih saringan Semua.'
            : 'Hasil deteksi muncul setelah admin menjalankan sinkronisasi data.',
        tombol: adaSaring ? 'Hapus pencarian' : 'Muat ulang',
        onTombol: () {
          _cari.clear();
          setState(() => _status = '');
          _muatUlang();
        },
      );
    }

    return RefreshIndicator(
      color: Warna.brand700,
      onRefresh: _muatUlang,
      child: ListView.builder(
        controller: _gulir,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: kepala.length + (kondisi != null ? 1 : _data.length + 1),
        itemBuilder: (context, i) {
          if (i < kepala.length) return kepala[i];
          if (kondisi != null) return kondisi;
          final j = i - kepala.length;
          if (j == _data.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _memuat
                    ? const CircularProgressIndicator(color: Warna.brand700)
                    : Text('${_data.length} dari $_total profil', style: const TextStyle(color: Warna.bodyLemah)),
              ),
            );
          }
          final h = _data[j];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: KartuHasil(h, onTap: () => bukaDetail(context, h['id_deteksi'] as int)),
          );
        },
      ),
    );
  }
}

/// Kartu profil pada daftar hasil deteksi: avatar, identitas samaran, peluang dan status di kanan.
class KartuHasil extends StatelessWidget {
  const KartuHasil(this.h, {super.key, this.onTap});
  final Json h;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = h['profil'] as Json;
    final kode = p['kode_pasien'] as String;
    final status = h['status_deteksi'] as String;
    final (teks, _) = warnaStatus(status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Kartu(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Avatar(fmt.avatarKode(kode), ukuran: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pasien ${fmt.kodePendek(kode)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    '${fmt.jenisKelamin(p['jenis_kelamin'] as String?)} · ${p['umur']} th · '
                    'Surat #${p['id_surat_silakes']}',
                    style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                Text('${fmt.tanggal(p['tanggal_periksa'] as String?)} · Panel kimia, 6 parameter',
                    style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Peluang', style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
              Text(fmt.peluang(h['peluang_anomali'] as num),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: teks, fontFeatures: angkaTabular)),
              const SizedBox(height: 4),
              LencanaStatus(status),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Kartu identitas profil pada halaman detail dan catat tindak lanjut.
class KartuPasien extends StatelessWidget {
  const KartuPasien(this.d, {super.key});
  final Json d;

  @override
  Widget build(BuildContext context) {
    final p = d['profil'] as Json;
    final kode = p['kode_pasien'] as String;
    return Kartu(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Avatar(fmt.avatarKode(kode), ukuran: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('Pasien ${fmt.kodePendek(kode)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              LencanaStatus(d['status_deteksi'] as String),
            ]),
            const SizedBox(height: 2),
            Text('${fmt.jenisKelamin(p['jenis_kelamin'] as String?)} · ${p['umur']} tahun',
                style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
            Text('Surat #${p['id_surat_silakes']} · ${fmt.tanggal(p['tanggal_periksa'] as String?)}',
                style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
            Text('Kode $kode', style: const TextStyle(fontSize: 12, color: Warna.bodyLemah, fontFeatures: angkaTabular)),
          ]),
        ),
      ]),
    );
  }
}

class HalamanDetail extends StatelessWidget {
  const HalamanDetail({super.key, required this.idDeteksi});
  final int idDeteksi;

  @override
  Widget build(BuildContext context) {
    final sesi = SesiScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Pemuat<Json>(
          ambil: () => sesi.api.detailDeteksi(idDeteksi),
          isi: (context, d, muatUlang) {
            final status = d['status_deteksi'] as String;
            final (teks, latar) = warnaStatus(status);
            final ambang = (d['model'] as Json)['ambang'] as num;
            final peluang = d['peluang_anomali'] as num;
            final ditinjau = status == 'perlu_ditinjau';
            return ListView(children: [
              const KepalaSub('Detail Hasil Deteksi'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  KartuPasien(d),
                  const SizedBox(height: 12),
                  Kartu(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Hasil Deteksi Model',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Warna.brand900)),
                          const SizedBox(height: 4),
                          Text(ditinjau ? 'Perlu ditinjau' : 'Tidak ada indikasi',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: teks)),
                          const SizedBox(height: 4),
                          Text(
                            ditinjau
                                ? 'Peluang anomali melebihi ambang, profil ditandai untuk ditinjau.'
                                : 'Peluang anomali tidak melebihi ambang, profil tidak ditandai.',
                            style: const TextStyle(fontSize: 13, color: Warna.bodyLemah),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: latar, border: Border.all(color: teks, width: 2)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Peluang', style: TextStyle(fontSize: 12, color: teks)),
                          Text(fmt.peluang(peluang),
                              style:
                                  TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: teks, fontFeatures: angkaTabular)),
                          Text('ambang ${fmt.peluang(ambang)}', style: TextStyle(fontSize: 12, color: teks)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Kartu(child: _TabelPanel((d['panel'] as List).cast<Json>())),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanShap(detail: d))),
                        child: const Text('Penjelasan SHAP'),
                      ),
                    ),
                    if (!sesi.admin) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                          onPressed: () async {
                            final tersimpan = await Navigator.push<bool>(
                                context, MaterialPageRoute(builder: (_) => HalamanTindakLanjut(detail: d)));
                            if (tersimpan == true) await muatUlang();
                          },
                          child: const Text('Catat Tindak Lanjut'),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  const KotakInfo('Hasil merupakan prediksi model dan bukan diagnosis. '
                      'Keputusan akhir tetap pada petugas laboratorium.'),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _TabelPanel extends StatelessWidget {
  const _TabelPanel(this.panel);
  final List<Json> panel;

  @override
  Widget build(BuildContext context) {
    const kepala = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Warna.brand900);
    const sel = TextStyle(fontSize: 13);
    Widget baris(List<Widget> isi, {bool tebal = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tebal ? Warna.body : Warna.garis, width: tebal ? 1.5 : 1))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: isi),
        );
    Widget ket(Json b) {
      final k = b['keterangan'] as String?;
      if (k == null) return const Text('-', style: sel);
      final (teks, label) = switch (k) {
        'rendah' => (Warna.galatTeks, '↓ Rendah'),
        'tinggi' => (Warna.galatTeks, '↑ Tinggi'),
        _ => (Warna.amanTeks, 'Sesuai'),
      };
      return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: teks));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      JudulKartu('Nilai Panel Kimia',
          ikon: Icons.science_outlined,
          kanan: Text('${panel.length} parameter', style: const TextStyle(fontSize: 13, color: Warna.brand700))),
      const SizedBox(height: 8),
      baris(const [
        SizedBox(width: 22, child: Text('No', style: kepala)),
        Expanded(flex: 7, child: Text('Parameter', style: kepala)),
        Expanded(flex: 4, child: Text('Hasil', style: kepala)),
        Expanded(flex: 4, child: Text('Satuan', style: kepala)),
        Expanded(flex: 6, child: Text('Rujukan', style: kepala)),
        Expanded(flex: 5, child: Text('Ket.', style: kepala)),
      ], tebal: true),
      for (final b in panel)
        baris([
          SizedBox(width: 22, child: Text('${b['no']}', style: sel)),
          Expanded(flex: 7, child: Text(fmt.labelFitur[b['parameter']] ?? '${b['parameter']}', style: sel)),
          Expanded(
              flex: 4,
              child: Text(fmt.nilaiHasil(b['nilai'] as num),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFeatures: angkaTabular))),
          Expanded(flex: 4, child: Text('${b['satuan'] ?? '-'}', style: sel)),
          Expanded(flex: 6, child: Text('${b['rujukan'] ?? '-'}', style: sel)),
          Expanded(flex: 5, child: ket(b)),
        ]),
      const SizedBox(height: 8),
      const Text('Rujukan dan keterangan mengikuti rentang rujukan SiLAKES menurut jenis kelamin dan umur pasien. '
          'Fitur lain: jenis kelamin dan umur.', style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
    ]);
  }
}

class HalamanShap extends StatelessWidget {
  const HalamanShap({super.key, required this.detail});
  final Json detail;

  @override
  Widget build(BuildContext context) {
    final p = detail['profil'] as Json;
    // Diurutkan dari nilai SHAP terbesar (paling mendorong ke arah anomali) seperti pada wireframe.
    final kontribusi = (detail['kontribusi'] as List).cast<Json>().toList()
      ..sort((a, b) => (b['nilai_shap'] as num).compareTo(a['nilai_shap'] as num));
    final maks = kontribusi.fold<double>(0.0001, (m, k) => math.max(m, (k['nilai_shap'] as num).abs().toDouble()));
    final dasar = detail['nilai_dasar'] as num?;
    final keluaran = detail['keluaran_log_odds'] as num?;
    final jumlah = kontribusi.fold<double>(0, (s, k) => s + (k['nilai_shap'] as num));
    final positif = kontribusi.where((k) => (k['nilai_shap'] as num) > 0).toList();
    final ditinjau = detail['status_deteksi'] == 'perlu_ditinjau';

    String kesimpulan() {
      if (positif.isEmpty) {
        return 'Tidak ada fitur yang mendorong prediksi ke arah anomali pada profil ini.';
      }
      final utama = fmt.labelFitur[positif.first['nama_fitur']]!;
      final ikut = positif.skip(1).take(2).map((k) => fmt.labelDalamKalimat(k['nama_fitur'] as String)).toList();
      return '$utama memberi kontribusi terbesar terhadap prediksi anomali pada profil ini'
          '${ikut.isEmpty ? '' : ', diikuti ${ikut.join(' dan ')}'}.';
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(children: [
          const KepalaSub('Penjelasan SHAP'),
          JudulHalaman(
            ditinjau ? 'Mengapa Profil Ini Ditandai?' : 'Mengapa Profil Ini Tidak Ditandai?',
            'Pasien ${fmt.kodePendek(p['kode_pasien'] as String)} · ${fmt.tanggal(p['tanggal_periksa'] as String?)} · '
                'peluang anomali ${fmt.peluang(detail['peluang_anomali'] as num)}',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const KotakInfo('Nilai SHAP menunjukkan kontribusi setiap fitur terhadap prediksi model, bukan penyebab '
                  'klinis. Nilai positif ke arah anomali, negatif ke arah tidak ada indikasi.'),
              const SizedBox(height: 12),
              Kartu(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const JudulKartu('Kontribusi Fitur (Nilai SHAP)', ikon: Icons.bar_chart),
                  const Text('Delapan fitur model', style: TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                  const SizedBox(height: 10),
                  for (final k in kontribusi)
                    _BarisShap(fmt.labelFitur[k['nama_fitur']]!, (k['nilai_shap'] as num).toDouble(), maks),
                  const SizedBox(height: 6),
                  const Text('←  tidak ada indikasi          anomali  →',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
                ]),
              ),
              const SizedBox(height: 12),
              Kartu(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const JudulKartu('Penjumlahan Nilai SHAP', ikon: Icons.functions),
                  const SizedBox(height: 6),
                  BarisNilai('Nilai dasar model (φ₀)', dasar == null ? '-' : fmt.angka(dasar, 3)),
                  BarisNilai('Jumlah kontribusi fitur (Σφⱼ)', '${jumlah >= 0 ? '+' : ''}${fmt.angka(jumlah, 3)}'),
                  BarisNilai('Keluaran model f(x) = φ₀ + Σφⱼ', keluaran == null ? '-' : fmt.angka(keluaran, 3)),
                  BarisNilai('Peluang anomali = 1 / (1 + e^(−f(x)))', fmt.peluang(detail['peluang_anomali'] as num),
                      tebal: true),
                ]),
              ),
              const SizedBox(height: 12),
              KotakInfo(kesimpulan(), ikon: Icons.lightbulb_outline),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BarisShap extends StatelessWidget {
  const _BarisShap(this.label, this.shap, this.maks);
  final String label;
  final double shap;
  final double maks;

  @override
  Widget build(BuildContext context) {
    final positif = shap > 0;
    final warna = positif ? Warna.ditinjauTeks : Warna.brand700;
    final batang = FractionallySizedBox(
      widthFactor: (shap.abs() / maks).clamp(0.03, 1.0),
      alignment: positif ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(height: 14, decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(2))),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 104, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(child: positif ? const SizedBox(height: 14) : batang),
        Container(width: 1.5, height: 20, color: Warna.body),
        Expanded(child: positif ? batang : const SizedBox(height: 14)),
        SizedBox(
          width: 58,
          child: Text('${positif ? '+' : ''}${fmt.angka(shap, 2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: warna, fontFeatures: angkaTabular)),
        ),
      ]),
    );
  }
}

class HalamanTindakLanjut extends StatefulWidget {
  const HalamanTindakLanjut({super.key, required this.detail});
  final Json detail;

  @override
  State<HalamanTindakLanjut> createState() => _HalamanTindakLanjutState();
}

class _HalamanTindakLanjutState extends State<HalamanTindakLanjut> {
  String? _keputusan;
  final _catatan = TextEditingController();
  bool _proses = false;

  Future<void> _simpan() async {
    if (_keputusan == null) {
      pesan(context, 'Pilih salah satu keputusan peninjauan terlebih dahulu.', galat: true);
      return;
    }
    setState(() => _proses = true);
    try {
      await SesiScope.of(context)
          .api
          .catatTindakLanjut(widget.detail['id_deteksi'] as int, _keputusan!, _catatan.text.trim());
      if (!mounted) return;
      pesan(context, 'Tindak lanjut tersimpan.');
      Navigator.pop(context, true);
    } on ApiGalat catch (e) {
      if (mounted) pesan(context, e.pesan, galat: true);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(children: [
          const KepalaSub('Catat Tindak Lanjut'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              KartuPasien(widget.detail),
              const SizedBox(height: 16),
              const Text('Keputusan peninjauan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Warna.brand900)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _keputusan,
                onChanged: (v) => setState(() => _keputusan = v),
                child: Column(children: [
                  for (final e in fmt.labelKeputusan.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(radius),
                        onTap: () => setState(() => _keputusan = e.key),
                        child: Kartu(
                          tebal: _keputusan == e.key,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Row(children: [
                            Radio<String>(value: e.key, activeColor: Warna.brand700),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(fmt.keteranganKeputusan[e.key]!,
                                    style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 6),
              const Text('Catatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Warna.brand900)),
              const SizedBox(height: 8),
              TextField(
                controller: _catatan,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(hintText: 'Tulis hasil peninjauan...'),
              ),
              const SizedBox(height: 4),
              const KotakInfo('Tindak lanjut disimpan pada basis data prototipe beserta nama petugas dan waktu. '
                  'Data SiLAKES tidak diubah.'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(onPressed: _proses ? null : () => Navigator.pop(context), child: const Text('Batal')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: _proses ? null : _simpan,
                    child: _proses
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Simpan Tindak Lanjut'),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
