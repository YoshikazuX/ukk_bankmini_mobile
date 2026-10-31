# PRODUCT REQUIREMENT DOCUMENT (PRD)
# LKM MITRA SISWA ABADI — FLUTTER MOBILE APP

---

## 1. Identifikasi Dokumen

| Properti | Nilai Spesifikasi |
|---|---|
| **Nama Produk** | LKM Mitra Siswa Abadi Mobile |
| **Platform Target** | Android (APK/AAB), iOS, Web (PWA), Windows Desktop |
| **Framework & Versi** | Flutter 3.x / Dart 3.x (Material Design 3) |
| **Backend Integration** | Laravel 13 REST API (PHP 8.2+) with Laravel Sanctum |
| **Database Engine** | MySQL / MariaDB (`db_bankmini`) |
| **Versi Dokumen** | **v2.0.0 (Master Implementation & Full Backend Integration)** |
| **Status Dokumen** | **APPROVED & VERIFIED (Production-Built Ready)** |
| **Tanggal Terbit** | 31 Oktober 2026 |

---

## 2. Visi Produk & Ringkasan Eksekutif

### 2.1 Konteks & Latar Belakang
**LKM Mitra Siswa Abadi Mobile** adalah aplikasi perbankan mikro sekolah berbasis Flutter yang dirancang sebagai sarana edukasi literasi keuangan riil bagi siswa, simulator operasional kasir perbankan (*Point of Sale Teller*), terminal otorisasi supervisor (*Checker/Approval Center*), serta instrumen Uji Kompetensi Keahlian (UKK) Nasional bagi siswa jurusan Akuntansi dan Rekayasa Perangkat Lunak di SMK Negeri 1 Bantul.

Aplikasi ini mengadopsi arsitektur **4-in-1 Role-Adaptive Interface**. Melalui autentikasi universal satu pintu (*Universal Auth*), aplikasi secara cerdas mendeteksi hak akses pengguna dari basis data pusat dan secara dinamis membuka lingkungan kerja yang sesuai:
1. **Portal Nasabah / Siswa**: Layanan *self-service mobile banking* yang dilengkapi buku tabungan digital, QRIS identitas, target menabung (*Saving Goals*), lencana literasi (*Badges Gamification*), grafik arus kas bulanan interaktif, dan perlindungan darurat mandiri (*Emergency Account Freeze*).
2. **Portal Petugas Teller Loket**: Terminal *Mobile POS* yang dilengkapi pemindai kamera QRIS/Barcode nasabah, formulir setor tunai cepat, penarikan tunai aman dengan 3 lapis proteksi, pengajuan droping kas, serta penyusunan lembar tutup kas harian (*Daily Report*).
3. **Portal Supervisor (Kepala Bank Mini)**: Panel otorisasi mobile untuk menyetujui atau menolak tiket droping kas loket (*pessimistic lock*), verifikasi laporan penutupan kasir dengan kalkulasi selisih kas otomatis, dan inspeksi buku besar jurnal akuntansi.
4. **Portal Administrator Sistem**: Dashboard mobile pemantauan status kesehatan server backend Laravel, latensi koneksi basis data MySQL, pemantauan shift avalis, dan konfigurasi dinamis alamat IP server (*Base URL Selector*).

### 2.2 Keputusan Arsitektur Utama (v2.0.0)
- **Backend sebagai Single Source of Truth**: Seluruh identitas pengguna, profil, saldo, mutasi, transaksi, status rekening, PIN, saving goals, badges, session logs, dan notifikasi berasal langsung dari Laravel REST API dan MySQL/MariaDB.
- **Zero Dummy Data Policy**: Seluruh ketergantungan runtime terhadap `DummyDataService` dan mekanisme data mock telah dieliminasi 100%. Data pengujian hanya berupa unit test fixture yang terisolasi.
- **Kebijakan Ketika Server Tidak Tersedia**: Menampilkan pesan koneksi terputus ("Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali.") dengan tombol Coba Lagi tanpa mengganti saldo dengan angka statis atau membuat data palsu.
- **FR-29 Deprecated**: FR-29 Offline Mocking resmi dinyatakan *deprecated* dan diganti dengan *offline connection detection*, *retry mechanism*, dan *idempotency status verification*.
- **FR-30 Base URL Switcher**: Konfigurasi dinamis alamat server dipertahankan untuk fleksibilitas testing jaringan Wi-Fi sekolah maupun emulator.
- **Kebijakan Finansial Aman Pelajar**: Fitur transfer mandiri antar-siswa dinonaktifkan secara terprogram untuk mencegah pemerasan (*bullying*) di lingkungan sekolah. Seluruh transaksi kas fisik dipusatkan melalui loket resmi teller ber-slip dan ber-jurnal.
- **Strict Separation of Duties (SoD)**: Teller (*Maker*) tidak dapat menyetujui pengajuan kasnya sendiri; Supervisor (*Checker*) bertindak sebagai pemutus sah.

