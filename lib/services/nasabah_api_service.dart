import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/storage/session_storage.dart';
import '../models/badge_model.dart';
import '../models/nasabah_model.dart';
import '../models/notifikasi_model.dart';
import '../models/saving_goal_model.dart';
import '../models/session_model.dart';
import '../models/transaksi_model.dart';

/// Service API resmi untuk modul Nasabah / Siswa (Mobile Banking)
/// Backend Laravel sebagai Single Source of Truth — Zero Dummy Data Runtime Policy
class NasabahApiService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. DATA PROFIL NASABAH
  // =========================================================================

  /// Mengambil data profil lengkap nasabah yang sedang login dari server Laravel
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 2. CEK SALDO REAL-TIME
  // =========================================================================

  /// Mengambil rincian saldo aktual (total, mengendap, tersedia) langsung dari database
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

        // Sinkronisasi saldo ke cached nasabah lokal
        final currentNasabah = SessionStorage.cachedNasabah;
        if (currentNasabah != null && saldoData['saldo'] != null) {
          final newSaldo = (saldoData['saldo'] as num).toDouble();
          final updated = currentNasabah.copyWith(totalSaldo: newSaldo);
          await SessionStorage.saveCachedNasabah(updated);
        }

        return ApiResponse.success(data: saldoData, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 3. RIWAYAT MUTASI TRANSAKSI
  // =========================================================================

  /// Mengambil daftar riwayat transaksi mutasi aktual dari backend
  static Future<ApiResponse<List<TransaksiModel>>> getRiwayat({
    String? jenis, // 'setor', 'tarik', 'admin', 'koreksi_setor', 'koreksi_tarik'
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 4. RINGKASAN PEMASUKAN & PENGELUARAN BULANAN
  // =========================================================================

  /// Mengambil statistik masuk, keluar, dan agregasi 6 bulan dari backend
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

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 5. FITUR TRANSFER ANTAR SISWA DINONAKTIFKAN
  // =========================================================================

  /// Fitur transfer dinonaktifkan demi perlindungan dana pelajar: transaksi tabungan melalui loket resmi
  static Future<ApiResponse<Map<String, dynamic>>> transfer({
    required String noRekeningTujuan,
    required double nominal,
    required String pin,
    String? catatan,
  }) async {
    return ApiResponse.error(
      message: 'Fitur transfer antar siswa dinonaktifkan. Transaksi tabungan dilayani secara aman melalui loket teller bank mini.',
    );
  }

  // =========================================================================
  // 6. VERIFIKASI PIN OTORISASI
  // =========================================================================

  /// Memverifikasi PIN transaksi 6-digit ke server Laravel
  static Future<ApiResponse<bool>> verifyPin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.length != 6) {
      return ApiResponse.error(message: 'PIN harus tepat 6 digit');
    }

    final nasabah = SessionStorage.cachedNasabah;

    try {
      final response = await _api.post(
        ApiConstants.nasabahVerifyPin,
        data: {
          if (nasabah != null) 'no_rekening': nasabah.noRekening,
          'pin': cleanPin,
        },
      );

      if (response.success) {
        return ApiResponse.success(data: true, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'PIN otorisasi tidak valid!',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 7. PAYLOAD QRIS / KARTU DIGITAL
  // =========================================================================

  /// Mengambil data payload QR Code rekening langsung dari server backend
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

    final nasabah = SessionStorage.cachedNasabah;
    if (nasabah != null) {
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

    return ApiResponse.error(
      message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
    );
  }

  // =========================================================================
  // 8. EMERGENCY ACCOUNT FREEZE (BLOKIR REKENING MANDIRI)
  // =========================================================================

  /// Membekukan rekening siswa secara mandiri demi keamanan
  static Future<ApiResponse<Map<String, dynamic>>> emergencyFreeze({
    String? alasan,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.nasabahEmergencyFreeze,
        data: alasan != null ? {'alasan': alasan} : null,
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> map = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};

        // Sinkronisasi status di cache sesi
        final currentNasabah = SessionStorage.cachedNasabah;
        if (currentNasabah != null) {
          final updated = currentNasabah.copyWith(status: 'NONAKTIF');
          await SessionStorage.saveCachedNasabah(updated);
        }

        return ApiResponse.success(
          data: map,
          message: response.message.isNotEmpty
              ? response.message
              : 'Rekening Anda berhasil dibekukan secara mandiri.',
        );
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal membekukan rekening.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 9. LENCANA PRESTASI MENABUNG (BADGES GAMIFICATION)
  // =========================================================================

  /// Mengambil daftar evaluasi lencana menabung langsung dari backend
  static Future<ApiResponse<List<BadgeModel>>> getBadges() async {
    try {
      final response = await _api.get(ApiConstants.nasabahBadges);

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final List<BadgeModel> list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item);
          DateTime? unlockedAt;
          if (m['unlocked_at'] != null) {
            unlockedAt = DateTime.tryParse(m['unlocked_at'].toString());
          }
          return BadgeModel(
            id: m['id']?.toString() ?? '',
            nama: m['nama']?.toString() ?? '',
            deskripsi: m['deskripsi']?.toString() ?? '',
            icon: m['icon']?.toString() ?? 'military_tech',
            tier: m['tier']?.toString() ?? 'bronze',
            isUnlocked: m['is_unlocked'] == true,
            unlockedAt: unlockedAt,
          );
        }).toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 10. RIWAYAT SESI LOGIN (SESSION LOGS)
  // =========================================================================

  /// Mengambil log sesi perangkat aktif dari backend
  static Future<ApiResponse<List<SessionModel>>> getSessionLogs() async {
    try {
      final response = await _api.get(ApiConstants.nasabahSessions);

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final List<SessionModel> list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item);
          DateTime lastAccess = DateTime.now();
          if (m['last_access'] != null) {
            lastAccess = DateTime.tryParse(m['last_access'].toString()) ?? DateTime.now();
          }
          return SessionModel(
            id: m['id']?.toString() ?? '',
            deviceName: m['device_name']?.toString() ?? 'Aplikasi Mobile',
            deviceType: m['device_type']?.toString() ?? 'mobile',
            ipAddress: m['ip_address']?.toString() ?? '',
            location: m['location']?.toString() ?? '',
            lastAccess: lastAccess,
            isCurrentSession: m['is_current_session'] == true,
          );
        }).toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 11. TARGET TABUNGAN IMPIAN (SAVING GOALS CRUD)
  // =========================================================================

  /// Mengambil daftar target tabungan dari server Laravel
  static Future<ApiResponse<List<SavingGoalModel>>> getSavingGoals() async {
    try {
      final response = await _api.get(ApiConstants.nasabahGoals);

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final List<SavingGoalModel> list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item);
          DateTime? createdAt;
          if (m['created_at'] != null) {
            createdAt = DateTime.tryParse(m['created_at'].toString());
          }
          DateTime? deadline;
          if (m['deadline'] != null) {
            deadline = DateTime.tryParse(m['deadline'].toString());
          }

          return SavingGoalModel(
            id: m['id']?.toString() ?? '',
            nama: m['nama']?.toString() ?? '',
            targetAmount: (m['target_amount'] as num?)?.toDouble() ?? 0.0,
            currentAmount: (m['current_amount'] as num?)?.toDouble() ?? 0.0,
            icon: m['icon']?.toString(),
            createdAt: createdAt,
            deadline: deadline,
            isCompleted: m['is_completed'] == true,
          );
        }).toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Membuat target tabungan impian baru ke server
  static Future<ApiResponse<SavingGoalModel>> createSavingGoal({
    required String nama,
    required double targetAmount,
    double? currentAmount,
    String? icon,
    DateTime? deadline,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.nasabahGoals,
        data: {
          'nama': nama,
          'target_amount': targetAmount,
          'current_amount': currentAmount ?? 0,
          'icon': icon ?? 'savings',
          if (deadline != null) 'deadline': deadline.toIso8601String().substring(0, 10),
        },
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> m = response.data is Map<String, dynamic>
            ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data']
                : response.data)
            : <String, dynamic>{};

        DateTime? dl;
        if (m['deadline'] != null) {
          dl = DateTime.tryParse(m['deadline'].toString());
        }

        final goal = SavingGoalModel(
          id: m['id']?.toString() ?? '',
          nama: m['nama']?.toString() ?? nama,
          targetAmount: (m['target_amount'] as num?)?.toDouble() ?? targetAmount,
          currentAmount: (m['current_amount'] as num?)?.toDouble() ?? (currentAmount ?? 0),
          icon: m['icon']?.toString() ?? icon,
          deadline: dl,
          isCompleted: m['is_completed'] == true,
        );

        return ApiResponse.success(data: goal, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Gagal membuat target tabungan.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Menghapus target tabungan dari server
  static Future<ApiResponse<bool>> deleteSavingGoal(String id) async {
    try {
      final response = await _api.delete(ApiConstants.nasabahGoalDetail(id));
      if (response.success) {
        return ApiResponse.success(data: true, message: response.message);
      }
      return ApiResponse.error(
        message: response.message.isNotEmpty ? response.message : 'Gagal menghapus target.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  // =========================================================================
  // 12. PUSAT NOTIFIKASI UNIVERSAL
  // =========================================================================

  /// Mengambil daftar notifikasi pengguna dari server
  static Future<ApiResponse<List<NotifikasiModel>>> getNotifications() async {
    try {
      final response = await _api.get(ApiConstants.notifikasi);

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];
        if (response.data is Map<String, dynamic> &&
            response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        final List<NotifikasiModel> list = rawList.map((item) {
          final m = Map<String, dynamic>.from(item);
          DateTime ts = DateTime.now();
          if (m['timestamp'] != null) {
            ts = DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now();
          }

          return NotifikasiModel(
            id: m['id']?.toString() ?? '',
            title: m['title']?.toString() ?? 'Pemberitahuan Bank Mini',
            message: m['message']?.toString() ?? '',
            jenis: m['type']?.toString() ?? 'SISTEM',
            timestamp: ts,
            isRead: m['is_read'] == true,
          );
        }).toList();

        return ApiResponse.success(data: list, message: response.message);
      }

      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.',
      );
    }
  }

  /// Menandai seluruh notifikasi telah dibaca
  static Future<ApiResponse<bool>> markAllNotificationsRead() async {
    try {
      final response = await _api.post(ApiConstants.notifikasiReadAll);
      if (response.success) {
        return ApiResponse.success(data: true, message: response.message);
      }
      return ApiResponse.error(
        message: response.message.isNotEmpty ? response.message : 'Gagal menandai notifikasi.',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Server Bank Mini tidak dapat dihubungi.',
      );
    }
  }
}
