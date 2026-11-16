import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/saving_goal_model.dart';
import '../services/nasabah_api_service.dart';
import '../widgets/common/app_buttons.dart';
import '../widgets/common/app_cards.dart';
import '../widgets/common/app_inputs.dart';
import '../widgets/common/app_states.dart';

/// Halaman Target Tabungan Impian (Saving Goals / Alokasi Saldo Siswa)
/// Menggunakan Backend Laravel sebagai Single Source of Truth
/// Saldo utama di dashboard tetap utuh, dana disisihkan secara internal ke target tabungan.
class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  List<SavingGoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Ringkasan saldo rekening & alokasi tabungan
  double _saldoRekening = 0.0;
  double _totalTeralokasi = 0.0;
  double _saldoTersedia = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await NasabahApiService.getSavingGoalsSummary();
      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _goals = res.data!.goals;
          _saldoRekening = res.data!.saldoRekening;
          _totalTeralokasi = res.data!.totalTeralokasi;
          _saldoTersedia = res.data!.saldoTersedia;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.message.isNotEmpty
              ? res.message
              : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.';
        _isLoading = false;
      });
    }
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final initialController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
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
                  Text(
                    'Buat Target Tabungan Baru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rencanakan target impian Anda. Saldo dapat disisihkan dari saldo rekening yang ada.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    controller: nameController,
                    label: 'Nama Target Tabungan',
                    hint: 'Contoh: Buku Pelajaran SMK, Laptop Sekolah',
                  ),
                  const SizedBox(height: 14),
                  InputField(
                    controller: amountController,
                    label: 'Target Nominal (Rp)',
                    hint: 'Contoh: 500000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  InputField(
                    controller: initialController,
                    label: 'Nominal Awal yang Disisihkan (Opsional)',
                    hint: _saldoTersedia > 0
                        ? 'Maks. ${formatRupiah(_saldoTersedia)}'
                        : 'Saldo rekening tersedia: Rp 0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Simpan Target Tabungan',
                    icon: Icons.check_rounded,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final amountText = amountController.text
                                .replaceAll('.', '')
                                .replaceAll(',', '')
                                .trim();
                            final amount = double.tryParse(amountText);

                            final initialText = initialController.text
                                .replaceAll('.', '')
                                .replaceAll(',', '')
                                .trim();
                            final initialAmount = double.tryParse(initialText) ?? 0.0;

                            if (name.isEmpty) {
                              showAppSnackbar(
                                context,
                                'Nama target tabungan wajib diisi',
                                isError: true,
                              );
                              return;
                            }
                            if (amount == null || amount <= 0) {
                              showAppSnackbar(
                                context,
                                'Target nominal harus lebih besar dari 0',
                                isError: true,
                              );
                              return;
                            }
                            if (initialAmount > _saldoTersedia) {
                              showAppSnackbar(
                                context,
                                'Nominal awal melebihi sisa saldo rekening bebas (${formatRupiah(_saldoTersedia)})',
                                isError: true,
                              );
                              return;
                            }

                            final nav = Navigator.of(sheetCtx);
                            setModalState(() => isSaving = true);
                            final res = await NasabahApiService.createSavingGoal(
                              nama: name,
                              targetAmount: amount,
                              currentAmount: initialAmount > 0 ? initialAmount : 0,
                            );

                            if (!mounted) return;
                            setModalState(() => isSaving = false);

                            if (res.success) {
                              nav.pop();
                              showAppSnackbar(
                                context,
                                'Target tabungan "$name" berhasil dibuat!',
                              );
                              _fetchGoals();
                            } else {
                              showAppSnackbar(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Gagal membuat target tabungan',
                                isError: true,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAlokasiDialog(SavingGoalModel goal) {
    String mode = 'tambah'; // 'tambah', 'set', 'kurang'
    final nominalController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final rawNominal = nominalController.text
              .replaceAll('.', '')
              .replaceAll(',', '')
              .trim();
          final inputNominal = double.tryParse(rawNominal) ?? 0.0;

          // Estimasi kalkulasi
          double estimatedGoal = goal.currentAmount;
          double estimatedSisaBebas = _saldoTersedia;

          if (mode == 'tambah') {
            estimatedGoal = (goal.currentAmount + inputNominal).clamp(0.0, goal.targetAmount);
            estimatedSisaBebas = _saldoTersedia - inputNominal;
          } else if (mode == 'kurang') {
            estimatedGoal = (goal.currentAmount - inputNominal).clamp(0.0, double.infinity);
            estimatedSisaBebas = _saldoTersedia + inputNominal;
          } else {
            // 'set'
            estimatedGoal = inputNominal.clamp(0.0, goal.targetAmount);
            final selisih = inputNominal - goal.currentAmount;
            estimatedSisaBebas = _saldoTersedia - selisih;
          }

          final bool isOverBudget = (mode == 'tambah' && inputNominal > _saldoTersedia) ||
              (mode == 'kurang' && inputNominal > goal.currentAmount) ||
              (mode == 'set' && inputNominal > (_saldoTersedia + goal.currentAmount));

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisihkan Saldo ke Target',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          goal.nama,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentTealHover,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo rekening di dashboard tetap utuh, dicatat tersisihkan khusus target ini.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Detail Kartu Info Alokasi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Target Nominal:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            Text(formatRupiah(goal.targetAmount), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Saat Ini Terkumpul:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            Text(formatRupiah(goal.currentAmount), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentTealHover)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sisa Menuju Target:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            Text(formatRupiah(goal.remaining), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                        const Divider(height: 14, color: AppColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sisa Saldo Bebas:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(formatRupiah(_saldoTersedia), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _modeChip(
                          label: 'Tambah Saldo',
                          isSelected: mode == 'tambah',
                          onTap: () => setModalState(() => mode = 'tambah'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _modeChip(
                          label: 'Atur Total',
                          isSelected: mode == 'set',
                          onTap: () => setModalState(() => mode = 'set'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _modeChip(
                          label: 'Tarik Bebas',
                          isSelected: mode == 'kurang',
                          onTap: () => setModalState(() => mode = 'kurang'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Input Nominal
                  InputField(
                    controller: nominalController,
                    label: mode == 'tambah'
                        ? 'Nominal yang Ingin Disisihkan (Rp)'
                        : mode == 'kurang'
                            ? 'Nominal yang Ditarik ke Saldo Bebas (Rp)'
                            : 'Set Nominal Total Tabungan (Rp)',
                    hint: 'Contoh: 50000',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Quick Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _quickChip('+Rp 10.000', 10000, nominalController, setModalState),
                      _quickChip('+Rp 20.000', 20000, nominalController, setModalState),
                      _quickChip('+Rp 50.000', 50000, nominalController, setModalState),
                      _quickChip('+Rp 100.000', 100000, nominalController, setModalState),
                      if (goal.remaining > 0 && mode == 'tambah')
                        ActionChip(
                          label: Text(
                            'Penuhkan (${formatRupiah(goal.remaining)})',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentTealHover,
                            ),
                          ),
                          backgroundColor: AppColors.greenLight,
                          side: const BorderSide(color: AppColors.accentTealHover),
                          onPressed: () {
                            setModalState(() {
                              final fillNominal = goal.remaining > _saldoTersedia
                                  ? _saldoTersedia
                                  : goal.remaining;
                              nominalController.text = fillNominal.toInt().toString();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Info Estimasi Hasil
                  if (inputNominal > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOverBudget
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.greenLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOverBudget
                              ? AppColors.danger.withValues(alpha: 0.3)
                              : AppColors.accentTealHover.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOverBudget
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: isOverBudget ? AppColors.danger : AppColors.accentTealHover,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isOverBudget
                                  ? (mode == 'tambah'
                                      ? 'Nominal melebihi sisa saldo bebas (${formatRupiah(_saldoTersedia)})'
                                      : mode == 'kurang'
                                          ? 'Nominal melebihi dana tabungan (${formatRupiah(goal.currentAmount)})'
                                          : 'Nominal melebihi kapasitas saldo')
                                  : 'Target akan terkumpul: ${formatRupiah(estimatedGoal)} (Sisa saldo bebas: ${formatRupiah(estimatedSisaBebas)})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isOverBudget ? AppColors.danger : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  PrimaryButton(
                    text: mode == 'tambah'
                        ? 'Sisihkan Saldo Sekarang'
                        : mode == 'kurang'
                            ? 'Tarik Dana ke Saldo Bebas'
                            : 'Setel Nominal Tabungan',
                    icon: Icons.check_rounded,
                    isLoading: isSaving,
                    onPressed: (isSaving || isOverBudget || inputNominal <= 0)
                        ? null
                        : () async {
                            final nav = Navigator.of(sheetCtx);
                            setModalState(() => isSaving = true);
                            final res = await NasabahApiService.alokasikanDanaSavingGoal(
                              id: goal.id,
                              nominal: inputNominal,
                              mode: mode,
                            );

                            if (!mounted) return;
                            setModalState(() => isSaving = false);

                            if (res.success) {
                              nav.pop();
                              showAppSnackbar(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Alokasi target "${goal.nama}" berhasil diperbarui!',
                              );
                              _fetchGoals();
                            } else {
                              showAppSnackbar(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Gagal menyisihkan saldo tabungan',
                                isError: true,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTeal : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentTealHover : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _quickChip(
    String label,
    double value,
    TextEditingController controller,
    StateSetter setModalState,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surfaceMuted,
      side: const BorderSide(color: AppColors.border),
      onPressed: () {
        setModalState(() {
          final cur = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
          controller.text = (cur + value).toInt().toString();
        });
      },
    );
  }

  Future<void> _confirmDeleteGoal(SavingGoalModel goal) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Hapus Target Tabungan',
      message: 'Apakah Anda yakin ingin menghapus target "${goal.nama}"?',
      confirmLabel: 'Hapus Target',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      final res = await NasabahApiService.deleteSavingGoal(goal.id);
      if (!mounted) return;
      if (res.success) {
        showAppSnackbar(context, 'Target "${goal.nama}" berhasil dihapus');
        _fetchGoals();
      } else {
        showAppSnackbar(
          context,
          res.message.isNotEmpty ? res.message : 'Gagal menghapus target tabungan',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGoals = _goals.where((g) => !g.isCompleted).toList();
    final completedGoals = _goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Target Tabungan',
            subtitle: 'Alokasi dan perencanaan tabungan siswa',
            showBackButton: Navigator.canPop(context),
            onBack: () => Navigator.maybePop(context),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.accentTealHover),
                tooltip: 'Tambah Target',
                onPressed: _showAddGoalDialog,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentTealHover,
              onRefresh: _fetchGoals,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accentTealHover,
                      ),
                    )
                  : _errorMessage != null
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: ErrorState(
                              title: 'Gagal Memuat Target',
                              message: _errorMessage!,
                              onRetry: _fetchGoals,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Ringkasan Saldo Rekening & Alokasi Terencana
                              Container(
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
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.greenLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet_rounded,
                                            color: AppColors.accentTealHover,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Saldo Rekening Siswa',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                formatRupiah(_saldoRekening),
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Disisihkan',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formatRupiah(_totalTeralokasi),
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.accentTealHover,
                                                  ),
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
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sisa Saldo Bebas',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formatRupiah(_saldoTersedia),
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Setoran teller langsung masuk ke saldo rekening. Anda dapat menyisihkan dana ke target impian kapan saja tanpa mengurangi total saldo di dashboard.',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Empty State jika belum ada target
                              if (_goals.isEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: AppColors.cardShadow,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.savings_outlined,
                                          size: 40,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Belum Ada Target Tabungan',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Klik tombol "+" di pojok kanan atas untuk merencanakan target tabungan Anda.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Active Goals
                              if (activeGoals.isNotEmpty) ...[
                                Text(
                                  'Target Tabungan Aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...activeGoals.map((goal) => _goalCard(goal)),
                              ],

                              // Completed Goals
                              if (completedGoals.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Target Telah Tercapai',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...completedGoals.map((goal) => _goalCard(goal)),
                              ],
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppColors.accentTeal,
        foregroundColor: Colors.white,
        elevation: 1,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _goalCard(SavingGoalModel goal) {
    final isCompleted = goal.isCompleted;
    final color = isCompleted ? AppColors.success : AppColors.accentTealHover;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircularPercentIndicator(
                radius: 28,
                lineWidth: 4.5,
                percent: (goal.progressPercent / 100).clamp(0.0, 1.0),
                center: Text(
                  '${goal.progressPercent.toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                progressColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.nama,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          label: isCompleted ? 'Tercapai' : 'Berjalan',
                          color: isCompleted ? AppColors.success : AppColors.accentTealHover,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Terkumpul: ',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          formatRupiah(goal.currentAmount),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          'Target: ',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                        ),
                        Text(
                          formatRupiah(goal.targetAmount),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Hapus Target',
                onPressed: () => _confirmDeleteGoal(goal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCompleted ? AppColors.success : AppColors.accentTealHover,
                    side: BorderSide(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.6)
                          : AppColors.accentTealHover,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: () => _showAlokasiDialog(goal),
                  icon: Icon(
                    isCompleted ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
                    size: 15,
                  ),
                  label: Text(
                    isCompleted ? 'Atur Alokasi Tabungan' : 'Sisihkan Saldo ke Target',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
