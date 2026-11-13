import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart' as fmt;
import '../main.dart';
import '../tema.dart';
import '../widget/umum.dart';
import 'akun.dart';

/// Menu admin sesuai use case admin: dashboard, mengelola akun pengguna, mengatur ambang deteksi, dan
/// menjalankan sinkronisasi data (yang mencakup deteksi anomali), serta akun untuk logout.
class ShellAdmin extends StatefulWidget {
  const ShellAdmin({super.key});

  @override
  State<ShellAdmin> createState() => _ShellAdminState();
}

class _ShellAdminState extends State<ShellAdmin> {
  int _menu = 0;
  // Kunci berganti setiap kali tab dibuka agar data tab selalu baru.
  final _versi = [0, 0, 0, 0];

  void _pilih(int i) => setState(() {
        _menu = i;
        _versi[i]++;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _menu, children: [
          BerandaAdmin(key: ValueKey('b${_versi[0]}'), keMenu: _pilih),
          HalamanPengguna(key: ValueKey('p${_versi[1]}'), kembali: () => _pilih(0)),
          HalamanSinkronisasi(key: ValueKey('s${_versi[2]}'), kembali: () => _pilih(0)),
          HalamanAkun(kembali: () => _pilih(0)),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _menu,
        onDestinationSelected: _pilih,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Pengguna'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Sinkronisasi'),
          NavigationDestination(
              icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Akun'),
        ],
      ),
    );
  }
}

String rentangWaktu(String? mulai, String? selesai) {
  if (mulai == null) return '-';
  return '${fmt.waktu(mulai)}–${fmt.jam(selesai)}';
}

class BerandaAdmin extends StatelessWidget {
  const BerandaAdmin({super.key, required this.keMenu});
  final void Function(int) keMenu;

  @override
  Widget build(BuildContext context) {
    final api = SesiScope.of(context).api;
    return Pemuat<Json>(
      ambil: api.ringkasanAdmin,
      isi: (context, d, muatUlang) {
        final m = d['model_aktif'] as Json?;
        final s = d['sinkronisasi_terakhir'] as Json?;
        return ListView(children: [
          KepalaUtama(keAkun: () => keMenu(3)),
          const JudulHalaman('Selamat datang,', 'Kelola akun, ambang deteksi, dan sinkronisasi data.', subjudul: 'Admin'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Kartu(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Model Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(m == null ? 'Belum ada' : 'XGBoost',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Warna.brand900)),
                        Text(m == null ? 'Impor model di server' : 'Versi ${m['versi']}',
                            style: const TextStyle(fontSize: 12, color: Warna.bodyLemah)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Kartu(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Ambang Deteksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(m == null ? '-' : fmt.peluang(m['ambang'] as num),
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700, color: Warna.brand900, fontFeatures: angkaTabular)),
                        const Text('Peluang > ambang = perlu ditinjau',
                            style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Kartu(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  JudulKartu('Sinkronisasi Terakhir',
                      kanan: s == null
                          ? null
                          : const Text('Berhasil',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Warna.amanTeks))),
                  const SizedBox(height: 12),
                  if (s == null)
                    const Text('Belum ada sinkronisasi yang berhasil.', style: TextStyle(color: Warna.bodyLemah))
                  else ...[
                    Row(children: [
                      _Angka('${s['jumlah_profil']}', 'Profil diproses'),
                      _Angka('${s['perlu_ditinjau']}', 'Perlu ditinjau', warna: Warna.ditinjauTeks),
                      _Angka('${s['tidak_ada_indikasi']}', 'Tidak ada indikasi', warna: Warna.amanTeks),
                    ]),
                    const SizedBox(height: 10),
                    Text(rentangWaktu(s['waktu_mulai'] as String?, s['waktu_selesai'] as String?),
                        style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              _Menu(Icons.manage_accounts_outlined, 'Kelola Akun Pengguna', 'Tambah, ubah, nonaktifkan akun', () => keMenu(1)),
              const SizedBox(height: 10),
              _Menu(Icons.tune, 'Atur Ambang Deteksi', 'Ambang peluang pada model aktif', m == null
                  ? null
                  : () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanAmbang()));
                      await muatUlang();
                    }),
              const SizedBox(height: 10),
              _Menu(Icons.sync, 'Sinkronisasi Data', 'Baca surat hasil baru dan jalankan deteksi', () => keMenu(2)),
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
  final String nilai;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(nilai,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: warna ?? Warna.brand900, fontFeatures: angkaTabular)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Warna.bodyLemah)),
        ]),
      );
}

class _Menu extends StatelessWidget {
  const _Menu(this.ikon, this.judul, this.sub, this.onTap);
  final IconData ikon;
  final String judul;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Kartu(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Warna.brand50, borderRadius: BorderRadius.circular(radius)),
              child: Icon(ikon, color: Warna.brand700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(sub, style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
              ]),
            ),
            Icon(Icons.chevron_right, color: onTap == null ? Warna.garis : Warna.body),
          ]),
        ),
      ),
    );
  }
}

