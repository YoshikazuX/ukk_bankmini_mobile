import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/badge_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_states.dart';

/// Halaman Lencana Prestasi Menabung (Gamification Badges)
/// Menggunakan Backend Laravel sebagai Single Source of Truth
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<BadgeModel> _badges = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await NasabahApiService.getBadges();
      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _badges = res.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.message.isNotEmpty
              ? res.message
              : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedBadges = _badges.where((b) => b.isUnlocked).toList();
    final lockedBadges = _badges.where((b) => !b.isUnlocked).toList();
    final unlockedCount = unlockedBadges.length;
    final totalCount = _badges.length;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan Lencana',
            onPressed: _fetchBadges,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          onRefresh: _fetchBadges,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryNavy,
                  ),
                )
              : _errorMessage != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: ErrorState(
                          title: 'Gagal Memuat Lencana',
                          message: _errorMessage!,
                          onRetry: _fetchBadges,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Card
                          _buildStatsCard(unlockedCount, totalCount),
                          const SizedBox(height: 20),

                          // Unlocked Badges
                          if (unlockedBadges.isNotEmpty) ...[
                            Text(
                              'Lencana Telah Diraih (${unlockedBadges.length})',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...unlockedBadges.map((b) => _badgeCard(b, true)),
                            const SizedBox(height: 20),
                          ],

                          // Locked Badges
                          if (lockedBadges.isNotEmpty) ...[
                            Text(
                              'Tantangan Lencana Berikutnya (${lockedBadges.length})',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...lockedBadges.map((b) => _badgeCard(b, false)),
                          ],

                          if (_badges.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: EmptyState(
                                icon: Icons.military_tech_outlined,
                                title: 'Belum Ada Data Lencana',
                                message:
                                    'Lencana prestasi akan ditampilkan berdasarkan rekam jejak tabungan Anda.',
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int unlocked, int total) {
    final double percent = total > 0 ? (unlocked / total) : 0.0;
    String level = 'Pemula Menabung';
    if (unlocked >= 5) {
      level = 'Duta Literasi Finansial';
    } else if (unlocked >= 3) {
      level = 'Penabung Disiplin';
    } else if (unlocked >= 1) {
      level = 'Penabung Aktif';
    }

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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
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
                'Level: $level',
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

  Widget _badgeCard(BadgeModel badge, bool isUnlocked) {
    Color tierColor;
    String tierLabel;

    switch (badge.tier.toLowerCase()) {
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
          color: isUnlocked
              ? tierColor.withValues(alpha: 0.35)
              : AppColors.border,
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
                color: isUnlocked
                    ? tierColor.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Center(
              child: Icon(
                isUnlocked
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor
                            .withValues(alpha: isUnlocked ? 0.12 : 0.05),
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
