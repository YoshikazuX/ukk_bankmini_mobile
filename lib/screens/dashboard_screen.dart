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
import '../widgets/common/app_states.dart';
import 'badges_screen.dart';
import 'blokir_rekening_screen.dart';
import 'financial_chart_screen.dart';
import 'kartu_digital_screen.dart';
import 'mutasi_screen.dart';
import 'saving_goals_screen.dart';
import 'notifikasi_screen.dart';

/// Halaman Dashboard Utama Nasabah Siswa (Unslopped & Craft-Focused)
/// - One Bright Element: Kartu saldo hijau solid (#19C9A3) dengan tipografi tegas & no gradients.
/// - Quiet Chrome: Navigasi dan permukaan kartu pendukung tenang, bersih, tanpa glow/dekorasi semu.
/// - Spacing & Density: Standar grid 4px dengan ritme 16px konsisten di seluruh seksi.
/// - Real Product Features: Akses langsung ke Target Simpanan, Mutasi Kas, Lencana Prestasi, dan Grafik Keuangan.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late NasabahModel _nasabah;
  bool _showBalance = true;
  List<TransaksiModel> _liveTransactions = [];

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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentTealHover,
          backgroundColor: AppColors.surface,
          onRefresh: _fetchLiveDashboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. App Bar Institusional (Quiet Chrome)
              SliverToBoxAdapter(child: _buildHeader()),

              // 2. Hero Balance Card (The One Bright Element - Solid Green, No Gradients)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildBalanceHero(),
                ),
              ),

              // 3. Layanan Siswa Terpadu (Complementary Services, No Duplication)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildQuickActions(),
                ),
              ),

              // 4. Ringkasan Arus Kas Bulan Ini (Cash Flow Ledger)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildCashFlowSummary(),
                ),
              ),

              // 5. Riwayat 5 Transaksi Terbaru (Recent Transactions)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildRecentTransactions(),
                ),
              ),

              // 6. Layanan Keamanan Darurat
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
  // 1. HEADER INSTITUSIONAL DENGAN PROFIL SISWA (QUIET CHROME)
  // =========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar Profil Siswa
          ProfileAvatar(
            name: _nasabah.namaLengkap,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Akun Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _nasabah.kategori,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTealHover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _nasabah.namaLengkap,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Quiet Chrome: Ikon notifikasi bersih tanpa duplikasi tombol refresh manual
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
  // 2. HERO BALANCE CARD (THE ONE BRIGHT ELEMENT - SOLID GREEN #19C9A3)
  // =========================================================================
  Widget _buildBalanceHero() {
    final saldoDapatDigunakan = (_nasabah.totalSaldo - _nasabah.saldoMengendap).clamp(0, double.infinity).toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentTeal, // HIJAU SOLID PRIMARY LOGIN, TANPA GRADASI!
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentTealHover, width: 1.5),
        boxShadow: AppColors.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header Kartu: Brand & Toggle Sembunyikan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _showBalance = !_showBalance),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 13,
                          color: AppColors.textOnGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showBalance ? 'Sembunyikan' : 'Tampilkan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),

          // B. Nominal Saldo & Detail Rekening
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Tabungan Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnGreen.withValues(alpha: 0.85),
                      ),
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
                              color: AppColors.textOnGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 11, color: AppColors.textOnGreen),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Dapat ditarik: ${_showBalance ? formatRupiah(saldoDapatDigunakan) : "••••"}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• Min. simpanan: ${formatRupiah(_nasabah.saldoMengendap)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textOnGreen.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Horizontal Pill Selector (Jenius Home Alt 1 Reference)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildBalancePill('Saldo Aktif', isSelected: true, onTap: null),
                      const SizedBox(width: 6),
                      _buildBalancePill('Kartu Siswa', isSelected: false, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KartuDigitalScreen()));
                      }),
                      const SizedBox(width: 6),
                      _buildBalancePill('Target Nabung', isSelected: false, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen()));
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // C. Strip Aksi Cepat pada Kartu (Jenius Segmented Action Reference)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCardActionItem(Icons.qr_code_rounded, 'QR Rekening', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const KartuDigitalScreen()));
                }),
                Container(height: 16, width: 1, color: Colors.white.withValues(alpha: 0.25)),
                _buildCardActionItem(Icons.receipt_long_rounded, 'Buku Mutasi', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MutasiScreen()));
                }),
                Container(height: 16, width: 1, color: Colors.white.withValues(alpha: 0.25)),
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

  Widget _buildBalancePill(String title, {required bool isSelected, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textOnGreen : AppColors.textOnGreen.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.accentTealHover : AppColors.textOnGreen,
          ),
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textOnGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. LAYANAN SISWA TERPADU (COMPLEMENTARY SERVICES, TANPA DUPLIKASI)
  // =========================================================================
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Perbankan Siswa',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.savings_outlined,
                title: 'Target Tabungan',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.military_tech_outlined,
                title: 'Lencana Prestasi',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.insights_outlined,
                title: 'Grafik Keuangan',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialChartScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.support_agent_outlined,
                title: 'Bantuan Siswa',
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.accentTealHover, size: 19),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. RINGKASAN ARUS KAS BULAN INI (CASH FLOW LEDGER)
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas Bulan Ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialChartScreen()));
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat Grafik',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.accentTealHover,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.accentTealHover),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Total Setoran (+)',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(totalSetoran),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text(
                            'Total Penarikan (-)',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupiah(totalPenarikan),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
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
                fontWeight: FontWeight.w600,
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
                  color: AppColors.accentTealHover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi tercatat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Setoran atau penarikan yang dilakukan di loket Bank Mini akan tercatat di sini',
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pusat Keamanan & Pemblokiran Darurat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Bekukan rekening sementara jika kartu atau perangkat hilang',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
