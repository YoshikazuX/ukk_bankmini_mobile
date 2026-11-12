# LKM Mitra Siswa Abadi — Mobile Banking & POS Loket

Aplikasi mobile perbankan mikro sekolah berbasis Flutter untuk ekosistem Bank Mini Sekolah (SMK Negeri 1 Bantul). Aplikasi ini menggabungkan layanan *self-service mobile banking* untuk siswa nasabah dengan operasional loket kasir (*Mobile POS*), otorisasi supervisor (*Checker*), dan pemantauan sistem admin dalam satu aplikasi adaptif peran (*4-in-1 Role-Adaptive Interface*).

---

## 📌 Ringkasan Proyek

| Informasi | Detail |
|---|---|
| **Nama Aplikasi** | LKM Mitra Siswa Abadi Mobile |
| **Paket / Versi** | `ukk_bankmini` (v2.4.0+1) |
| **Framework & Bahasa** | Flutter 3.x / Dart 3.11+ |
| **Design System** | Material Design 3 (Institutional Theme: Emerald Teal & Deep Navy) |
| **Backend Integration** | Laravel 13 REST API + Laravel Sanctum Authentication |
| **Basis Data Utama** | MySQL / MariaDB (`db_bankmini`) |
| **Target Platform** | Android (APK/AAB), iOS, Web, Windows Desktop |

---

## 🎯 Arsitektur Antarmuka 4-in-1 (Role-Adaptive)

Aplikasi menggunakan autentikasi universal satu pintu (`/api/auth/login`). Hak akses dideteksi langsung dari respons server dan mengarahkan pengguna ke antarmuka yang sesuai:

1. **Nasabah (Siswa)**: Akses mandiri untuk pemantauan saldo, riwayat transaksi, target menabung (*Saving Goals*), lencana literasi (*Badges*), kartu digital identitas QRIS, grafik arus kas, dan pemblokiran darurat rekening mandiri.
2. **Teller (Petugas Loket)**: Terminal kasir mobile untuk pencarian nasabah, pemindaian QRIS/barcode, transaksi setor tunai, tarik tunai dengan verifikasi PIN, pengajuan droping kas, serta penyusunan lembar tutup kas harian (*Daily Report*).
3. **Supervisor (Kepala Bank Mini)**: Panel persetujuan (*Approval*) tiket droping kas loket dengan *pessimistic lock*, inspeksi selisih kas fisik vs sistem, dan validasi laporan tutup kas harian.
4. **Administrator Sistem**: Dashboard pemantauan status koneksi server (*Healthcheck*), latensi basis data, riwayat sesi aktif, dan konfigurasi dinamis alamat server (*Base URL Selector*).

---

## ⚙️ Fitur Utama Berdasarkan Peran

### 1. Modul Nasabah (Siswa)
- **Ringkasan Saldo**: Informasi saldo riil, saldo mengendap (minimum Rp 10.000), dan saldo tersedia untuk penarikan.
- **Mutasi Rekening**: Riwayat transaksi setor dan tarik lengkap dengan filter tanggal dan status.
- **Kartu Digital & QRIS**: Tampilan kartu identitas rekening digital dengan kode QR untuk dipindai oleh teller loket.
- **Saving Goals**: Penetapan target tabungan mandiri dengan indikator progres persentase.
- **Gamifikasi Literasi (Badges)**: Sistem penghargaan otomatis berdasarkan konsistensi menabung dan pencapaian target.
- **Grafik Finansial**: Visualisasi tren pemasukan dan pengeluaran bulanan menggunakan `fl_chart`.
- **Emergency Account Freeze**: Tombol blokir rekening mandiri jika kartu atau kredensial hilang/terkompromi.

### 2. Modul Teller (Petugas Loket / Mobile POS)
- **Pemindai QRIS/Barcode**: Pemindaian kamera instan (`mobile_scanner`) untuk memuat rekening nasabah tanpa input manual.
- **Pencarian Nasabah**: Filter pencarian cepat berdasarkan Nama, NIS, Kelas, atau Nomor Rekening.
- **Setor Tunai Cepat**: Formulir setoran kas loket dengan konfirmasi instan ke backend.
- **Tarik Tunai Terproteksi**: Alur penarikan dengan pengecekan saldo tersedia dan verifikasi otorisasi PIN 6-digit nasabah.
- **Pengajuan Droping Kas**: Pengajuan penambahan kas loket ke supervisor saat modal kasir menipis.
- **Laporan Tutup Kas (Daily Report)**: Rekonsiliasi total penerimaan, total pengeluaran, dan penghitungan selisih kas fisik di akhir shift.

### 3. Modul Supervisor (Pemeriksa / Checker)
- **Otorisasi Droping Kas**: Antrean persetujuan atau penolakan permohonan dana loket teller.
- **Verifikasi Laporan Harian**: Pemeriksaan dan penandatanganan digital laporan tutup kas teller harian.
- **Audit Selisih Kas**: Deteksi selisih lebih (*surplus*) atau selisih kurang (*shortage*) kas loket.

### 4. Modul Administrator
- **Server Healthcheck**: Pemantauan status operasional endpoint REST API Laravel.
- **Monitoring Latensi**: Indikator koneksi jaringan dan respons waktu server.
- **Base URL Switcher**: Penggantian dinamis alamat host backend langsung dari aplikasi tanpa kompilasi ulang.

