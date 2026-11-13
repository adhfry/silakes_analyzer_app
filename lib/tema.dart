import 'package:flutter/material.dart';

/// Token warna diambil dari konfigurasi frontend SiLAKES (lihat DESIGN.md).
class Warna {
  static const brand700 = Color(0xFF224097);
  static const brand900 = Color(0xFF1B2F63);
  static const brand50 = Color(0xFFEEF2FB);
  static const body = Color(0xFF1E293B);
  static const bodyLemah = Color(0xFF475569); // slate-600, teks keterangan
  static const garis = Color(0xFFE2E8F0); // slate-200
  static const garisTegas = Color(0xFF64748B); // slate-500, garis putus kotak info dan lencana bergaris (kontras 4,76)
  static const latar = Color(0xFFF1F5F9);
  static const permukaan = Colors.white;

  static const ditinjauTeks = Color(0xFF92400E);
  static const ditinjauLatar = Color(0xFFFEF3C7);
  static const amanTeks = Color(0xFF047857);
  static const amanLatar = Color(0xFFD1FAE5);
  static const galatTeks = Color(0xFF9F1239);
  static const galatLatar = Color(0xFFFFE4E6);
}

const radius = 8.0;
const angkaTabular = [FontFeature.tabularFigures()];

ThemeData buatTema() {
  final dasar = ThemeData(
    useMaterial3: true,
    fontFamily: 'PublicSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Warna.brand700,
      primary: Warna.brand700,
      onPrimary: Colors.white,
      surface: Warna.permukaan,
      onSurface: Warna.body,
      error: Warna.galatTeks,
    ),
    scaffoldBackgroundColor: Warna.latar,
  );
  final bentuk = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  return dasar.copyWith(
    textTheme: dasar.textTheme.apply(bodyColor: Warna.body, displayColor: Warna.brand900),
    appBarTheme: const AppBarTheme(
      backgroundColor: Warna.brand700,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontFamily: 'PublicSans', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    cardTheme: CardThemeData(color: Warna.permukaan, elevation: 0, margin: EdgeInsets.zero, shape: bentuk),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.brand700,
        minimumSize: const Size.fromHeight(48),
        shape: bentuk,
        textStyle: const TextStyle(fontFamily: 'PublicSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.brand700,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Warna.brand700),
        shape: bentuk,
        textStyle: const TextStyle(fontFamily: 'PublicSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.permukaan,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: Warna.garis)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: Warna.garis)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: Warna.brand700, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.permukaan,
      indicatorColor: Warna.brand50,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'PublicSans', fontSize: 12, fontWeight: FontWeight.w500)),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Warna.brand700 : Warna.bodyLemah)),
    ),
    dividerTheme: const DividerThemeData(color: Warna.garis, space: 1, thickness: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
