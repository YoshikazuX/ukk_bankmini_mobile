import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/nasabah_model.dart';
import '../../models/petugas_model.dart';
import '../constants/api_constants.dart';

/// Service penyimpanan sesi autentikasi, token Sanctum & role aktif pengguna
class SessionStorage {
  static const String _keyToken = 'auth_bearer_token';
  static const String _keyRole = 'user_active_role';
  static const String _keyUserData = 'user_profile_json';
  static const String _keyCustomBaseUrl = 'app_custom_base_url';

  static SharedPreferences? _prefs;
  static NasabahModel? _cachedNasabah;
  static PetugasModel? _cachedPetugas;

  /// Membaca nasabah aktif yang ter-cache di memori
  static NasabahModel? get cachedNasabah => _cachedNasabah;

  /// Membaca petugas aktif yang ter-cache di memori
  static PetugasModel? get cachedPetugas => _cachedPetugas;

  /// Inisialisasi SharedPreferences instance
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Inisialisasi startup membaca profil yang tersimpan
  static Future<void> init() async {
    final data = await getUserData();
    final role = await getRole();
    if (data != null) {
      try {
        if (role == 'nasabah') {
          _cachedNasabah = NasabahModel.fromJson(data);
        } else if (role != null) {
          _cachedPetugas = PetugasModel.fromJson(data);
        }
      } catch (_) {
        _cachedNasabah = null;
        _cachedPetugas = null;
      }
    }
  }

  // =========================================================================
  // 1. MANAJEMEN BEARER TOKEN SANCTUM
  // =========================================================================

  /// Simpan token Bearer dari Sanctum
  static Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, token);
  }

  /// Ambil token Bearer saat ini
  static Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyToken);
  }

  /// Cek apakah pengguna sedang login (memiliki token)
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  // =========================================================================
  // 2. MANAJEMEN ROLE & HAK AKSES (RBAC)
  // =========================================================================

  /// Simpan role aktif ('nasabah', 'teller', 'supervisor', 'admin')
  static Future<void> saveRole(String role) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyRole, role.toLowerCase().trim());
  }

  /// Ambil role aktif saat ini
  static Future<String?> getRole() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyRole);
  }

  // =========================================================================
  // 3. DATA PROFIL PENGGUNA
  // =========================================================================

  /// Simpan snapshot profil pengguna ke JSON cache
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserData, jsonEncode(data));
  }

  /// Ambil profil pengguna
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Simpan profil Nasabah ke memory cache dan persistent storage
  static Future<void> saveCachedNasabah(NasabahModel nasabah) async {
    _cachedNasabah = nasabah;
    await saveUserData(nasabah.toJson());
  }

  /// Alias untuk saveCachedNasabah
  static Future<void> saveNasabah(NasabahModel nasabah) async =>
      saveCachedNasabah(nasabah);

  /// Simpan profil Petugas ke memory cache dan persistent storage
  static Future<void> saveCachedPetugas(PetugasModel petugas) async {
    _cachedPetugas = petugas;
    await saveUserData(petugas.toJson());
  }

  // =========================================================================
  // 4. KONFIGURASI DINAMIS BASE URL API
  // =========================================================================

  /// Simpan Base URL custom (misal jika testing IP Wi-Fi lokal HP fisik)
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCustomBaseUrl, url.trim());
  }

  /// Alias untuk saveBaseUrl
  static Future<void> setBaseUrl(String url) async => saveBaseUrl(url);

  /// Ambil Base URL aktif
  static Future<String> getBaseUrl() async {
    final prefs = await _getPrefs();
    final customUrl = prefs.getString(_keyCustomBaseUrl);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    return ApiConstants.defaultBaseUrl;
  }

  /// Reset Base URL ke bawaan platform
  static Future<void> resetBaseUrl() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCustomBaseUrl);
  }

  // =========================================================================
  // 5. LOGOUT & BERSIHKAN SESI
  // =========================================================================

  /// Hapus seluruh sesi login (Token, Role, User Data, Memory Cache)
  static Future<void> clearSession() async {
    _cachedNasabah = null;
    _cachedPetugas = null;
    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserData);
  }
}