---

## 🛡️ Kebijakan Bisnis & Keamanan

- **Zero Dummy Data Runtime**: Seluruh data (profil, saldo, mutasi, sesi) bersumber dari backend riil. Tidak ada data palsu atau saldo tiruan yang di-hardcode.
- **Proteksi Bullying / Anti-Pemerasan Finansial**: Fitur transfer mandiri antar-siswa ditiadakan secara sengaja. Seluruh lalu lintas kas fisik wajib melalui loket resmi teller dengan penerbitan slip dan pencatatan buku besar.
- **Separation of Duties (SoD)**: Teller (*Maker*) tidak memiliki wewenang untuk menyetujui pengajuan kasnya sendiri; persetujuan mutlak berada di bawah akun Supervisor (*Checker*).
- **3-Layer Security Penarikan Kas**:
  1. Identifikasi fisik atau pemindaian QRIS nasabah di loket.
  2. Validasi kecukupan saldo efektif (mempertahankan saldo minimum mengendap).
  3. Verifikasi PIN 6-digit pada layar otorisasi nasabah.

---

## 🗂️ Struktur Direktori Proyek

```text
lib/
├── core/
│   ├── constants/       # ApiConstants (Endpoint & fallback URL per platform)
│   ├── network/         # ApiClient (Dio singleton), AuthInterceptor, ApiResponse
│   ├── storage/         # SessionStorage (Token Sanctum & cache lokal nasabah)
│   ├── theme/           # AppTheme, AppColors, TextStyle tokens
│   └── utils/           # Helper fungsi (format mata uang, tanggal, validator)
├── models/              # Model data Dart (Nasabah, Petugas, Transaksi, Goals, Badges, Session)
├── screens/             # Tampilan layar UI
│   ├── admin/           # AdminMainScreen
│   ├── supervisor/      # SupervisorMainScreen
│   ├── teller/          # TellerMainScreen, ScanNasabah, Setor, Tarik, DailyReport
│   ├── dashboard_screen.dart
│   ├── kartu_digital_screen.dart
│   ├── login_screen.dart
│   ├── mutasi_screen.dart
│   ├── saving_goals_screen.dart
│   └── ...
├── services/            # Layer integrasi API backend
│   ├── auth_service.dart
│   ├── nasabah_api_service.dart
│   ├── teller_api_service.dart
│   └── supervisor_api_service.dart
├── widgets/             # Komponen UI modular yang dapat digunakan kembali
│   └── common/          # AppButtons, AppCards, AppInputs, AppStates
└── main.dart            # Titik masuk utama & konfigurasi rute named
```

---

## 🚀 Panduan Memulai & Instalasi

### 1. Prasyarat Sistem
- **Flutter SDK**: Versi 3.x (disarankan channel stable dengan Dart SDK ^3.11.5)
- **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart terpasang
- **Android SDK Platform** (API level 21 minimum, target API 34+)
- Koneksi ke Backend Laravel 13 (lokal atau cloud production)

### 2. Kloning & Pemasangan Dependensi
```bash
# Masuk ke direktori mobile
cd ukk_bankmini_mobile

# Unduh seluruh dependensi paket
flutter pub get
```

### 3. Konfigurasi Endpoint Backend (Base URL)
Secara default, URL backend dikonfigurasi pada file [api_constants.dart](file:///d:/UKK%20Bank%20Mini/ukk_bankmini_mobile/lib/core/constants/api_constants.dart):

- **Production URL**: `https://hanbank.my.id/api` (digunakan secara otomatis saat mode `--release`)
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **Windows / Web / iOS Simulator**: `http://127.0.0.1:8000/api`

Untuk menentukan alamat server kustom saat menjalankan atau membangun aplikasi, gunakan parameter `--dart-define`:
```bash
flutter run --dart-define=BASE_URL=http://192.168.1.100:8000/api
```

### 4. Menjalankan Aplikasi
```bash
# Menjalankan di perangkat fisik atau emulator aktif
flutter run

# Menjalankan di target spesifik (misalnya Chrome atau Windows)
flutter run -d chrome
flutter run -d windows
```

### 5. Menjalankan Pengujian (Unit & Widget Test)
```bash
flutter test
```

---

## 📦 Kompilasi & Paket Distribusi APK

Aplikasi dapat dikompilasi ke dalam format APK Android dengan perintah berikut:

```bash
# Kompilasi rilis universal
flutter build apk --release

# Kompilasi teroptimasi per arsitektur CPU (ukuran berkas lebih hemat)
flutter build apk --split-per-abi
```

Hasil kompilasi siap pakai yang sudah tersedia pada repositori ini berada di direktori `apk/`:
- `apk/BankMini-v2.4.0-arm64-v8a.apk` (Arsitektur 64-bit modern)
- `apk/BankMini-v2.4.0-armeabi-v7a.apk` (Arsitektur 32-bit perangkat lama)
- `apk/BankMini-v2.4.0-universal.apk` (Arsitektur gabungan seluruh perangkat)

---

## 📄 Lisensi & Hak Cipta

Proyek ini dikembangkan untuk kebutuhan operasional Bank Mini Sekolah dan instrumen Uji Kompetensi Keahlian (UKK) Rekayasa Perangkat Lunak / Akuntansi di SMK Negeri 1 Bantul. Hak cipta dilindungi oleh LKM Mitra Siswa Abadi.
