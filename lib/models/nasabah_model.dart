/// Model data nasabah (customer/student) disesuaikan dengan database Laravel Bank Mini Sekolah
class NasabahModel {
  final String id;
  final String noRekening;
  final String nis;
  final String namaLengkap;
  final String kelas;
  final String jurusan;
  final String kategori;
  final String status; // 'AKTIF', 'DIBLOKIR', 'NONAKTIF'
  final double totalSaldo;
  final double saldoMengendap; // Rp10.000
  final String? fotoProfil;
  final String? username;
  final String pinKeamanan;
  final DateTime createdAt;

  NasabahModel({
    required this.id,
    required this.noRekening,
    required this.nis,
    required this.namaLengkap,
    required this.kelas,
    required this.jurusan,
    this.kategori = 'SISWA',
    this.status = 'AKTIF',
    required this.totalSaldo,
    this.saldoMengendap = 10000,
    this.fotoProfil,
    this.username,
    this.pinKeamanan = '240808',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory constructor untuk memetakan respon JSON dari Laravel API
  factory NasabahModel.fromJson(Map<String, dynamic> json) {
    return NasabahModel(
      id: (json['id_nasabah'] ?? json['id'] ?? '').toString(),
      noRekening: (json['no_rekening'] ?? '').toString(),
      nis: (json['nis'] ?? '').toString(),
      namaLengkap: (json['nama_siswa'] ?? json['nama'] ?? '').toString(),
      kelas: (json['kelas'] ?? '').toString(),
      jurusan: (json['jurusan'] ?? '').toString(),
      kategori: (json['kategori'] ?? 'SISWA').toString().toUpperCase(),
      status: (json['status'] ?? 'AKTIF').toString().toUpperCase(),
      totalSaldo: double.tryParse((json['saldo'] ?? 0).toString()) ?? 0.0,
      saldoMengendap:
          double.tryParse((json['saldo_mengendap'] ?? 10000).toString()) ??
              10000.0,
      fotoProfil: json['foto_url']?.toString(),
      username: json['username']?.toString(),
      pinKeamanan: (json['pin_keamanan'] ?? '240808').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_rekening': noRekening,
      'nis': nis,
      'nama_siswa': namaLengkap,
      'kelas': kelas,
      'jurusan': jurusan,
      'kategori': kategori,
      'status': status,
      'saldo': totalSaldo,
      'saldo_mengendap': saldoMengendap,
      'foto_url': fotoProfil,
      'username': username,
      'pin_keamanan': pinKeamanan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Saldo maksimal yang boleh ditarik (Saldo Efektif / Tersedia)
  double get saldoEfektif =>
      (totalSaldo - saldoMengendap).clamp(0, double.infinity);

  /// Alias saldoTersedia sesuai PRD
  double get saldoTersedia => saldoEfektif;

  /// Status keaktifan rekening
  bool get isActive => status.toUpperCase() == 'AKTIF';

  /// Status rekening dibekukan / diblokir
  bool get isBlocked =>
      status.toUpperCase() == 'DIBLOKIR' || status.toUpperCase() == 'NONAKTIF';

  /// Payload QRIS / Kartu Digital Siswa
  String get qrisPayload =>
      'BANKMINI:REK:$noRekening:NIS:$nis:NAMA:$namaLengkap';

  /// Cek kecukupan saldo efektif
  bool canWithdraw(double amount) => amount <= saldoEfektif;

  NasabahModel copyWith({
    String? status,
    double? totalSaldo,
    String? pinKeamanan,
  }) {
    return NasabahModel(
      id: id,
      noRekening: noRekening,
      nis: nis,
      namaLengkap: namaLengkap,
      kelas: kelas,
      jurusan: jurusan,
      kategori: kategori,
      status: status ?? this.status,
      totalSaldo: totalSaldo ?? this.totalSaldo,
      saldoMengendap: saldoMengendap,
      fotoProfil: fotoProfil,
      username: username,
      pinKeamanan: pinKeamanan ?? this.pinKeamanan,
      createdAt: createdAt,
    );
  }
}