---

## 3. Arsitektur Perangkat Lunak & Struktur Direktori

### 3.1 Diagram Arsitektur Komponen Mobile

```mermaid
graph TB
    subgraph UI & Presentation Layer
        Screens["15 Named Routes (Login, Dashboard, POS, SPV, Admin)"]
        CommonWidgets["Reusable Components (AppButtons, AppCards, AppInputs, AppStates)"]
        FLChart["FL Chart Visualizer (Monthly Cashflow & Trends)"]
        Scanner["MobileScanner (Camera QRIS & Barcode)"]
    end

    subgraph Service & Controller Layer
        AuthService["AuthService (Universal Auth & Token Lifecycle)"]
        NasabahService["NasabahApiService (Saldo, Mutasi, PIN, Goals, Badges, Freeze)"]
        TellerService["TellerApiService (Setor, Tarik, Droping, Daily Report)"]
        SpvService["SupervisorApiService (Approval, Review, Jurnal)"]
    end

    subgraph Core Network & Storage Layer
        ApiClient["ApiClient Singleton (Dio HTTP Engine)"]
        AuthInterceptor["AuthInterceptor (Bearer Token Injection & 401 Handler)"]
        ApiConstants["ApiConstants (Platform-Aware Base URLs & Endpoints)"]
        SessionStorage["SessionStorage (SharedPreferences Persistence)"]
    end

    subgraph Backend Core Single Source of Truth
        LaravelAPI["Laravel 13 REST API (Sanctum Tokens & Policy Engine)"]
        Database[("MySQL / MariaDB: db_bankmini")]
    end

    Screens --> CommonWidgets
    Screens --> FLChart
    Screens --> Scanner

    Screens --> AuthService
    Screens --> NasabahService
    Screens --> TellerService
    Screens --> SpvService

    AuthService --> ApiClient
    NasabahService --> ApiClient
    TellerService --> ApiClient
    SpvService --> ApiClient

    ApiClient --> AuthInterceptor
    ApiClient --> ApiConstants
    ApiClient --> SessionStorage
    ApiClient --> LaravelAPI
    LaravelAPI --> Database
```

### 3.2 Struktur File Aktual Proyek Flutter (`lib/`)

