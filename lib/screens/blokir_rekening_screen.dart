import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_states.dart';

/// Halaman Blokir Rekening Darurat (Emergency Account Freeze)
/// Mengikuti SOP-09 & PRD FR-27: Nasabah dapat membekukan rekening mandiri via API,
/// namun pembukaan blokir wajib melalui Administrator / Petugas Bank Mini Sekolah.
class BlokirRekeningScreen extends StatefulWidget {
  const BlokirRekeningScreen({super.key});

  @override
  State<BlokirRekeningScreen> createState() => _BlokirRekeningScreenState();
}

class _BlokirRekeningScreenState extends State<BlokirRekeningScreen> {
  late bool _isBlocked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isBlocked = SessionStorage.cachedNasabah?.isBlocked ?? false;
  }

  Future<void> _freezeAccount() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Blokir Rekening Darurat',
      message:
          'Rekening akan dibekukan sementara di sistem pusat backend. Seluruh penarikan tunai di loket Teller akan ditolak sampai rekening diaktifkan kembali oleh Administrator Bank Mini.',
      confirmLabel: 'Blokir Rekening Sekarang',
      isDanger: true,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final res = await NasabahApiService.emergencyFreeze(
        alasan: 'Pemblokiran mandiri via Mobile App (Kehilangan kartu/QR)',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (res.success) {
        setState(() {
          _isBlocked = true;
        });

        // Update cached nasabah state to NONAKTIF
        final cached = SessionStorage.cachedNasabah;
        if (cached != null) {
          final updated = cached.copyWith(status: 'NONAKTIF');
          await SessionStorage.saveNasabah(updated);
        }

        if (!mounted) return;
        showAppSnackbar(
          context,
          'Rekening berhasil dibekukan untuk keamanan! Transaksi penarikan telah dinonaktifkan.',
          isError: true,
        );
      } else {
        showAppSnackbar(
          context,
          res.message.isNotEmpty
              ? res.message
              : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showAppSnackbar(
        context,
        'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        isError: true,
      );
    }
  }

  void _showUnfreezeInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.primaryNavy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Prosedur Buka Blokir',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Sesuai Standar Operasional Prosedur SOP-09 Keamanan Perbankan Sekolah:\n\n'
          '1. Rekening yang telah dibekukan darurat tidak dapat dibuka kembali secara mandiri di aplikasi.\n'
          '2. Siswa pemilik rekening wajib hadir langsung ke loket Bank Mini SMK Negeri 1 Bantul.\n'
          '3. Tunjukkan Kartu Pelajar asli dan sebutkan NIS kepada Administrator Bank Mini untuk verifikasi identitas.\n'
          '4. Administrator akan membuka blokir melalui modul Back-Office Bank Mini.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          PrimaryButton(
            text: 'Hubungi Admin via WA',
            icon: Icons.chat_outlined,
            onPressed: () {
              Navigator.pop(ctx);
              openWhatsAppAdmin(context: context);
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
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
      appBar: AppBar(
        title: Text(
          'Blokir Rekening Darurat',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Action Button
              if (!_isBlocked)
                PrimaryButton(
                  text: 'Blokir Rekening Sekarang',
                  icon: Icons.shield_rounded,
                  backgroundColor: AppColors.danger,
                  textColor: Colors.white,
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _freezeAccount,
                )
              else
                PrimaryButton(
                  text: 'Ajukan Buka Blokir ke Petugas',
                  icon: Icons.support_agent_rounded,
                  backgroundColor: AppColors.primaryNavy,
                  textColor: Colors.white,
                  onPressed: _showUnfreezeInfo,
                ),
              const SizedBox(height: 20),

              // Info Section
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isBlocked
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (_isBlocked ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isBlocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
              color: _isBlocked ? AppColors.danger : AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isBlocked ? 'STATUS REKENING: DIBLOKIR' : 'STATUS REKENING: AKTIF',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _isBlocked ? AppColors.danger : AppColors.success,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isBlocked
                ? 'Rekening Anda telah dibekukan sementara di database Bank Mini. Seluruh transaksi penarikan tunai di loket teller ditolak secara otomatis untuk melindungi simpanan Anda.'
                : 'Rekening Anda dalam kondisi aktif & normal. Seluruh transaksi setor dan tarik tunai dapat dilakukan di loket Teller.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryNavy,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Protokol Keamanan (SOP-09)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoItem(
            Icons.credit_card_off_outlined,
            'Jika kartu fisik digital atau QR Code Anda hilang atau tercecer, segera aktifkan fitur blokir darurat.',
          ),
          _infoItem(
            Icons.block_outlined,
            'Selama status rekening diblokir, transaksi penarikan di loket teller manapun akan otomatis ditolak oleh sistem perbankan.',
          ),
          _infoItem(
            Icons.savings_outlined,
            'Setoran tabungan tetap dapat diterima oleh loket Teller agar tabungan Anda tetap aman bertambah.',
          ),
          _infoItem(
            Icons.support_agent_outlined,
            'Kunjungi loket Administrator Bank Mini Sekolah dengan membawa Kartu Pelajar fisik jika ingin mengaktifkan kembali rekening Anda.',
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primaryNavy, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
