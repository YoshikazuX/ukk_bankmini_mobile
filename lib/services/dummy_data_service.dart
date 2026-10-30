import '../models/nasabah_model.dart';
import '../models/transaksi_model.dart';
import '../models/notifikasi_model.dart';
import '../models/saving_goal_model.dart';
import '../models/badge_model.dart';
import '../models/session_model.dart';

/// Hasil otentikasi login
class AuthResult {
  final bool success;
  final String message;
  final NasabahModel? nasabah;

  const AuthResult({
    required this.success,
    required this.message,
    this.nasabah,
  });
}

/// Service data nasabah Bank Mini Sekolah
/// Disesuaikan 100% dengan database Laravel (belajar_laravel_handa):
/// - Roles backend yang membuat & melayani nasabah: admin (Administrator Utama), teller1 (Petugas Loket Teller), spv1 (Kepala Bank Mini)
/// - Nasabah hanya bisa masuk jika akun sudah didaftarkan oleh admin di web.
/// - Akun Dewi Handayani Nur Halimah adalah akun baru (saldo awal Rp50.000, 1 mutasi setoran awal, lencana lainnya terkunci, statistik grafik awal).
class DummyDataService {
  // Current active nasabah state
  static NasabahModel _currentNasabah = NasabahModel(
    id: '1',
    noRekening: '202601001',
    nis: '17763', // Sesuai DatabaseSeeder Laravel
    namaLengkap: 'Dewi Handayani Nur Halimah',
    kelas: 'XI RPL 1',
    jurusan: 'Rekayasa Perangkat Lunak',
    kategori: 'SISWA',
    status: 'AKTIF',
    totalSaldo: 50000, // Saldo setoran awal saat dibuatkan admin
    saldoMengendap: 10000,
    username: 'Handa', // Username resmi di Laravel
    pinKeamanan: '240808', // PIN keamanan resmi di DatabaseSeeder Laravel
    createdAt: DateTime(2026, 10, 26, 14, 0),
  );

  /// Database akun resmi yang dibuat oleh Admin Bank Mini di Web Laravel
  static final Map<String, Map<String, dynamic>> _registeredAccounts = {
    // Akun 1: Dewi Handayani Nur Halimah (Sesuai DatabaseSeeder.php)
    'handa': {
      'username': 'Handa',
      'password': 'password123',
      'pin': '240808',
      'nasabah': _currentNasabah,
    },
    // Alias untuk kenyamanan pengujian
    'dewi_halimah': {
      'username': 'Handa',
      'password': 'password123',
      'pin': '240808',
      'nasabah': _currentNasabah,
    },
    // Akun 2: Siswa Kedua (Sesuai CSV Template NasabahController.php)
    'siswa2': {
      'username': 'siswa2',
      'password': 'password123',
      'pin': '123456',
      'nasabah': NasabahModel(
        id: '2',
        noRekening: '202601002',
        nis: '17764',
        namaLengkap: 'Contoh Siswa Kedua',
        kelas: 'X TKJ 2',
        jurusan: 'Teknik Komputer dan Jaringan',
        kategori: 'SISWA',
        status: 'AKTIF',
        totalSaldo: 0,
        saldoMengendap: 10000,
        username: 'siswa2',
        pinKeamanan: '123456',
        createdAt: DateTime(2026, 10, 26, 15, 0),
      ),
    },
  };

  /// Otentikasi login nasabah
  /// Memastikan HANYA akun yang telah dibuatkan oleh Admin yang dapat login.
  static AuthResult authenticate(String username, String password) {
    final key = username.trim().toLowerCase();

    // 1. Cek apakah username terdaftar di sistem admin
    if (!_registeredAccounts.containsKey(key)) {
      return AuthResult(
        success: false,
        message:
            'Akun "$username" tidak ditemukan. Akun nasabah Bank Mini Sekolah hanya dapat dibuatkan oleh Administrator Utama / Petugas Loket melalui aplikasi web perbankan.',
      );
    }

    final account = _registeredAccounts[key]!;
    final validPassword = account['password'] as String;

    // 2. Cek kecocokan password (mendukung 'password123' dari seeder atau '123456' sebagai alias demo)
    if (password != validPassword && password != '123456') {
      return AuthResult(
        success: false,
        message:
            'Kata sandi salah untuk akun "$username". Silakan cek kembali atau gunakan layanan WhatsApp Admin untuk bantuan pemulihan.',
      );
    }

    // 3. Cek status blokir
    final nasabah = account['nasabah'] as NasabahModel;
    if (nasabah.isBlocked) {
      return const AuthResult(
        success: false,
        message:
            'Rekening ini sedang dibekukan/diblokir sementara. Silakan buka blokir darurat atau hubungi Admin loket.',
      );
    }

    _currentNasabah = nasabah;
    return AuthResult(
      success: true,
      message: 'Login berhasil.',
      nasabah: _currentNasabah,
    );
  }

  /// Ambil data nasabah saat ini
  static NasabahModel getNasabah() => _currentNasabah;

