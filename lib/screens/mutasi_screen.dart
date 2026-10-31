import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/transaksi_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_states.dart';

/// Halaman Riwayat Mutasi / Buku Tabungan Digital
class MutasiScreen extends StatefulWidget {
  const MutasiScreen({super.key});

  @override
  State<MutasiScreen> createState() => _MutasiScreenState();
}

class _MutasiScreenState extends State<MutasiScreen> {
  String _filterJenis = 'SEMUA'; // SEMUA, SETORAN, PENARIKAN
  List<TransaksiModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMutasi();
  }

  Future<void> _fetchMutasi() async {
    setState(() => _isLoading = true);
    try {
      final res = await NasabahApiService.getRiwayat();
      if (res.data != null && mounted) {
        setState(() {
          _transactions = res.data!;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailTransaksi(TransaksiModel trx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rincian Transaksi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusBadge(
                  label: trx.status,
                  color: trx.isSuccess ? AppColors.success : AppColors.danger,
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
              child: Column(
                children: [
                  _detailRow('Nominal Transaksi', formatRupiah(trx.jumlah), isPrimary: true),
                  const Divider(color: AppColors.border, height: 16),
                  _detailRow('Jenis Mutasi', trx.jenis),
                  const SizedBox(height: 8),
                  _detailRow('Kode Sandi', trx.kodeSandi.isNotEmpty ? trx.kodeSandi : '-'),
                  const SizedBox(height: 8),
                  _detailRow('Keterangan', (trx.keterangan != null && trx.keterangan!.isNotEmpty) ? trx.keterangan! : trx.namaTransaksi),
                  const SizedBox(height: 8),
                  _detailRow('Waktu Transaksi', trx.formattedTanggal),
                  const SizedBox(height: 8),
                  _detailRow('ID Transaksi', '#TRX-${trx.id}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isPrimary = false}) {
    final isMonospaced = isPrimary || value.startsWith('Rp') || value.startsWith('#');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isMonospaced
              ? GoogleFonts.jetBrainsMono(
                  fontSize: isPrimary ? 16 : 12,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.textPrimary,
                )
              : GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = _transactions;

    final filteredTransactions = _filterJenis == 'SEMUA'
        ? allTransactions
        : allTransactions.where((t) {
            if (_filterJenis == 'SETORAN') return t.isSetoran;
            if (_filterJenis == 'PENARIKAN') return t.isPenarikan;
            return t.jenis == _filterJenis;
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bersih Institusional (Quiet Chrome)
          PageHeader(
            title: 'Buku Tabungan Digital',
            subtitle: 'Riwayat mutasi transaksi rekening siswa',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
          ),

          // Filter Segmented Strip (Clean Pill Filter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildFilterItem('SEMUA', 'Semua Transaksi'),
                const SizedBox(width: 8),
                _buildFilterItem('SETORAN', 'Setoran (+)'),
                const SizedBox(width: 8),
                _buildFilterItem('PENARIKAN', 'Penarikan (-)'),
              ],
            ),
          ),

          // Transaction Count Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ${filteredTransactions.length} Transaksi Tercatat',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Terurut terbaru',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // List Mutasi
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentTealHover,
              backgroundColor: AppColors.surface,
              onRefresh: _fetchMutasi,
              child: _isLoading && _transactions.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accentTealHover,
                      ),
                    )
                  : filteredTransactions.isEmpty
                      ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'Belum Ada Mutasi',
                          message: 'Tidak ditemukan transaksi pada kategori ini.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final trx = filteredTransactions[index];
                        return TransactionItem(
                          title: (trx.keterangan != null && trx.keterangan!.isNotEmpty)
                              ? trx.keterangan!
                              : trx.namaTransaksi,
                          subtitle: '${trx.formattedTanggal} • ${trx.kodeSandi.isNotEmpty ? "[${trx.kodeSandi}]" : ""}',
                          amount: trx.jumlah,
                          isDebit: trx.isDebit,
                          status: trx.status,
                          onTap: () => _showDetailTransaksi(trx),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String value, String label) {
    final isSelected = _filterJenis == value;
    return InkWell(
      onTap: () => setState(() => _filterJenis = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentTealHover : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.accentTealHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
