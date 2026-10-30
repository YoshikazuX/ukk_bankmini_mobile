import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/nasabah_model.dart';
import '../models/transaksi_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_cards.dart';
import 'blokir_rekening_screen.dart';
import 'financial_chart_screen.dart';
import 'kartu_digital_screen.dart';
import 'mutasi_screen.dart';
import 'saving_goals_screen.dart';
import 'notifikasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late NasabahModel _nasabah;
  bool _showBalance = true;
  List<TransaksiModel> _liveTransactions = [];
  bool _isLoadingLive = false;

  @override
  void initState() {
    super.initState();
    _nasabah = SessionStorage.cachedNasabah ??
        NasabahModel(
          id: '',
          noRekening: '-',
          nis: '-',
          namaLengkap: 'Nasabah Siswa',
          kelas: '-',
          jurusan: '-',
          totalSaldo: 0,
          status: 'AKTIF',
        );
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoadingLive = true);
    try {
      final profileRes = await NasabahApiService.getProfil();
      if (profileRes.data != null && mounted) {
        setState(() {
          _nasabah = profileRes.data!;
        });
      }

      final riwayatRes = await NasabahApiService.getRiwayat();
      if (riwayatRes.data != null && mounted) {
        setState(() {
          _liveTransactions = riwayatRes.data!;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingLive = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          backgroundColor: AppColors.surface,
          onRefresh: _fetchLiveDashboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. App Bar Institusional
              SliverToBoxAdapter(child: _buildHeader()),

              // 2. Hero Balance Card (Navy)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildBalanceHero(),
                ),
              ),

              // 3. Pintasan Menu Utama (Aksi Cepat)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildQuickActions(),
                ),
              ),

              // 4. Ringkasan Pemasukan & Pengeluaran Bulan Ini
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildCashFlowSummary(),
                ),
              ),

              // 5. Riwayat 5 Transaksi Terbaru
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: _buildRecentTransactions(),
                ),
              ),

              // 6. Layanan Keamanan Darurat
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _buildEmergencySecurityTile(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. HEADER INSTITUSIONAL DENGAN PROFIL SISWA
  // =========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar Inisial Institusional
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _nasabah.namaLengkap.isNotEmpty
                    ? (_nasabah.namaLengkap.length >= 2
                        ? _nasabah.namaLengkap.substring(0, 2).toUpperCase()
                        : _nasabah.namaLengkap.toUpperCase())
                    : 'NA',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Selamat datang,',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _nasabah.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentTealHover,
                      ),
                    ),
                  ],
                ),
                Text(
                  _nasabah.namaLengkap,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Refresh Icon
          IconButton(
            icon: _isLoadingLive
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Segarkan Data',
            onPressed: _isLoadingLive ? null : _fetchLiveDashboardData,
          ),
          // Notifikasi Icon
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 22),
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. HERO BALANCE CARD (NAVY RESMI INSTITUSI)
  // =========================================================================
  Widget _buildBalanceHero() {
    final saldoDapatDigunakan = (_nasabah.totalSaldo - _nasabah.saldoMengendap).clamp(0, double.infinity).toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryNavy, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _showBalance = !_showBalance),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 13,
                          color: AppColors.textOnNavyMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showBalance ? 'Sembunyikan' : 'Tampilkan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textOnNavyMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E2D3D), height: 1),

          // Nominal Saldo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Saldo Tabungan',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textOnNavyMuted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _nasabah.noRekening));
                        showAppSnackbar(context, 'Nomor rekening ${_nasabah.noRekening} disalin');
                      },
                      child: Row(
                        children: [
                          Text(
                            _nasabah.noRekening,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: AppColors.accentTeal),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _showBalance ? formatRupiah(_nasabah.totalSaldo) : 'Rp ••••••••',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Dapat digunakan: ${_showBalance ? formatRupiah(saldoDapatDigunakan) : "••••"}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• Min. simpanan: ${formatRupiah(_nasabah.saldoMengendap)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textOnNavyMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Strip Aksi Cepat pada Kartu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF142236),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCardActionItem(Icons.receipt_long_rounded, 'Riwayat Mutasi', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MutasiScreen()));
                }),
                _buildCardActionItem(Icons.qr_code_rounded, 'QR Rekening', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const KartuDigitalScreen()));
                }),
                _buildCardActionItem(Icons.flag_rounded, 'Target Nabung', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen()));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.accentTeal),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. PINTASAN MENU UTAMA (AKSI CEPAT SISWA)
  // =========================================================================
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Perbankan',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.savings_rounded,
                title: 'Target\nNabung',
                color: AppColors.primaryNavy,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.receipt_long_rounded,
                title: 'Buku\nMutasi',
                color: const Color(0xFF1E3A8A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MutasiScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.credit_card_rounded,
                title: 'Kartu\nPelajar',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KartuDigitalScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.support_agent_rounded,
                title: 'Bantuan\nAdmin WA',
                color: const Color(0xFF16A36A),
                onTap: () => openWhatsAppAdmin(context: context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. RINGKASAN ARUS KAS BULAN INI (DIHITUNG DARI DATA TRANSAKSI NYATA)
  // =========================================================================
  Widget _buildCashFlowSummary() {
    double totalSetoran = 0;
    double totalPenarikan = 0;

    for (final trx in _liveTransactions) {
      if (trx.isSetoran || trx.isTransferMasuk) {
        totalSetoran += trx.jumlah;
      } else if (trx.isPenarikan || trx.isTransferKeluar) {
        totalPenarikan += trx.jumlah;
      }
    }

    return Container(
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
                'Arus Kas Bulan Ini',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialChartScreen()));
                },
                child: Row(
                  children: [
                    Text('Lihat Grafik', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primaryNavy),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('Total Setoran (+)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(totalSetoran),
                        style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text('Total Penarikan (-)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(totalPenarikan),
                        style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. RIWAYAT TRANSAKSI TERBARU (DATA NYATA BACKEND)
  // =========================================================================
  Widget _buildRecentTransactions() {
    final recent = _liveTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mutasi Terakhir',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MutasiScreen()));
              },
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi tercatat.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seluruh setoran atau penarikan yang Anda lakukan di loket Bank Mini akan tercatat di sini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final trx = recent[index];
              return TransactionItem(
                title: (trx.keterangan != null && trx.keterangan!.isNotEmpty)
                    ? trx.keterangan!
                    : trx.namaTransaksi,
                subtitle: trx.formattedTanggal,
                amount: trx.jumlah,
                isDebit: trx.isDebit,
                status: trx.status,
              );
            },
          ),
      ],
    );
  }

  // =========================================================================
  // 6. LAYANAN BLOKIR REKENING DARURAT
  // =========================================================================
  Widget _buildEmergencySecurityTile() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlokirRekeningScreen()));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.danger, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pusat Keamanan & Pemblokiran Darurat',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  Text(
                    'Bekukan rekening sementara jika kartu atau perangkat hilang',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
