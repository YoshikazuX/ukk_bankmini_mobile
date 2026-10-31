import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/petugas_model.dart';
import '../../services/auth_service.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_cards.dart';
import '../../widgets/common/app_states.dart';
import '../login_screen.dart';
import 'daily_report_screen.dart';
import 'pengajuan_kas_screen.dart';
import 'scan_nasabah_screen.dart';
import 'setor_tunai_screen.dart';
import 'tarik_tunai_screen.dart';

/// Shell Navigasi & POS Terminal Loket Teller (Bank Mini Sekolah)
class TellerMainScreen extends StatefulWidget {
  final PetugasModel? petugas;

  const TellerMainScreen({super.key, this.petugas});

  @override
  State<TellerMainScreen> createState() => _TellerMainScreenState();
}

class _TellerMainScreenState extends State<TellerMainScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _kasStatus;
  Map<String, dynamic>? _todayTransactions;

  @override
  void initState() {
    super.initState();
    _fetchTellerData();
  }

  Future<void> _fetchTellerData() async {
    setState(() => _isLoading = true);
    try {
      final kasRes = await TellerApiService.getStatusKas();
      final trxRes = await TellerApiService.getTransaksiHariIni();

      if (!mounted) return;
      setState(() {
        _kasStatus = kasRes.data;
        _todayTransactions = trxRes.data;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cached = SessionStorage.cachedPetugas;
    final namaPetugas = widget.petugas?.namaPetugas ?? cached?.namaPetugas ?? 'Petugas Loket Teller';
    final kelas = widget.petugas?.kelas ?? cached?.kelas ?? 'Loket Operasional';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 2),
          child: Image.asset(
            'assets/images/SMK_Negeri_1_Bantul_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TELLER POS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTealHover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  namaPetugas,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              'Loket Aktif: $kelas • Sistem Kasir Bank Mini',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Segarkan Data Loket',
                  onPressed: _fetchTellerData,
                ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 20),
            tooltip: 'Logout Teller',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.point_of_sale_rounded, 'Kasir POS'),
                _buildNavItem(1, Icons.history_rounded, 'Riwayat'),
                _buildNavItem(2, Icons.request_quote_rounded, 'Pengajuan Kas'),
                _buildNavItem(3, Icons.event_note_rounded, 'Tutup Kas'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPosDashboard();
      case 1:
        return _buildHistoryTab();
      case 2:
        return const PengajuanKasScreen();
      case 3:
      default:
        return const DailyReportScreen();
    }
  }

  // =========================================================================
  // TAB 0: DASHBOARD OPERASIONAL LOKET TELLER
  // =========================================================================
  Widget _buildPosDashboard() {
    final kasTersedia = (_kasStatus?['kas_tersedia'] as num?)?.toDouble() ?? 2250000.0;
    final saldoAwal = (_kasStatus?['saldo_awal'] as num?)?.toDouble() ?? 2000000.0;
    final List<dynamic> trxList = _todayTransactions?['data'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      color: AppColors.accentTealHover,
      backgroundColor: AppColors.surface,
      onRefresh: _fetchTellerData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Kas Fisik Laci (Primary Navy Hero)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accentTeal,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentTealHover, width: 1),
              boxShadow: AppColors.heroShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUS KAS FISIK LACI LOKET',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Online POS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(kasTersedia),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modal Kas Awal: ${formatRupiah(saldoAwal)} • Siap Melayani Nasabah',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textOnGreen.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kehadiran Petugas Banner (Read-only per batasan role)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Presensi Petugas: Hadir • Shift Pagi (07:30 - 11:30 WIB)',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Layanan Operasional Loket (2x2 Grid)
          Text(
            'Layanan Transaksi Loket',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Setoran Tunai',
                  subtitle: 'Kode Sandi [101]',
                  color: AppColors.success,
                  onTap: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const SetorTunaiScreen()),
                    );
                    if (res == true) _fetchTellerData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Penarikan Tunai',
                  subtitle: 'Kode Sandi [201]',
                  color: AppColors.danger,
                  onTap: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const TarikTunaiScreen()),
                    );
                    if (res == true) _fetchTellerData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan QR Siswa',
                  subtitle: 'Pindai Kartu Digital',
                  color: AppColors.accentTealHover,
                  onTap: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanNasabahScreen()),
                    );
                    if (res == true) _fetchTellerData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.search_rounded,
                  title: 'Cari Nasabah',
                  subtitle: 'Inquiry by NIS / Rek',
                  color: const Color(0xFF1E3A8A),
                  onTap: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanNasabahScreen()),
                    );
                    if (res == true) _fetchTellerData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transaksi Loket Terkini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Loket Hari Ini',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentTealHover),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (trxList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  'Belum ada transaksi loket yang diproses hari ini.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trxList.take(5).length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trx = trxList[index] as Map<String, dynamic>;
                final jenis = trx['jenis']?.toString().toLowerCase() ?? 'setor';
                final isDebit = jenis == 'tarik';
                final nominal = (trx['nominal'] as num?)?.toDouble() ?? 0;
                final namaSiswa = trx['nama_siswa']?.toString() ?? 'Siswa';
                final jam = trx['jam']?.toString() ?? '-';
                final kode = trx['kode_sandi']?.toString() ?? (isDebit ? '201' : '101');

                return TransactionItem(
                  title: '$namaSiswa • [$kode]',
                  subtitle: '$jam • ${trx['keterangan'] ?? (isDebit ? "Penarikan Tunai" : "Setoran Tunai")}',
                  amount: nominal,
                  isDebit: isDebit,
                  status: 'Sukses',
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOperationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: RIWAYAT TRANSAKSI LOKET HARI INI
  // =========================================================================
  Widget _buildHistoryTab() {
    final List<dynamic> trxList = _todayTransactions?['data'] as List<dynamic>? ?? [];

    return Column(
      children: [
        PageHeader(
          title: 'Riwayat Transaksi Loket',
          subtitle: 'Daftar seluruh setoran dan penarikan yang diproses hari ini',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              tooltip: 'Segarkan',
              onPressed: _fetchTellerData,
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accentTealHover,
            backgroundColor: AppColors.surface,
            onRefresh: _fetchTellerData,
            child: trxList.isEmpty
                ? const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Belum Ada Transaksi',
                    message: 'Transaksi setoran dan penarikan loket akan muncul di sini.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: trxList.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final trx = trxList[index] as Map<String, dynamic>;
                      final jenis = trx['jenis']?.toString().toLowerCase() ?? 'setor';
                      final isDebit = jenis == 'tarik';
                      final nominal = (trx['nominal'] as num?)?.toDouble() ?? 0;
                      final namaSiswa = trx['nama_siswa']?.toString() ?? 'Siswa';
                      final jam = trx['jam']?.toString() ?? '-';
                      final kode = trx['kode_sandi']?.toString() ?? (isDebit ? '201' : '101');

                      return TransactionItem(
                        title: '$namaSiswa • [$kode]',
                        subtitle: '$jam • ${trx['keterangan'] ?? (isDebit ? "Penarikan Tunai" : "Setoran Tunai")}',
                        amount: nominal,
                        isDebit: isDebit,
                        status: 'Sukses',
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar dari sesi loket kasir Teller?',
      confirmLabel: 'Ya, Logout',
      confirmColor: AppColors.danger,
      confirmTextColor: Colors.white,
    ).then((confirmed) async {
      if (confirmed == true) {
        await AuthService.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    });
  }
}
