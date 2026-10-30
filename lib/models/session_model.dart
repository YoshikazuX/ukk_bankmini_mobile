/// Model sesi login / device log
class SessionModel {
  final String id;
  final String deviceName;
  final String deviceType; // 'android', 'ios', 'web'
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
}
