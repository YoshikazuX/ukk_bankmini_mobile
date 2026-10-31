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

  /// Alias getter untuk kompatibilitas tampilan
  double get terkumpul => currentAmount;
  double get target => targetAmount;

  /// Persentase ketercapaian target
  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  /// Sisa yang harus ditabung
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }
    DateTime? deadline;
    if (json['deadline'] != null) {
      deadline = DateTime.tryParse(json['deadline'].toString());
    }

    return SavingGoalModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon']?.toString(),
      createdAt: createdAt,
      deadline: deadline,
      isCompleted: json['is_completed'] == true ||
          json['status'] == 'completed' ||
          ((json['target_amount'] as num?)?.toDouble() ?? 0.0) <=
              ((json['current_amount'] as num?)?.toDouble() ?? 0.0) &&
              ((json['target_amount'] as num?)?.toDouble() ?? 0.0) > 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}
