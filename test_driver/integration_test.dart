import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Menyimpan tangkapan layar uji emulator ke build/uji_emulator/.
Future<void> main() => integrationDriver(
      onScreenshot: (nama, gambar, [argumen]) async {
        final berkas = File('build/uji_emulator/$nama.png');
        berkas.parent.createSync(recursive: true);
        berkas.writeAsBytesSync(gambar);
        return true;
      },
    );
