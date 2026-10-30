/// Model data pegawai (Teller, Supervisor, Admin)
class PetugasModel {
  final int id;
  final String username;
  final String namaPetugas;
  final String role; // 'teller', 'supervisor', 'admin'
  final String? kelas;
  final String? noHp;
  final String? email;
  final String? fotoUrl;
  final Map<String, dynamic>? shiftHariIni;

  const PetugasModel({
    required this.id,
    required this.username,
    required this.namaPetugas,
    required this.role,
    this.kelas,
    this.noHp,
    this.email,
    this.fotoUrl,
    this.shiftHariIni,
  });

  /// Factory constructor dari respon JSON Laravel
  factory PetugasModel.fromJson(Map<String, dynamic> json) {
    return PetugasModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: (json['username'] ?? '').toString(),
      namaPetugas: (json['nama_petugas'] ?? json['nama'] ?? '').toString(),
      role: (json['role'] ?? 'teller').toString().toLowerCase().trim(),
      kelas: json['kelas']?.toString(),
      noHp: json['no_hp']?.toString(),
      email: json['email']?.toString(),
      fotoUrl: json['foto_url']?.toString(),
      shiftHariIni: json['shift_hari_ini'] is Map<String, dynamic>
          ? json['shift_hari_ini'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_petugas': namaPetugas,
      'role': role,
      'kelas': kelas,
      'no_hp': noHp,
      'email': email,
      'foto_url': fotoUrl,
      'shift_hari_ini': shiftHariIni,
    };
  }

  bool get isTeller => role == 'teller';
  bool get isSupervisor => role == 'supervisor' || role == 'accounting';
  bool get isAdmin => role == 'admin';

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Administrator Utama';
      case 'supervisor':
      case 'accounting':
        return 'Supervisor / Kepala Bank';
      case 'teller':
      default:
        return 'Petugas Loket Teller';
    }
  }
}

