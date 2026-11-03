import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../widgets/common/app_buttons.dart';
import 'login_screen.dart';

/// Model item data onboarding
class _OnboardingItem {
  final String category;
  final IconData icon;
  final String title;
  final String description;
  final List<String> highlights;

  const _OnboardingItem({
    required this.category,
    required this.icon,
    required this.title,
    required this.description,
    required this.highlights,
  });
}

/// Halaman Onboarding Resmi LKM Mitra Siswa Abadi
/// Memperkenalkan fitur perbankan siswa, kartu digital, dan literasi tabungan
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimatingPage = false;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      category: 'PERBANKAN SISWA TERPADU',
      icon: Icons.account_balance_rounded,
      title: 'Tabungan Sekolah Aman & Transparan',
      description:
          'Kelola simpanan masa depan, cek saldo efektif riil, dan pantau seluruh histori mutasi transaksi langsung dari genggaman.',
      highlights: [
        'Buku mutasi transaksi otomatis & tercatat',
        'Pemisahan saldo efektif dan saldo mengendap',
        'Integrasi langsung dengan loket kasir Teller',
      ],
    ),
    _OnboardingItem(
      category: 'KARTU DIGITAL & KEAMANAN',
      icon: Icons.credit_card_rounded,
      title: 'Identitas Kartu Digital & PIN Otorisasi',
      description:
          'Akses kartu siswa berstandar GPN resmi untuk verifikasi transaksi di loket sekolah, dilengkapi otorisasi PIN dan kunci kartu instan.',
      highlights: [
        'Kartu debit digital resmi siswa SMK N 1 Bantul',
        'PIN 6-digit untuk persetujuan penarikan loket',
        'Kunci atau blokir rekening mandiri seketika',
      ],
    ),
    _OnboardingItem(
      category: 'LITERASI FINANSIAL & PRESTASI',
      icon: Icons.savings_rounded,
      title: 'Rencanakan Impian dengan Saving Goals',
      description:
          'Bangun kebiasaan finansial cerdas sejak masa sekolah. Buat target tabungan impian dan raih lencana apresiasi literasi keuangan.',
      highlights: [
        'Target simpanan terencana & terukur',
        'Lencana apresiasi (Badges) konsistensi menabung',
        'Edukasi pengelolaan dana berbasis perbankan syariah',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isAnimatingPage) return;
    _isAnimatingPage = true;

    await SessionStorage.setOnboardingCompleted(completed: true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _nextPage() {
    if (_isAnimatingPage) return;
    if (_currentPage < _items.length - 1) {
      _isAnimatingPage = true;
      final targetPage = _currentPage + 1;
      _pageController
          .animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) {
        if (mounted) {
          setState(() {
            _currentPage = targetPage;
            _isAnimatingPage = false;
          });
        }
      });
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo Sekolah & Tombol Lewati
            _buildTopBar(),

            // Page View Konten Onboarding
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  if (!_isAnimatingPage) {
                    setState(() => _currentPage = index);
                  }
                },
                itemBuilder: (context, index) {
                  return _buildPageSlide(_items[index]);
                },
              ),
            ),

            // Bottom Navigation Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  /// Top Bar Header
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/SMK_Negeri_1_Bantul_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'LKM Mitra Siswa Abadi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lewati',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Konten Per Slide
  Widget _buildPageSlide(_OnboardingItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Icon Emblem Card
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accentTeal.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 48,
              color: AppColors.accentTealHover,
            ),
          ),

          const SizedBox(height: 24),

          // Kategori Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              item.category,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentTealHover,
                letterSpacing: 0.8,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Judul Utama Slide
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Deskripsi Slide
          Text(
            item.description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Kartu Fitur Unggulan (Pills / Highlights)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: item.highlights.map((highlight) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentTeal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.accentTealHover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          highlight,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Controls (Dots & Nav Buttons)
  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _items.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentTealHover : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Tombol Tindakan
          if (isLastPage) ...[
            PrimaryButton(
              key: const ValueKey('btn_onboarding_complete'),
              text: 'Mulai Sekarang — Masuk ke Akun',
              icon: Icons.login_rounded,
              backgroundColor: AppColors.accentTealHover,
              textColor: Colors.white,
              height: 48,
              onPressed: _completeOnboarding,
            ),
          ] else ...[
            Row(
              key: const ValueKey('row_onboarding_actions'),
              children: [
                Expanded(
                  flex: 2,
                  child: SecondaryButton(
                    key: const ValueKey('btn_onboarding_skip'),
                    text: 'Lewati',
                    height: 46,
                    onPressed: _completeOnboarding,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: PrimaryButton(
                    key: const ValueKey('btn_onboarding_next'),
                    text: 'Lanjut',
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: AppColors.accentTealHover,
                    textColor: Colors.white,
                    height: 46,
                    onPressed: _nextPage,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