class HalamanPengguna extends StatefulWidget {
  const HalamanPengguna({super.key, required this.kembali});
  final VoidCallback kembali;

  @override
  State<HalamanPengguna> createState() => _HalamanPenggunaState();
}

class _HalamanPenggunaState extends State<HalamanPengguna> {
  final _kunci = GlobalKey<PemuatState<List<dynamic>>>();
  final _cari = TextEditingController();
  final Set<int> _mengubah = {};

  Future<void> _buka([Json? p]) async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => FormPengguna(pengguna: p)));
    if (ok == true) await _kunci.currentState?.muatUlang();
  }

  Future<void> _ubahAktif(Json p, bool aktif) async {
    final id = p['id_pengguna'] as int;
    setState(() => _mengubah.add(id));
    try {
      await SesiScope.of(context).api.ubahPengguna(id, {'status_aktif': aktif});
      if (!mounted) return;
      pesan(context, aktif ? 'Akun ${p['username']} diaktifkan.' : 'Akun ${p['username']} dinonaktifkan.');
      await _kunci.currentState?.muatUlang();
    } on ApiGalat catch (e) {
      if (mounted) pesan(context, e.pesan, galat: true);
    } finally {
      if (mounted) setState(() => _mengubah.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saya = SesiScope.of(context).pengguna!['id_pengguna'];
    return Pemuat<List<dynamic>>(
      key: _kunci,
      ambil: SesiScope.of(context).api.daftarPengguna,
      isi: (context, data, _) {
        final q = _cari.text.trim().toLowerCase();
        final daftar = data
            .cast<Json>()
            .where((p) => q.isEmpty || '${p['nama']} ${p['username']}'.toLowerCase().contains(q))
            .toList();
        return ListView(children: [
          KepalaSub('Kelola Akun Pengguna', kembali: widget.kembali),
          const JudulHalaman('Kelola Akun Pengguna', 'Akun petugas laboratorium dan admin.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _cari,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Cari nama atau username', prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(height: 12),
              if (daftar.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Tidak ada akun yang cocok dengan pencarian.',
                      textAlign: TextAlign.center, style: TextStyle(color: Warna.bodyLemah)),
                ),
              for (final p in daftar) ...[
                Kartu(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Avatar(fmt.inisial(p['nama'] as String), ukuran: 46, foto: fotoAkun(context, p)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['nama'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('@${p['username']}', style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          Lencana(p['peran'] == 'admin' ? 'Admin' : 'Petugas'),
                          Lencana(p['status_aktif'] == true ? 'Aktif' : 'Nonaktif', isi: p['status_aktif'] == true),
                        ]),
                      ]),
                    ),
                    Switch(
                      value: p['status_aktif'] == true,
                      activeThumbColor: Warna.brand700,
                      onChanged: p['id_pengguna'] == saya || _mengubah.contains(p['id_pengguna'])
                          ? null
                          : (v) => _ubahAktif(p, v),
                    ),
                    IconButton(tooltip: 'Ubah akun', onPressed: () => _buka(p), icon: const Icon(Icons.edit_outlined)),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              const KotakInfo('Kata sandi disimpan dalam bentuk hash. Akun nonaktif tidak dapat digunakan untuk masuk.'),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: () => _buka(), icon: const Icon(Icons.add), label: const Text('Tambah Akun')),
            ]),
          ),
        ]);
      },
    );
  }
}

class FormPengguna extends StatefulWidget {
  const FormPengguna({super.key, this.pengguna});
  final Json? pengguna;

  @override
  State<FormPengguna> createState() => _FormPenggunaState();
}

