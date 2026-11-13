import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'halaman/admin.dart';
import 'halaman/masuk.dart';
import 'halaman/petugas.dart';
import 'sesi.dart';
import 'tema.dart';
import 'widget/umum.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(Aplikasi(sesi: Sesi()));
}

/// Memberi akses Sesi ke seluruh halaman: `SesiScope.of(context)`.
class SesiScope extends InheritedNotifier<Sesi> {
  const SesiScope({super.key, required Sesi sesi, required super.child}) : super(notifier: sesi);
  static Sesi of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SesiScope>()!.notifier!;
}

class Aplikasi extends StatefulWidget {
  const Aplikasi({super.key, required this.sesi});
  final Sesi sesi;

  @override
  State<Aplikasi> createState() => _AplikasiState();
}

class _AplikasiState extends State<Aplikasi> {
  late final Future<void> _awal = _mulai();

  /// Durasi minimum splash dihitung setelah bingkai pertama tampil, bukan sejak widget dibuat,
  /// agar splash tetap terlihat pada perangkat yang lambat saat aplikasi pertama kali dibuka.
  Future<void> _mulai() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.wait([
      widget.sesi.muat(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SesiScope(
      sesi: widget.sesi,
      child: MaterialApp(
        title: 'SiLAKES Analyzer',
        debugShowCheckedModeBanner: false,
        theme: buatTema(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: FutureBuilder(
          future: _awal,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) return const HalamanSplash();
            return ListenableBuilder(
              listenable: widget.sesi,
              builder: (context, _) {
                if (!widget.sesi.masuk) return const HalamanMasuk();
                return widget.sesi.admin ? const ShellAdmin() : const ShellPetugas();
              },
            );
          },
        ),
      ),
    );
  }
}

/// Splash screen sesuai wireframe (a): logo, nama aplikasi, keterangan, dan indikator pemuatan.
class HalamanSplash extends StatelessWidget {
  const HalamanSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.permukaan,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Logo(ukuran: 120),
            const SizedBox(height: 18),
            const Text('SiLAKES Analyzer', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Warna.brand900)),
            const SizedBox(height: 6),
            const Text('Deteksi Anomali Pra-Analitik\nLaboratorium Klinis',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Warna.bodyLemah, height: 1.4)),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(minHeight: 8, color: Warna.brand700, backgroundColor: Warna.brand50),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Memuat aplikasi...', style: TextStyle(fontSize: 13, color: Warna.bodyLemah)),
          ]),
        ),
      ),
    );
  }
}
