import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';

/// Alamat layanan REST API. Bawaan: layanan produksi. Untuk pengujian di emulator ditimpa saat build:
/// --dart-define=API_URL=http://10.0.2.2:5000
const alamatBawaan =
    String.fromEnvironment('API_URL', defaultValue: 'https://analyzer.silakes.labkesdasumenep.id');

/// Menyimpan token JWT di penyimpanan aman Android (Keystore).
class Sesi extends ChangeNotifier {
  Sesi() : api = ApiKlien(alamat: alamatBawaan) {
    api.saatSesiBerakhir = _berakhir;
  }

  final ApiKlien api;
  final _aman = const FlutterSecureStorage();
  Json? pengguna;
  String? pesanSesi;

  bool get masuk => pengguna != null;
  bool get admin => pengguna?['peran'] == 'admin';

  Future<void> muat() async {
    api.token = await _aman.read(key: 'token');
    if (api.token == null) return;
    try {
      pengguna = await api.saya();
    } on ApiGalat catch (e) {
      if (e.sesiBerakhir) {
        await _hapusToken();
      } else {
        pesanSesi = e.pesan;
      }
    }
    notifyListeners();
  }

  Future<void> masukDengan(String username, String kataSandi) async {
    final hasil = await api.masuk(username, kataSandi);
    api.token = hasil['token'] as String;
    await _aman.write(key: 'token', value: api.token);
    pengguna = hasil['pengguna'] as Json;
    pesanSesi = null;
    notifyListeners();
  }

  Future<void> keluar() async {
    await _hapusToken();
    pengguna = null;
    notifyListeners();
  }

  Future<void> _hapusToken() async {
    api.token = null;
    await _aman.delete(key: 'token');
  }

  void _berakhir() {
    if (pengguna == null) return;
    pesanSesi = 'Sesi berakhir atau akun dinonaktifkan. Silakan masuk kembali.';
    _hapusToken();
    pengguna = null;
    notifyListeners();
  }
}
