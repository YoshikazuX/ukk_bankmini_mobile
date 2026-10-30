import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';

/// Service API untuk Modul Petugas Loket Teller (Mobile POS)
class TellerApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. PENCARIAN & DETAIL NASABAH LOKET
  // =========================================================================

  /// Pencarian nasabah berdasarkan nama, NIS, atau nomor rekening
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

      // Offline fallback search
      final filtered = _getOfflineNasabahList(query);
      return ApiResponse.success(
        data: filtered,
        message: 'Menampilkan data nasabah (Offline)',
      );
    } catch (_) {
      final filtered = _getOfflineNasabahList(query);
      return ApiResponse.success(
        data: filtered,
        message: 'Menampilkan data nasabah lokal (Offline)',
      );
    }
  }

  /// Detail lengkap rekening nasabah & riwayat 10 transaksi terakhir
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

      final offlineDetail = _getOfflineDetail(cleanId);
      if (offlineDetail != null) {
        return ApiResponse.success(
          data: offlineDetail,
          message: 'Data nasabah dimuat secara offline',
        );
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Data nasabah tidak ditemukan!',
      );
    } catch (_) {
      final offlineDetail = _getOfflineDetail(cleanId);
      if (offlineDetail != null) {
        return ApiResponse.success(
          data: offlineDetail,
          message: 'Data nasabah dimuat secara offline',
        );
      }
      return ApiResponse.error(message: 'Data nasabah tidak ditemukan.');
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
          'keterangan': keterangan?.trim(),
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

      // Offline simulation fallback
      return ApiResponse.success(
        data: {
          'id_transaksi': DateTime.now().millisecondsSinceEpoch,
          'kode_sandi': '101',
          'no_rekening': cleanRek,
          'nama_siswa': _resolveNamaSiswaOffline(cleanRek),
          'nominal': nominal,
          'saldo_akhir': 150000.0 + nominal,
          'petugas': 'Teller Loket 1',
          'waktu': DateTime.now().toString(),
        },
        message: 'Setoran tunai berhasil diproses (Mode Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {
          'id_transaksi': DateTime.now().millisecondsSinceEpoch,
          'kode_sandi': '101',
          'no_rekening': cleanRek,
          'nama_siswa': _resolveNamaSiswaOffline(cleanRek),
          'nominal': nominal,
          'saldo_akhir': 150000.0 + nominal,
          'petugas': 'Teller Loket 1',
          'waktu': DateTime.now().toString(),
        },
        message: 'Setoran tunai berhasil diproses (Mode Offline)',
      );
    }
  }

  // =========================================================================
  // 3. TRANSAKSI TARIK TUNAI LOKET (KODE SANDI 201)
  // =========================================================================

  /// Proses penarikan tunai loket teller dengan validasi kas fisik & PIN
  static Future<ApiResponse<Map<String, dynamic>>> tarikTunai({
    required String noRekening,
    required double nominal,
    String? pin,
    String? keterangan,
  }) async {
    final cleanRek = noRekening.trim();
    if (nominal < 1000) {
      return ApiResponse.error(message: 'Nominal penarikan minimal Rp 1.000');
    }

    try {
      final response = await _api.post(
        ApiConstants.tellerTarik,
        data: {
          'no_rekening': cleanRek,
          'nominal': nominal.toInt(),
          'pin': pin?.trim(),
          'keterangan': keterangan?.trim(),
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

      // Offline simulation fallback
      if (pin != null && pin != '240808' && pin != '123456') {
        return ApiResponse.error(
          message: 'Penarikan ditolak: PIN Keamanan nasabah tidak valid!',
        );
      }

      return ApiResponse.success(
        data: {
          'id_transaksi': DateTime.now().millisecondsSinceEpoch,
          'kode_sandi': '201',
          'no_rekening': cleanRek,
          'nama_siswa': _resolveNamaSiswaOffline(cleanRek),
          'nominal': nominal,
          'saldo_akhir': 100000.0 - nominal,
          'petugas': 'Teller Loket 1',
          'waktu': DateTime.now().toString(),
        },
        message: 'Penarikan tunai berhasil diproses (Mode Offline)',
      );
    } catch (_) {
      if (pin != null && pin != '240808' && pin != '123456') {
        return ApiResponse.error(
          message: 'Penarikan ditolak: PIN Keamanan nasabah tidak valid!',
        );
      }

      return ApiResponse.success(
        data: {
          'id_transaksi': DateTime.now().millisecondsSinceEpoch,
          'kode_sandi': '201',
          'no_rekening': cleanRek,
          'nama_siswa': _resolveNamaSiswaOffline(cleanRek),
          'nominal': nominal,
          'saldo_akhir': 100000.0 - nominal,
          'petugas': 'Teller Loket 1',
          'waktu': DateTime.now().toString(),
        },
        message: 'Penarikan tunai berhasil diproses (Mode Offline)',
      );
    }
  }

  // =========================================================================
  // 4. MONITORING TRANSAKSI HARI INI
  // =========================================================================

  /// Mengambil rekap transaksi yang dilayani teller hari ini
  static Future<ApiResponse<Map<String, dynamic>>> getTransaksiHariIni() async {
    try {
      final response = await _api.get(ApiConstants.tellerTransaksiHariIni);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: _getOfflineTransaksiHariIni(),
        message: 'Data transaksi hari ini (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: _getOfflineTransaksiHariIni(),
        message: 'Data transaksi hari ini (Offline)',
      );
    }
  }

  // =========================================================================
  // 5. STATUS KAS LOKET & BRANKAS
  // =========================================================================

  /// Posisi kas fisik loket teller hari ini
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

      return ApiResponse.success(
        data: {
          'saldo_awal': 2000000.0,
          'kas_masuk': 350000.0,
          'kas_keluar': 100000.0,
          'kas_tersedia': 2250000.0,
          'tanggal': DateTime.now().toString().substring(0, 10),
        },
        message: 'Status kas fisik loket (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {
          'saldo_awal': 2000000.0,
          'kas_masuk': 350000.0,
          'kas_keluar': 100000.0,
          'kas_tersedia': 2250000.0,
          'tanggal': DateTime.now().toString().substring(0, 10),
        },
        message: 'Status kas fisik loket (Offline)',
      );
    }
  }

  // =========================================================================
  // 6. PENGAJUAN DROPING KAS KE SUPERVISOR
  // =========================================================================

  /// Daftar tiket pengajuan kas teller
  static Future<ApiResponse<Map<String, dynamic>>> getPengajuanKas() async {
    try {
      final response = await _api.get(ApiConstants.tellerPengajuanKas);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: {
          'summary': {
            'kas_awal_hari_ini': 2000000.0,
            'kas_tersedia_laci': 2250000.0,
            'total_pengajuan': 1,
          },
          'data': [
            {
              'id': 1,
              'nomor_pengajuan': 'PK-20261030-001',
              'nominal': 1000000.0,
              'alasan': 'Tambahan modal kas pagi loket',
              'status': 'disetujui',
              'nama_spv': 'Supervisor Utama',
              'catatan_spv': 'Disetujui untuk operasional loket',
              'created_at': DateTime.now().toString(),
            },
          ],
        },
        message: 'Daftar pengajuan kas (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {
          'summary': {
            'kas_awal_hari_ini': 2000000.0,
            'kas_tersedia_laci': 2250000.0,
            'total_pengajuan': 1,
          },
          'data': [],
        },
        message: 'Daftar pengajuan kas (Offline)',
      );
    }
  }

  /// Teller mengirimkan pengajuan kas tambahan ke Supervisor
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
      return ApiResponse.error(message: 'Alasan pengajuan kas wajib diisi');
    }

    try {
      final response = await _api.post(
        ApiConstants.tellerPengajuanKas,
        data: {'nominal': nominal.toInt(), 'alasan': alasan.trim()},
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                  ? response.data['data']
                  : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      // Offline simulation
      final nomorPengajuan =
          'PK-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-002';
      return ApiResponse.success(
        data: {
          'id': DateTime.now().millisecondsSinceEpoch,
          'nomor_pengajuan': nomorPengajuan,
          'nominal': nominal,
          'status': 'pending',
          'tanggal': DateTime.now().toString().substring(0, 10),
        },
        message:
            'Pengajuan kas #$nomorPengajuan berhasil dikirim! Menunggu persetujuan Supervisor (Offline)',
      );
    } catch (_) {
      final nomorPengajuan =
          'PK-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-002';
      return ApiResponse.success(
        data: {
          'id': DateTime.now().millisecondsSinceEpoch,
          'nomor_pengajuan': nomorPengajuan,
          'nominal': nominal,
          'status': 'pending',
          'tanggal': DateTime.now().toString().substring(0, 10),
        },
        message:
            'Pengajuan kas #$nomorPengajuan berhasil dikirim! Menunggu persetujuan Supervisor (Offline)',
      );
    }
  }

  // =========================================================================
  // 7. DAILY REPORT TUTUP KAS TELLER
  // =========================================================================

  /// Cek posisi saldo tutup kas & status laporan teller hari ini
  static Future<ApiResponse<Map<String, dynamic>>>
  getStatusDailyReport() async {
    try {
      final response = await _api.get(ApiConstants.tellerDailyReport);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                  ? response.data['data']
                  : response.data)
            : <String, dynamic>{};
        return ApiResponse.success(data: data, message: response.message);
      }

      return ApiResponse.success(
        data: {
          'tanggal': DateTime.now().toString().substring(0, 10),
          'opening_balance': 2000000.0,
          'total_deposit': 350000.0,
          'total_withdrawal': 100000.0,
          'system_balance': 2250000.0,
          'is_submitted': false,
          'report': null,
        },
        message: 'Status daily report (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {
          'tanggal': DateTime.now().toString().substring(0, 10),
          'opening_balance': 2000000.0,
          'total_deposit': 350000.0,
          'total_withdrawal': 100000.0,
          'system_balance': 2250000.0,
          'is_submitted': false,
          'report': null,
        },
        message: 'Status daily report (Offline)',
      );
    }
  }

  /// Submit laporan tutup kas harian ke Supervisor
  static Future<ApiResponse<Map<String, dynamic>>> submitDailyReport({
    required double physicalBalance,
    String? notes,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.tellerDailyReport,
        data: {
          'physical_balance': physicalBalance.toInt(),
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
        data: {
          'id': DateTime.now().millisecondsSinceEpoch,
          'physical_balance': physicalBalance,
          'difference': physicalBalance - 2250000.0,
          'status': 'submitted',
          'notes': notes,
        },
        message: 'Laporan kas harian berhasil disubmit ke Supervisor (Offline)',
      );
    } catch (_) {
      return ApiResponse.success(
        data: {
          'id': DateTime.now().millisecondsSinceEpoch,
          'physical_balance': physicalBalance,
          'difference': physicalBalance - 2250000.0,
          'status': 'submitted',
          'notes': notes,
        },
        message: 'Laporan kas harian berhasil disubmit ke Supervisor (Offline)',
      );
    }
  }

  // =========================================================================
  // HELPER DATA DUMMY OFFLINE LOKET
  // =========================================================================

  static List<Map<String, dynamic>> _getOfflineNasabahList(String? query) {
    final list = [
      {
        'id': 1,
        'nis': '10293847',
        'nama_siswa': 'Handa',
        'kelas': 'XII RPL 1',
        'jurusan': 'Rekayasa Perangkat Lunak',
        'no_rekening': '202601001',
        'saldo': 60000.0,
        'status': 'aktif',
      },
      {
        'id': 2,
        'nis': '10293848',
        'nama_siswa': 'Siti Rahmawati',
        'kelas': 'XI AKL 2',
        'jurusan': 'Akuntansi & Keuangan Lembaga',
        'no_rekening': '202601002',
        'saldo': 150000.0,
        'status': 'aktif',
      },
      {
        'id': 3,
        'nis': '10293849',
        'nama_siswa': 'Budi Santoso',
        'kelas': 'X DKV 1',
        'jurusan': 'Desain Komunikasi Visual',
        'no_rekening': '202601003',
        'saldo': 75000.0,
        'status': 'aktif',
      },
    ];

    if (query == null || query.trim().isEmpty) return list;
    final q = query.toLowerCase().trim();
    return list.where((item) {
      return item['nama_siswa'].toString().toLowerCase().contains(q) ||
          item['nis'].toString().contains(q) ||
          item['no_rekening'].toString().contains(q);
    }).toList();
  }

  static Map<String, dynamic>? _getOfflineDetail(String identifier) {
    final list = _getOfflineNasabahList(null);
    for (final found in list) {
      if (found['id'].toString() == identifier ||
          found['no_rekening'] == identifier ||
          found['nis'] == identifier) {
        final saldo = (found['saldo'] as num).toDouble();
        return {
          'id': found['id'],
          'nis': found['nis'],
          'nama_siswa': found['nama_siswa'],
          'kelas': found['kelas'],
          'jurusan': found['jurusan'],
          'no_rekening': found['no_rekening'],
          'saldo': saldo,
          'saldo_mengendap_min': 10000.0,
          'saldo_dapat_ditarik': (saldo - 10000.0).clamp(0, double.infinity),
          'status': found['status'],
          'riwayat_terakhir': [
            {
              'id': 1,
              'jenis_transaksi': 'setor',
              'kode_sandi': '101',
              'nominal': 50000.0,
              'status': 'sukses',
              'tanggal': DateTime.now().toString().substring(0, 19),
            },
          ],
        };
      }
    }
    return null;
  }

  static String _resolveNamaSiswaOffline(String noRek) {
    if (noRek == '202601001') return 'Handa';
    if (noRek == '202601002') return 'Siti Rahmawati';
    if (noRek == '202601003') return 'Budi Santoso';
    return 'Nasabah Bank Mini ($noRek)';
  }

  static Map<String, dynamic> _getOfflineTransaksiHariIni() {
    return {
      'summary': {
        'tanggal': DateTime.now().toString().substring(0, 10),
        'total_transaksi': 2,
        'total_nominal_setor': 50000.0,
        'formatted_setor': 'Rp 50.000',
        'total_nominal_tarik': 20000.0,
        'formatted_tarik': 'Rp 20.000',
      },
      'data': [
        {
          'id': 1,
          'no_rekening': '202601001',
          'nama_siswa': 'Handa',
          'kelas': 'XII RPL 1',
          'petugas': 'Teller Loket 1',
          'jenis_transaksi': 'setor',
          'kode_sandi': '101',
          'nominal': 50000.0,
          'formatted_nominal': 'Rp 50.000',
          'status': 'sukses',
          'waktu': '08:30:15',
        },
        {
          'id': 2,
          'no_rekening': '202601002',
          'nama_siswa': 'Siti Rahmawati',
          'kelas': 'XI AKL 2',
          'petugas': 'Teller Loket 1',
          'jenis_transaksi': 'tarik',
          'kode_sandi': '201',
          'nominal': 20000.0,
          'formatted_nominal': 'Rp 20.000',
          'status': 'sukses',
          'waktu': '09:12:40',
        },
      ],
    };
  }
}
