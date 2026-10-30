import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna resmi LKM Mitra Siswa Abadi
/// Modern Institutional Banking Interface
class AppColors {
  AppColors._();

  // =========================================================================
  // DESIGN TOKENS RESMI WEBSITE LKM MITRA SISWA ABADI
  // =========================================================================

  /// Primary Navy: Identitas institusi & elemen navigasi utama
  static const Color primaryNavy = Color(0xFF101B2D);

  /// Primary Navy Light: Varian navy sedikit lebih terang untuk border & sub-header
  static const Color primaryNavyLight = Color(0xFF1E3A5F);

  /// Secondary Navy: Aksen permukaan navy gelap, header sub-menu
  static const Color secondaryNavy = Color(0xFF172538);

  /// Accent Teal: Tombol utama (CTA), link aktif, highlight perbankan
  static const Color accentTeal = Color(0xFF19C9A3);

  /// Accent Teal Hover/Pressed: Interaksi tombol aktif
  static const Color accentTealHover = Color(0xFF12B892);

  /// Background: Kanvas utama abu-abu netral perbankan modern
  static const Color background = Color(0xFFF5F7FA);

  /// Surface: Kartu konten, modul form, modal (Putih Bersih)
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface Muted: Latar belakang sekunder ringan (tabel zebra, chip input)
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  /// Primary Text: Teks judul, label utama, dan nominal penting (Navy Gelap)
  static const Color textPrimary = Color(0xFF152238);

  /// Secondary Text: Subtitle, keterangan, timestamp (Slate Gray)
  static const Color textSecondary = Color(0xFF64748B);

  /// Text Muted / Hint: Placeholder, keterangan non-aktif
  static const Color textMuted = Color(0xFF94A3B8);

  /// Teks di atas latar belakang Navy
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnNavyMuted = Color(0xFF94A3B8);

  /// Border: Garis pembatas tipis, rapi, dan konsisten
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);
  static const Color borderFocus = Color(0xFF19C9A3);

  // =========================================================================
  // FUNCTIONAL STATUS COLORS (Strict Banking Semantics)
  // =========================================================================

  /// Success: Transaksi berhasil, presensi hadir, saldo masuk
  static const Color success = Color(0xFF16A36A);
  static const Color successBg = Color(0xFFE8F5E9);

  /// Warning: Izin petugas, pending approval, rekonsiliasi selisih
  static const Color warning = Color(0xFFD99A28);
  static const Color warningBg = Color(0xFFFFF8E1);

  /// Danger: Transaksi gagal, saldo keluar, penolakan, blokir, alpha
  static const Color danger = Color(0xFFDC5656);
  static const Color dangerBg = Color(0xFFFFEBEE);

  /// Information: Status sistem, informasi rekening, panduan
  static const Color info = Color(0xFF3986C8);
  static const Color infoBg = Color(0xFFE3F2FD);

  // =========================================================================
  // BACKWARDS-COMPATIBILITY ALIASES (Memastikan screen existing tetap jalan)
  // =========================================================================
  static const Color primaryTeal = accentTeal;
  static const Color primaryTealDark = accentTealHover;
  static const Color primaryTealLight = Color(0xFF5EEAD4);
  static const Color backgroundDark = primaryNavy;
  static const Color backgroundCard = surface;
  static const Color backgroundCardLight = surfaceMuted;
  static const Color backgroundInput = surface;
  static const Color backgroundSurface = background;
  static const Color borderTeal = accentTeal;

  static const Color badgeGold = Color(0xFFD99A28);
  static const Color badgeSilver = Color(0xFF94A3B8);
  static const Color badgeBronze = Color(0xFFB45309);

  static const Color frozenBlue = Color(0xFF3986C8);
  static const Color frozenBackground = Color(0xFFE8F0FE);

  // Gradients for backwards-compatibility
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentTeal, accentTealHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surfaceMuted],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surfaceMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Konfigurasi Tema Global Institutional Banking
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseFont = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentTeal,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTeal,
        onPrimary: AppColors.primaryNavy,
        secondary: AppColors.primaryNavy,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: baseFont.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: AppColors.primaryNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Alias darkTheme diarahkan ke lightTheme perbankan institusional
  static ThemeData get darkTheme => lightTheme;
}