  /// Update status blokir rekening darurat
  static void setBlockedStatus(bool blocked) {
    _currentNasabah = _currentNasabah.copyWith(
      status: blocked ? 'DIBLOKIR' : 'AKTIF',
    );
  }

  /// Verifikasi PIN transaksi di loket Teller (Sesuai PIN Laravel: 240808)
  static bool verifyPin(String pin) {
    return pin == _currentNasabah.pinKeamanan ||
        pin == '240808' ||
        pin == '123456';
  }

  /// Riwayat mutasi buku tabungan digital
  /// Karena akun Dewi adalah akun dummy yang baru dibuat oleh Admin:
  /// Hanya terdapat 1 transaksi awal: Setoran Awal Pembukaan Rekening oleh Petugas Teller (teller1)
  static List<TransaksiModel> getTransaksiList() {
    return [
      TransaksiModel(
        id: 'TRX-20261026-001',
        noRekening: _currentNasabah.noRekening,
        jenis: 'SETORAN',
        jumlah: 50000,
        saldoSebelum: 0,
        saldoSesudah: 50000,
        keterangan: 'Setoran Awal Pembukaan Rekening',
        tellerName: 'Petugas Loket Teller (teller1)',
        tanggal: DateTime(2026, 10, 26, 14, 15),
        isRead: true,
      ),
    ];
  }

  /// Notifikasi transaksi real-time
  static List<NotifikasiModel> getNotifikasiList() {
    return [
      NotifikasiModel(
        id: 'N001',
        title: 'Setoran Awal Buka Rekening',
        message:
            'Setoran awal sebesar Rp50.000 telah disahkan oleh Petugas Loket Teller (teller1) di Loket 01. Saldo aktif Anda sekarang Rp50.000.',
        jenis: 'SETORAN',
        timestamp: DateTime(2026, 10, 26, 14, 15),
        isRead: false,
      ),
      NotifikasiModel(
        id: 'N002',
        title: 'Pendaftaran Rekening Baru',
        message:
            'Selamat datang di LKM Mitra Siswa Abadi! Rekening ${_currentNasabah.noRekening} atas nama ${_currentNasabah.namaLengkap} resmi didaftarkan oleh Administrator Utama (admin).',
        jenis: 'SYSTEM',
        timestamp: DateTime(2026, 10, 26, 14, 0),
        isRead: true,
      ),
      NotifikasiModel(
        id: 'N003',
        title: '⭐ Lencana Pertama Diraih!',
        message:
            'Selamat! Anda meraih lencana "First Deposit" setelah setoran awal pembukaan rekening berhasil dikonfirmasi.',
        jenis: 'SYSTEM',
        timestamp: DateTime(2026, 10, 26, 14, 16),
        isRead: true,
      ),
    ];
  }

  /// Target Tabungan Impian (Saving Goals)
  /// Untuk akun baru, target baru dibuat dan progres masih 0% (belum ada target yang selesai).
  static List<SavingGoalModel> getSavingGoals() {
    return [
      SavingGoalModel(
        id: 'SG001',
        nama: 'Beli Buku Komputer',
        targetAmount: 200000,
        currentAmount: 0,
        icon: '📚',
        createdAt: DateTime(2026, 10, 26),
        deadline: DateTime(2026, 12, 31),
        isCompleted: false,
      ),
      SavingGoalModel(
        id: 'SG002',
        nama: 'Kunjungan Industri',
        targetAmount: 500000,
        currentAmount: 0,
        icon: '🏭',
        createdAt: DateTime(2026, 10, 26),
        deadline: DateTime(2027, 3, 15),
        isCompleted: false,
      ),
    ];
  }

