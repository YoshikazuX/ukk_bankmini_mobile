import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/teller_api_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_inputs.dart';
import '../../widgets/common/app_states.dart';
import 'setor_tunai_screen.dart';
import 'tarik_tunai_screen.dart';

/// Layanan Scanner QR Code Kartu Digital Siswa & Cari Nasabah Loket
class ScanNasabahScreen extends StatefulWidget {
  const ScanNasabahScreen({super.key});

  @override
  State<ScanNasabahScreen> createState() => _ScanNasabahScreenState();
}

class _ScanNasabahScreenState extends State<ScanNasabahScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _searchController = TextEditingController();

  bool _isProcessing = false;
  bool _isTorchOn = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _handleBarcodeValue(rawValue);
  }

  void _handleBarcodeValue(String raw) {
    setState(() => _isProcessing = true);

    // Parsing payload QR:
    // Format 1: BANKMINI:REK:202601001:NIS:10293847:NAMA:Handa
    // Format 2: BANKMINI|202601001|Handa|10293847
    // Format 3: Rekening langsung, misal "202601001"
    String noRek = raw.trim();

    if (raw.contains('BANKMINI:REK:')) {
      final parts = raw.split(':');
      final rekIdx = parts.indexOf('REK');
      if (rekIdx != -1 && rekIdx + 1 < parts.length) {
        noRek = parts[rekIdx + 1];
      }
    } else if (raw.contains('|')) {
      final parts = raw.split('|');
      if (parts.length >= 2) {
        noRek = parts[1];
      }
    }

    _loadDetailAndShowModal(noRek);
  }

  Future<void> _loadDetailAndShowModal(String identifier) async {
    final res = await TellerApiService.getDetailNasabah(identifier);

    if (!mounted) return;

    if (res.success && res.data != null) {
      _showNasabahBottomSheet(res.data!);
    } else {
      showAppSnackbar(
        context,
        res.message.isNotEmpty ? res.message : 'Data nasabah tidak ditemukan',
        isError: true,
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _performManualSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final res = await TellerApiService.searchNasabah(query: query);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResults = res.data ?? [];
    });
  }

  void _showNasabahBottomSheet(Map<String, dynamic> nasabah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final saldo = (nasabah['saldo'] as num?)?.toDouble() ?? 0.0;
        final saldoDapatDitarik =
            (nasabah['saldo_dapat_ditarik'] as num?)?.toDouble() ??
                (saldo - 10000).clamp(0, double.infinity);

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  ProfileAvatar(
                    name: nasabah['nama_siswa'] ?? 'N',
                    size: 46,
                    backgroundColor: AppColors.primaryNavy,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nasabah['nama_siswa'] ?? 'Nasabah Siswa',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${nasabah['kelas'] ?? ''} • NIS: ${nasabah['nis'] ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'No. Rekening: ${nasabah['no_rekening']}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Total Saldo',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(saldo),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: AppColors.border),
                    Column(
                      children: [
                        Text(
                          'Saldo Efektif (Bisa Ditarik)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(saldoDapatDitarik),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Setor Tunai [101]',
                      icon: Icons.arrow_downward_rounded,
                      backgroundColor: AppColors.success,
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SetorTunaiScreen(
                              initialRekening: nasabah['no_rekening'],
                              nasabahData: nasabah,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Tarik Tunai [201]',
                      icon: Icons.arrow_upward_rounded,
                      backgroundColor: AppColors.danger,
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TarikTunaiScreen(
                              initialRekening: nasabah['no_rekening'],
                              nasabahData: nasabah,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Scan Kartu / Cari Siswa',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppColors.accentTeal : Colors.white70,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scanner Camera View
            Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.accentTeal,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Manual Search Input Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                controller: _searchController,
                hint: 'Cari Nama Siswa, NIS, atau Rekening...',
                onChanged: _performManualSearch,
                onClear: () => _performManualSearch(''),
              ),
            ),
            const SizedBox(height: 12),

            // Search Results List
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentTeal,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                    Icons.qr_code_scanner_rounded,
                                    size: 24,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Arahkan kamera ke QR kartu nasabah atau cari secara manual',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final item = _searchResults[idx];
                            return InkWell(
                              onTap: () => _loadDetailAndShowModal(
                                item['no_rekening'],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    ProfileAvatar(
                                      name: item['nama_siswa'] ?? 'N',
                                      size: 38,
                                      backgroundColor: AppColors.primaryNavy,
                                      textColor: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nama_siswa'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item['kelas'] ?? ''} • Rek: ${item['no_rekening']}',
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
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
