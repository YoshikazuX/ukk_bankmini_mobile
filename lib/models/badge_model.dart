/// Model lencana prestasi menabung (gamification badges)
class BadgeModel {
  final String id;
  final String nama;
  final String deskripsi;
  final String icon;
  final String tier; // 'bronze', 'silver', 'gold'
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.icon,
    required this.tier,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    DateTime? unlockedAt;
    if (json['unlocked_at'] != null) {
      unlockedAt = DateTime.tryParse(json['unlocked_at'].toString());
    }

    return BadgeModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'military_tech',
      tier: json['tier']?.toString() ?? 'bronze',
      isUnlocked: json['is_unlocked'] == true,
      unlockedAt: unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'icon': icon,
      'tier': tier,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }
}