```
ukk_bankmini_mobile/
├── lib/
│   ├── main.dart                       # Entry point, theme binding, 15 named routes
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart      # Platform-aware base URL, 35+ API endpoints
│   │   ├── network/
│   │   │   ├── api_client.dart         # Dio singleton, timeout, error normalization
│   │   │   ├── api_response.dart       # Generic Laravel API envelope parser
│   │   │   └── auth_interceptor.dart   # Sanctum Bearer token injector, 401 handler
│   │   ├── storage/
│   │   │   └── session_storage.dart    # SharedPreferences token, role, cache persistence
│   │   ├── theme/
│   │   │   └── app_theme.dart          # Deep Navy, Mint Teal, Slate Gray, Typography
│   │   └── utils/
│   │       └── helpers.dart            # Rupiah formatter, relative time, snackbars
│   ├── models/
│   │   ├── badge_model.dart            # Achievement badge, unlock status, tier mapping
│   │   ├── nasabah_model.dart          # Student account, effective balance, QRIS payload
│   │   ├── notifikasi_model.dart       # Real-time transaction alert & system notices
│   │   ├── petugas_model.dart          # Employee profile & RBAC role
│   │   ├── saving_goal_model.dart      # Target impian, progress percent, remaining
│   │   ├── session_model.dart          # Active Sanctum token session & device logs
│   │   └── transaksi_model.dart        # Transaction mutation, voucher, ledger code
│   ├── screens/
│   │   ├── admin/
│   │   │   └── admin_main_screen.dart  # Server health, MySQL latency, avalis attendance
│   │   ├── supervisor/
│   │   │   └── supervisor_main_screen.dart # Approval center, daily review, general ledger
│   │   ├── teller/
│   │   │   ├── daily_report_screen.dart    # Cash closing form with difference calculation
│   │   │   ├── pengajuan_kas_screen.dart   # Cash drop request ticket submission
│   │   │   ├── scan_nasabah_screen.dart    # QRIS & Barcode native camera scanner
│   │   │   ├── setor_tunai_screen.dart     # Deposit form [Code 101] with quick amounts
│   │   │   ├── tarik_tunai_screen.dart     # Withdrawal [Code 201] with 6-digit PIN modal
│   │   │   └── teller_main_screen.dart     # Mobile POS shell & shift statistics
│   │   ├── badges_screen.dart          # Dynamic gamification badges from database
│   │   ├── blokir_rekening_screen.dart # Emergency account freeze via REST API
│   │   ├── dashboard_screen.dart       # Student hero balance, cashflow, quick actions
│   │   ├── financial_chart_screen.dart # 6-month FL Chart cashflow and running balance
│   │   ├── forgot_password_screen.dart # Help instructions to contact CS / Back-office
│   │   ├── help_center_screen.dart     # FAQ, WhatsApp admin button, SOP guidance
│   │   ├── kartu_digital_screen.dart   # High-contrast QRIS, barcode, copy account
│   │   ├── login_screen.dart           # Universal Auth, role router, Base URL switcher
│   │   ├── main_navigation.dart        # 4-tab bottom navigation for student banking
│   │   ├── mutasi_screen.dart          # Transaction passbook with filter & receipt sheet
│   │   ├── notifikasi_screen.dart      # Real-time in-app notification center
│   │   ├── pin_authorization_screen.dart # 6-digit PIN numpad verification
│   │   ├── profile_menu_screen.dart    # Profile menu, security, terms, and logout
│   │   ├── saving_goals_screen.dart    # Target wallet CRUD & progress tracking
│   │   └── session_log_screen.dart     # Sanctum device session & audit log viewer
│   ├── services/
│   │   ├── auth_service.dart           # Universal auth controller & token management
│   │   ├── nasabah_api_service.dart    # Real API client for student banking features
│   │   ├── supervisor_api_service.dart # Real API client for approval & ledger features
│   │   └── teller_api_service.dart     # Real API client for teller POS features
│   └── widgets/common/
│       ├── app_buttons.dart            # Primary, secondary, danger, quick chips
│       ├── app_cards.dart              # Status badges, balance card, transaction tiles
│       ├── app_inputs.dart             # InputField with prefix/suffix icons, numpad
│       └── app_states.dart             # PageHeader, EmptyState, ErrorState, ConfirmDialog
└── test/
    ├── fitur_lengkap_nasabah_test.dart # Saving goals, badges, freeze, sessions test
    ├── nasabah_module_test.dart        # Model parsing, effective balance, PIN verification
    ├── network_test.dart               # Core network, ApiClient, SessionStorage
    ├── supervisor_admin_test.dart      # Cash drop approval, daily closing review, RBAC
    ├── teller_module_test.dart         # Setor 101, tarik 201, kas laci, pengajuan kas
    ├── test_api_mock_interceptor.dart  # Isolated unit test mock fixture adapter
    └── widget_test.dart                # LkmBankMiniApp, LoginScreen, UI theme rendering
```

---

## 4. Skema Warna & Desain Token Institusional

