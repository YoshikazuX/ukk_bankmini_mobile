import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/session_storage.dart';
import '../models/nasabah_model.dart';
import '../models/petugas_model.dart';

/// Hasil otentikasi login terpadu (Nasabah atau Petugas)
class UnifiedAuthResult {
  final bool success;
  final String message;
  final String? role; // 'nasabah', 'teller', 'supervisor', 'admin'
  final String? token;
  final NasabahModel? nasabah;
  final PetugasModel? petugas;

  const UnifiedAuthResult({
    required this.success,
    required this.message,
    this.role,
    this.token,
    this.nasabah,
    this.petugas,
  });
}

/// Service autentikasi terpadu & Role-Based Access Control (RBAC)
/// Menggunakan Endpoint Universal Backend Laravel: /api/auth/login
class AuthService {
  static final ApiClient _api = ApiClient.instance;

  // =========================================================================
  // 1. LOGIN UNIVERSAL (ROLE OTOMATIS DITENTUKAN OLEH BACKEND DATABASE)
  // =========================================================================

  /// Login satu pintu untuk seluruh role (Nasabah, Teller, Supervisor, Admin).
  /// Kredensial diverifikasi secara real-time ke database backend Laravel.
  static Future<UnifiedAuthResult> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      return const UnifiedAuthResult(
        success: false,
        message: 'Username dan kata sandi wajib diisi!',
      );
    }

    try {
      final response = await _api.post(
        ApiConstants.authLogin,
        data: {
          'username': cleanUsername,
          'password': cleanPassword,
        },
      );

      if (response.success && (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data as Map<String, dynamic>?;

        // Ekstraksi Token Sanctum
        String? token;
        if (response.raw is Map<String, dynamic>) {
          token = (response.raw as Map<String, dynamic>)['token']?.toString();
        }
        token ??= raw?['token']?.toString();

        if (token != null && token.isNotEmpty) {
          await SessionStorage.saveToken(token);
        }

        // Ekstraksi Role & Data Akun
        final String detectedRole = (raw?['role'] ??
                (response.raw is Map ? (response.raw as Map)['role'] : null) ??
                'nasabah')
            .toString()
            .toLowerCase();

        await SessionStorage.saveRole(detectedRole);

        final userData = raw?['data'] is Map<String, dynamic>
            ? raw!['data'] as Map<String, dynamic>
            : (raw ?? <String, dynamic>{});

        NasabahModel? nasabah;
        PetugasModel? petugas;

        if (detectedRole == 'nasabah') {
          nasabah = NasabahModel.fromJson(userData);
          await SessionStorage.saveCachedNasabah(nasabah);
        } else {
          petugas = PetugasModel.fromJson(userData);
          await SessionStorage.saveCachedPetugas(petugas);
        }

        return UnifiedAuthResult(
          success: true,
          message: response.message.isNotEmpty ? response.message : 'Login berhasil',
          role: detectedRole,
          token: token,
          nasabah: nasabah,
          petugas: petugas,
        );
      }

      // Penolakan Kredensial atau Akun Nonaktif dari Backend
      return UnifiedAuthResult(
        success: false,
        message: response.message.isNotEmpty
            ? response.message
            : 'Kredensial login tidak valid!',
      );
    } catch (e) {
      return UnifiedAuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server perbankan. Periksa jaringan Anda dan pastikan server aktif.',
      );
    }
  }

  // =========================================================================
  // 2. METODE SPESIFIK (BACKWARD COMPATIBILITY)
  // =========================================================================

  /// Wrapper untuk backward compatibility modul nasabah
  static Future<UnifiedAuthResult> loginNasabah({
    required String username,
    required String password,
  }) async {
    return login(username: username, password: password);
  }

  /// Wrapper untuk backward compatibility modul petugas
  static Future<UnifiedAuthResult> loginPetugas({
    required String username,
    required String password,
  }) async {
    return login(username: username, password: password);
  }

  // =========================================================================
  // 3. LOGOUT & PEMBERSIHAN TOKEN
  // =========================================================================

  /// Logout terpadu: memanggil API Sanctum untuk mencabut token dan menghapus sesi lokal
  static Future<void> logout() async {
    try {
      await _api.post(ApiConstants.authLogout);
    } catch (_) {
      // Abaikan jika server offline saat logout
    } finally {
      await SessionStorage.clearSession();
    }
  }

  // =========================================================================
  // 4. VALIDASI SESI AKTIF (AUTO-LOGIN CHECK)
  // =========================================================================

  /// Cek sesi yang sedang tersimpan
  static Future<UnifiedAuthResult?> getActiveSession() async {
    final hasToken = await SessionStorage.hasToken();
    final role = await SessionStorage.getRole();
    final userData = await SessionStorage.getUserData();

    if (!hasToken && userData == null) {
      return null;
    }

    if (role == 'nasabah') {
      NasabahModel? nasabah;
      if (userData != null) {
        nasabah = NasabahModel.fromJson(userData);
      }
      return UnifiedAuthResult(
        success: true,
        message: 'Sesi nasabah aktif',
        role: 'nasabah',
        nasabah: nasabah,
      );
    } else if (role != null) {
      PetugasModel? petugas;
      if (userData != null) {
        petugas = PetugasModel.fromJson(userData);
      }
      return UnifiedAuthResult(
        success: true,
        message: 'Sesi petugas aktif',
        role: role,
        petugas: petugas,
      );
    }

    return null;
  }
}
