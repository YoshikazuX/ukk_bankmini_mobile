import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/nasabah_model.dart';
import '../services/auth_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_states.dart';
import 'badges_screen.dart';
import 'blokir_rekening_screen.dart';
import 'financial_chart_screen.dart';
import 'help_center_screen.dart';
import 'login_screen.dart';
import 'pin_authorization_screen.dart';
import 'saving_goals_screen.dart';
import 'session_log_screen.dart';

/// Halaman Profil & Pengaturan Nasabah Siswa (Quiet Chrome, Unslop)
class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nasabah = SessionStorage.cachedNasabah ??
        NasabahModel(
          id: '',
          noRekening: '-',
          nis: '-',
          namaLengkap: 'Nasabah Siswa',
          kelas: '-',
          jurusan: '-',
          totalSaldo: 0,
          status: 'AKTIF',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bersih Institusional (Quiet Chrome)
          PageHeader(
            title: 'Profil & Pengaturan',
            subtitle: 'Informasi identitas dan preferensi keamanan akun',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
          ),

          // Scrollable Menu Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  _buildProfileCard(nasabah),
                  const SizedBox(height: 16),

                  // Bagian 1: Informasi Rekening
                  _buildSectionHeader('Informasi Rekening & Finansial'),
                  _buildMenuGroup([
                    _menuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Rincian Saldo Tabungan',
                      desc: 'Total saldo, saldo mengendap, dan saldo efektif',
                      onTap: () => _showSaldoBottomSheet(context, nasabah),
                    ),
                    _menuTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan Grafik Finansial',
                      desc: 'Visualisasi setoran vs penarikan berkala',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialChartScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Bagian 2: Fitur Siswa
                  _buildSectionHeader('Program Menabung Siswa'),
                  _buildMenuGroup([
                    _menuTile(
                      icon: Icons.savings_outlined,
                      title: 'Target Tabungan Impian',
                      desc: 'Rencanakan alokasi tabungan untuk kebutuhan masa depan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen())),
                    ),
                    _menuTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Lencana Prestasi Menabung',
                      desc: 'Daftar pencapaian konsistensi menabung',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Bagian 3: Keamanan & Autentikasi
                  _buildSectionHeader('Keamanan & Privasi Akun'),
                  _buildMenuGroup([
                    _menuTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Otorisasi PIN Penarikan Loket',
                      desc: 'Layar input 6-digit PIN saat transaksi tarik tunai di loket',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinAuthorizationScreen())),
                    ),
                    _menuTile(
                      icon: Icons.devices_outlined,
                      title: 'Riwayat Sesi Login',
                      desc: 'Daftar perangkat dan waktu autentikasi terakhir',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionLogScreen())),
                    ),
                    _menuTile(
                      icon: Icons.shield_outlined,
                      title: 'Blokir Rekening Darurat',
                      desc: 'Bekukan rekening jika kartu atau ponsel hilang',
                      color: AppColors.danger,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlokirRekeningScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Bagian 4: Layanan & Bantuan
                  _buildSectionHeader('Bantuan & Informasi'),
                  _buildMenuGroup([
                    _menuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Pusat Bantuan & FAQ',
                      desc: 'Panduan teknis dan pertanyaan yang sering diajukan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                    ),
                    _menuTile(
                      icon: Icons.chat_outlined,
                      title: 'Hubungi Admin via WhatsApp',
                      desc: 'Layanan interaktif petugas LKM Mitra Siswa Abadi',
                      color: AppColors.success,
                      onTap: () => openWhatsAppAdmin(context: context),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Tombol Logout
                  SecondaryButton(
                    text: 'Keluar dari Sesi Nasabah',
                    icon: Icons.logout_rounded,
                    borderColor: AppColors.danger.withValues(alpha: 0.3),
                    textColor: AppColors.danger,
                    onPressed: () => _confirmLogout(context),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/SMK_Negeri_1_Bantul_logo.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LKM Mitra Siswa Abadi • SMK Negeri 1 Bantul',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(NasabahModel nasabah) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ProfileAvatar(
            name: nasabah.namaLengkap,
            size: 50,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nasabah.namaLengkap,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS: ${nasabah.nis} • Rek: ${nasabah.noRekening}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${nasabah.kelas} - ${nasabah.jurusan}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: nasabah.status,
            color: nasabah.isBlocked ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          final isLast = index == children.length - 1;
          return Column(
            children: [
              children[index],
              if (!isLast) const Divider(color: AppColors.border, height: 1),
            ],
          );
        }),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String desc,
    Color? color,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? AppColors.accentTealHover;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (color != null) ? color.withValues(alpha: 0.1) : AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showSaldoBottomSheet(BuildContext context, NasabahModel nasabah) {
    final saldoDapatDigunakan = (nasabah.totalSaldo - nasabah.saldoMengendap).clamp(0, double.infinity).toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rincian Saldo Tabungan Siswa',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _saldoRow('Total Saldo Tabungan', formatRupiah(nasabah.totalSaldo), isBold: true, color: AppColors.accentTealHover),
                  const Divider(color: AppColors.border, height: 16),
                  _saldoRow('Saldo Mengendap (Wajib)', formatRupiah(nasabah.saldoMengendap), isBold: false, color: AppColors.textSecondary),
                  const Divider(color: AppColors.border, height: 16),
                  _saldoRow('Saldo Efektif (Dapat Ditarik)', formatRupiah(saldoDapatDigunakan), isBold: true, color: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Catatan: Saldo mengendap adalah saldo jaminan pembukaan rekening Bank Mini Sekolah dan tidak dapat ditarik.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, height: 1.3),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saldoRow(String label, String value, {required bool isBold, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    ConfirmationDialog.show(
      context,
      title: 'Keluar dari Sesi',
      message: 'Apakah Anda yakin ingin keluar dari akun Nasabah Siswa ini? Anda harus masuk kembali dengan kata sandi.',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
      isDanger: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        await AuthService.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    });
  }
}
