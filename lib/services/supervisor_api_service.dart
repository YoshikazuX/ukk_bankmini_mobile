import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';

/// Service API untuk Modul Supervisor & Laporan Eksekutif Bank Mini
class SupervisorApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. APPROVAL PENGAJUAN DROPING KAS
  // =========================================================================

  /// Mengambil seluruh tiket pengajuan droping kas dari loket teller
  static Future<ApiResponse<List<Map<String, dynamic>>>> listPengajuanKas({
    String? status,
    String? tanggal,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (tanggal != null && tanggal.isNotEmpty) queryParams['tanggal'] = tanggal;

      final response = await _api.get(
        ApiConstants.supervisorPengajuanKas,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final list = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflinePengajuanKasList(status),
        message: 'Daftar tiket droping kas (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflinePengajuanKasList(status),
        message: 'Daftar tiket droping kas (Offline)',
      );
    }
  }

  /// Supervisor menyetujui tiket droping kas teller
  static Future<ApiResponse<Map<String, dynamic>>> setujuiPengajuanKas(
    dynamic id, {
    String? catatan,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.supervisorSetujuiKas(id),
        data: {
          'catatan_spv': catatan?.trim() ?? 'Disetujui untuk operasional kas loket',
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: {'id': id, 'status': 'disetujui'},
        message: 'Tiket droping kas berhasil disetujui! (Mode Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {'id': id, 'status': 'disetujui'},
        message: 'Tiket droping kas berhasil disetujui! (Mode Offline)',
      );
    }
  }

  /// Supervisor menolak tiket droping kas teller
  static Future<ApiResponse<Map<String, dynamic>>> tolakPengajuanKas(
    dynamic id, {
    String? catatan,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.supervisorTolakKas(id),
        data: {
          'catatan_spv': catatan?.trim() ?? 'Ditolak: Kas loket dinilai masih mencukupi.',
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: {'id': id, 'status': 'ditolak'},
        message: 'Tiket droping kas telah ditolak. (Mode Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {'id': id, 'status': 'ditolak'},
        message: 'Tiket droping kas telah ditolak. (Mode Offline)',
      );
    }
  }

  // =========================================================================
  // 2. VERIFIKASI DAILY CLOSING REPORT TELLER
  // =========================================================================

  /// Mengambil daftar laporan tutup kas harian dari seluruh teller
  static Future<ApiResponse<List<Map<String, dynamic>>>> listDailyReport({
    String? status,
    String? tanggal,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (tanggal != null && tanggal.isNotEmpty) queryParams['tanggal'] = tanggal;

      final response = await _api.get(
        ApiConstants.supervisorDailyReport,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final list = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflineDailyReportList(status),
        message: 'Daftar daily report (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflineDailyReportList(status),
        message: 'Daftar daily report (Offline)',
      );
    }
  }

  /// Supervisor memverifikasi status daily report (approved / hold / rejected)
  static Future<ApiResponse<Map<String, dynamic>>> updateStatusDailyReport(
    dynamic id, {
    required String status, // 'approved', 'hold', 'rejected', 'verified'
    String? notes,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.supervisorUpdateDailyReport(id),
        data: {
          'status': status,
          'notes': notes?.trim(),
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: {'id': id, 'status': status},
        message: 'Status daily report diperbarui (Mode Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {'id': id, 'status': status},
        message: 'Status daily report diperbarui (Mode Offline)',
      );
    }
  }

  // =========================================================================
  // 3. LAPORAN EKSEKUTIF, ARUS KAS & SALDO KELAS
  // =========================================================================

  /// Ringkasan eksekutif bank mini hari ini (Total nasabah, dana, kas fisik)
  static Future<ApiResponse<Map<String, dynamic>>> getRingkasanHarian() async {
    try {
      final response = await _api.get(ApiConstants.laporanRingkasanHarian);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflineRingkasanHarian(),
        message: 'Ringkasan eksekutif (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflineRingkasanHarian(),
        message: 'Ringkasan eksekutif (Offline)',
      );
    }
  }

  /// Distribusi simpanan tabungan siswa per kelas
  static Future<ApiResponse<List<Map<String, dynamic>>>> getSaldoPerKelas() async {
    try {
      final response = await _api.get(ApiConstants.laporanSaldoPerKelas);

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final list = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflineSaldoPerKelas(),
        message: 'Distribusi saldo per kelas (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflineSaldoPerKelas(),
        message: 'Distribusi saldo per kelas (Offline)',
      );
    }
  }

  /// Mutasi Jurnal Akuntansi (Buku Besar Transaksi Bank Mini)
  static Future<ApiResponse<Map<String, dynamic>>> getMutasiJurnal({
    String? dariTanggal,
    String? sampaiTanggal,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dariTanggal != null) queryParams['dari_tanggal'] = dariTanggal;
      if (sampaiTanggal != null) queryParams['sampai_tanggal'] = sampaiTanggal;

      final response = await _api.get(
        ApiConstants.laporanMutasiJurnal,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflineMutasiJurnal(),
        message: 'Jurnal akuntansi (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflineMutasiJurnal(),
        message: 'Jurnal akuntansi (Offline)',
      );
    }
  }

  // =========================================================================
  // HELPER DATA DUMMY OFFLINE SUPERVISOR
  // =========================================================================

  static List<Map<String, dynamic>> _getOfflinePengajuanKasList(String? status) {
    final all = [
      {
        'id': 1,
        'nomor_pengajuan': 'PK-20261030-001',
        'tanggal': DateTime.now().toString().substring(0, 10),
        'nominal': 1000000.0,
        'formatted_nominal': 'Rp 1.000.000',
        'alasan': 'Tambahan modal kerja pagi loket teller 1',
        'status': 'pending',
        'nama_teller': 'Petugas Teller 1',
        'kelas_teller': 'XII AKL 1',
        'disetujui_oleh': '-',
        'catatan_spv': null,
        'created_at': DateTime.now().toString().substring(0, 19),
      },
      {
        'id': 2,
        'nomor_pengajuan': 'PK-20261029-002',
        'tanggal': DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .substring(0, 10),
        'nominal': 500000.0,
        'formatted_nominal': 'Rp 500.000',
        'alasan': 'Antrean penarikan siswa tinggi',
        'status': 'disetujui',
        'nama_teller': 'Petugas Teller 1',
        'kelas_teller': 'XII AKL 1',
        'disetujui_oleh': 'Supervisor 1',
        'catatan_spv': 'Disetujui untuk cadangan kas loket',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .substring(0, 19),
      },
    ];

    if (status == null || status.isEmpty) return all;
    return all.where((item) => item['status'] == status).toList();
  }

  static List<Map<String, dynamic>> _getOfflineDailyReportList(String? status) {
    final all = [
      {
        'id': 1,
        'report_date': DateTime.now().toString().substring(0, 10),
        'nama_teller': 'Petugas Teller 1',
        'kelas_teller': 'XII AKL 1',
        'opening_balance': 2000000.0,
        'total_deposit': 350000.0,
        'total_withdrawal': 100000.0,
        'system_balance': 2250000.0,
        'physical_balance': 2250000.0,
        'difference': 0.0,
        'status': 'pending',
        'notes': 'Rekonsiliasi kas loket selesai dengan selisih 0',
        'verified_by': '-',
      },
      {
        'id': 2,
        'report_date': DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .substring(0, 10),
        'nama_teller': 'Petugas Teller 1',
        'kelas_teller': 'XII AKL 1',
        'opening_balance': 1500000.0,
        'total_deposit': 700000.0,
        'total_withdrawal': 200000.0,
        'system_balance': 2000000.0,
        'physical_balance': 2000000.0,
        'difference': 0.0,
        'status': 'approved',
        'notes': 'Laporan valid dan fisik uang sesuai',
        'verified_by': 'Supervisor 1',
      },
    ];

    if (status == null || status.isEmpty) return all;
    return all.where((item) => item['status'] == status).toList();
  }

  static Map<String, dynamic> _getOfflineRingkasanHarian() {
    return {
      'nasabah': {
        'total_nasabah_aktif': 128,
        'total_dana_tabungan': 14850000.0,
        'formatted_dana_tabungan': 'Rp 14.850.000',
      },
      'kas_operasional': {
        'kas_fisik_tersedia': 3500000.0,
        'formatted_kas_fisik': 'Rp 3.500.000',
        'kas_masuk_hari_ini': 450000.0,
        'formatted_kas_masuk': 'Rp 450.000',
        'kas_keluar_hari_ini': 120000.0,
        'formatted_kas_keluar': 'Rp 120.000',
      },
      'transaksi_hari_ini': {
        'frekuensi_transaksi': 14,
        'frekuensi_setor': 10,
        'frekuensi_tarik': 4,
      },
      'petugas_avalis': {
        'total_jadwal': 4,
        'hadir': 4,
      },
    };
  }

  static List<Map<String, dynamic>> _getOfflineSaldoPerKelas() {
    return [
      {
        'kelas': 'X DKV 1',
        'total_siswa': 32,
        'total_saldo': 3200000.0,
        'formatted_saldo': 'Rp 3.200.000',
        'rata_rata_saldo': 100000.0,
      },
      {
        'kelas': 'XI AKL 2',
        'total_siswa': 30,
        'total_saldo': 4500000.0,
        'formatted_saldo': 'Rp 4.500.000',
        'rata_rata_saldo': 150000.0,
      },
      {
        'kelas': 'XII RPL 1',
        'total_siswa': 34,
        'total_saldo': 7150000.0,
        'formatted_saldo': 'Rp 7.150.000',
        'rata_rata_saldo': 210294.0,
      },
    ];
  }

  static Map<String, dynamic> _getOfflineMutasiJurnal() {
    return {
      'periode': {
        'dari': DateTime.now().toString().substring(0, 10),
        'sampai': DateTime.now().toString().substring(0, 10),
      },
      'summary': {
        'total_entri': 3,
        'total_debit': 1550000.0,
        'formatted_debit': 'Rp 1.550.000',
        'total_kredit': 100000.0,
        'formatted_kredit': 'Rp 100.000',
      },
      'data': [
        {
          'id': 101,
          'tanggal': DateTime.now().toString().substring(0, 10),
          'keterangan': 'PENERIMAAN DROPING KAS OPERASIONAL [PK-20261030-001] - Teller 1',
          'debit': 1000000.0,
          'kredit': 0.0,
        },
        {
          'id': 102,
          'tanggal': DateTime.now().toString().substring(0, 10),
          'keterangan': 'Setoran Tunai [101] - Handa',
          'debit': 50000.0,
          'kredit': 0.0,
        },
        {
          'id': 103,
          'tanggal': DateTime.now().toString().substring(0, 10),
          'keterangan': 'Penarikan Tunai [201] - Siti Rahmawati',
          'debit': 0.0,
          'kredit': 100000.0,
        },
      ],
    };
  }
}

