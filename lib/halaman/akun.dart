import 'package:flutter/material.dart';

import '../format.dart' as fmt;
import '../main.dart';
import '../tema.dart';
import '../widget/umum.dart';

/// Menu Akun pada navigasi bawah: identitas akun yang sedang masuk dan logout.
class HalamanAkun extends StatelessWidget {
  const HalamanAkun({super.key, this.kembali});
  final VoidCallback? kembali;

  Future<void> _keluar(BuildContext context) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text('Anda perlu memasukkan username dan kata sandi lagi untuk masuk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ya == true && context.mounted) await SesiScope.of(context).keluar();
  }

  @override
  Widget build(BuildContext context) {
    final p = SesiScope.of(context).pengguna!;
    final admin = p['peran'] == 'admin';
    return ListView(children: [
      KepalaSub('Akun', kembali: kembali),
      const JudulHalaman('Akun', 'Akun yang sedang digunakan pada aplikasi ini.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Kartu(
            child: Row(children: [
              Avatar(fmt.inisial(p['nama'] as String), ukuran: 64, foto: fotoAkun(context, p)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['nama'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('@${p['username']}', style: const TextStyle(fontSize: 13, color: Warna.bodyLemah)),
                  const SizedBox(height: 6),
                  Lencana(admin ? 'Admin' : 'Petugas Laboratorium'),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => _keluar(context), icon: const Icon(Icons.logout), label: const Text('Keluar')),
        ]),
      ),
    ]);
  }
}
