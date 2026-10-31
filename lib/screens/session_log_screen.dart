import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/session_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_states.dart';

/// Halaman Riwayat Sesi Login (Active Session & Device Log)
/// Menggunakan Backend Laravel Sanctum sebagai Single Source of Truth
class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({super.key});

  @override
  State<SessionLogScreen> createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await NasabahApiService.getSessionLogs();
      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _sessions = res.data!;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Riwayat Sesi Login',
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
            tooltip: 'Segarkan Sesi',
            onPressed: _fetchSessions,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          onRefresh: _fetchSessions,
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
                          title: 'Gagal Memuat Sesi',
                          message: _errorMessage!,
                          onRetry: _fetchSessions,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.security_outlined,
                                    color: AppColors.primaryNavy,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Audit Keamanan Perangkat',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Daftar sesi terotentikasi Laravel Sanctum yang terhubung ke akun Anda.',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Perangkat & Sesi Terdaftar (${_sessions.length})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (_sessions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: EmptyState(
                                icon: Icons.devices_outlined,
                                title: 'Belum Ada Riwayat Sesi',
                                message:
                                    'Sesi aktif Anda akan dicatat di server backend Laravel.',
                              ),
                            )
                          else
                            ..._sessions.map((session) => _sessionCard(session)),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _sessionCard(SessionModel session) {
    IconData deviceIcon;
    switch (session.deviceType.toLowerCase()) {
      case 'android':
        deviceIcon = Icons.phone_android_rounded;
        break;
      case 'ios':
        deviceIcon = Icons.phone_iphone_rounded;
        break;
      case 'windows':
        deviceIcon = Icons.laptop_windows_rounded;
        break;
      default:
        deviceIcon = Icons.devices_rounded;
    }

    final isCurrent = session.isCurrentSession;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.accentTeal.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.accentTeal.withValues(alpha: 0.12)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  deviceIcon,
                  color: isCurrent
                      ? AppColors.primaryNavy
                      : AppColors.textSecondary,
                  size: 20,
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
                            session.deviceName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent)
                          const StatusBadge(
                            label: 'Sesi Aktif Ini',
                            type: StatusBadgeType.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Terakhir aktif: ${formatWaktuRelatif(session.lastAccess)}',
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.router_outlined,
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          session.ipAddress.isNotEmpty
                              ? session.ipAddress
                              : 'IP Terotentikasi',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.location.isNotEmpty
                              ? session.location
                              : 'Bank Mini Sekolah',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
