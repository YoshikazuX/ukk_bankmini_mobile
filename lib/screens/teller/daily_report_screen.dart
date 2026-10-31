import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';

/// Halaman Penutupan Kas Harian (Daily Report Closing) Loket Teller
class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _physicalBalanceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchDailyReportStatus();
  }

  @override
  void dispose() {
    _physicalBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDailyReportStatus() async {
    setState(() => _isLoading = true);
    final res = await TellerApiService.getStatusDailyReport();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.data != null) {
        _reportData = res.data;
        if (_reportData!['is_submitted'] == true &&
            _reportData!['report'] != null) {
          final rep = _reportData!['report'] as Map<String, dynamic>;
          final phys = (rep['physical_balance'] as num?)?.toDouble() ?? 0.0;
          _physicalBalanceController.text = phys.toInt().toString();
          _notesController.text = rep['notes'] ?? '';
        }
      }
    });
  }

  void _submitDailyReport() async {
    final physText =
        _physicalBalanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double physical = double.tryParse(physText) ?? 0;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Closing Kas Harian',
      message:
          'Setelah laporan dikirim, loket kasir akan terkunci sampai diverifikasi oleh Supervisor.',
      confirmLabel: 'Kirim Laporan Closing',
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final res = await TellerApiService.submitDailyReport(
      physicalBalance: physical,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Closing kas harian teller loket selesai',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      showAppSnackbar(
        context,
        res.message.isNotEmpty
            ? res.message
            : 'Laporan kas harian berhasil disubmit!',
      );
      _fetchDailyReportStatus();
    } else {
      showAppSnackbar(
        context,
        res.message.isNotEmpty
            ? res.message
            : 'Gagal mengirim laporan tutup kas!',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final opening =
        (_reportData?['opening_balance'] as num?)?.toDouble() ?? 2000000.0;
    final deposit =
        (_reportData?['total_deposit'] as num?)?.toDouble() ?? 350000.0;
    final withdrawal =
        (_reportData?['total_withdrawal'] as num?)?.toDouble() ?? 100000.0;
    final systemBalance =
        (_reportData?['system_balance'] as num?)?.toDouble() ?? 2250000.0;
    final isSubmitted = _reportData?['is_submitted'] == true;

    final double enteredPhysical = double.tryParse(
          _physicalBalanceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0.0;
    final double difference = enteredPhysical - systemBalance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Closing Kas Harian Loket',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentTeal),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    if (isSubmitted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_clock_rounded,
                              color: AppColors.warning,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Tutup Kas Sudah Dikirim',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Menunggu verifikasi fisik & persetujuan dari Supervisor.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // System Balance Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekapitulasi Sistem Hari Ini',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Divider(color: AppColors.border, height: 20),
                          _rekapRow(
                            'Saldo Awal Modal Kas',
                            formatRupiah(opening),
                          ),
                          _rekapRow(
                            'Total Setoran Tunai (+)',
                            formatRupiah(deposit),
                            valueColor: AppColors.success,
                          ),
                          _rekapRow(
                            'Total Penarikan Tunai (-)',
                            formatRupiah(withdrawal),
                            valueColor: AppColors.danger,
                          ),
                          const Divider(color: AppColors.border, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo Kas Menurut Sistem',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                formatRupiah(systemBalance),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Saldo Fisik Aktual Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hitung Fisik Uang di Laci (Aktual)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _physicalBalanceController,
                            enabled: !isSubmitted,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                            decoration: InputDecoration(
                              prefixText: 'Rp  ',
                              prefixStyle: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                              hintText: '0',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 20,
                                color: AppColors.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
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
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_physicalBalanceController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: difference == 0
                                    ? AppColors.success.withValues(alpha: 0.08)
                                    : AppColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: difference == 0
                                      ? AppColors.success.withValues(alpha: 0.25)
                                      : AppColors.danger.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        difference == 0
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_rounded,
                                        color: difference == 0
                                            ? AppColors.success
                                            : AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        difference == 0
                                            ? 'Status: Sesuai (Balance)'
                                            : (difference > 0
                                                ? 'Status: Selisih Lebih'
                                                : 'Status: Selisih Kurang'),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: difference == 0
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${difference >= 0 ? '+' : ''}${formatRupiah(difference)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: difference == 0
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          InputField(
                            controller: _notesController,
                            label: 'Catatan Closing & Berita Acara',
                            hint: 'Catatan penutupan loket atau rekonsiliasi kas...',
                            maxLines: 3,
                            enabled: !isSubmitted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    if (!isSubmitted)
                      PrimaryButton(
                        label: 'Kirim Laporan Tutup Kas',
                        icon: Icons.send_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submitDailyReport,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _rekapRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
