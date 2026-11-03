import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import 'admin/admin_main_screen.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';
import 'supervisor/supervisor_main_screen.dart';
import 'teller/teller_main_screen.dart';

/// Splash Screen Resmi LKM Mitra Siswa Abadi
/// Menampilkan identitas institusional sekolah dan mengarahkan pengguna ke sesi yang valid
class SplashScreen extends StatefulWidget {
  final Duration minDelay;

  const SplashScreen({
    super.key,
    this.minDelay = const Duration(milliseconds: 1200),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartupSession();
  }

  Future<void> _handleStartupSession() async {
    try {
      await Future.wait([
        SessionStorage.init().timeout(
          const Duration(milliseconds: 1000),
          onTimeout: () {},
        ),
        Future.delayed(widget.minDelay),
      ]);
    } catch (_) {
      // Fallback jika storage belum terinisialisasi
    }

    if (!mounted) return;

    try {
      final hasToken = await SessionStorage.hasToken().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => false,
      );
      if (!mounted) return;

      if (hasToken) {
        final role = (await SessionStorage.getRole().timeout(
                  const Duration(milliseconds: 500),
                  onTimeout: () => 'nasabah',
                ) ??
                'nasabah')
            .toLowerCase();
        Widget targetScreen;

        switch (role) {
          case 'admin':
            targetScreen = AdminMainScreen(petugas: SessionStorage.cachedPetugas);
            break;
          case 'supervisor':
          case 'accounting':
            targetScreen = SupervisorMainScreen(petugas: SessionStorage.cachedPetugas);
            break;
          case 'teller':
            targetScreen = TellerMainScreen(petugas: SessionStorage.cachedPetugas);
            break;
          case 'nasabah':
          default:
            targetScreen = const MainNavigation();
            break;
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        final isOnboardingDone = await SessionStorage.isOnboardingCompleted().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        );
        if (isOnboardingDone) {
          _navigateToLogin();
        } else {
          _navigateToOnboarding();
        }
      }
    } catch (_) {
      _navigateToLogin();
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Emblem / Logo Sekolah
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/SMK_Negeri_1_Bantul_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // Nama Institusi & Subtitle
              Text(
                'LKM Mitra Siswa Abadi',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sistem Informasi Bank Mini Sekolah',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Badge Terverifikasi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 13,
                      color: AppColors.accentTealHover,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SMK NEGERI 1 BANTUL',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentTealHover,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Loading Indicator Halus
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTealHover),
                ),
              ),

              const Spacer(flex: 3),

              // Footer Kemitraan & Versi
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Text(
                      'Lembaga Keuangan Mikro & Bank Mini Edukatif',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2026 SMK N 1 Bantul • Versi 2.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