| Token Desain | Nilai Heksadesimal | Peran & Penggunaan |
|---|:---:|---|
| `primaryNavy` | `#101B2D` | Warna identitas perbankan formal, AppBar, Hero Card, tombol aksi utama |
| `secondaryNavy`| `#1D2D44` | Garis tepi (*border*) kartu, aksen bayangan halus (*shadow*) |
| `accentTeal` | `#19C9A3` | Warna aksen kontras, highlight nominal, indikator progres, QR Code outline |
| `background` | `#F8FAFC` | Latar belakang kanvas aplikasi (*Clean Off-White*) |
| `surface` | `#FFFFFF` | Latar kartu informasi, modal bottom sheet, dialog input |
| `surfaceMuted` | `#F1F5F9` | Latar badge kode transaksi, avatar profil, input field non-aktif |
| `textPrimary` | `#0F172A` | Teks judul utama, nominal transaksi, nama lengkap pengguna |
| `textSecondary`| `#64748B` | Teks keterangan, tanggal mutasi, panduan field formulir |
| `success` | `#10B981` | Setoran masuk (+), status disetujui, rekening aktif |
| `danger` | `#EF4444` | Penarikan kas (-), rekening diblokir, tiket ditolak |
| `warning` | `#F59E0B` | Tiket pending approval, status saldo minimal mengendap |

---

## 5. Alur Kerja Universal Auth & Dynamic Routing

```mermaid
sequenceDiagram
    autonumber
    actor Pengguna
    participant UI as LoginScreen
    participant Auth as AuthService
    participant Storage as SessionStorage
    participant Backend as Laravel REST API (/api/auth/login)

    Pengguna->>UI: Input Username/NIS/No. Rekening & Password
    UI->>Auth: AuthService.login(username, password)
    Auth->>Backend: POST /api/auth/login
    alt Autentikasi Berhasil
        Backend-->>Auth: HTTP 200 {token, role, data: {...}}
        Auth->>Storage: saveToken(token) & saveRole(role)
        Auth->>Storage: Cache NasabahModel / PetugasModel
        Auth-->>UI: UnifiedAuthResult(success: true, role)
        UI->>UI: Dynamic Routing berdasarkan Role
        alt role == 'nasabah'
            UI-->>Pengguna: Navigasi ke MainNavigation (Dashboard Siswa)
        else role == 'teller'
            UI-->>Pengguna: Navigasi ke TellerMainScreen (Mobile POS)
        else role == 'supervisor'
            UI-->>Pengguna: Navigasi ke SupervisorMainScreen (Approval Center)
        else role == 'admin'
            UI-->>Pengguna: Navigasi ke AdminMainScreen (Infrastruktur)
        end
    else Kredensial Salah
        Backend-->>Auth: HTTP 401/422 {success: false, message}
        Auth-->>UI: UnifiedAuthResult(success: false, message)
        UI-->>Pengguna: Tampilkan pesan error validasi
    else Server Terputus / Jaringan Mati
        Auth->>UI: Tangkap Network Exception (Timeout/Connection Refused)
        UI-->>Pengguna: Tampilkan pesan "Server Bank Mini tidak dapat dihubungi. Periksa koneksi jaringan dan coba kembali."
    end
```

---

## 6. Spesifikasi Portal Nasabah (Siswa)

### 6.1 Dashboard Nasabah (`/home`)
- **Header Institusional**: Logo SMK Negeri 1 Bantul, avatar inisial, sapaan selamat datang, nama lengkap siswa, kategori nasabah.
- **Hero Balance Card**:
  - Saldo Total aktual dari database backend.
  - Eye toggle untuk menyembunyikan/menampilkan nominal saldo.
  - Saldo Tersedia = Total Saldo - Saldo Mengendap (Rp 10.000).
  - Tombol salin nomor rekening ke papan klip (*clipboard*).
- **Aksi Cepat**: Target Nabung, Buku Mutasi, Kartu Pelajar Digital, Bantuan Admin WhatsApp.
- **Ringkasan Arus Kas**: Total setoran dan total penarikan bulan berjalan.
- **5 Transaksi Terbaru**: Menampilkan mutasi transaksi terkini langsung dari server.

### 6.2 Target Tabungan Impian / Saving Goals (`/goals`)
- **CRUD Penuh via API**: `GET /api/nasabah/goals`, `POST /api/nasabah/goals`, `DELETE /api/nasabah/goals/{id}`.
- **Kalkulasi Real-Time**: Persentase ketercapaian target (`progressPercent`) dan sisa dana yang harus ditabung (`remaining`).
- **Status State**: Loading spinner saat memuat, Empty State ketika target belum dibuat, dan Error State dengan tombol Coba Lagi saat server terputus.

