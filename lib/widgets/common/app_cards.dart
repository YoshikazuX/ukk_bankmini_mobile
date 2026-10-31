import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';

enum StatusBadgeType { success, warning, danger, info }

/// Badge Status Transaksi & Kehadiran Perbankan (No Slop, Clean Hairline)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final StatusBadgeType? type;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
    this.type,
  });

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppColors.success,
      backgroundColor: AppColors.successBg,
      icon: icon ?? Icons.check_circle_rounded,
      type: StatusBadgeType.success,
    );
  }

  factory StatusBadge.warning(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppColors.warning,
      backgroundColor: AppColors.warningBg,
      icon: icon ?? Icons.schedule_rounded,
      type: StatusBadgeType.warning,
    );
  }

  factory StatusBadge.danger(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppColors.danger,
      backgroundColor: AppColors.dangerBg,
      icon: icon ?? Icons.cancel_rounded,
      type: StatusBadgeType.danger,
    );
  }

  factory StatusBadge.info(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppColors.info,
      backgroundColor: AppColors.infoBg,
      icon: icon ?? Icons.info_rounded,
      type: StatusBadgeType.info,
    );
  }

  Color get effectiveColor {
    if (color != null) return color!;
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.success;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.danger:
        return AppColors.danger;
      case StatusBadgeType.info:
      default:
        return AppColors.info;
    }
  }

  Color get effectiveBackgroundColor {
    if (backgroundColor != null) return backgroundColor!;
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.successBg;
      case StatusBadgeType.warning:
        return AppColors.warningBg;
      case StatusBadgeType.danger:
        return AppColors.dangerBg;
      case StatusBadgeType.info:
      default:
        return AppColors.infoBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = effectiveColor;
    final activeBg = effectiveBackgroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: activeColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: activeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: activeColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Balance Card Hero Nasabah Siswa (Green Primary - Solid Flat, No Gradients)
class BalanceCard extends StatelessWidget {
  final String namaNasabah;
  final String noRekening;
  final double totalSaldo;
  final double saldoMinimum;
  final bool isFrozen;
  final VoidCallback? onTopUp;
  final VoidCallback? onHistory;
  final VoidCallback? onQrCode;

  const BalanceCard({
    super.key,
    required this.namaNasabah,
    required this.noRekening,
    required this.totalSaldo,
    this.saldoMinimum = 10000.0,
    this.isFrozen = false,
    this.onTopUp,
    this.onHistory,
    this.onQrCode,
  });

  @override
  Widget build(BuildContext context) {
    final saldoDapatDigunakan = (totalSaldo - saldoMinimum).clamp(0, double.infinity).toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentTealHover, width: 1),
        boxShadow: AppColors.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Brand Logo & Status Rekening
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/images/SMK_Negeri_1_Bantul_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LKM MITRA SISWA ABADI',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isFrozen ? AppColors.danger : AppColors.textOnGreen).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFrozen ? 'TERBLOKIR' : 'AKTIF',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isFrozen ? AppColors.danger : AppColors.textOnGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),

          // Body: Saldo & Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Efektif Tersedia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOnGreen.withValues(alpha: 0.75),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: noRekening));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nomor rekening $noRekening disalin'),
                            backgroundColor: AppColors.primaryNavy,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            noRekening,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 13, color: AppColors.textOnGreen),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(totalSaldo),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Dapat ditarik: ${formatRupiah(saldoDapatDigunakan)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textOnGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' • Min. simpanan: ${formatRupiah(saldoMinimum)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textOnGreen.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.receipt_long_rounded, 'Riwayat Mutasi', onHistory),
                _buildQuickAction(Icons.qr_code_rounded, 'QR Rekening', onQrCode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textOnGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistic Card Bersih untuk Ringkasan Teller & Supervisor (No Gradients)
class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.accentTealHover,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris Item Transaksi Bersih & Mudah Dipindai (Jenius Reference Layout)
class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isDebit; // true = keluar (-), false = masuk (+)
  final String? status;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDebit,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isDebit ? AppColors.danger : AppColors.success;
    final sign = isDebit ? '- ' : '+ ';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDebit
                    ? AppColors.dangerBg
                    : AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: amountColor,
                size: 18,
              ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${formatRupiah(amount)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
                if (status != null && status!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    status!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
