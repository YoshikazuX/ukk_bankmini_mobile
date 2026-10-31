import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_inputs.dart';
import '../widgets/common/app_states.dart';

/// Halaman Lupa Password untuk Nasabah
/// Nasabah TIDAK menggunakan OTP. Hanya bisa:
/// 1. Hubungi WhatsApp Admin langsung
/// 2. Ajukan Tiket Reset Password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _selectedTab = 0; // 0: WhatsApp Admin, 1: Ajukan Tiket
  final _usernameController = TextEditingController();
  final _namaController = TextEditingController();
  final _waController = TextEditingController();
  final _keteranganController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _namaController.dispose();
    _waController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Pemulihan Akses Akun',
            subtitle: 'Layanan reset kredensial dan bantuan akun siswa',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildTabSelector(),
                  const SizedBox(height: 16),
                  _selectedTab == 0 ? _buildWhatsAppCard() : _buildTicketCard(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Layanan Keamanan Akun',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Lupa Kata Sandi Akun Siswa?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Untuk menjaga keamanan tabungan siswa, reset kata sandi diverifikasi langsung oleh Administrator Bank Mini Sekolah.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              index: 0,
              label: 'WhatsApp Admin',
              icon: Icons.chat_outlined,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _tabButton(
              index: 1,
              label: 'Ajukan Tiket',
              icon: Icons.assignment_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hubungi kontak resmi Admin Bank Mini untuk verifikasi identitas dan permohonan reset password instan.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InputField(
            controller: _namaController,
            label: 'Nama Lengkap / NIS Siswa',
            hint: 'Contoh: Handa (NIS: 10293847)',
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Buka Chat WhatsApp Resmi Admin',
            icon: Icons.chat_rounded,
            backgroundColor: AppColors.success,
            textColor: Colors.white,
            onPressed: () {
              final nama = _namaController.text.trim();
              final text = nama.isNotEmpty
                  ? 'Halo Admin LKM Mitra Siswa Abadi, saya nasabah ($nama) membutuhkan bantuan untuk reset password akun saya di aplikasi Bank Mini.'
                  : 'Halo Admin LKM Mitra Siswa Abadi, saya nasabah Bank Mini Sekolah membutuhkan bantuan untuk reset kata sandi akun saya.';
              openWhatsAppAdmin(context: context, message: text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputField(
            controller: _usernameController,
            label: 'Username Akun',
            hint: 'Contoh: Handa',
          ),
          const SizedBox(height: 14),
          InputField(
            controller: _waController,
            label: 'Nomor WhatsApp Aktif Pemohon',
            hint: 'Contoh: 081234567890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          InputField(
            controller: _keteranganController,
            label: 'Alasan / Keterangan',
            hint: 'Contoh: Lupa password dan nomor HP belum terdaftar di profil...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Kirim Tiket Permohonan Reset',
            icon: Icons.send_rounded,
            onPressed: () {
              showAppSnackbar(
                context,
                'Tiket permohonan reset berhasil dikirim ke Administrator!',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Autentikasi Terenkripsi SHA-256 / Laravel Sanctum',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 LKM Mitra Siswa Abadi. Sistem Bank Mini Sekolah. Seluruh hak cipta dilindungi.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
