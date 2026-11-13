import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiGalat implements Exception {
  ApiGalat(this.pesan, {this.kode});
  final String pesan;
  final int? kode;
  bool get sesiBerakhir => kode == 401;
  @override
  String toString() => pesan;
}

typedef Json = Map<String, dynamic>;

/// Klien REST API layanan Flask. Semua permintaan memakai token JWT pada header Authorization.
class ApiKlien {
  ApiKlien({required this.alamat, this.token, this.saatSesiBerakhir});

  String alamat;
  String? token;
  void Function()? saatSesiBerakhir;

  Uri _uri(String jalur, [Map<String, String>? query]) {
    final dasar = alamat.endsWith('/') ? alamat.substring(0, alamat.length - 1) : alamat;
    return Uri.parse('$dasar/api$jalur').replace(queryParameters: query);
  }

  /// Alamat foto akun (data pegawai SiLAKES) beserta header token untuk dimuat oleh widget gambar.
  String urlFoto(int idPengguna) => _uri('/pengguna/$idPengguna/foto').toString();
  Map<String, String> get kepalaToken => {if (token != null) 'Authorization': 'Bearer $token'};

  Map<String, String> get _kepala => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _kirim(Future<http.Response> Function() permintaan, {Duration batas = const Duration(seconds: 20)}) async {
    final http.Response r;
    try {
      r = await permintaan().timeout(batas);
    } on TimeoutException {
      throw ApiGalat('Server tidak menjawab dalam ${batas.inSeconds} detik. Periksa jaringan lalu coba lagi.');
    } on SocketException {
      throw ApiGalat('Tidak dapat terhubung ke server $alamat. Pastikan ponsel dan server berada pada jaringan yang sama.');
    } on http.ClientException {
      throw ApiGalat('Tidak dapat terhubung ke server $alamat.');
    }
    dynamic isi;
    try {
      isi = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      throw ApiGalat('Jawaban server tidak dapat dibaca (kode ${r.statusCode}).', kode: r.statusCode);
    }
    if (r.statusCode >= 400) {
      final pesan = isi is Map && isi['galat'] != null ? isi['galat'] as String : 'Permintaan gagal (kode ${r.statusCode}).';
      if (r.statusCode == 401 && token != null) saatSesiBerakhir?.call();
      throw ApiGalat(pesan, kode: r.statusCode);
    }
    return isi;
  }

  Future<dynamic> get(String jalur, [Map<String, String>? query]) =>
      _kirim(() => http.get(_uri(jalur, query), headers: _kepala));

  Future<dynamic> post(String jalur, [Object? data, Duration batas = const Duration(seconds: 20)]) =>
      _kirim(() => http.post(_uri(jalur), headers: _kepala, body: jsonEncode(data ?? {})), batas: batas);

  Future<dynamic> put(String jalur, Object data) =>
      _kirim(() => http.put(_uri(jalur), headers: _kepala, body: jsonEncode(data)));

  // Petugas dan umum
  Future<Json> masuk(String username, String kataSandi) async =>
      await post('/auth/masuk', {'username': username, 'kata_sandi': kataSandi}) as Json;
  Future<Json> saya() async => await get('/auth/saya') as Json;
  Future<Json> ringkasan() async => await get('/ringkasan') as Json;
  Future<Json> daftarDeteksi({String status = '', String cari = '', int halaman = 1}) async =>
      await get('/deteksi', {'status': status, 'cari': cari, 'halaman': '$halaman', 'per_halaman': '20'}) as Json;
  Future<Json> detailDeteksi(int id) async => await get('/deteksi/$id') as Json;
  Future<Json> catatTindakLanjut(int id, String keputusan, String catatan) async =>
      await post('/deteksi/$id/tindak-lanjut', {'keputusan': keputusan, 'catatan': catatan}) as Json;

  // Admin
  Future<Json> ringkasanAdmin() async => await get('/admin/ringkasan') as Json;
  Future<List<dynamic>> daftarPengguna() async => await get('/admin/pengguna') as List<dynamic>;
  Future<Json> tambahPengguna(Json data) async => await post('/admin/pengguna', data) as Json;
  Future<Json> ubahPengguna(int id, Json data) async => await put('/admin/pengguna/$id', data) as Json;
  Future<Json> ambang() async => await get('/admin/ambang') as Json;
  Future<Json> ubahAmbang(double nilai) async => await put('/admin/ambang', {'ambang': nilai}) as Json;
  // Sinkronisasi membaca SiLAKES dan menjalankan model, sehingga batas waktunya lebih panjang.
  Future<Json> sinkronisasi() async => await post('/admin/sinkronisasi', null, const Duration(minutes: 10)) as Json;
}
