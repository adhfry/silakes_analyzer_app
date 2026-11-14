import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../tema.dart';
import '../widget/umum.dart';

/// Halaman login sesuai wireframe (b) pada Gambar rancangan splash screen dan login:
/// satu halaman masuk untuk petugas laboratorium dan admin.
class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _sandi = TextEditingController();
  bool _proses = false;
  bool _tampilSandi = false;
  // Setelah percobaan masuk pertama, pesan galat diperbarui setiap kali isian diubah.
  bool _sudahDicoba = false;
  String? _galat;

  Future<void> _masuk() async {
    if (!_sudahDicoba) setState(() => _sudahDicoba = true);
    if (!_form.currentState!.validate()) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await SesiScope.of(context).masukDengan(_username.text.trim(), _sandi.text);
    } on ApiGalat catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final galat = _galat ?? SesiScope.of(context).pesanSesi;
    return Scaffold(
      backgroundColor: Warna.permukaan,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    autovalidateMode: _sudahDicoba ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Center(child: Logo(ukuran: 96)),
                      const SizedBox(height: 14),
                      const Text('SiLAKES Analyzer',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Warna.brand900)),
                      const SizedBox(height: 4),
                      const Text('Deteksi Anomali Pra-Analitik Laboratorium Klinis',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Warna.bodyLemah)),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _username,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Masukkan username',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Username wajib diisi.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _sandi,
                        obscureText: !_tampilSandi,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _masuk(),
                        validator: (v) => (v ?? '').isEmpty ? 'Kata sandi wajib diisi.' : null,
                        decoration: InputDecoration(
                          labelText: 'Kata sandi',
                          hintText: 'Masukkan kata sandi',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _tampilSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                            icon: Icon(_tampilSandi ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _tampilSandi = !_tampilSandi),
                          ),
                        ),
                      ),
                      if (galat != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Warna.galatLatar, borderRadius: BorderRadius.circular(radius)),
                          child: Text(galat, style: const TextStyle(color: Warna.galatTeks)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _proses ? null : _masuk,
                        child: _proses
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Masuk'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              '© 2026 Skripsi Ahda Firly Barori · NIM 2302310186\n'
              'Program Studi Informatika, Fakultas Sains dan Teknologi\n'
              'Universitas Bahaudin Mudhary Madura',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Warna.bodyLemah, height: 1.45),
            ),
          ),
        ]),
      ),
    );
  }
}
