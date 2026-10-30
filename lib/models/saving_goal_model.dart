/// Model target tabungan impian / saving goals
class SavingGoalModel {
  final String id;
  final String nama;
  final double targetAmount;
  final double currentAmount;
  final String? icon;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isCompleted;

  SavingGoalModel({
    required this.id,
    required this.nama,
    required this.targetAmount,
    required this.currentAmount,
    this.icon,
    DateTime? createdAt,
    this.deadline,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Persentase ketercapaian target
  double get progressPercent =>
      (currentAmount / targetAmount * 100).clamp(0, 100);

  /// Sisa yang harus ditabung
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);
}
