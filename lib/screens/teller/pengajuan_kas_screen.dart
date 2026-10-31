import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_cards.dart';
import '../../widgets/common/app_inputs.dart';

/// Halaman Pengajuan Droping Kas / Modal Loket Teller ke Supervisor
class PengajuanKasScreen extends StatefulWidget {
  const PengajuanKasScreen({super.key});

  @override
  State<PengajuanKasScreen> createState() => _PengajuanKasScreenState();
}

class _PengajuanKasScreenState extends State<PengajuanKasScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _pengajuanList = [];

  @override
  void initState() {
    super.initState();
    _fetchPengajuan();
  }

  Future<void> _fetchPengajuan() async {
    setState(() => _isLoading = true);
    final res = await TellerApiService.getPengajuanKas();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.data != null) {
        _summary = res.data!['summary'] as Map<String, dynamic>?;
        final rawList = res.data!['data'] as List<dynamic>? ?? [];
        _pengajuanList = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    });
  }

  void _showBuatPengajuanModal() {
    final nominalController = TextEditingController();
    final alasanController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
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
                    'Pengajuan Droping Kas Loket',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kirim permintaan penambahan kas fisik laci loket ke Supervisor',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nominal Kas Tambahan (Rp)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      hintText: '500.000',
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
                  const SizedBox(height: 14),
                  InputField(
                    controller: alasanController,
                    label: 'Alasan Kebutuhan Kas',
                    hint: 'Contoh: Kas laci menipis karena antrean penarikan siswa tinggi',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Kirim Pengajuan ke Supervisor',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final nominalText = nominalController.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            final nominal = double.tryParse(nominalText) ?? 0;
                            final alasan = alasanController.text.trim();

                            if (nominal < 10000) {
                              showAppSnackbar(
                                context,
                                'Nominal minimal Rp 10.000',
                                isError: true,
                              );
                              return;
                            }
                            if (alasan.isEmpty) {
                              showAppSnackbar(
                                context,
                                'Alasan pengajuan wajib diisi',
                                isError: true,
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final res = await TellerApiService.kirimPengajuanKas(
                              nominal: nominal,
                              alasan: alasan,
                            );

                            if (bottomCtx.mounted) {
                              Navigator.pop(bottomCtx);
                            }
                            if (!mounted) return;

                            if (res.success) {
                              showAppSnackbar(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Pengajuan kas berhasil dikirim!',
                              );
                              _fetchPengajuan();
                            } else {
                              showAppSnackbar(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Gagal mengirim pengajuan kas',
                                isError: true,
                              );
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasTersedia =
        (_summary?['kas_tersedia_laci'] as num?)?.toDouble() ?? 2250000.0;
    final kasAwal =
        (_summary?['kas_awal_hari_ini'] as num?)?.toDouble() ?? 2000000.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Droping & Pengajuan Kas',
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
        child: RefreshIndicator(
          color: AppColors.accentTeal,
          backgroundColor: AppColors.surface,
          onRefresh: _fetchPengajuan,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Kas Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modal Kas Awal',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRupiah(kasAwal),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Kas Tersedia di Laci',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRupiah(kasTersedia),
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
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Ajukan Droping Kas Baru',
                      icon: Icons.add_rounded,
                      onPressed: _showBuatPengajuanModal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Pengajuan Kas',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_pengajuanList.length} tiket',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentTeal,
                    ),
                  ),
                )
              else if (_pengajuanList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada tiket pengajuan kas yang diajukan.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._pengajuanList.map((item) => _buildTicketCard(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final nominal = (item['nominal'] as num?)?.toDouble() ?? 0.0;

    StatusBadgeType badgeType;
    String statusLabel;
    if (status == 'disetujui') {
      badgeType = StatusBadgeType.success;
      statusLabel = 'Disetujui';
    } else if (status == 'ditolak') {
      badgeType = StatusBadgeType.danger;
      statusLabel = 'Ditolak';
    } else {
      badgeType = StatusBadgeType.warning;
      statusLabel = 'Menunggu SPV';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['nomor_pengajuan'] ?? '#PK-REQ',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
              StatusBadge(label: statusLabel, type: badgeType),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(nominal),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['alasan'] ?? '-',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (item['catatan_spv'] != null &&
              item['catatan_spv'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan SPV: ${item['catatan_spv']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
