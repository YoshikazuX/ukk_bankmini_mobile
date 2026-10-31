import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna resmi LKM Mitra Siswa Abadi
/// Modern Institutional Banking Interface - Green Primary (No Gradients)
class AppColors {
  AppColors._();

  // =========================================================================
  // DESIGN TOKENS RESMI WEBSITE LKM MITRA SISWA ABADI
  // =========================================================================

  /// Primary Accent: Warna hijau utama dari login page (CTA, active, highlight)
  static const Color accentTeal = Color(0xFF19C9A3);

  /// Primary Accent Hover / Deeper: Kontras tinggi di atas permukaan putih
  static const Color accentTealHover = Color(0xFF008F83);

  /// Dark Green untuk kontras teks di atas permukaan putih (WCAG AA compliant)
  static const Color greenDark = Color(0xFF0F766E);

  /// Green Muted / Tinted Background (untuk pill & chip aktif)
  static const Color greenLight = Color(0xFFE6F8F3);

  /// Primary Navy: Identitas institusi pendukung & teks pada tombol hijau
  static const Color primaryNavy = Color(0xFF101B2D);

  /// Primary Navy Light: Varian navy untuk border & kartu sekunder
  static const Color primaryNavyLight = Color(0xFF1E3A5F);

  /// Secondary Navy: Aksen permukaan navy gelap
  static const Color secondaryNavy = Color(0xFF172538);

  /// Background: Kanvas utama abu-abu netral perbankan modern (Unslop Ink Light)
  static const Color background = Color(0xFFF5F7FA);

  /// Surface: Kartu konten, modul form, modal (Putih Bersih)
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface Muted: Latar belakang sekunder ringan (tabel zebra, chip input)
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  /// Primary Text: Teks judul, label utama, dan nominal penting (Navy Gelap)
  static const Color textPrimary = Color(0xFF1D2B45);
  static const Color textAccent = Color(0xFF008F83);
  static const Color textDisabled = Color(0xFFA0AEC0);

  /// Secondary Text: Subtitle, keterangan, timestamp (Slate Gray)
  static const Color textSecondary = Color(0xFF64748B);

  /// Text Muted / Hint: Placeholder, keterangan non-aktif
  static const Color textMuted = Color(0xFF94A3B8);

  /// Teks di atas latar belakang Navy / Dark Card
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnNavyMuted = Color(0xFF94A3B8);

  /// Teks di atas latar belakang Green (Putih Bersih agar terang dan tidak nabrak)
  static const Color textOnGreen = Color(0xFFFFFFFF);
  static const Color textOnGreenMuted = Color(0xD9FFFFFF);

  /// Border: Garis pembatas tipis, rapi, dan konsisten (Hairline)
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
  // CARD & CONTAINER SHADOWS (Clean Depth Without Slop)
  // =========================================================================
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 12,
      offset: Offset(0, -3),
    ),
  ];

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

  // SOLID FLAT COLORS (Gradasi dinonaktifkan sesuai aturan tanpa gradasi)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentTeal, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [surface, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surface],
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
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w500,
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
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
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
          foregroundColor: AppColors.textPrimary,
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
        selectedItemColor: AppColors.accentTealHover,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
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
