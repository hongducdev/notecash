import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      // Sử dụng Momo Trust Sans cho nội dung chính
      textTheme: GoogleFonts.momoTrustSansTextTheme().copyWith(
        // Momo Trust Display cho các tiêu đề lớn
        displayLarge: GoogleFonts.momoTrustDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.momoTrustDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.momoTrustDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        // Momo Trust Display cho tiêu đề trang
        titleLarge: GoogleFonts.momoTrustDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.momoTrustDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      // Cấu hình các component theo style M3 mặc định
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.momoTrustDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }

  static ColorScheme _defaultScheme(Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFD82D8B), // Màu hồng MoMo đặc trưng
        brightness: brightness,
      );

  static ThemeData get lightTheme => theme(_defaultScheme(Brightness.light));
  static ThemeData get darkTheme => theme(_defaultScheme(Brightness.dark));
}
