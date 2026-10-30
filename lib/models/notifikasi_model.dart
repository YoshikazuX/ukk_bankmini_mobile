/// Model notifikasi transaksi real-time
class NotifikasiModel {
  final String id;
  final String title;
  final String message;
  final String jenis; // 'SETORAN', 'PENARIKAN', 'SYSTEM', 'KEAMANAN'
  final DateTime timestamp;
  bool isRead;

  NotifikasiModel({
    required this.id,
    required this.title,
    required this.message,
    required this.jenis,
    required this.timestamp,
    this.isRead = false,
  });
}
