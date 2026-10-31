import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/petugas_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_cards.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';
import '../login_screen.dart';

/// Shell Navigasi Utama untuk Role: Administrator Utama (System & Infrastructure)
/// Menggunakan Backend Laravel API sebagai Single Source of Truth — Zero Dummy Data
class AdminMainScreen extends StatefulWidget {
  final PetugasModel? petugas;

  const AdminMainScreen({super.key, this.petugas});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  String _serverStatus = 'Memeriksa server...';
  bool _isHealthy = false;
  String _activeBaseUrl = '';
  int _responseTimeMs = 0;
  bool _isChecking = false;

  // State Kehadiran Petugas dari Backend API
  List<Map<String, dynamic>> _staffAttendance = [];
  bool _isLoadingStaff = false;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    _checkServer();
    _fetchStaffAttendance();
  }

  Future<void> _checkServer() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    final url = await SessionStorage.getBaseUrl();
    final stopwatch = Stopwatch()..start();
    final res = await ApiClient.instance.get(ApiConstants.health);
    stopwatch.stop();

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _activeBaseUrl = url;
      _responseTimeMs = stopwatch.elapsedMilliseconds;
      _isHealthy = res.success;
      _serverStatus = res.success
          ? 'Server Laravel Aktif & Terhubung (MySQL Online)'
          : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan.';
    });
  }

  Future<void> _fetchStaffAttendance() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStaff = true;
      _staffError = null;
    });

    try {
      final res = await ApiClient.instance.get(ApiConstants.avalisAbsensi);
      if (!mounted) return;

      if (res.success && res.data != null) {
        List<dynamic> items = [];
        if (res.data is Map<String, dynamic>) {
          final dataMap = res.data as Map<String, dynamic>;
          if (dataMap['data'] is Map<String, dynamic> &&
              dataMap['data']['items'] is List) {
            items = dataMap['data']['items'];
          } else if (dataMap['items'] is List) {
            items = dataMap['items'];
          } else if (dataMap['data'] is List) {
            items = dataMap['data'];
          }
        } else if (res.data is List) {
          items = res.data;
        }

        setState(() {
          _staffAttendance = items
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoadingStaff = false;
        });
      } else {
        setState(() {
          _staffError = res.message.isNotEmpty
              ? res.message
              : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
          _isLoadingStaff = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _staffError =
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
        _isLoadingStaff = false;
      });
    }
  }

  void _showChangeBaseUrlDialog() {
    final ctrl = TextEditingController(text: _activeBaseUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dns_outlined,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Konfigurasi Base URL',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ganti alamat server backend Laravel:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            InputField(
              controller: ctrl,
              hint: 'http://192.168.1.x:8000/api',
              prefixIcon: Icons.link_rounded,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Batal',
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Simpan & Uji',
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    if (ctrl.text.trim().isNotEmpty) {
                      await SessionStorage.setBaseUrl(ctrl.text.trim());
                      await ApiClient.instance.updateBaseUrl();
                      if (mounted) {
                        showAppSnackbar(
                            context, 'Base URL berhasil diperbarui!');
                        _checkServer();
                        _fetchStaffAttendance();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = SessionStorage.cachedPetugas;
    final namaPetugas = widget.petugas?.namaPetugas ??
        cached?.namaPetugas ??
        'Administrator Utama';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: Padding(
          padding:
              const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 2),
          child: Image.asset(
            'assets/images/SMK_Negeri_1_Bantul_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 8,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'ADMINISTRATOR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF87171),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    namaPetugas,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Pengawas Sistem & Infrastruktur Bank Mini',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentTeal,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Uji Latensi Server',
            onPressed: () {
              _checkServer();
              _fetchStaffAttendance();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Logout Admin',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card Server
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHealthy ? AppColors.accentTeal : AppColors.danger,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color:
                              _isHealthy ? AppColors.success : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serverStatus,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Base URL: $_activeBaseUrl',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_suggest_outlined,
                          color: AppColors.primaryNavy,
                          size: 20,
                        ),
                        tooltip: 'Ubah Base URL',
                        onPressed: _showChangeBaseUrlDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latensi Jaringan:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _isHealthy ? '$_responseTimeMs ms' : 'N/A (Offline)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              _isHealthy ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Manajemen Presensi & Shift Petugas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manajemen Presensi & Shift Petugas',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Shift Pagi & Siang',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoadingStaff)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryNavy,
                  ),
                ),
              )
            else if (_staffError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _staffError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchStaffAttendance,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (_staffAttendance.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Belum ada data presensi petugas hari ini.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _staffAttendance.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final staff = _staffAttendance[idx];
                  final nama = staff['nama']?.toString() ??
                      staff['user']?['nama_petugas']?.toString() ??
                      'Petugas Loket';
                  final status = staff['status']?.toString() ?? 'Hadir';
                  final shift = staff['shift_jaga']?.toString() ??
                      staff['shift']?.toString() ??
                      'Shift Pagi';
                  final jamMasuk = staff['jam_masuk']?.toString() ?? '-';

                  StatusBadgeType bType;
                  if (status == 'Hadir') {
                    bType = StatusBadgeType.success;
                  } else if (status == 'Izin') {
                    bType = StatusBadgeType.warning;
                  } else {
                    bType = StatusBadgeType.danger;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          name: nama,
                          size: 36,
                          backgroundColor: AppColors.primaryNavy,
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$shift • Masuk: $jamMasuk',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(label: status, type: bType),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Arsitektur RBAC Bank Mini
            Text(
              'Arsitektur Role-Based Access Control (RBAC)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _buildRbacRow(
              role: 'ADMINISTRATOR',
              badgeColor: AppColors.danger,
              credential: 'admin / admin123',
              desc:
                  'Manajemen server, konfigurasi global, audit log transaksi',
            ),
            const SizedBox(height: 8),
            _buildRbacRow(
              role: 'SUPERVISOR',
              badgeColor: AppColors.warning,
              credential: 'spv1 / spv123',
              desc:
                  'Approval tiket droping kas loket & verifikasi daily report',
            ),
            const SizedBox(height: 8),
            _buildRbacRow(
              role: 'TELLER LOKET',
              badgeColor: AppColors.accentTeal,
              credential: 'teller1 / teller123',
              desc: 'Mobile POS transaksi Setoran [101] & Penarikan [201]',
            ),
            const SizedBox(height: 8),
            _buildRbacRow(
              role: 'NASABAH SISWA',
              badgeColor: AppColors.info,
              credential: 'Handa / password123',
              desc: 'Mobile banking: cek saldo, mutasi tabungan & QRIS',
            ),
            const SizedBox(height: 20),

            // Spesifikasi Sistem
            Text(
              'Spesifikasi Mesin & Environment',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _buildSpecTile('Backend Framework', 'Laravel 13 (PHP 8.2+)'),
            const SizedBox(height: 6),
            _buildSpecTile('Database Engine', 'MySQL / MariaDB (db_bankmini)'),
            const SizedBox(height: 6),
            _buildSpecTile('Autentikasi Token', 'Laravel Sanctum Bearer Token'),
            const SizedBox(height: 6),
            _buildSpecTile(
                'HTTP Client Library', 'Dio v5.11.1 (Interceptors & Retry)'),
            const SizedBox(height: 6),
            _buildSpecTile(
                'Scanner Engine', 'mobile_scanner v7.4.2 (Native Barcode)'),
            const SizedBox(height: 6),
            _buildSpecTile('Aturan Saldo Minimal', 'Rp 10.000 mengendap di rekening'),
          ],
        ),
      ),
    );
  }

  Widget _buildRbacRow({
    required String role,
    required Color badgeColor,
    required String credential,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              role,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kredensial: $credential',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
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
    );
  }

  Widget _buildSpecTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin mengakhiri sesi Administrator?',
      confirmLabel: 'Logout',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
