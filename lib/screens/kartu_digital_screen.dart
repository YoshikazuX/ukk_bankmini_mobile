import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/nasabah_model.dart';
import '../models/transaksi_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_states.dart';
import 'blokir_rekening_screen.dart';
import 'mutasi_screen.dart';
import 'pin_authorization_screen.dart';

/// Halaman Kartu Siswa & Card Center
/// Dirancang setia mengacu pada wireframe Jenius "Card Center":
/// - Header Card Center & Status Kartu
/// - Kartu Fisik Digital Hijau Solid (AppColors.accentTeal, TANPA gradasi)
/// - Saldo Aktif Besar, Simbol Speaker / Contactless Wave, EMV Chip, Card Number grouping, Nama & GPN
/// - Horizontal Pill Selector: ( Saldo Aktif ) ( QR Rekening ) ( Rincian Siswa )
/// - Bagian "Transaksi Terakhir" (Recent Transactions) dengan tombol Lihat Semua
/// - Kontrol Keamanan Kartu (PIN Otorisasi & Blokir Darurat)
class KartuDigitalScreen extends StatefulWidget {
  const KartuDigitalScreen({super.key});

  @override
  State<KartuDigitalScreen> createState() => _KartuDigitalScreenState();
}

class _KartuDigitalScreenState extends State<KartuDigitalScreen> {
  late NasabahModel _nasabah;
  bool _showBalance = true;
  int _selectedPillIndex = 0; // 0: Saldo Aktif, 1: QR Rekening, 2: Rincian Siswa
  List<TransaksiModel> _recentTransactions = [];
  bool _isLoadingTrx = false;

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
    _loadData();
  }

  Future<void> _loadData() async {
    _loadProfile();
    _loadTransactions();
  }

  Future<void> _loadProfile() async {
    final res = await NasabahApiService.getProfil();
    if (res.data != null && mounted) {
      setState(() => _nasabah = res.data!);
    }
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _isLoadingTrx = true);
    try {
      final res = await NasabahApiService.getRiwayat();
      if (res.data != null && mounted) {
        setState(() => _recentTransactions = res.data!);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingTrx = false);
      }
    }
  }

  String _formatCardNumber(String noRek) {
    if (noRek.isEmpty || noRek == '-') return '••••  ••••  ••••';
    final clean = noRek.replaceAll(' ', '');
    if (clean.length == 9) {
      return '${clean.substring(0, 4)}  ${clean.substring(4)}';
    }
    final chunks = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      chunks.add(clean.substring(i, (i + 4 <= clean.length) ? i + 4 : clean.length));
    }
    return chunks.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = _nasabah.qrisPayload;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bersih Institusional (Quiet Chrome)
          PageHeader(
            title: 'Card Center',
            subtitle: 'Identitas resmi & kartu perbankan siswa',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
          ),

          // Scrollable Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentTealHover,
              backgroundColor: AppColors.surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader Bar: "Kartu Siswa" & Status Aktif
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kartu Siswa',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentTealHover.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _nasabah.isBlocked ? AppColors.danger : AppColors.accentTealHover,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _nasabah.isBlocked ? 'DIBLOKIR' : 'STATUS AKTIF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _nasabah.isBlocked ? AppColors.danger : AppColors.accentTealHover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1. KARTU DIGITAL FISIK (Jenius Card Center Style - Solid Green, No Gradients)
                    _buildDigitalCard(),
                    const SizedBox(height: 16),

                    // 2. HORIZONTAL PILL SELECTOR (Jenius Card Center Pills Row)
                    _buildPillSelector(),
                    const SizedBox(height: 16),

                    // 3. KONTEN DINAMIS BERDASARKAN PILL AKTIF
                    if (_selectedPillIndex == 0) ...[
                      // TAMPILAN UTAMA: TRANSAKSI TERAKHIR KARTU (Recent Transactions)
                      _buildRecentTransactionsSection(),
                      const SizedBox(height: 16),

                      // KONTROL KEAMANAN KARTU (Card Management / Safety)
                      _buildCardSecuritySection(),
                    ] else if (_selectedPillIndex == 1) ...[
                      // TAMPILAN QR CODE TRANSAKSI LOKET TELLER
                      _buildQRCodeSection(qrPayload),
                    ] else ...[
                      // TAMPILAN RINCIAN METADATA SISWA
                      _buildAccountMetadataCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. KARTU DIGITAL FISIK (JENIUS CARD CENTER - SOLID GREEN #19C9A3)
  // =========================================================================
  Widget _buildDigitalCard() {
    final formattedNoRek = _formatCardNumber(_nasabah.noRekening);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentTealHover, width: 1.5),
        boxShadow: AppColors.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Top Row: Institusi Bank Mini & Toggle Saldo
          Row(
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
          const SizedBox(height: 14),

          // B. Nominal Saldo Siswa
          Text(
            'Saldo Tabungan Siswa',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnGreen.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showBalance ? formatRupiah(_nasabah.totalSaldo) : 'Rp ••••••••',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnGreen,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // C. Simbol Contactless Wave & EMV Chip
          Row(
            children: [
              Transform.rotate(
                angle: 1.5708,
                child: const Icon(
                  Icons.wifi_rounded,
                  size: 20,
                  color: AppColors.textOnGreen,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.memory_rounded,
                    size: 14,
                    color: AppColors.textOnGreen.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'DEBIT SISWA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnGreen.withValues(alpha: 0.85),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // D. Nomor Rekening & Aksi Salin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedNoRek,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnGreen,
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _nasabah.noRekening));
                  showAppSnackbar(context, 'Nomor rekening ${_nasabah.noRekening} disalin');
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 11, color: AppColors.textOnGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Salin',
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
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
          const SizedBox(height: 10),

          // E. Identitas Pemegang Kartu & Logo Jaringan GPN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nasabah.namaLengkap.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnGreen,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${_nasabah.nis} • ${_nasabah.kelas}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textOnGreen.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GPN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE53935),
                    letterSpacing: 0.8,
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
  // 2. HORIZONTAL PILL SELECTOR (JENIUS CARD CENTER PILLS ROW)
  // =========================================================================
  Widget _buildPillSelector() {
    final pills = [
      {'title': 'Saldo Aktif', 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'QR Rekening', 'icon': Icons.qr_code_rounded},
      {'title': 'Rincian Siswa', 'icon': Icons.badge_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(pills.length, (index) {
          final isSelected = _selectedPillIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedPillIndex = index),
              borderRadius: BorderRadius.circular(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceMuted : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: isSelected
                      ? Border.all(color: AppColors.border, width: 1)
                      : Border.all(color: Colors.transparent, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      pills[index]['icon'] as IconData,
                      size: 14,
                      color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pills[index]['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========================================================================
  // 3. TRANSAKSI TERAKHIR (JENIUS "RECENT TRANSACTIONS" WIREFRAME SECTION)
  // =========================================================================
  Widget _buildRecentTransactionsSection() {
    final recent = _recentTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terakhir',
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
        if (_isLoadingTrx)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTealHover),
              ),
            ),
          )
        else if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  'Belum ada riwayat transaksi kartu',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Setoran atau penarikan loket akan tercatat otomatis di sini',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          Column(
            children: recent.map((trx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionItem(
                  title: (trx.keterangan != null && trx.keterangan!.isNotEmpty)
                      ? trx.keterangan!
                      : trx.namaTransaksi,
                  subtitle: trx.formattedTanggal,
                  amount: trx.jumlah,
                  isDebit: trx.isDebit,
                  status: trx.status,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // =========================================================================
  // 4. KONTROL KEAMANAN KARTU (CARD MANAGEMENT & CONTROLS)
  // =========================================================================
  Widget _buildCardSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan & Keamanan Kartu',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Tile PIN Otorisasi
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PinAuthorizationScreen()));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pin_rounded, color: AppColors.accentTealHover, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Otorisasi PIN Penarikan Loket',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Siapkan PIN 6-digit saat verifikasi di Teller',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka PIN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTealHover,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 20),
          // Tile Blokir Kartu Darurat
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlokirRekeningScreen()));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: AppColors.danger, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keamanan & Blokir Rekening',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nasabah.isBlocked ? 'Kartu terkunci (transaksi dinonaktifkan)' : 'Kunci kartu seketika bila hilang atau dicuri',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nasabah.isBlocked ? 'Buka Blokir' : 'Kelola',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _nasabah.isBlocked ? AppColors.accentTealHover : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. AREA QR CODE TRANSAKSI LOKET TELLER
  // =========================================================================
  Widget _buildQRCodeSection(String payload) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Identitas Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tunjukkan ke petugas Teller saat setor atau tarik tunai',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Segarkan Profil',
                onPressed: _loadProfile,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _nasabah.noRekening));
              showAppSnackbar(context, 'Nomor rekening ${_nasabah.noRekening} disalin');
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No. Rekening: ${_nasabah.noRekening}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTealHover,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 13, color: AppColors.accentTealHover),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'QR ini memuat nomor rekening resmi yang terhubung dengan akun Bank Mini Sekolah Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. INFORMASI RINCIAN METADATA SISWA
  // =========================================================================
  Widget _buildAccountMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Siswa Terdaftar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _metaRow('Nama Lengkap', _nasabah.namaLengkap),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Nomor Induk Siswa (NIS)', _nasabah.nis),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Kelas & Jurusan', '${_nasabah.kelas} - ${_nasabah.jurusan}'),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Nomor Rekening', _nasabah.noRekening),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Kategori Nasabah', _nasabah.kategori),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Saldo Wajib Mengendap', formatRupiah(_nasabah.saldoMengendap)),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Status Rekening', _nasabah.status),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
