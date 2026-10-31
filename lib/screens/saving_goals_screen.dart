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

/// Halaman Target Tabungan Impian (Saving Goals / Target Wallet)
/// Menggunakan Backend Laravel sebagai Single Source of Truth
class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  List<SavingGoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

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
      final res = await NasabahApiService.getSavingGoals();
      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _goals = res.data!;
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
              20,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
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
                  'Rencanakan target finansial atau impian pembelian Anda',
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

                          final nav = Navigator.of(sheetCtx);
                          setModalState(() => isSaving = true);
                          final res = await NasabahApiService.createSavingGoal(
                            nama: name,
                            targetAmount: amount,
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
          );
        },
      ),
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
      appBar: AppBar(
        title: Text(
          'Target Tabungan Impian',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan',
            onPressed: _fetchGoals,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Tambah Target',
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          onRefresh: _fetchGoals,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryNavy,
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
                          // Header Banner Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.track_changes_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alokasi Tabungan Terencana',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pantau progres impian tabungan Anda secara transparan.',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Empty State jika belum ada target
                          if (_goals.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
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
                                        fontWeight: FontWeight.w700,
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
                                fontWeight: FontWeight.w700,
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
                                fontWeight: FontWeight.w700,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _goalCard(SavingGoalModel goal) {
    final isCompleted = goal.isCompleted;
    final color = isCompleted ? AppColors.success : AppColors.accentTeal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 28,
            lineWidth: 4.5,
            percent: (goal.progressPercent / 100).clamp(0.0, 1.0),
            center: Text(
              '${goal.progressPercent.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      label: isCompleted ? 'Tercapai' : 'Berjalan',
                      type: isCompleted
                          ? StatusBadgeType.success
                          : StatusBadgeType.info,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Terkumpul: ${formatRupiah(goal.currentAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Target: ${formatRupiah(goal.targetAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
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
    );
  }
}
