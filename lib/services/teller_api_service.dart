import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';

/// Service API resmi untuk Modul Petugas Loket Teller (Mobile POS)
/// Single Source of Truth: Backend Laravel REST API — Zero Dummy Data Runtime Policy
class TellerApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. PENCARIAN & DETAIL NASABAH LOKET
  // =========================================================================

  /// Pencarian nasabah aktual berdasarkan nama, NIS, atau nomor rekening dari backend
  static Future<ApiResponse<List<Map<String, dynamic>>>> searchNasabah({
    String? query,
    String? kelas,
    String status = 'aktif',
  }) async {
    try {
      final queryParams = <String, dynamic>{'status': status};
      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }
      if (kelas != null && kelas.isNotEmpty) {
        queryParams['kelas'] = kelas;
      }

      final response = await _api.get(
        ApiConstants.petugasNasabahSearch,
        queryParameters: queryParams,
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
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Detail lengkap rekening nasabah & riwayat 10 transaksi terakhir dari server
  static Future<ApiResponse<Map<String, dynamic>>> getDetailNasabah(
    String identifier,
  ) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) {
      return ApiResponse.error(
        message: 'Identifier nasabah tidak boleh kosong',
      );
    }

    try {
      final response = await _api.get(
        '${ApiConstants.petugasNasabahDetail}/$cleanId',
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
            : 'Data nasabah tidak ditemukan pada database server!',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 2. TRANSAKSI SETOR TUNAI LOKET (KODE SANDI 101)
  // =========================================================================

  /// Proses setoran tunai loket teller
  static Future<ApiResponse<Map<String, dynamic>>> setorTunai({
    required String noRekening,
    required double nominal,
    String? keterangan,
  }) async {
    final cleanRek = noRekening.trim();
    if (nominal < 1000) {
      return ApiResponse.error(message: 'Nominal setoran minimal Rp 1.000');
    }

    try {
      final response = await _api.post(
        ApiConstants.tellerSetor,
        data: {
          'no_rekening': cleanRek,
          'nominal': nominal.toInt(),
          'keterangan': keterangan ?? 'Setoran Tunai Loket',
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
            : 'Setoran tunai ditolak oleh server.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message:
            'Server Bank Mini tidak dapat dihubungi. Transaksi setoran belum terkonfirmasi.',
      );
    }
  }

  // =========================================================================
  // 3. TRANSAKSI PENARIKAN TUNAI LOKET (KODE SANDI 201)
  // =========================================================================

  /// Proses penarikan tunai loket teller (Proteksi Saldo Mengendap, PIN, & Kas Minus)
  static Future<ApiResponse<Map<String, dynamic>>> tarikTunai({
    required String noRekening,
    required double nominal,
    required String pin,
    String? keterangan,
  }) async {
    final cleanRek = noRekening.trim();
    final cleanPin = pin.trim();

    if (nominal < 1000) {
      return ApiResponse.error(message: 'Nominal penarikan minimal Rp 1.000');
    }
    if (cleanPin.length != 6) {
      return ApiResponse.error(message: 'PIN otorisasi nasabah harus 6 digit');
    }

    try {
      final response = await _api.post(
        ApiConstants.tellerTarik,
        data: {
          'no_rekening': cleanRek,
          'nominal': nominal.toInt(),
          'pin': cleanPin,
          'keterangan': keterangan ?? 'Penarikan Tunai Loket',
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
            : 'Penarikan tunai ditolak oleh server perbankan.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa ketersediaan koneksi dan status transaksi.',
      );
    }
  }

  // =========================================================================
  // 4. METRIK & TRANSAKSI TELLER HARI INI
  // =========================================================================

  /// Rekapitulasi transaksi yang diproses loket teller hari ini
  static Future<ApiResponse<Map<String, dynamic>>> getTransaksiHariIni() async {
    try {
      final response = await _api.get(ApiConstants.tellerTransaksiHariIni);

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
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Posisi kas fisik laci loket dan brankas hari ini
  static Future<ApiResponse<Map<String, dynamic>>> getStatusKas() async {
    try {
      final response = await _api.get(ApiConstants.tellerKas);

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
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 5. PENGAJUAN KAS (DROPING KAS LOKET TELLER)
  // =========================================================================

  /// Mengambil daftar riwayat pengajuan droping kas loket teller
  static Future<ApiResponse<Map<String, dynamic>>> getPengajuanKas() async {
    try {
      final response = await _api.get(ApiConstants.tellerPengajuanKas);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
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
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Mengirim tiket permohonan penambahan modal kas loket ke Supervisor
  static Future<ApiResponse<Map<String, dynamic>>> kirimPengajuanKas({
    required double nominal,
    required String alasan,
  }) async {
    if (nominal < 10000) {
      return ApiResponse.error(
        message: 'Nominal pengajuan kas minimal Rp 10.000',
      );
    }
    if (alasan.trim().isEmpty) {
      return ApiResponse.error(
        message: 'Alasan pengajuan modal kas wajib diisi',
      );
    }

    try {
      final response = await _api.post(
        ApiConstants.tellerPengajuanKas,
        data: {
          'nominal': nominal.toInt(),
          'alasan': alasan.trim(),
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
            : 'Pengajuan droping kas gagal dikirim ke server.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 6. LEMBAR LAPORAN KAS HARIAN TELLER (DAILY REPORT)
  // =========================================================================

  /// Mengambil status lembar daily report loket teller hari ini
  static Future<ApiResponse<Map<String, dynamic>>> getDailyReportStatus() async {
    try {
      final response = await _api.get(ApiConstants.tellerDailyReport);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
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
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Alias getStatusDailyReport untuk kompatibilitas tampilan
  static Future<ApiResponse<Map<String, dynamic>>> getStatusDailyReport() =>
      getDailyReportStatus();

  /// Mengirim laporan penutupan kas harian loket ke Supervisor
  static Future<ApiResponse<Map<String, dynamic>>> submitDailyReport({
    required double physicalBalance,
    double openingBalance = 0,
    double totalDeposit = 0,
    double totalWithdrawal = 0,
    double totalCashDrop = 0,
    String? notes,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.tellerDailyReport,
        data: {
          'saldo_awal': openingBalance.toInt(),
          'total_deposit': totalDeposit.toInt(),
          'total_withdrawal': totalWithdrawal.toInt(),
          'total_cash_drop': totalCashDrop.toInt(),
          'saldo_akhir': physicalBalance.toInt(),
          'notes': notes ?? '',
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
            : 'Gagal mengirim daily report ke server.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.error(
        message:
            'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }
}
