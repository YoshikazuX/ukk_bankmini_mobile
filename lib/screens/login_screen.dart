import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_client.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../services/auth_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_inputs.dart';
import 'admin/admin_main_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation.dart';
import 'supervisor/supervisor_main_screen.dart';
import 'teller/teller_main_screen.dart';

/// Halaman Autentikasi Universal Bank Mini Sekolah (Production-Ready)
/// Sesuai Identitas Visual LKM Mitra Siswa Abadi (Modern Institutional Banking)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showAppSnackbar(context, 'Username dan kata sandi wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!result.success) {
        showAppSnackbar(context, result.message, isError: true);
        return;
      }

      // Navigasi Terpadu Berdasarkan Respons Role Backend (RBAC)
      Widget destinationScreen;
      final role = (result.role ?? 'nasabah').toLowerCase();

      switch (role) {
        case 'teller':
          destinationScreen = TellerMainScreen(petugas: result.petugas);
          break;
        case 'supervisor':
        case 'accounting':
          destinationScreen = SupervisorMainScreen(petugas: result.petugas);
          break;
        case 'admin':
          destinationScreen = AdminMainScreen(petugas: result.petugas);
          break;
        case 'nasabah':
        default:
          destinationScreen = const MainNavigation();
          break;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppSnackbar(context, 'Terjadi kesalahan saat masuk: $e', isError: true);
    }
  }

  void _showServerConfigDialog() async {
    final currentUrl = await SessionStorage.getBaseUrl();
    final urlController = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_ethernet_rounded, color: AppColors.primaryNavy),
            const SizedBox(width: 8),
            Text(
              'Konfigurasi Server API',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ganti alamat server backend Laravel (IP LAN Wi-Fi / Host):',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            InputField(
              label: 'Base URL Backend',
              controller: urlController,
              hint: 'http://192.168.1.x:8000/api',
              prefixIcon: const Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Tutup', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: AppColors.primaryNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await SessionStorage.setBaseUrl(newUrl);
                await ApiClient.instance.updateBaseUrl();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  showAppSnackbar(context, 'Base URL berhasil disimpan ke: $newUrl');
                }
              }
            },
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 850;

          if (isDesktop) {
            return _buildDesktopLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  // =========================================================================
  // DESKTOP DUAL-COLUMN LAYOUT (LKM MITRA SISWA ABADI)
  // =========================================================================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Kolom Kiri: Form Login Putih Bersih
        Expanded(
          flex: 6,
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandHeaderSmall(),
                      const SizedBox(height: 32),
                      _buildLoginForm(),
                      const SizedBox(height: 24),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Kolom Kanan: Branding Navy Institusional
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primaryNavy,
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/SMK_Negeri_1_Bantul_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'LKM Mitra Siswa Abadi',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem Lembaga Keuangan Mikro & Bank Mini Sekolah Berbasis Perbankan Syariah dan Konvensional Terpadu.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textOnNavyMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInstitutionalFeature(
                  Icons.shield_outlined,
                  'Role-Based Access Control',
                  'Pemisahan hak akses otomatis nasabah siswa, loket teller, supervisor, dan administrator.',
                ),
                const SizedBox(height: 16),
                _buildInstitutionalFeature(
                  Icons.security_rounded,
                  'Standar Keamanan Perbankan',
                  'Otorisasi token Bearer Sanctum, enkripsi PIN transaksi, dan rekonsiliasi kas riil.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MOBILE SINGLE-COLUMN LAYOUT
  // =========================================================================
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action: Pengaturan Server
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings_ethernet_rounded, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Pengaturan Server API',
                    onPressed: _showServerConfigDialog,
                  ),
                ),
                const SizedBox(height: 4),

                // Brand Header Mobile
                Center(child: _buildBrandHeaderSmall()),
                const SizedBox(height: 24),

                // Card Putih Bersih Universal Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildLoginForm(),
                ),
                const SizedBox(height: 24),

                // Footer
                _buildFooterNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeaderSmall() {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/SMK_Negeri_1_Bantul_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'LKM Mitra Siswa Abadi',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Sistem Informasi Bank Mini Sekolah',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masuk ke Akun Anda',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Masukkan kredensial Anda untuk mengakses portal perbankan.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        InputField(
          label: 'Username / NIS / No. Rekening',
          controller: _usernameController,
          hint: 'Masukkan username, NIS, atau nomor rekening',
          prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        PasswordField(
          label: 'Kata Sandi',
          controller: _passwordController,
          hint: 'Masukkan kata sandi',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.accentTeal,
                      checkColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ingat saya',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                'Lupa password?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Masuk ke Dashboard',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildInstitutionalFeature(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accentTeal, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textOnNavyMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Text(
        '© 2026 LKM Mitra Siswa Abadi • Sistem Bank Mini Sekolah Terverifikasi',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
