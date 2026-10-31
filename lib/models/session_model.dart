/// Model sesi login / device log
class SessionModel {
  final String id;
  final String deviceName;
  final String deviceType; // 'android', 'ios', 'web', 'windows'
  final String ipAddress;
  final String location;
  final DateTime lastAccess;
  final bool isCurrentSession;

  SessionModel({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress = '',
    this.location = '',
    required this.lastAccess,
    this.isCurrentSession = false,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    DateTime lastAccess = DateTime.now();
    if (json['last_access'] != null) {
      lastAccess = DateTime.tryParse(json['last_access'].toString()) ?? DateTime.now();
    } else if (json['last_used_at'] != null) {
      lastAccess = DateTime.tryParse(json['last_used_at'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      lastAccess = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return SessionModel(
      id: json['id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? json['name']?.toString() ?? 'Perangkat Terdaftar',
      deviceType: json['device_type']?.toString() ?? 'web',
      ipAddress: json['ip_address']?.toString() ?? '-',
      location: json['location']?.toString() ?? 'Lingkungan Bank Mini',
      lastAccess: lastAccess,
      isCurrentSession: json['is_current'] == true || json['is_current_session'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_name': deviceName,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'location': location,
      'last_access': lastAccess.toIso8601String(),
      'is_current_session': isCurrentSession,
    };
  }
}