### 6.3 Lencana Prestasi Menabung / Gamification Badges (`/badges`)
- **Evaluasi Dinamis Backend**: `GET /api/nasabah/badges` menghitung pencapaian berdasarkan frekuensi setor, akumulasi saldo, dan kedisiplinan riil di database.
- **Sistem Tiering**: Bronze (Perunggu), Silver (Perak), Gold (Emas).
- **Statistik Apresiasi**: Persentase koleksi lencana dan penentuan level literasi finansial.

### 6.4 Grafik Arus Kas & Analisis Keuangan (`/chart`)
- **Single Source of Truth**: Mengonsumsi data tren 6 bulan terakhir dari `GET /api/nasabah/ringkasan`.
- **Mode Visualisasi**:
  - *Diagram Batang*: Membandingkan setoran tabungan (Hijau) vs penarikan (Merah) per bulan.
  - *Grafik Garis Tren*: Pertumbuhan akumulasi saldo berjalan riil (tanpa angka saldo statis/dummy).
- **Metrik Analisis**: Rata-rata setoran bulanan, rasio tabung (*savings rate*), dan tips literasi finansial.

### 6.5 Blokir Rekening Darurat (`/blokir`)
- **Protokol SOP-09 Keamanan**: `POST /api/nasabah/blokir-darurat` membekukan rekening mandiri ketika kartu/QR hilang.
- **Irreversible Mandiri**: Rekening yang dibekukan berstatus `NONAKTIF`. Pembukaan blokir wajib dilakukan langsung di loket Bank Mini Sekolah melalui verifikasi identitas fisik oleh Administrator.

### 6.6 Riwayat Sesi Login (`/session`)
- **Audit Keamanan**: `GET /api/nasabah/sessions` menampilkan daftar token aktif Laravel Sanctum, nama perangkat, alamat IP, lokasi, dan cap waktu akses terakhir.

### 6.7 Kartu Digital & QRIS Siswa (`/kartu`)
- **Format Kartu Virtual**: Visual kartu navy dengan logo sekolah, nama siswa, NIS, kelas, jurusan, dan tanggal terbit.
- **Kode QRIS Rekening**: Payload standar `BANKMINI:REK:{noRekening}:NIS:{nis}:NAMA:{nama}` untuk di-scan oleh teller di loket.

### 6.8 Pusat Notifikasi Transaksi (`/notifikasi`)
- **Universal In-App Alert**: `GET /api/notifications`, `POST /api/notifications/read-all`.
- **Kategori Filter**: SEMUA, TRANSAKSI (Setor/Tarik), KEAMANAN (Login/Blokir).

---

## 7. Spesifikasi Portal Teller Loket (Mobile POS)

- **Pencarian & Scan Nasabah**: Auto-complete pencarian nama/NIS/rekening dan kamera native pemindai QRIS/Barcode.
- **Setor Tunai (Kode Sandi 101)**: Input nominal setor cepat (Rp10rb, Rp20rb, Rp50rb, Rp100rb), validasi minimal Rp1.000, penerbitan slip setoran.
- **Penarikan Tunai (Kode Sandi 201)**: 3 Lapis proteksi:
  1. Proteksi Saldo Mengendap (Rp 10.000 wajib tersisa).
  2. Proteksi Ketersediaan Kas Fisik Laci Teller (mencegah kas negatif).
  3. Verifikasi 6-Digit PIN Otorisasi Nasabah.
- **Pengajuan Droping Kas**: Tiket permohonan modal kas loket ke Supervisor dengan validasi minimal Rp 10.000 dan pencatatan alasan operasional.
- **Closing Kas Harian (Daily Report)**: Rekonsiliasi saldo awal, total setor, total tarik, total droping kas, perhitungan kas sistem vs kas fisik, dan deteksi selisih otomatis.

---

## 8. Spesifikasi Portal Supervisor (Approval Center)

- **Otorisasi Droping Kas**: Daftar tiket kas masuk pending dengan mekanisme *pessimistic lock*, tombol setujui, dan formulir penolakan wajib alasan.
- **Review Closing Kasir (Daily Report)**: Verifikasi lembar closing harian seluruh teller loket dengan tanda selisih (klop/selisih lebih/selisih kurang).
- **Inspeksi Buku Jurnal Umum**: Pemantauan jurnal akuntansi berpasangan ganda (*double-entry balancing*) secara periodik.
- **Metrik Eksekutif**: Total dana tabungan siswa, kas fisik tersedia, distribusi simpanan per kelas.

