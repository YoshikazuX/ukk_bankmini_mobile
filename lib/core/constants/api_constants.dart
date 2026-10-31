import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Konstanta Rute & Konfigurasi URL API Backend Bank Mini Sekolah
class ApiConstants {
  // Port default artisan serve / server laravel
  static const int defaultPort = 8000;

  /// Default Base URL yang otomatis mendeteksi platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 adalah alias localhost host machine pada Android Emulator
      return 'http://10.0.2.2:$defaultPort/api';
    }
    // Windows Desktop, macOS, iOS simulator
    return 'http://127.0.0.1:$defaultPort/api';
  }

  // =========================================================================
  // 1. SISTEM & HEALTHCHECK
  // =========================================================================
  static const String root = '/';
  static const String health = '/health';
  static const String docs = '/docs';

  // =========================================================================
  // 1B. AUTENTIKASI UNIVERSAL (ROLE-AGNOSTIC LOGIN)
  // =========================================================================
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  // =========================================================================
  // 2. MODUL NASABAH (MOBILE BANKING SISWA)
  // =========================================================================
  static const String nasabahLogin = '/nasabah/login';
  static const String nasabahLogout = '/nasabah/logout';
  static const String nasabahMe = '/nasabah/me';
  static const String nasabahProfil = '/nasabah/profil';
  static const String nasabahUpdateProfil = '/nasabah/update-profil';
  static const String nasabahSaldo = '/nasabah/saldo';
  static const String nasabahQrisPayload = '/nasabah/qris-payload';
  static const String nasabahVerifyPin = '/nasabah/verify-pin';
  static const String nasabahGantiPassword = '/nasabah/ganti-password';
  static const String nasabahGantiPin = '/nasabah/ganti-pin';
  static const String nasabahRiwayat = '/nasabah/riwayat';
  static const String nasabahRingkasan = '/nasabah/ringkasan';
  static const String nasabahEmergencyFreeze = '/nasabah/emergency-freeze';
  static const String nasabahBadges = '/nasabah/badges';
  static const String nasabahSessions = '/nasabah/sessions';
  static const String nasabahGoals = '/nasabah/goals';
  static String nasabahGoalDetail(dynamic id) => '/nasabah/goals/$id';

  // =========================================================================
  // 2B. PUSAT NOTIFIKASI UNIVERSAL (NASABAH & PETUGAS)
  // =========================================================================
  static const String notifikasi = '/notifikasi';
  static const String notifikasiUnreadCount = '/notifikasi/unread-count';
  static String notifikasiRead(dynamic id) => '/notifikasi/$id/read';
  static const String notifikasiReadAll = '/notifikasi/read-all';

  // =========================================================================
  // 3. MODUL PETUGAS & LOKET TELLER (MOBILE POS)
  // =========================================================================
  static const String petugasLogin = '/petugas/login';
  static const String petugasLogout = '/petugas/logout';
  static const String petugasMe = '/petugas/me';
  static const String petugasNasabahSearch = '/petugas/nasabah';
  static const String petugasNasabahDetail = '/petugas/nasabah'; // + /{identifier}
  static const String tellerSetor = '/petugas/transaksi/setor';
  static const String tellerTarik = '/petugas/transaksi/tarik';
  static const String tellerTransaksiHariIni = '/petugas/transaksi/hari-ini';
  static const String tellerKas = '/petugas/kas';

  // Droping Kas & Daily Report (Teller)
  static const String tellerPengajuanKas = '/petugas/pengajuan-kas';
  static const String tellerDailyReport = '/petugas/daily-report';

  // =========================================================================
  // 4. MODUL SUPERVISOR (APPROVAL & REVIEW)
  // =========================================================================
  static const String supervisorPengajuanKas = '/supervisor/pengajuan-kas';
  static String supervisorSetujuiKas(dynamic id) => '/supervisor/pengajuan-kas/$id/setujui';
  static String supervisorTolakKas(dynamic id) => '/supervisor/pengajuan-kas/$id/tolak';
  static const String supervisorDailyReport = '/supervisor/daily-report';
  static String supervisorUpdateDailyReport(dynamic id) => '/supervisor/daily-report/$id/status';

  // =========================================================================
  // 5. MODUL AVALIS & PRESENSI LOKET
  // =========================================================================
  static const String avalisAbsensi = '/avalis/absensi';
  static const String avalisJadwalHariIni = '/avalis/jadwal-hari-ini';
  static const String avalisCheckIn = '/avalis/absensi/check-in';
  static const String avalisKunjunganSiswa = '/avalis/kunjungan-siswa';
  static const String avalisVerifikasiKunjungan = '/avalis/kunjungan-siswa/verifikasi';

  // =========================================================================
  // 6. MODUL LAPORAN & EKSEKUTIF METRICS
  // =========================================================================
  static const String laporanRingkasanHarian = '/laporan/ringkasan-harian';
  static const String laporanSaldoPerKelas = '/laporan/saldo-per-kelas';
  static const String laporanMutasiJurnal = '/laporan/mutasi-jurnal';
}
