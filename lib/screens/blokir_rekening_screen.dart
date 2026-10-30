import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_states.dart';

/// Halaman Blokir Rekening Darurat (Emergency Account Freeze)
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

  Future<void> _toggleBlock() async {
    final title = _isBlocked ? 'Konfirmasi Buka Blokir Rekening' : 'Konfirmasi Blokir Rekening Darurat';
    final message = _isBlocked
        ? 'Rekening akan diaktifkan kembali. Anda dapat melakukan penarikan dan transaksi tunai di loket seperti biasa.'
        : 'Rekening akan dibekukan sementara. Seluruh penarikan tunai di loket Teller akan ditolak sampai Anda mengaktifkannya kembali.';

    final confirmed = await ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: _isBlocked ? 'Buka Blokir Rekening' : 'Blokir Rekening Sekarang',
      isDanger: !_isBlocked,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _isBlocked = !_isBlocked;
      _isProcessing = false;
    });

    showAppSnackbar(
      context,
      _isBlocked
          ? 'Rekening berhasil dibekukan untuk keamanan!'
          : 'Rekening berhasil dibuka kembali!',
      isError: _isBlocked,
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
              PrimaryButton(
                text: _isBlocked ? 'Buka Blokir Rekening' : 'Blokir Rekening Sekarang',
                icon: _isBlocked ? Icons.lock_open_rounded : Icons.shield_rounded,
                backgroundColor: _isBlocked ? AppColors.success : AppColors.danger,
                textColor: Colors.white,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : _toggleBlock,
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
          color: _isBlocked ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (_isBlocked ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
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
                ? 'Rekening Anda sedang dibekukan sementara. Transaksi penarikan uang di loket tidak dapat dilakukan.'
                : 'Rekening Anda dalam kondisi aktif & normal. Seluruh transaksi setor dan tarik tunai dapat dilakukan.',
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
                'Informasi Protokol Keamanan',
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
            'Selama status rekening diblokir, transaksi penarikan di loket teller manapun akan otomatis ditolak oleh sistem.',
          ),
          _infoItem(
            Icons.savings_outlined,
            'Setoran tunai tetap dapat diterima agar tabungan Anda tetap aman bertambah.',
          ),
          _infoItem(
            Icons.support_agent_outlined,
            'Hubungi Administrator Bank Mini jika memerlukan bantuan pemulihan akses kartu atau akun Anda.',
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