---

## 9. Spesifikasi Portal Administrator Sistem

- **Pemantauan Kesehatan Backend**: Ping status kesehatan `/api/health` dan latensi respon dalam milidetik (ms).
- **Presensi Staff Avalis**: Integrasi `/api/avalis/absensi` menampilkan kehadiran shift petugas loket hari ini.
- **Matriks Hak Akses (RBAC)**: Direktori akun resmi percontohan dan batasan wewenang (*Separation of Duties*).
- **Base URL Switcher**: Dialog pengaturan alamat IP backend untuk pengujian lintas perangkat Wi-Fi laboratorium.

---

## 10. Matriks Pengujian & Verifikasi Kualitas (100% Passed)

### 10.1 Hasil Pengujian Unit & Widget Flutter (38 Tests — 100% PASS)

| Test Suite File | Modul / Cakupan | Jumlah Test | Hasil | Keterangan |
|---|---|:---:|:---:|---|
| `network_test.dart` | ApiConstants, ApiResponse, SessionStorage, ApiClient | 6 Tests | **PASS** | Base URL, Token, Session storage |
| `nasabah_module_test.dart` | NasabahModel, TransaksiModel, PIN Verification | 5 Tests | **PASS** | Saldo efektif, format mutasi, validasi PIN |
| `fitur_lengkap_nasabah_test.dart`| Saving Goals, Badges, Sessions, Freeze Status | 5 Tests | **PASS** | CRUD goals, tier lencana, sesi Sanctum, status nonaktif |
| `teller_module_test.dart` | Search, Setor 101, Tarik 201, Kas, Pengajuan Kas, Closing | 7 Tests | **PASS** | POS teller, proteksi kas minus, validasi alasan |
| `supervisor_admin_test.dart` | Approval Kas, Review Daily, Jurnal, Admin Health | 12 Tests | **PASS** | Approval/Reject, audit report, rendering SPV & Admin |
| `widget_test.dart` | Domain Model Fixtures, LkmBankMiniApp Institutional UI | 3 Tests | **PASS** | Rendering LoginScreen, eliminasi demo dummy UI |
| **TOTAL FLUTTER** | **6 Test Suites** | **38 Tests** | **100% PASS** | **Zero Defect — Zero Dummy Data Runtime** |

### 10.2 Hasil Pengujian Backend Laravel (51 Tests, 387 Assertions — 100% PASS)

| Test Suite File | Modul / Cakupan | Jumlah Test | Hasil | Keterangan |
|---|---|:---:|:---:|---|
| `BankMiniFiturSempurnaTest.php` | Filter, detail, audit trail, RBAC, password reset, absensi | 7 Tests | **PASS** | Keamanan & aturan operasional perbankan |
| `DashboardWidgetsTest.php` | Widget Admin, Teller, Supervisor, konsistensi data agregat | 7 Tests | **PASS** | Integritas agregat database antar-dashboard |
| `NasabahApiTest.php` | Universal Auth, Me, Saldo, Mutasi, PIN, Profil CRUD | 13 Tests | **PASS** | Endpoint REST API nasabah siswa |
| `NasabahMobileFiturLengkapTest.php`| Emergency Freeze, Saving Goals, Badges, Sessions, Notifikasi, 6M Trend | 6 Tests | **PASS** | Fitur mobile lengkap terintegrasi database |
| `SupervisorPenyempurnaanTest.php` | Approval center, detail kas, void monitoring, selisih rekonsiliasi | 9 Tests | **PASS** | Maker-checker, locking, no double approval |
| `TellerPenyempurnaanTest.php` | Rekening nonaktif ditolak, kas fisik loket proteksi, idempotency key | 9 Tests | **PASS** | Transaksi aman, idempotensi, void reversal |
| **TOTAL LARAVEL** | **6 Feature Test Suites** | **51 Tests (387 Assertions)** | **100% PASS** | **Integrasi REST API sempurna** |

---

### *Disahkan & Diverifikasi Oleh:*
- **Tim Pengembang Mobile**: Antigravity Mobile Engineering & Core Banking Team
- **Institusi**: SMK Negeri 1 Bantul (Program Keahlian AKL & RPL)
- **Status Produk**: **APPROVED & VERIFIED (Production-Built Ready UKK 2026)**
