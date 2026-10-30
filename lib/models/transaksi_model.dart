/// Model transaksi perbankan mini (setoran, penarikan, dan transfer)
class TransaksiModel {
  final String id;
  final String noRekening;
  final String jenis; // 'SETORAN' atau 'PENARIKAN'
  final double jumlah;
  final double saldoSebelum;
  final double saldoSesudah;
  final String? keterangan;
  final String? tellerName;
  final DateTime tanggal;
  final bool isRead;
  final String? jenisTransaksiRaw; // 'setor', 'tarik', 'transfer_masuk', 'transfer_keluar'

  TransaksiModel({
    required this.id,
    required this.noRekening,
    required this.jenis,
    required this.jumlah,
    required this.saldoSebelum,
    required this.saldoSesudah,
    this.keterangan,
    this.tellerName,
    required this.tanggal,
    this.isRead = false,
    this.jenisTransaksiRaw,
  });

  bool get isSetoran => jenis == 'SETORAN';
  bool get isPenarikan => jenis == 'PENARIKAN';
  bool get isTransferMasuk => jenisTransaksiRaw == 'transfer_masuk';
  bool get isTransferKeluar => jenisTransaksiRaw == 'transfer_keluar';
  bool get isTransfer => isTransferMasuk || isTransferKeluar;

  bool get isDebit => isPenarikan || isTransferKeluar;
  bool get isSuccess => true;
  String get status => 'Berhasil';
  String get namaTransaksi => isSetoran
      ? 'Setor Tunai'
      : (isTransfer
          ? (isTransferMasuk ? 'Transfer Masuk' : 'Transfer Keluar')
          : 'Tarik Tunai');
  String get formattedTanggal =>
      '${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year} ${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}';
  String get kodeSandi => isSetoran ? '101' : (isPenarikan ? '201' : '301');

  String get displayBadge {
    if (isTransferMasuk) return 'TRANSFER MASUK';
    if (isTransferKeluar) return 'TRANSFER KELUAR';
    return jenis;
  }

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['jenis_transaksi'] ?? json['jenis'] ?? '')
        .toString()
        .toLowerCase();

    // Klasifikasi transaksi masuk vs keluar
    final bool isIncoming = rawType == 'setor' ||
        rawType == 'transfer_masuk' ||
        rawType == 'setoran' ||
        rawType == 'kredit';

    final String computedJenis = isIncoming ? 'SETORAN' : 'PENARIKAN';

    final double jumlah = (json['nominal'] ?? json['jumlah'] ?? 0).toDouble();

    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate =
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['tanggal'] != null) {
      if (json['tanggal'] is DateTime) {
        parsedDate = json['tanggal'];
      } else {
        parsedDate =
            DateTime.tryParse(json['tanggal'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return TransaksiModel(
      id: json['id']?.toString() ?? '',
      noRekening: (json['no_rekening'] ?? json['noRekening'] ?? '').toString(),
      jenis: computedJenis,
      jumlah: jumlah,
      saldoSebelum:
          (json['saldo_sebelum'] ?? json['saldoSebelum'] ?? 0).toDouble(),
      saldoSesudah:
          (json['saldo_sesudah'] ?? json['saldoSesudah'] ?? 0).toDouble(),
      keterangan: json['keterangan'] ?? json['catatan'],
      tellerName:
          json['nama_petugas'] ?? json['teller_name'] ?? json['tellerName'],
      tanggal: parsedDate,
      isRead: json['is_read'] == true || json['isRead'] == true,
      jenisTransaksiRaw: rawType.isNotEmpty ? rawType : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_rekening': noRekening,
      'jenis': jenis,
      'jenis_transaksi': jenisTransaksiRaw ?? (isSetoran ? 'setor' : 'tarik'),
      'nominal': jumlah,
      'saldo_sebelum': saldoSebelum,
      'saldo_sesudah': saldoSesudah,
      'keterangan': keterangan,
      'nama_petugas': tellerName,
      'created_at': tanggal.toIso8601String(),
      'is_read': isRead,
    };
  }
}
