import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:silakes_analyzer/format.dart' as fmt;
import 'package:silakes_analyzer/halaman/petugas.dart';
import 'package:silakes_analyzer/tema.dart';
import 'package:silakes_analyzer/widget/umum.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('format angka memakai koma desimal', () {
    expect(fmt.peluang(0.6634), '0,66');
    expect(fmt.nilaiHasil(0.9), '0,9');
    expect(fmt.nilaiHasil(200), '200');
    expect(fmt.labelDalamKalimat('kolesterol_total'), 'kolesterol total');
    expect(fmt.labelDalamKalimat('hdl'), 'HDL');
    expect(fmt.kodePendek('98fe909937f86ee5'), '98FE-90');
    expect(fmt.rentangTanggal('2026-09-28', '2026-09-29'), '28–29 Sep 2026');
  });

  testWidgets('kartu hasil menampilkan kode pendek, peluang, dan status', (tester) async {
    final data = {
      'id_deteksi': 1,
      'peluang_anomali': 0.7012,
      'status_deteksi': 'perlu_ditinjau',
      'profil': {
        'id_surat_silakes': 23889,
        'kode_pasien': '98fe909937f86ee5',
        'tanggal_periksa': '2026-10-09',
        'jenis_kelamin': 'P',
        'umur': 78,
      },
    };
    await tester.pumpWidget(MaterialApp(theme: buatTema(), home: Scaffold(body: KartuHasil(data))));
    expect(find.text('0,70'), findsOneWidget);
    expect(find.text('Perlu ditinjau'), findsOneWidget);
    expect(find.text('Pasien 98FE-90'), findsOneWidget);
    expect(find.text('Perempuan · 78 th · Surat #23889'), findsOneWidget);
  });

  testWidgets('kondisi galat menampilkan tombol coba lagi', (tester) async {
    var ditekan = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Kondisi.galat(pesan: 'Server tidak menjawab.', onTombol: () => ditekan = true))));
    expect(find.text('Data tidak dapat dimuat'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(ditekan, isTrue);
  });
}
