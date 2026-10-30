import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/storage/session_storage.dart';
import '../models/nasabah_model.dart';
import '../models/transaksi_model.dart';
import 'dummy_data_service.dart';

/// Service API khusus untuk modul Nasabah / Siswa (Mobile Banking)
class NasabahApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. DATA PROFIL NASABAH
  // =========================================================================

  /// Mengambil data profil lengkap nasabah yang sedang login
  static Future<ApiResponse<NasabahModel>> getProfil() async {
    try {
      final response = await _api.get(ApiConstants.nasabahMe);

      if (response.success && response.data != null) {
        final Map<String, dynamic> dataMap = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};

        final nasabah = NasabahModel.fromJson(dataMap);
        await SessionStorage.saveCachedNasabah(nasabah);
        return ApiResponse.success(data: nasabah, message: response.message);
      }

      // Fallback ke cache atau dummy data jika server offline/error
      final cached = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal memuat profil server, menggunakan data lokal.',
        data: cached,
        statusCode: response.statusCode,
      );
    } catch (e) {
      final cached = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();
      return ApiResponse.error(
        message: 'Offline: Memuat data profil lokal.',
        data: cached,
      );
    }
  }

  // =========================================================================
  // 2. CEK SALDO REAL-TIME
  // =========================================================================

  /// Mengambil rincian saldo (total, mengendap, tersedia)
  static Future<ApiResponse<Map<String, dynamic>>> getSaldo() async {
    try {
      final response = await _api.get(ApiConstants.nasabahSaldo);

      if (response.success && response.data != null) {
        final Map<String, dynamic> saldoData =
            response.data is Map<String, dynamic>
                ? (response.data['data'] is Map<String, dynamic>
                    ? response.data['data']
                    : response.data)
                : <String, dynamic>{};

        // Sinkronisasi saldo ke cached nasabah
        final currentNasabah = SessionStorage.cachedNasabah;
        if (currentNasabah != null && saldoData['saldo'] != null) {
          final newSaldo = (saldoData['saldo'] as num).toDouble();
          final updated = currentNasabah.copyWith(totalSaldo: newSaldo);
          await SessionStorage.saveCachedNasabah(updated);
        }

        return ApiResponse.success(data: saldoData, message: response.message);
      }

      // Fallback data lokal
      final nasabah = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();
      return ApiResponse.error(
        message: 'Server offline: Menampilkan saldo tersimpan.',
        data: {
          'saldo': nasabah.totalSaldo,
          'saldo_mengendap': nasabah.saldoMengendap,
          'saldo_tersedia': nasabah.saldoEfektif,
          'no_rekening': nasabah.noRekening,
          'nama_siswa': nasabah.namaLengkap,
        },
      );
    } catch (e) {
      final nasabah = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();
      return ApiResponse.error(
        message: 'Offline: Menggunakan saldo lokal.',
        data: {
          'saldo': nasabah.totalSaldo,
          'saldo_mengendap': nasabah.saldoMengendap,
          'saldo_tersedia': nasabah.saldoEfektif,
          'no_rekening': nasabah.noRekening,
          'nama_siswa': nasabah.namaLengkap,
        },
      );
    }
  }

  // =========================================================================
  // 3. RIWAYAT MUTASI TRANSAKSI
  // =========================================================================

  /// Mengambil daftar riwayat transaksi mutasi
  static Future<ApiResponse<List<TransaksiModel>>> getRiwayat({
    String? jenis, // 'setor', 'tarik', 'transfer_masuk', 'transfer_keluar', null
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (jenis != null && jenis.isNotEmpty) {
        queryParams['jenis'] = jenis;
      }

      final response = await _api.get(
        ApiConstants.nasabahRiwayat,
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

        final List<TransaksiModel> list = rawList
            .map((item) =>
                TransaksiModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      // Fallback lokal
      return ApiResponse.error(
        message: 'Memuat transaksi lokal.',
        data: DummyDataService.getTransaksiList(),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Offline: Memuat transaksi lokal.',
        data: DummyDataService.getTransaksiList(),
      );
    }
  }

  // =========================================================================
  // 4. RINGKASAN PEMASUKAN & PENGELUARAN BULANAN
  // =========================================================================

  /// Mengambil statistik masuk dan keluar bulan berjalan
  static Future<ApiResponse<Map<String, dynamic>>> getRingkasan() async {
    try {
      final response = await _api.get(ApiConstants.nasabahRingkasan);
      if (response.success && response.data != null) {
        final Map<String, dynamic> map = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: map, message: response.message);
      }

      // Fallback hitung lokal
      return ApiResponse.error(
        message: 'Offline data ringkasan',
        data: {
          'total_masuk': 350000.0,
          'total_keluar': 100000.0,
          'saldo': DummyDataService.getNasabah().totalSaldo,
        },
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Offline data ringkasan',
        data: {
          'total_masuk': 350000.0,
          'total_keluar': 100000.0,
          'saldo': DummyDataService.getNasabah().totalSaldo,
        },
      );
    }
  }

  // =========================================================================
  // 5. FITUR TRANSFER ANTAR SISWA TELAH DINONAKTIFKAN
  // =========================================================================
  /// Fitur transfer dinonaktifkan: transaksi keuangan hanya melalui loket teller
  static Future<ApiResponse<Map<String, dynamic>>> transfer({
    required String noRekeningTujuan,
    required double nominal,
    required String pin,
    String? catatan,
  }) async {
    return ApiResponse.error(
      message: 'Fitur transfer antar siswa dinonaktifkan. Transaksi tabungan dilayani melalui loket teller.',
    );
  }

  // =========================================================================
  // 7. VERIFIKASI PIN OTORISASI
  // =========================================================================

  /// Memverifikasi PIN transaksi 6-digit ke server
  static Future<ApiResponse<bool>> verifyPin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.length != 6) {
      return ApiResponse.error(message: 'PIN harus tepat 6 digit');
    }

    final nasabah = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();

    try {
      final response = await _api.post(
        ApiConstants.nasabahVerifyPin,
        data: {
          'no_rekening': nasabah.noRekening,
          'pin': cleanPin,
        },
      );

      if (response.success) {
        return ApiResponse.success(data: true, message: response.message);
      }

      // Offline fallback
      final isValid = DummyDataService.verifyPin(cleanPin);
      if (isValid) {
        return ApiResponse.success(data: true, message: 'Otorisasi PIN Valid (Offline)');
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'PIN otorisasi tidak valid!',
      );
    } catch (e) {
      // Offline fallback
      final isValid = DummyDataService.verifyPin(cleanPin);
      if (isValid) {
        return ApiResponse.success(data: true, message: 'Otorisasi PIN Valid (Offline)');
      }
      return ApiResponse.error(message: 'PIN Keamanan salah!');
    }
  }

  // =========================================================================
  // 8. PAYLOAD QRIS / KARTU DIGITAL
  // =========================================================================

  /// Mengambil data payload QR Code rekening untuk ditunjukkan ke loket Teller
  static Future<ApiResponse<Map<String, dynamic>>> getQrisPayload() async {
    try {
      final response = await _api.get(ApiConstants.nasabahQrisPayload);
      if (response.success && response.data != null) {
        final Map<String, dynamic> map = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: map, message: response.message);
      }
    } catch (_) {}

    final nasabah = SessionStorage.cachedNasabah ?? DummyDataService.getNasabah();
    final payload =
        'BANKMINI:REK:${nasabah.noRekening}:NIS:${nasabah.nis}:NAMA:${nasabah.namaLengkap}';

    return ApiResponse.success(data: {
      'no_rekening': nasabah.noRekening,
      'nama_siswa': nasabah.namaLengkap,
      'nis': nasabah.nis,
      'kelas': nasabah.kelas,
      'qr_string': payload,
    });
  }
}