class _FormPenggunaState extends State<FormPengguna> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.pengguna?['nama'] as String?);
  late final _username = TextEditingController(text: widget.pengguna?['username'] as String?);
  final _sandi = TextEditingController();
  late final _akunSilakes = TextEditingController(text: widget.pengguna?['akun_silakes'] as String?);
  late String _peran = (widget.pengguna?['peran'] as String?) ?? 'petugas';
  bool _proses = false;
  bool _tampilSandi = false;
  // setelah percobaan simpan pertama, pesan galat diperbarui setiap kali isian diubah
  bool _sudahDicoba = false;

  bool get _baru => widget.pengguna == null;

  Future<void> _simpan() async {
    if (!_sudahDicoba) setState(() => _sudahDicoba = true);
    if (!_form.currentState!.validate()) return;
    setState(() => _proses = true);
    final api = SesiScope.of(context).api;
    final data = <String, dynamic>{
      'nama': _nama.text.trim(),
      'username': _username.text.trim().toLowerCase(),
      'peran': _peran,
      'akun_silakes': _akunSilakes.text.trim().toLowerCase(),
      if (_sandi.text.isNotEmpty) 'kata_sandi': _sandi.text,
    };
    try {
      if (_baru) {
        await api.tambahPengguna(data);
      } else {
        await api.ubahPengguna(widget.pengguna!['id_pengguna'] as int, data);
      }
      if (!mounted) return;
      pesan(
          context,
          _baru
              ? 'Akun dibuat.'
              : _sandi.text.isNotEmpty
                  ? 'Perubahan akun disimpan. Kata sandi direset.'
                  : 'Perubahan akun disimpan.');
      Navigator.pop(context, true);
    } on ApiGalat catch (e) {
      if (mounted) pesan(context, e.pesan, galat: true);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration label(String teks, [String? bantuan]) =>
        InputDecoration(labelText: teks, helperText: bantuan, helperMaxLines: 2);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          autovalidateMode: _sudahDicoba ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(children: [
            KepalaSub(_baru ? 'Tambah Akun' : 'Ubah Akun'),
            JudulHalaman(_baru ? 'Tambah Akun' : 'Ubah Akun', 'Akun dibuat oleh admin; tidak ada pendaftaran mandiri.'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!_baru) ...[
                  Row(children: [
                    Avatar(fmt.inisial(widget.pengguna!['nama'] as String),
                        ukuran: 56, foto: fotoAkun(context, widget.pengguna!)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          widget.pengguna!['ada_foto'] == true
                              ? 'Foto diambil dari data pegawai SiLAKES.'
                              : 'Akun ini belum memiliki foto dari data pegawai SiLAKES.',
                          style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nama,
                  decoration: label('Nama'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Nama wajib diisi.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _username,
                  decoration: label('Username', 'Huruf kecil, angka, titik, atau garis bawah; 3 sampai 50 karakter.'),
                  validator: (v) => RegExp(r'^[a-z0-9._]{3,50}$').hasMatch((v ?? '').trim().toLowerCase())
                      ? null
                      : 'Format username tidak valid.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _akunSilakes,
                  decoration: label('Username pegawai SiLAKES',
                      'Opsional. Foto pegawai diambil dari SiLAKES (baca saja) saat akun disimpan.'),
                  validator: (v) {
                    final t = (v ?? '').trim().toLowerCase();
                    return t.isEmpty || RegExp(r'^[a-z0-9._@-]{3,60}$').hasMatch(t)
                        ? null
                        : 'Format username SiLAKES tidak valid.';
                  },
                ),
                const SizedBox(height: 18),
                if (!_baru) ...[
                  const Text('Reset kata sandi', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _sandi,
                  obscureText: !_tampilSandi,
                  decoration: label(_baru ? 'Kata sandi' : 'Kata sandi baru',
                          _baru ? 'Paling sedikit 8 karakter.' : 'Kosongkan bila kata sandi tidak direset.')
                      .copyWith(
                    suffixIcon: IconButton(
                      tooltip: _tampilSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                      onPressed: () => setState(() => _tampilSandi = !_tampilSandi),
                      icon: Icon(_tampilSandi ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (v) {
                    final t = v ?? '';
                    if ((_baru || t.isNotEmpty) && t.length < 8) return 'Kata sandi paling sedikit 8 karakter.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const Text('Peran', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'petugas', label: Text('Petugas')),
                    ButtonSegment(value: 'admin', label: Text('Admin')),
                  ],
                  selected: {_peran},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                    selectedBackgroundColor: Warna.brand50,
                    selectedForegroundColor: Warna.brand700,
                    foregroundColor: Warna.body,
                    backgroundColor: Warna.permukaan,
                    side: const BorderSide(color: Warna.garis),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onSelectionChanged: (s) => setState(() => _peran = s.first),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _proses ? null : _simpan,
                  child: _proses
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Simpan'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class HalamanAmbang extends StatefulWidget {
  const HalamanAmbang({super.key});

  @override
  State<HalamanAmbang> createState() => _HalamanAmbangState();
}

class _HalamanAmbangState extends State<HalamanAmbang> {
  double? _nilai;
  bool _proses = false;

  Future<void> _simpan() async {
    setState(() => _proses = true);
    try {
      await SesiScope.of(context).api.ubahAmbang(double.parse(_nilai!.toStringAsFixed(2)));
      if (!mounted) return;
      pesan(context, 'Ambang disimpan. Nilai baru dipakai pada sinkronisasi berikutnya.');
      Navigator.pop(context);
    } on ApiGalat catch (e) {
      if (mounted) pesan(context, e.pesan, galat: true);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Widget _aturan(String kiri, String kanan, bool isi) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          Lencana(kiri, isi: isi),
          const SizedBox(width: 8),
          Text('→ $kanan', style: const TextStyle(fontSize: 14)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Pemuat<Json>(
          ambil: SesiScope.of(context).api.ambang,
          isi: (context, m, _) {
            final nilai = _nilai ?? (m['ambang'] as num).toDouble();
            return ListView(children: [
              const KepalaSub('Atur Ambang Deteksi'),
              const JudulHalaman('Atur Ambang Deteksi', 'Ambang peluang yang memisahkan status hasil deteksi.'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Kartu(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const JudulKartu('Model Aktif'),
                      const SizedBox(height: 4),
                      const BarisNilai('Algoritme', 'XGBoost'),
                      BarisNilai('Versi model', '${m['versi']}'),
                      BarisNilai('Ambang saat ini', fmt.peluang(m['ambang'] as num), garis: false),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Kartu(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const JudulKartu('Nilai Ambang'),
                      Center(
                        child: Text(fmt.peluang(nilai),
                            style: const TextStyle(
                                fontSize: 44, fontWeight: FontWeight.w700, color: Warna.brand900, fontFeatures: angkaTabular)),
                      ),
                      Slider(
                        value: nilai,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        activeColor: Warna.brand700,
                        label: fmt.peluang(nilai),
                        onChanged: (v) => setState(() => _nilai = v),
                      ),
                      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('0,00', style: TextStyle(color: Warna.bodyLemah, fontSize: 12)),
                        Text('0,50', style: TextStyle(color: Warna.bodyLemah, fontSize: 12)),
                        Text('1,00', style: TextStyle(color: Warna.bodyLemah, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      _aturan('Peluang > ambang', 'Perlu ditinjau', true),
                      _aturan('Peluang ≤ ambang', 'Tidak ada indikasi', false),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const KotakInfo('Nilai awal ambang adalah 0,50. Ambang baru digunakan pada sinkronisasi berikutnya.',
                      ikon: Icons.warning_amber_outlined),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _proses || _nilai == null ? null : _simpan,
                    child: _proses
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Simpan Ambang'),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

enum _Tahap { menunggu, berjalan, selesai, gagal }

class HalamanSinkronisasi extends StatefulWidget {
  const HalamanSinkronisasi({super.key, required this.kembali});
  final VoidCallback kembali;

  @override
  State<HalamanSinkronisasi> createState() => _HalamanSinkronisasiState();
}

class _HalamanSinkronisasiState extends State<HalamanSinkronisasi> {
  // Tahapan sama dengan alur sinkronisasi pada flowchart sistem admin di BAB III.
  static const _tahapan = [
    ('Membaca surat hasil baru', 'Data SiLAKES dibaca dengan akses baca saja'),
    ('Menyiapkan data profil', 'Konversi nilai, umur, satu baris per surat hasil'),
    ('Menghitung peluang anomali', 'Model XGBoost memproses setiap profil'),
    ('Menghitung nilai SHAP', 'Kontribusi setiap fitur terhadap prediksi'),
    ('Menentukan status', 'Peluang dibandingkan dengan ambang'),
    ('Menyimpan hasil deteksi', 'Hasil dan riwayat sinkronisasi disimpan'),
  ];

  _Tahap _tahap = _Tahap.menunggu;
  Json? _hasil;
  Json? _terakhir;
  double? _ambang;
  String? _galat;
  bool _memuatTerakhir = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatTerakhir());
  }

  Future<void> _muatTerakhir() async {
    try {
      final r = await SesiScope.of(context).api.ringkasanAdmin();
      if (!mounted) return;
      setState(() {
        _terakhir = r['sinkronisasi_terakhir'] as Json?;
        _ambang = ((r['model_aktif'] as Json?)?['ambang'] as num?)?.toDouble();
      });
    } on ApiGalat catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memuatTerakhir = false);
    }
  }

  Future<void> _mulai() async {
    setState(() {
      _tahap = _Tahap.berjalan;
      _galat = null;
      _hasil = null;
    });
    try {
      final r = await SesiScope.of(context).api.sinkronisasi();
      if (!mounted) return;
      setState(() {
        _hasil = r;
        _tahap = _Tahap.selesai;
      });
      await _muatTerakhir();
    } on ApiGalat catch (e) {
      if (mounted) {
        setState(() {
          _galat = e.pesan;
          _tahap = _Tahap.gagal;
        });
      }
    }
  }

  Widget _status() => switch (_tahap) {
        _Tahap.menunggu => const Text('Menunggu', style: TextStyle(fontSize: 12, color: Warna.bodyLemah)),
        _Tahap.berjalan => const SizedBox(
            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Warna.brand700)),
        _Tahap.selesai =>
          const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Warna.amanTeks)),
        _Tahap.gagal =>
          const Text('Gagal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Warna.galatTeks)),
      };

  @override
  Widget build(BuildContext context) {
    final h = _hasil;
    final t = _terakhir;
    return ListView(children: [
      KepalaSub('Sinkronisasi Data', kembali: widget.kembali),
      const JudulHalaman('Sinkronisasi Data', 'Surat hasil baru dibaca dari SiLAKES, lalu diproses oleh model.'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Kartu(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const JudulKartu('Tahapan Proses'),
              const SizedBox(height: 8),
              for (final (i, (judul, sub)) in _tahapan.indexed)
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 24,
                      child: Column(children: [
                        Icon(_tahap == _Tahap.selesai ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 20, color: Warna.brand700),
                        if (i < _tahapan.length - 1) Expanded(child: Container(width: 2, color: Warna.brand700)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(i == 4 && _ambang != null ? 'Peluang dibandingkan dengan ambang ${fmt.peluang(_ambang!)}' : sub,
                              style: const TextStyle(fontSize: 12, color: Warna.bodyLemah)),
                        ]),
                      ),
                    ),
                    _status(),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _tahap == _Tahap.berjalan ? null : _mulai,
            icon: const Icon(Icons.sync),
            label: Text(_tahap == _Tahap.berjalan ? 'Sinkronisasi berjalan...' : 'Mulai Sinkronisasi'),
          ),
          if (_tahap == _Tahap.berjalan) ...[
            const SizedBox(height: 6),
            const Text('Proses dapat berlangsung beberapa menit. Jangan tutup aplikasi.',
                style: TextStyle(fontSize: 13, color: Warna.bodyLemah)),
          ],
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Warna.galatLatar, borderRadius: BorderRadius.circular(radius)),
              child: Text(_galat!, style: const TextStyle(color: Warna.galatTeks)),
            ),
          ],
          if (h != null && h['ada_data_baru'] != true) ...[
            const SizedBox(height: 12),
            const KotakInfo('Tidak ada surat hasil baru sejak sinkronisasi terakhir.'),
          ],
          const SizedBox(height: 12),
          Kartu(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              JudulKartu('Ringkasan Sinkronisasi',
                  kanan: t == null
                      ? null
                      : const Text('Berhasil',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Warna.amanTeks))),
              const SizedBox(height: 4),
              if (t == null && h == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_memuatTerakhir ? 'Memuat ringkasan sinkronisasi terakhir...' : 'Belum ada sinkronisasi yang berhasil.',
                      style: const TextStyle(color: Warna.bodyLemah)),
                )
              else if (h != null) ...[
                // Hasil sinkronisasi yang baru saja dijalankan.
                BarisNilai('Surat hasil baru', '${h['surat_baru']}'),
                BarisNilai('Profil diproses', '${h['profil_diproses']}'),
                BarisNilai('Perlu ditinjau', '${h['perlu_ditinjau']}'),
                BarisNilai('Tidak ada indikasi', '${h['tidak_ada_indikasi']}'),
                BarisNilai(
                    'Waktu',
                    rentangWaktu((h['log'] as Json)['waktu_mulai'] as String?,
                        (h['log'] as Json)['waktu_selesai'] as String?),
                    garis: false),
              ] else if (t != null) ...[
                BarisNilai('Profil diproses', '${t['jumlah_profil']}'),
                BarisNilai('Perlu ditinjau', '${t['perlu_ditinjau']}'),
                BarisNilai('Tidak ada indikasi', '${t['tidak_ada_indikasi']}'),
                BarisNilai('Waktu', rentangWaktu(t['waktu_mulai'] as String?, t['waktu_selesai'] as String?),
                    garis: false),
              ],
            ]),
          ),
        ]),
      ),
    ]);
  }
}
