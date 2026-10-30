import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/session_model.dart';
import '../widgets/common/app_cards.dart';

/// Halaman Riwayat Sesi Login (Active Session & Device Log)
class SessionLogScreen extends StatelessWidget {
  const SessionLogScreen({super.key});

  List<SessionModel> _getActiveDeviceSessions() {
    String deviceType = 'web';
    String deviceName = 'Web Browser (Sesi Aktif)';
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        deviceType = 'android';
        deviceName = 'Android Device (Aplikasi Resmi)';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
        deviceName = 'iOS Device (Aplikasi Resmi)';
      } else if (Platform.isWindows) {
        deviceType = 'windows';
        deviceName = 'Windows Workstation (Aplikasi Resmi)';
      }
    }

    return [
      SessionModel(
        id: 'sess_current',
        deviceName: deviceName,
        deviceType: deviceType,
        ipAddress: 'Koneksi Terotentikasi Sanctum',
        location: 'Lingkungan Bank Mini Sekolah',
        lastAccess: DateTime.now(),
        isCurrentSession: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _getActiveDeviceSessions();

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Daftar perangkat yang terhubung ke akun Anda. Segera laporkan jika terdapat aktivitas tak dikenal.',
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
                'Perangkat & Sesi Terdaftar',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              ...sessions.map((session) => _sessionCard(session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionCard(dynamic session) {
    IconData deviceIcon;
    switch (session.deviceType) {
      case 'android':
        deviceIcon = Icons.phone_android_rounded;
        break;
      case 'ios':
        deviceIcon = Icons.phone_iphone_rounded;
        break;
      default:
        deviceIcon = Icons.laptop_mac_rounded;
    }

    final isCurrent = session.isCurrentSession;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.accentTeal.withValues(alpha: 0.5) : AppColors.border,
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
                  color: isCurrent ? AppColors.primaryNavy : AppColors.textSecondary,
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
                      Text(
                        session.ipAddress,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
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
                          session.location,
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
