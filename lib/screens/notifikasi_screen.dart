import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/notifikasi_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_states.dart';

/// Halaman Notifikasi Transaksi Real-Time (In-App Transaction Alert)
/// Menggunakan Backend Laravel API sebagai Single Source of Truth
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<NotifikasiModel> _notifikasi = [];
  String _selectedFilter = 'SEMUA';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await NasabahApiService.getNotifications();
      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _notifikasi = res.data!;
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

  Future<void> _markAllRead() async {
    setState(() {
      for (var n in _notifikasi) {
        n.isRead = true;
      }
    });

    try {
      await NasabahApiService.markAllNotificationsRead();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifikasi.where((n) => !n.isRead).length;

    final filteredNotif = _notifikasi.where((n) {
      if (_selectedFilter == 'SEMUA') return true;
      if (_selectedFilter == 'TRANSAKSI') {
        return n.jenis == 'SETORAN' ||
            n.jenis == 'PENARIKAN' ||
            n.jenis == 'TRANSAKSI';
      }
      if (_selectedFilter == 'KEAMANAN') {
        return n.jenis == 'KEAMANAN' || n.jenis == 'SYSTEM';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Pemberitahuan Transaksi',
            subtitle: 'Catatan aktivitas transaksi dan sistem akun siswa',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(Icons.done_all_rounded,
                      size: 16, color: AppColors.accentTealHover),
                  label: Text(
                    'Tandai Dibaca',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTealHover,
                    ),
                  ),
                ),
            ],
          ),
          // Filter Tabs (Pill style)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _filterChip('SEMUA', 'Semua (${_notifikasi.length})'),
                const SizedBox(width: 8),
                _filterChip('TRANSAKSI', 'Transaksi'),
                const SizedBox(width: 8),
                _filterChip('KEAMANAN', 'Keamanan & Sistem'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Notification List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentTealHover,
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentTealHover,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _errorMessage != null
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: ErrorState(
                              title: 'Gagal Memuat Notifikasi',
                              message: _errorMessage!,
                              onRetry: _loadNotifications,
                            ),
                          ),
                        )
                      : filteredNotif.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                alignment: Alignment.center,
                                child: const EmptyState(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Tidak Ada Notifikasi',
                                  message:
                                      'Semua informasi dan notifikasi transaksi resmi akan muncul di sini.',
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredNotif.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = filteredNotif[index];
                                return _notifikasiCard(notif);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentTealHover : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _notifikasiCard(NotifikasiModel notif) {
    IconData icon;
    Color color;

    switch (notif.jenis) {
      case 'SETORAN':
        icon = Icons.south_west_rounded;
        color = AppColors.success;
        break;
      case 'PENARIKAN':
        icon = Icons.north_east_rounded;
        color = AppColors.danger;
        break;
      case 'KEAMANAN':
        icon = Icons.shield_outlined;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = AppColors.info;
    }

    return GestureDetector(
      onTap: () {
        setState(() => notif.isRead = true);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.surface : AppColors.greenLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : AppColors.accentTealHover.withValues(alpha: 0.3),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                          notif.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                notif.isRead ? FontWeight.w500 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentTealHover,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatWaktuRelatif(notif.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
