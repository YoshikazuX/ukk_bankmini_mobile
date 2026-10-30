import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/badge_model.dart';

/// Halaman Lencana Prestasi Menabung (Gamification Badges)
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  List<BadgeModel> _computeBadges(num saldo) {
    return [
      BadgeModel(
        id: 'badge_1',
        nama: 'First Deposit',
        deskripsi: 'Berhasil melakukan setoran awal tabungan',
        icon: 'savings',
        tier: 'bronze',
        isUnlocked: saldo > 0,
        unlockedAt: saldo > 0 ? DateTime(2026, 10, 26) : null,
      ),
      BadgeModel(
        id: 'badge_2',
        nama: 'Silver Saver',
        deskripsi: 'Mencapai total saldo tabungan Rp 100.000',
        icon: 'military_tech',
        tier: 'silver',
        isUnlocked: saldo >= 100000,
      ),
      BadgeModel(
        id: 'badge_3',
        nama: 'Golden Saver',
        deskripsi: 'Mencapai total saldo tabungan Rp 500.000',
        icon: 'stars',
        tier: 'gold',
        isUnlocked: saldo >= 500000,
      ),
      BadgeModel(
        id: 'badge_4',
        nama: 'Master Saver',
        deskripsi: 'Mencapai total saldo tabungan Rp 1.000.000',
        icon: 'workspace_premium',
        tier: 'gold',
        isUnlocked: saldo >= 1000000,
      ),
      BadgeModel(
        id: 'badge_5',
        nama: 'Disiplin Finansial',
        deskripsi: 'Mencapai total akumulasi simpanan Rp 2.000.000',
        icon: 'verified',
        tier: 'gold',
        isUnlocked: saldo >= 2000000,
      ),
      BadgeModel(
        id: 'badge_6',
        nama: 'Duta Literasi',
        deskripsi: 'Mencapai saldo Rp 5.000.000 dan aktif menabung',
        icon: 'diamond',
        tier: 'gold',
        isUnlocked: saldo >= 5000000,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final saldo = SessionStorage.cachedNasabah?.totalSaldo ?? 0;
    final badges = _computeBadges(saldo);
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Lencana Prestasi',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Card
              _buildStatsCard(unlockedCount, badges.length),
              const SizedBox(height: 20),

              // Unlocked Badges
              Text(
                'Lencana Telah Diraih',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...badges
                  .where((b) => b.isUnlocked)
                  .map((b) => _badgeCard(b, true)),
              const SizedBox(height: 20),

              // Locked Badges
              Text(
                'Tantangan Lencana Berikutnya',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...badges
                  .where((b) => !b.isUnlocked)
                  .map((b) => _badgeCard(b, false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int unlocked, int total) {
    final double percent = total > 0 ? (unlocked / total) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'APRESIASI LITERASI FINANSIAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTeal,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}% Selesai',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Koleksi Lencana Menabung Siswa',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Dapatkan penghargaan atas kedisiplinan dan konsistensi Anda menabung.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lencana Terbuka: $unlocked dari $total',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Level: Penabung Disiplin',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeCard(dynamic badge, bool isUnlocked) {
    Color tierColor;
    String tierLabel;

    switch (badge.tier) {
      case 'gold':
        tierColor = AppColors.badgeGold;
        tierLabel = 'EMAS';
        break;
      case 'silver':
        tierColor = AppColors.badgeSilver;
        tierLabel = 'PERAK';
        break;
      default:
        tierColor = AppColors.badgeBronze;
        tierLabel = 'PERUNGGU';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked ? tierColor.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? tierColor.withValues(alpha: 0.12)
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked ? tierColor.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Center(
              child: Icon(
                isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                color: isUnlocked ? tierColor : AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        badge.nama,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: isUnlocked ? 0.12 : 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tierLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? tierColor : AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  badge.deskripsi,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (isUnlocked && badge.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tercapai: ${formatTanggalSingkat(badge.unlockedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
