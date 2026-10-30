import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/nasabah_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_states.dart';
import 'pin_authorization_screen.dart';

/// Halaman Kartu Digital & QR Code Rekening Siswa
class KartuDigitalScreen extends StatefulWidget {
  const KartuDigitalScreen({super.key});

  @override
  State<KartuDigitalScreen> createState() => _KartuDigitalScreenState();
}

class _KartuDigitalScreenState extends State<KartuDigitalScreen> {
  bool _showQR = true;
  late NasabahModel _nasabah;

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await NasabahApiService.getProfil();
    if (res.data != null && mounted) {
      setState(() => _nasabah = res.data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = _nasabah.qrisPayload;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bersih Institusional
          PageHeader(
            title: 'Kartu Pelajar & QR Rekening',
            subtitle: 'Identitas perbankan resmi untuk transaksi di loket Teller',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Fisik Digital (Primary Navy)
                  _buildDigitalCard(),
                  const SizedBox(height: 18),

                  // Area QR Code Rekening (High Contrast White Card)
                  _buildQRCodeSection(qrPayload),
                  const SizedBox(height: 18),

                  // Informasi Nasabah Rinci
                  _buildAccountMetadataCard(),
                  const SizedBox(height: 18),

                  // Tombol Otorisasi PIN Cepat
                  _buildPinAuthAction(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryNavy, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bank & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LKM MITRA SISWA ABADI',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Bank Mini Sekolah • Kartu Digital',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: AppColors.textOnNavyMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: _nasabah.status,
                color: _nasabah.isBlocked ? AppColors.danger : AppColors.accentTeal,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profil Siswa
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    _nasabah.namaLengkap.isNotEmpty
                        ? _nasabah.namaLengkap.substring(0, 2).toUpperCase()
                        : 'NA',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nasabah.namaLengkap,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${_nasabah.nis} • ${_nasabah.kelas}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textOnNavyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF1E2D3D), height: 1),
          const SizedBox(height: 12),

          // Nomor Rekening
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOMOR REKENING',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnNavyMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _nasabah.noRekening,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentTeal,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF142236),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _nasabah.kategori,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(String payload) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Identitas Transaksi',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Tunjukkan ke petugas Teller saat setor atau tarik tunai',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showQR ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: _showQR ? 'Sembunyikan QR' : 'Tampilkan QR',
                onPressed: () => setState(() => _showQR = !_showQR),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showQR) ...[
            Container(
              padding: const EdgeInsets.all(14),
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
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded, size: 12, color: AppColors.primaryNavy),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Siswa Terdaftar',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _metaRow('Nama Lengkap', _nasabah.namaLengkap),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Nomor Induk Siswa (NIS)', _nasabah.nis),
          const Divider(color: AppColors.border, height: 16),
          _metaRow('Kelas & Jurusan', '${_nasabah.kelas} - ${_nasabah.jurusan}'),
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
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPinAuthAction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pin_rounded, color: AppColors.primaryNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Otorisasi PIN Penarikan',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  'Siapkan 6-digit PIN saat melakukan transaksi tarik tunai di loket',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PinAuthorizationScreen()));
            },
            child: Text('Buka PIN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
