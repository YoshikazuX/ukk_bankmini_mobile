import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';

/// Halaman Layanan Setor Tunai Loket Teller (Sandi Transaksi 101)
class SetorTunaiScreen extends StatefulWidget {
  final String? initialRekening;
  final Map<String, dynamic>? nasabahData;

  const SetorTunaiScreen({super.key, this.initialRekening, this.nasabahData});

  @override
  State<SetorTunaiScreen> createState() => _SetorTunaiScreenState();
}

class _SetorTunaiScreenState extends State<SetorTunaiScreen> {
  final _rekeningController = TextEditingController();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();

  Map<String, dynamic>? _nasabah;
  bool _isLoadingInquiry = false;
  bool _isSubmitting = false;
  String? _inquiryError;

  final List<double> _quickNominals = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRekening != null) {
      _rekeningController.text = widget.initialRekening!;
    }
    if (widget.nasabahData != null) {
      _nasabah = widget.nasabahData;
    } else if (widget.initialRekening != null) {
      _inquiryNasabah();
    }
  }

  @override
  void dispose() {
    _rekeningController.dispose();
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _inquiryNasabah() async {
    final rek = _rekeningController.text.trim();
    if (rek.isEmpty) {
      setState(() {
        _inquiryError = 'Masukkan nomor rekening nasabah';
        _nasabah = null;
      });
      return;
    }

    setState(() {
      _isLoadingInquiry = true;
      _inquiryError = null;
    });

    final res = await TellerApiService.getDetailNasabah(rek);

    if (!mounted) return;
    setState(() {
      _isLoadingInquiry = false;
      if (res.success && res.data != null) {
        _nasabah = res.data;
        _inquiryError = null;
      } else {
        _nasabah = null;
        _inquiryError = res.message.isNotEmpty ? res.message : 'Nomor rekening tidak ditemukan!';
      }
    });
  }

  void _submitSetoran() async {
    if (_nasabah == null) {
      showAppSnackbar(context, 'Silakan verifikasi nomor rekening nasabah terlebih dahulu', isError: true);
      return;
    }

    final nominalText = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double nominal = double.tryParse(nominalText) ?? 0;

    if (nominal < 1000) {
      showAppSnackbar(context, 'Nominal setoran tunai minimal Rp 1.000', isError: true);
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Setor Tunai [101]',
      message: 'Pastikan uang fisik tunai telah diterima dan dihitung oleh Teller.',
      confirmLabel: 'Proses Setoran',
      contentExtra: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _slipRow('Nama Siswa', _nasabah?['nama_siswa'] ?? '-'),
            const SizedBox(height: 6),
            _slipRow('No. Rekening', _rekeningController.text.trim()),
            const Divider(color: AppColors.border, height: 14),
            _slipRow('Nominal Uang', formatRupiah(nominal), isHighlight: true),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final res = await TellerApiService.setorTunai(
      noRekening: _rekeningController.text.trim(),
      nominal: nominal,
      keterangan: _keteranganController.text.trim().isNotEmpty
          ? _keteranganController.text.trim()
          : 'Setoran tunai loket [101]',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success && res.data != null) {
      _showDigitalReceipt(nominal, res.data!);
    } else {
      showAppSnackbar(context, res.message, isError: true);
    }
  }

  void _showDigitalReceipt(double nominal, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Setoran Tunai Berhasil',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              'Slip Validasi Transaksi Loket [101]',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: AppColors.border, height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    formatRupiah(nominal),
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _slipRow('Kode Sandi', '101 (Setor Tunai)'),
                  const SizedBox(height: 6),
                  _slipRow('No. Rekening', _rekeningController.text.trim()),
                  const SizedBox(height: 6),
                  _slipRow('Nama Siswa', _nasabah?['nama_siswa'] ?? '-'),
                  const SizedBox(height: 6),
                  _slipRow('Saldo Akhir', formatRupiah((data['saldo_akhir'] as num?)?.toDouble() ?? 0)),
                  const SizedBox(height: 6),
                  _slipRow('Petugas Loket', data['petugas'] ?? 'Teller Loket'),
                  const SizedBox(height: 6),
                  _slipRow('Waktu Cetak', formatTanggal(DateTime.now())),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            text: 'Selesai & Tutup Slip',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }

  Widget _slipRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 13 : 11,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            color: isHighlight ? AppColors.primaryNavy : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Setoran Tunai Nasabah',
            subtitle: 'Transaksi loket kasir kode sandi 101',
            showBackButton: true,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Inquiry Rekening
                  _buildInquiryCard(),
                  const SizedBox(height: 16),

                  // Section 2: Input Nominal & Quick Chips
                  _buildNominalCard(),
                  const SizedBox(height: 16),

                  // Section 3: Keterangan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: InputField(
                      label: 'Keterangan Setoran (Opsional)',
                      controller: _keteranganController,
                      hint: 'Contoh: Tabungan wajib pekanan, setoran kas',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Proses
                  PrimaryButton(
                    text: 'Proses Setoran Tunai [101]',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submitSetoran,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard() {
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
            'Rekening Nasabah',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rekeningController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan no. rekening (202601001)',
                    prefixIcon: const Icon(Icons.person_search_rounded, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _isLoadingInquiry ? null : _inquiryNasabah,
                  child: _isLoadingInquiry
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Inquiry', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          if (_inquiryError != null) ...[
            const SizedBox(height: 8),
            Text(_inquiryError!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger)),
          ],

          // Profil Siswa Terinquiry
          if (_nasabah != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _nasabah!['nama_siswa']?.toString().substring(0, 1) ?? 'S',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nasabah!['nama_siswa'] ?? '-',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'NIS: ${_nasabah!['nis'] ?? '-'} • Kelas: ${_nasabah!['kelas'] ?? '-'}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Saldo Saat Ini', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                      Text(
                        formatRupiah((_nasabah!['saldo'] as num?)?.toDouble() ?? 0),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNominalCard() {
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
            'Nominal Uang Tunai Diterima',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              hintText: '0',
              filled: true,
              fillColor: AppColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _quickNominals.map((nom) {
              return InkWell(
                onTap: () => setState(() => _nominalController.text = nom.toInt().toString()),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    formatRupiah(nom),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
