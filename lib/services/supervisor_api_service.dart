import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';

/// Service API resmi untuk Modul Supervisor & Laporan Eksekutif Bank Mini
/// Single Source of Truth: Backend Laravel REST API — Zero Dummy Data Runtime Policy
class SupervisorApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. APPROVAL PENGAJUAN DROPING KAS
  // =========================================================================

  /// Mengambil seluruh tiket pengajuan droping kas dari loket teller langsung dari database
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Supervisor menyetujui tiket droping kas teller (Pessimistic lock di backend)
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal menyetujui pengajuan kas di server.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Supervisor menolak tiket droping kas teller (wajib alasan penolakan)
  static Future<ApiResponse<Map<String, dynamic>>> tolakPengajuanKas(
    dynamic id, {
    String? catatan,
    String? alasanPenolakan,
  }) async {
    final reason = alasanPenolakan ?? catatan ?? 'Ditolak oleh Supervisor';
    try {
      final response = await _api.post(
        ApiConstants.supervisorTolakKas(id),
        data: {
          'alasan_penolakan': reason.trim(),
          'catatan_spv': reason.trim(),
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal menolak pengajuan kas di server.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 2. VERIFIKASI DAILY CLOSING REPORT TELLER
  // =========================================================================

  /// Mengambil daftar laporan tutup kas harian dari seluruh teller langsung dari backend
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Supervisor memverifikasi status daily report (verified / rejected)
  static Future<ApiResponse<Map<String, dynamic>>> updateStatusDailyReport(
    dynamic id, {
    required String status, // 'verified', 'rejected'
    String? notes,
    String? catatanSpv,
    String? alasanPenolakan,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.supervisorUpdateDailyReport(id),
        data: {
          'status': status,
          'notes': notes?.trim(),
          if (catatanSpv != null) 'catatan_spv': catatanSpv.trim(),
          if (alasanPenolakan != null) 'alasan_penolakan': alasanPenolakan.trim(),
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal memperbarui status daily report.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Mengambil buku besar mutasi jurnal akuntansi
  static Future<ApiResponse<Map<String, dynamic>>> getMutasiJurnal({
    String? dariTanggal,
    String? sampaiTanggal,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dariTanggal != null && dariTanggal.isNotEmpty) {
        queryParams['dari_tanggal'] = dariTanggal;
      }
      if (sampaiTanggal != null && sampaiTanggal.isNotEmpty) {
        queryParams['sampai_tanggal'] = sampaiTanggal;
      }

      final response = await _api.get(
        ApiConstants.laporanMutasiJurnal,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }
}
