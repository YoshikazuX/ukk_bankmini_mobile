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
}