  /// Sistem Lencana Prestasi Menabung (Gamification Badges)
  /// Karena akun baru, hanya lencana "First Deposit" yang terbuka (dari setoran awal buka rekening).
  /// Lencana lainnya masih TERKUNCI dan baru bisa diraih setelah aktif bertransaksi di loket.
  static List<BadgeModel> getBadges() {
    return [
      BadgeModel(
        id: 'B001',
        nama: 'First Deposit',
        deskripsi: 'Berhasil melakukan setoran pertama saat pembukaan rekening di loket.',
        icon: '⭐',
        tier: 'bronze',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 10, 26, 14, 15),
      ),
      BadgeModel(
        id: 'B002',
        nama: 'Penabung Konsisten',
        deskripsi: 'Menabung rutin selama 3 bulan berturut-turut di loket Teller.',
        icon: '🔥',
        tier: 'silver',
        isUnlocked: false,
      ),
      BadgeModel(
        id: 'B003',
        nama: 'Pro Saver',
        deskripsi: 'Mencapai total saldo tabungan Rp100.000 untuk pertama kalinya.',
        icon: '💎',
        tier: 'gold',
        isUnlocked: false,
      ),
      BadgeModel(
        id: 'B004',
        nama: 'Target Hunter',
        deskripsi: 'Berhasil menyelesaikan minimal 1 target tabungan impian Anda.',
        icon: '🎯',
        tier: 'silver',
        isUnlocked: false,
      ),
      BadgeModel(
        id: 'B005',
        nama: 'Super Saver',
        deskripsi: 'Mencapai total saldo tabungan Rp500.000.',
        icon: '🏆',
        tier: 'gold',
        isUnlocked: false,
      ),
      BadgeModel(
        id: 'B006',
        nama: 'Aktivis Loket',
        deskripsi: 'Melakukan minimal 5 kali transaksi mandiri di loket Bank Mini Sekolah.',
        icon: '👑',
        tier: 'gold',
        isUnlocked: false,
      ),
    ];
  }

  /// Riwayat Sesi Login (Active Session & Device Log)
  static List<SessionModel> getSessionLogs() {
    return [
      SessionModel(
        id: 'S001',
        deviceName: 'Perangkat Siswa (Android / Mobile)',
        deviceType: 'android',
        ipAddress: '192.168.1.105',
        location: 'SMK - Lab Rekayasa Perangkat Lunak',
        lastAccess: DateTime.now(),
        isCurrentSession: true,
      ),
    ];
  }

  /// Data untuk grafik keuangan
  /// Karena akun baru, hanya terdapat data bulan berjalan (Setoran Awal Rp50.000, Penarikan Rp0)
  static Map<String, List<double>> getMonthlyFinancialData() {
    return {
      'months': [10.0], // Bulan Oktober 2026 (Bulan pendaftaran akun baru)
      'setoran': [50000.0],
      'penarikan': [0.0],
    };
  }

  static List<Map<String, dynamic>> getFaqList() {
    return [
      {
        'category': 'Transaksi di Loket',
        'items': [
          {
            'question': 'Bagaimana cara melakukan setoran di loket?',
            'answer':
                'Datangi loket Bank Mini, serahkan uang kepada Petugas Teller, lalu tunjukkan QR Code rekening Anda dari aplikasi. Teller akan memindai QR Code dan memproses setoran. Pastikan Anda mengecek notifikasi di aplikasi untuk konfirmasi.',
          },
          {
            'question': 'Bagaimana cara melakukan penarikan di loket?',
            'answer':
                'Datangi loket Bank Mini, sampaikan jumlah penarikan kepada Teller, tunjukkan QR Code rekening Anda, lalu masukkan PIN 6 digit Anda (PIN: 240808) pada layar otorisasi sebagai persetujuan penarikan. Teller akan memproses dan menyerahkan uang tunai.',
          },
          {
            'question': 'Berapa minimal saldo yang harus tersisa?',
            'answer':
                'Saldo mengendap minimum adalah Rp10.000. Anda hanya dapat menarik dana di atas jumlah tersebut. Contoh: jika saldo Anda Rp50.000, maka maksimal penarikan adalah Rp40.000.',
          },
        ],
      },
      {
        'category': 'Keamanan Akun',
        'items': [
          {
            'question': 'Bagaimana cara menjaga kerahasiaan PIN saya?',
            'answer':
                'Jangan pernah membagikan PIN kepada siapapun termasuk teman, guru, atau sesama siswa. Ganti PIN secara berkala dan hubungi Admin jika kartu Anda hilang.',
          },
          {
            'question': 'Apa yang harus dilakukan jika kartu/QR Code saya dicuri?',
            'answer':
                'Segera gunakan fitur "Blokir Rekening Darurat" di aplikasi untuk membekukan rekening sementara. Kemudian hubungi Admin melalui WhatsApp untuk tindak lanjut.',
          },
          {
            'question': 'Bagaimana cara mereset password akun saya?',
            'answer':
                'Hubungi Admin Bank Mini melalui WhatsApp. Akun nasabah dikelola secara terpusat oleh sekolah sehingga Admin dapat langsung membantu mereset kata sandi Anda.',
          },
        ],
      },
      {
        'category': 'Fitur Aplikasi',
        'items': [
          {
            'question': 'Apa itu Target Tabungan Impian?',
            'answer':
                'Fitur untuk membuat rencana tabungan dengan target nominal tertentu. Misalnya "Beli Buku Komputer - Rp200.000". Anda bisa memantau progres pencapaian target melalui progress bar di aplikasi.',
          },
          {
            'question': 'Bagaimana cara mendapatkan lencana prestasi?',
            'answer':
                'Lencana diberikan secara otomatis berdasarkan aktivitas transaksi Anda di loket. Karena akun Anda masih baru, baru lencana "First Deposit" yang terbuka. Lencana lainnya akan terbuka seiring keaktifan Anda menabung.',
          },
          {
            'question': 'Apa itu Saldo Efektif dan Saldo Mengendap?',
            'answer':
                'Total Saldo adalah keseluruhan uang di rekening (Rp50.000). Saldo Mengendap (Rp10.000) adalah jumlah minimum yang harus tetap tersisa. Saldo Efektif (Rp40.000) adalah jumlah yang bisa Anda tarik di loket.',
          },
        ],
      },
    ];
  }
}
