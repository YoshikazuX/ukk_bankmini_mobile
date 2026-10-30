import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/petugas_model.dart';
import '../../services/auth_service.dart';
import '../../services/supervisor_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_cards.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';
import '../login_screen.dart';

/// Shell Navigasi Utama & Layanan Otorisasi Supervisor Bank Mini
class SupervisorMainScreen extends StatefulWidget {
  final PetugasModel? petugas;

  const SupervisorMainScreen({super.key, this.petugas});

  @override
  State<SupervisorMainScreen> createState() => _SupervisorMainScreenState();
}

class _SupervisorMainScreenState extends State<SupervisorMainScreen> {
  int _currentIndex = 0;

  // State Tab 0: Ringkasan
  bool _isLoadingDashboard = false;
  Map<String, dynamic>? _ringkasanData;
  List<Map<String, dynamic>> _saldoKelasList = [];

  // State Tab 1: Approval Kas
  bool _isLoadingPengajuan = false;
  List<Map<String, dynamic>> _pengajuanList = [];
  String _filterPengajuan = 'all';

  // State Tab 2: Review Daily Report
  bool _isLoadingDaily = false;
  List<Map<String, dynamic>> _dailyReportList = [];
  String _filterDaily = 'all';

  // State Tab 3: Buku Jurnal
  bool _isLoadingJurnal = false;
  Map<String, dynamic>? _jurnalData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDashboardData(),
      _loadPengajuanKas(),
      _loadDailyReport(),
      _loadJurnalData(),
    ]);
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoadingDashboard = true);

    final resRingkasan = await SupervisorApiService.getRingkasanHarian();
    final resKelas = await SupervisorApiService.getSaldoPerKelas();

    if (!mounted) return;
    setState(() {
      _isLoadingDashboard = false;
      if (resRingkasan.data != null) {
        _ringkasanData = resRingkasan.data;
      }
      if (resKelas.data != null) {
        _saldoKelasList = resKelas.data!;
      }
    });
  }

  Future<void> _loadPengajuanKas() async {
    if (!mounted) return;
    setState(() => _isLoadingPengajuan = true);

    final filter = _filterPengajuan == 'all' ? null : _filterPengajuan;
    final res = await SupervisorApiService.listPengajuanKas(status: filter);

    if (!mounted) return;
    setState(() {
      _isLoadingPengajuan = false;
      if (res.data != null) {
        _pengajuanList = res.data!;
      }
    });
  }

  Future<void> _loadDailyReport() async {
    if (!mounted) return;
    setState(() => _isLoadingDaily = true);

    final filter = _filterDaily == 'all' ? null : _filterDaily;
    final res = await SupervisorApiService.listDailyReport(status: filter);

    if (!mounted) return;
    setState(() {
      _isLoadingDaily = false;
      if (res.data != null) {
        _dailyReportList = res.data!;
      }
    });
  }

  Future<void> _loadJurnalData() async {
    if (!mounted) return;
    setState(() => _isLoadingJurnal = true);

    final res = await SupervisorApiService.getMutasiJurnal();

    if (!mounted) return;
    setState(() {
      _isLoadingJurnal = false;
      if (res.data != null) {
        _jurnalData = res.data!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cached = SessionStorage.cachedPetugas;
    final namaPetugas = widget.petugas?.namaPetugas ?? cached?.namaPetugas ?? 'Kepala Bank Mini';
    final jabatan = widget.petugas?.roleDisplay ?? cached?.roleDisplay ?? 'Supervisor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'SUPERVISOR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
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
              '$jabatan • Otorisasi Kas & Approval Laporan',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan Data',
            onPressed: () {
              switch (_currentIndex) {
                case 0:
                  _loadDashboardData();
                  break;
                case 1:
                  _loadPengajuanKas();
                  break;
                case 2:
                  _loadDailyReport();
                  break;
                case 3:
                  _loadJurnalData();
                  break;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Logout Supervisor',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.approval_outlined, Icons.approval_rounded, 'Approval Kas'),
                _buildNavItem(2, Icons.fact_check_outlined, Icons.fact_check_rounded, 'Review Daily'),
                _buildNavItem(3, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Buku Jurnal'),
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
        return _buildDashboardTab();
      case 1:
        return _buildApprovalKasTab();
      case 2:
        return _buildReviewDailyReportTab();
      case 3:
      default:
        return _buildJurnalTab();
    }
  }

  // =========================================================================
  // TAB 0: EXECUTIVE DASHBOARD & RINGKASAN OPERASIONAL
  // =========================================================================
  Widget _buildDashboardTab() {
    if (_isLoadingDashboard && _ringkasanData == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
    }

    final nasabah = _ringkasanData?['nasabah'] as Map<String, dynamic>? ?? {};
    final kasOp = _ringkasanData?['kas_operasional'] as Map<String, dynamic>? ?? {};
    final trx = _ringkasanData?['transaksi_hari_ini'] as Map<String, dynamic>? ?? {};

    final totalDana = nasabah['formatted_dana_tabungan'] ??
        formatRupiah((nasabah['total_dana_tabungan'] as num?)?.toDouble() ?? 0);
    final totalNasabah = nasabah['total_nasabah_aktif']?.toString() ?? '0';

    final kasFisik = kasOp['formatted_kas_fisik'] ??
        formatRupiah((kasOp['kas_fisik_tersedia'] as num?)?.toDouble() ?? 0);
    final kasMasuk = kasOp['formatted_kas_masuk'] ??
        formatRupiah((kasOp['kas_masuk_hari_ini'] as num?)?.toDouble() ?? 0);
    final kasKeluar = kasOp['formatted_kas_keluar'] ??
        formatRupiah((kasOp['kas_keluar_hari_ini'] as num?)?.toDouble() ?? 0);

    final freqTrx = trx['frekuensi_transaksi']?.toString() ?? '0';
    final freqSetor = trx['frekuensi_setor']?.toString() ?? '0';
    final freqTarik = trx['frekuensi_tarik']?.toString() ?? '0';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.accentTeal,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Otorisasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryNavyLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PORTAL OTORISASI SUPERVISOR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentTeal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Persetujuan & Monitoring Kas',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prinsip Maker-Checker Perbankan Mikro',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accentTeal,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Read-Only Presence & Shift Notification for Supervisor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Presensi & Shift Petugas: Read-only (Dikelola oleh Administrator)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrik Utama Cards (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Dana Tabungan',
                    value: totalDana,
                    subtitle: '$totalNasabah Siswa Terdaftar',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Kas Fisik Tersedia',
                    value: kasFisik,
                    subtitle: 'Brankas & Kas Loket',
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Arus Kas Hari Ini',
                    value: '+$kasMasuk',
                    subtitle: 'Keluar: -$kasKeluar',
                    icon: Icons.swap_vert_rounded,
                    iconColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Volume Transaksi',
                    value: '$freqTrx Transaksi',
                    subtitle: '$freqSetor Setor • $freqTarik Tarik',
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pintasan Menu Otorisasi
            Text(
              'Aksi Cepat Otorisasi',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _buildSupervisorCard(
              icon: Icons.approval_rounded,
              title: 'Approval Droping Kas Teller',
              desc: 'Tinjau tiket permohonan modal kerja laci kasir teller',
              iconColor: AppColors.warning,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: 8),
            _buildSupervisorCard(
              icon: Icons.fact_check_rounded,
              title: 'Verifikasi Laporan Harian (Daily Report)',
              desc: 'Sahkan rekonsiliasi kas fisik vs sistem sebelum tutup kas',
              iconColor: AppColors.primaryNavy,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            const SizedBox(height: 8),
            _buildSupervisorCard(
              icon: Icons.auto_stories_rounded,
              title: 'Laporan Jurnal Umum Akuntansi',
              desc: 'Audit mutasi debit dan kredit otomatis buku besar keuangan',
              iconColor: AppColors.info,
              onTap: () => setState(() => _currentIndex = 3),
            ),
            const SizedBox(height: 20),

            // Distribusi Saldo per Kelas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distribusi Simpanan Per Kelas',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_saldoKelasList.length} Rombel',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_saldoKelasList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'Belum ada data distribusi kelas',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _saldoKelasList.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final k = _saldoKelasList[index];
                  final kelas = k['kelas']?.toString() ?? '-';
                  final totalSiswa = k['total_siswa']?.toString() ?? '0';
                  final saldo = k['formatted_saldo'] ??
                      formatRupiah((k['total_saldo'] as num?)?.toDouble() ?? 0);
                  final rataRata = k['rata_rata_saldo'] != null
                      ? formatRupiah((k['rata_rata_saldo'] as num).toDouble())
                      : '-';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: AppColors.primaryNavy,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kelas,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$totalSiswa Siswa • Rata-rata: $rataRata',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          saldo,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: APPROVAL DROPING KAS TELLER
  // =========================================================================
  Widget _buildApprovalKasTab() {
    return Column(
      children: [
        // Filter Status Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua Status', _filterPengajuan, (v) {
                  setState(() => _filterPengajuan = v);
                  _loadPengajuanKas();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Menunggu Approval', _filterPengajuan, (v) {
                  setState(() => _filterPengajuan = v);
                  _loadPengajuanKas();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('disetujui', 'Disetujui', _filterPengajuan, (v) {
                  setState(() => _filterPengajuan = v);
                  _loadPengajuanKas();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('ditolak', 'Ditolak', _filterPengajuan, (v) {
                  setState(() => _filterPengajuan = v);
                  _loadPengajuanKas();
                }),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // List Tiket
        Expanded(
          child: _isLoadingPengajuan
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
              : RefreshIndicator(
                  onRefresh: _loadPengajuanKas,
                  color: AppColors.accentTeal,
                  backgroundColor: AppColors.surface,
                  child: _pengajuanList.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(
                                      Icons.inbox_outlined,
                                      size: 24,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada tiket droping kas',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Filter: $_filterPengajuan',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pengajuanList.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _pengajuanList[index];
                            return _buildPengajuanKasCard(item);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildPengajuanKasCard(Map<String, dynamic> item) {
    final id = item['id'];
    final noTiket = item['nomor_pengajuan']?.toString() ?? '#PK-$id';
    final tanggal = item['tanggal']?.toString() ?? '-';
    final namaTeller = item['nama_teller']?.toString() ?? 'Teller Loket';
    final nominal = item['formatted_nominal'] ??
        formatRupiah((item['nominal'] as num?)?.toDouble() ?? 0);
    final alasan = item['alasan']?.toString() ?? '-';
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    final catatanSpv = item['catatan_spv']?.toString();

    StatusBadgeType badgeType;
    String statusLabel;

    if (status == 'disetujui' || status == 'approved') {
      badgeType = StatusBadgeType.success;
      statusLabel = 'Disetujui';
    } else if (status == 'ditolak' || status == 'rejected') {
      badgeType = StatusBadgeType.danger;
      statusLabel = 'Ditolak';
    } else {
      badgeType = StatusBadgeType.warning;
      statusLabel = 'Menunggu Approval';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'pending' ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tiket
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.primaryNavy,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noTiket,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$tanggal • Oleh $namaTeller',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(label: statusLabel, type: badgeType),
            ],
          ),
          const SizedBox(height: 12),

          // Nominal Droping
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nominal Droping Diminta:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  nominal,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alasan
          Text(
            'Keperluan / Alasan:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            alasan,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),

          // Catatan SPV jika sudah diproses
          if (catatanSpv != null && catatanSpv.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                      'Catatan SPV: $catatanSpv',
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

          // Action Buttons untuk Tiket 'pending'
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Tolak Tiket',
                    icon: Icons.close_rounded,
                    onPressed: () => _handleTolakPengajuanKas(id, noTiket),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Setujui Kas',
                    icon: Icons.check_rounded,
                    backgroundColor: AppColors.success,
                    onPressed: () => _handleSetujuiPengajuanKas(id, noTiket, nominal),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleSetujuiPengajuanKas(dynamic id, String noTiket, String nominal) {
    final noteCtrl = TextEditingController(text: 'Disetujui untuk operasional kas loket');

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
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Setujui Droping Kas',
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
              'Anda akan menyetujui tiket $noTiket dengan nominal $nominal.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            InputField(
              controller: noteCtrl,
              label: 'Catatan Persetujuan (Opsional)',
              hint: 'Tuliskan catatan otorisasi...',
              maxLines: 2,
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
                  label: 'Setujui',
                  backgroundColor: AppColors.success,
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final res = await SupervisorApiService.setujuiPengajuanKas(
                      id,
                      catatan: noteCtrl.text,
                    );
                    if (mounted) {
                      showAppSnackbar(context, res.message, isError: !res.success);
                      _loadPengajuanKas();
                      _loadDashboardData();
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

  void _handleTolakPengajuanKas(dynamic id, String noTiket) {
    final noteCtrl = TextEditingController(text: 'Ditolak: Kas loket dinilai masih mencukupi');

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
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Tolak Tiket Droping Kas',
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
              'Yakin ingin menolak tiket droping kas $noTiket?',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            InputField(
              controller: noteCtrl,
              label: 'Alasan Penolakan',
              hint: 'Masukkan alasan penolakan...',
              maxLines: 2,
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
                  label: 'Tolak Tiket',
                  backgroundColor: AppColors.danger,
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final res = await SupervisorApiService.tolakPengajuanKas(
                      id,
                      catatan: noteCtrl.text,
                    );
                    if (mounted) {
                      showAppSnackbar(context, res.message, isError: !res.success);
                      _loadPengajuanKas();
                      _loadDashboardData();
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

  // =========================================================================
  // TAB 2: REVIEW & VERIFIKASI DAILY REPORT TUTUP KAS
  // =========================================================================
  Widget _buildReviewDailyReportTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua Status', _filterDaily, (v) {
                  setState(() => _filterDaily = v);
                  _loadDailyReport();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Menunggu Verifikasi', _filterDaily, (v) {
                  setState(() => _filterDaily = v);
                  _loadDailyReport();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'Telah Disahkan', _filterDaily, (v) {
                  setState(() => _filterDaily = v);
                  _loadDailyReport();
                }),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // List Daily Report
        Expanded(
          child: _isLoadingDaily
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
              : RefreshIndicator(
                  onRefresh: _loadDailyReport,
                  color: AppColors.accentTeal,
                  backgroundColor: AppColors.surface,
                  child: _dailyReportList.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(
                                      Icons.fact_check_outlined,
                                      size: 24,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada laporan harian tutup kas',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Filter: $_filterDaily',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _dailyReportList.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _dailyReportList[index];
                            return _buildDailyReportCard(item);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildDailyReportCard(Map<String, dynamic> item) {
    final id = item['id'];
    final tgl = item['report_date']?.toString() ?? '-';
    final namaTeller = item['nama_teller']?.toString() ?? 'Teller Loket';
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    final notes = item['notes']?.toString();

    final opening = (item['opening_balance'] as num?)?.toDouble() ?? 0;
    final deposit = (item['total_deposit'] as num?)?.toDouble() ?? 0;
    final withdrawal = (item['total_withdrawal'] as num?)?.toDouble() ?? 0;
    final systemBal = (item['system_balance'] as num?)?.toDouble() ?? 0;
    final physicalBal = (item['physical_balance'] as num?)?.toDouble() ?? 0;
    final difference = (item['difference'] as num?)?.toDouble() ?? 0;

    final isBalanced = difference == 0;
    StatusBadgeType badgeType;
    String statusText;

    if (status == 'approved') {
      badgeType = StatusBadgeType.success;
      statusText = 'Disahkan';
    } else if (status == 'rejected') {
      badgeType = StatusBadgeType.danger;
      statusText = 'Ditolak';
    } else {
      badgeType = StatusBadgeType.warning;
      statusText = 'Menunggu Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'pending' ? AppColors.accentTeal.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.primaryNavy,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tutup Kas: $tgl',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Oleh: $namaTeller',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(label: statusText, type: badgeType),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Rekonsiliasi Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildReportRow('Saldo Awal Loket', formatRupiah(opening)),
                const SizedBox(height: 4),
                _buildReportRow('Total Setoran (+)', formatRupiah(deposit), valueColor: AppColors.success),
                const SizedBox(height: 4),
                _buildReportRow('Total Penarikan (-)', formatRupiah(withdrawal), valueColor: AppColors.danger),
                const Divider(color: AppColors.border, height: 16),
                _buildReportRow('Saldo Akhir Sistem', formatRupiah(systemBal), isBold: true),
                const SizedBox(height: 4),
                _buildReportRow('Kas Fisik Riil Laci', formatRupiah(physicalBal), isBold: true),
                const SizedBox(height: 4),
                _buildReportRow(
                  'Selisih Rekonsiliasi',
                  isBalanced ? 'Seimbang (Rp 0)' : formatRupiah(difference),
                  valueColor: isBalanced ? AppColors.success : AppColors.danger,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Catatan Teller
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan Teller: $notes',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Action Verifikasi untuk Status 'pending'
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Tolak Laporan',
                    icon: Icons.close_rounded,
                    onPressed: () => _handleVerifikasiDailyReport(id, 'rejected'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Sahkan Laporan',
                    icon: Icons.check_circle_outline_rounded,
                    backgroundColor: AppColors.accentTeal,
                    onPressed: () => _handleVerifikasiDailyReport(id, 'approved'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _handleVerifikasiDailyReport(dynamic id, String status) {
    final noteCtrl = TextEditingController(
      text: status == 'approved'
          ? 'Laporan harian telah diverifikasi dan disahkan oleh Supervisor'
          : 'Laporan belum sesuai, periksa kembali kas fisik',
    );

    final actionTitle = status == 'approved' ? 'Sahkan Daily Report' : 'Tolak Daily Report';
    final actionColor = status == 'approved' ? AppColors.accentTeal : AppColors.danger;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          actionTitle,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikan catatan otorisasi untuk teller:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            InputField(
              controller: noteCtrl,
              label: 'Catatan Otorisasi',
              hint: 'Tuliskan catatan...',
              maxLines: 2,
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
                  label: status == 'approved' ? 'Sahkan' : 'Tolak',
                  backgroundColor: actionColor,
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final res = await SupervisorApiService.updateStatusDailyReport(
                      id,
                      status: status,
                      notes: noteCtrl.text,
                    );
                    if (mounted) {
                      showAppSnackbar(context, res.message, isError: !res.success);
                      _loadDailyReport();
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

  // =========================================================================
  // TAB 3: BUKU JURNAL UMUM AKUNTANSI
  // =========================================================================
  Widget _buildJurnalTab() {
    if (_isLoadingJurnal && _jurnalData == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
    }

    final summary = _jurnalData?['summary'] as Map<String, dynamic>? ?? {};
    final totalEntri = summary['total_entri']?.toString() ?? '0';
    final totalDebit = summary['formatted_debit'] ??
        formatRupiah((summary['total_debit'] as num?)?.toDouble() ?? 0);
    final totalKredit = summary['formatted_kredit'] ??
        formatRupiah((summary['total_kredit'] as num?)?.toDouble() ?? 0);

    final periode = _jurnalData?['periode'] as Map<String, dynamic>? ?? {};
    final tglDari = periode['dari'] ?? DateTime.now().toString().substring(0, 10);
    final tglSampai = periode['sampai'] ?? DateTime.now().toString().substring(0, 10);

    final entries = (_jurnalData?['data'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return RefreshIndicator(
      onRefresh: _loadJurnalData,
      color: AppColors.accentTeal,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card Jurnal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryNavyLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BUKU BESAR MUTASI JURNAL',
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
                        '$totalEntri Entri',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rekap Pembukuan Finansial',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Periode: $tglDari s/d $tglSampai',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Debit (+)',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalDebit,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Kredit (-)',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalKredit,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Rincian Transaksi Jurnal',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  'Belum ada transaksi jurnal pada periode ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final e = entries[index];
                final tgl = e['tanggal']?.toString() ?? '-';
                final ket = e['keterangan']?.toString() ?? '-';
                final debit = (e['debit'] as num?)?.toDouble() ?? 0;
                final kredit = (e['kredit'] as num?)?.toDouble() ?? 0;

                final hasDebit = debit > 0;
                final amountText = hasDebit ? formatRupiah(debit) : formatRupiah(kredit);
                final amountColor = hasDebit ? AppColors.success : AppColors.danger;
                final sign = hasDebit ? '+ ' : '- ';

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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (hasDebit ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          hasDebit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: hasDebit ? AppColors.success : AppColors.danger,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ket,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tgl,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$sign$amountText',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // COMMON HELPER WIDGETS
  // =========================================================================

  Widget _buildFilterChip(
    String value,
    String label,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutline, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutline,
              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin mengakhiri sesi Supervisor?',
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
