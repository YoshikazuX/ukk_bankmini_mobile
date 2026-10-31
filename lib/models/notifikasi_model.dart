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

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    DateTime timestamp = DateTime.now();
    if (json['created_at'] != null) {
      timestamp = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['timestamp'] != null) {
      timestamp = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    }

    return NotifikasiModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['judul']?.toString() ?? 'Pemberitahuan Bank Mini',
      message: json['message']?.toString() ?? json['pesan']?.toString() ?? '',
      jenis: (json['type']?.toString() ?? json['jenis']?.toString() ?? 'SYSTEM').toUpperCase(),
      timestamp: timestamp,
      isRead: json['is_read'] == true || json['read_at'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'jenis': jenis,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}
