import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_cards.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';

/// Halaman Layanan Tarik Tunai Loket Teller (Sandi Transaksi 201)
class TarikTunaiScreen extends StatefulWidget {
  final String? initialRekening;
  final Map<String, dynamic>? nasabahData;

  const TarikTunaiScreen({
    super.key,
    this.initialRekening,
    this.nasabahData,
  });

  @override
  State<TarikTunaiScreen> createState() => _TarikTunaiScreenState();
}

class _TarikTunaiScreenState extends State<TarikTunaiScreen> {
  final _rekeningController = TextEditingController();
  final _nominalController = TextEditingController();
  final _pinController = TextEditingController();
  final _keteranganController = TextEditingController();

  Map<String, dynamic>? _nasabah;
  Map<String, dynamic>? _kasStatus;
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
    _fetchKasStatus();
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
    _pinController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _fetchKasStatus() async {
    final res = await TellerApiService.getStatusKas();
    if (res.data != null && mounted) {
      setState(() {
        _kasStatus = res.data;
      });
    }
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
        _inquiryError = res.message.isNotEmpty
            ? res.message
            : 'Nomor rekening tidak ditemukan!';
      }
    });
  }

  void _submitPenarikan() async {
    if (_nasabah == null) {
      showAppSnackbar(
        context,
        'Silakan verifikasi nomor rekening nasabah terlebih dahulu',
        isError: true,
      );
      return;
    }

    final nominalText = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double nominal = double.tryParse(nominalText) ?? 0;

    if (nominal < 1000) {
      showAppSnackbar(
        context,
        'Nominal penarikan minimal Rp 1.000',
        isError: true,
      );
      return;
    }

    final saldoDapatDitarik =
        (_nasabah!['saldo_dapat_ditarik'] as num?)?.toDouble() ?? 0.0;

    if (nominal > saldoDapatDitarik) {
      showAppSnackbar(
        context,
        'Penarikan melebihi saldo efektif! Maksimal: ${formatRupiah(saldoDapatDitarik)} (Saldo wajib mengendap Rp 10.000)',
        isError: true,
      );
      return;
    }

    // Validasi kas fisik di loket
    final kasTersedia =
        (_kasStatus?['kas_tersedia'] as num?)?.toDouble() ?? 2500000.0;
    if (nominal > kasTersedia) {
      showAppSnackbar(
        context,
        'Kas fisik loket teller tidak mencukupi (Tersedia: ${formatRupiah(kasTersedia)}). Harap ajukan droping kas ke Supervisor.',
        isError: true,
      );
      return;
    }

    // Tampilkan dialog PIN Nasabah
    _showPinDialog(nominal);
  }

  void _showPinDialog(double nominal) {
    _pinController.clear();
    String? localPinError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.danger,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Otorisasi PIN Nasabah (Siswa)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minta siswa memasukkan 6 digit PIN persetujuan penarikan ${formatRupiah(nominal)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 16,
                      color: AppColors.textPrimary,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        letterSpacing: 16,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (localPinError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localPinError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Batal',
                          onPressed: () => Navigator.pop(bottomCtx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Otorisasi & Tarik',
                          backgroundColor: AppColors.danger,
                          onPressed: () {
                            final pin = _pinController.text.trim();
                            if (pin.length != 6) {
                              setModalState(() {
                                localPinError = 'PIN harus tepat 6 digit angka!';
                              });
                              return;
                            }
                            Navigator.pop(bottomCtx);
                            _executePenarikan(nominal, pin);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executePenarikan(double nominal, String pin) async {
    setState(() => _isSubmitting = true);

    final res = await TellerApiService.tarikTunai(
      noRekening: _rekeningController.text.trim(),
      nominal: nominal,
      pin: pin,
      keterangan: _keteranganController.text.trim().isNotEmpty
          ? _keteranganController.text.trim()
          : 'Penarikan tunai loket teller [201]',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success && res.data != null) {
      _showSlipDialog(res.data!, nominal);
    } else {
      showAppSnackbar(
        context,
        res.message.isNotEmpty ? res.message : 'Gagal memproses penarikan!',
        isError: true,
      );
    }
  }

  void _showSlipDialog(Map<String, dynamic> data, double nominal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
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
                  color: AppColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Penarikan Berhasil',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Slip Validasi Transaksi Loket [201]',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
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
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 18),
                    _slipRow('Kode Sandi', '201 (Tarik Tunai)'),
                    _slipRow('No. Rekening', _rekeningController.text.trim()),
                    _slipRow('Nama Siswa', _nasabah?['nama_siswa'] ?? '-'),
                    _slipRow(
                      'Sisa Saldo Rekening',
                      formatRupiah(
                        (data['saldo_akhir'] as num?)?.toDouble() ?? 0.0,
                      ),
                      isHighlight: true,
                    ),
                    _slipRow('Petugas Loket', data['petugas'] ?? 'Teller Loket'),
                    _slipRow(
                      'Waktu Transaksi',
                      data['waktu']?.toString().substring(0, 19) ??
                          DateTime.now().toString().substring(0, 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PrimaryButton(
              label: 'Selesai & Tutup Slip',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  static Widget _slipRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight ? AppColors.primaryNavy : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasTersedia =
        (_kasStatus?['kas_tersedia'] as num?)?.toDouble() ?? 2500000.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tarik Tunai Loket [201]',
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
              // Info Kas Laci Teller
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kas Fisik Laci Teller',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Batas Maksimal Penarikan',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      formatRupiah(kasTersedia),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inquiry Input Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Rekening Nasabah',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rekeningController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan no. rekening',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _inquiryNasabah(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: PrimaryButton(
                            label: 'Cari',
                            isLoading: _isLoadingInquiry,
                            onPressed: _isLoadingInquiry ? null : _inquiryNasabah,
                          ),
                        ),
                      ],
                    ),

                    if (_inquiryError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _inquiryError!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_nasabah != null) ...[
                      const SizedBox(height: 14),
                      _buildVerifiedNasabahCard(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Nominal Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nominal Penarikan (Rp)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp  ',
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                        hintText: '0',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 20,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primaryNavy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickNominals.map((amount) {
                        return InkWell(
                          onTap: () {
                            _nominalController.text = amount.toInt().toString();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              formatRupiah(amount),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    InputField(
                      controller: _keteranganController,
                      label: 'Keterangan / Keperluan (Opsional)',
                      hint: 'Contoh: Penarikan kegiatan ekstrakurikuler',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Lanjutkan & Otorisasi PIN Siswa',
                icon: Icons.lock_outline_rounded,
                backgroundColor: AppColors.danger,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitPenarikan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedNasabahCard() {
    final saldo = (_nasabah!['saldo'] as num?)?.toDouble() ?? 0.0;
    final saldoDapatDitarik =
        (_nasabah!['saldo_dapat_ditarik'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: _nasabah!['nama_siswa'] ?? 'N',
                size: 38,
                backgroundColor: AppColors.primaryNavy,
                textColor: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nasabah!['nama_siswa'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_nasabah!['kelas'] ?? ''} • NIS: ${_nasabah!['nis'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'Terverifikasi',
                type: StatusBadgeType.success,
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saldo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatRupiah(saldo),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Saldo Mengendap',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'Rp 10.000',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Maksimal Ditarik',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    formatRupiah(saldoDapatDitarik),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
