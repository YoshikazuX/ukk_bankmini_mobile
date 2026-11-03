import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';
import 'package:ukk_bankmini/main.dart';
import 'package:ukk_bankmini/models/badge_model.dart';
import 'package:ukk_bankmini/models/nasabah_model.dart';
import 'package:ukk_bankmini/models/saving_goal_model.dart';
import 'package:ukk_bankmini/models/session_model.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'app_onboarding_completed': true,
    });
  });

  group('Domain Model Fixtures & Calculations Test', () {
    test('NasabahModel calculates saldo efektif and status correctly', () {
      final nasabah = NasabahModel(
        id: '1',
        noRekening: '202601001',
        nis: '17763',
        namaLengkap: 'Dewi Handayani Nur Halimah',
        kelas: 'XII AKL 1',
        jurusan: 'Akuntansi & Keuangan Lembaga',
        totalSaldo: 50000,
        status: 'AKTIF',
        saldoMengendap: 10000,
      );

      expect(nasabah.saldoTersedia, equals(40000));
      expect(nasabah.isBlocked, isFalse);
      expect(nasabah.isActive, isTrue);
      expect(nasabah.qrisPayload, contains('202601001'));
    });

    test('SavingGoalModel calculates progress percentage and remaining correctly', () {
      final goal = SavingGoalModel(
        id: '1',
        nama: 'Laptop SMK',
        targetAmount: 5000000,
        currentAmount: 2500000,
      );

      expect(goal.progressPercent, equals(50.0));
      expect(goal.remaining, equals(2500000));
      expect(goal.isCompleted, isFalse);
    });

    test('BadgeModel serializes and evaluates unlocked status', () {
      final badge = BadgeModel(
        id: 'badge_1',
        nama: 'First Deposit',
        deskripsi: 'Berhasil melakukan setoran awal tabungan',
        icon: 'savings',
        tier: 'bronze',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 10, 26),
      );

      expect(badge.isUnlocked, isTrue);
      expect(badge.tier, equals('bronze'));
      final json = badge.toJson();
      expect(json['is_unlocked'], isTrue);
    });

    test('SessionModel maps correctly from JSON fixture', () {
      final json = {
        'id': 'sess_123',
        'device_name': 'Chrome Web Browser',
        'device_type': 'web',
        'ip_address': '127.0.0.1',
        'location': 'SMK N 1 Bantul',
        'last_access': '2026-10-31T12:00:00Z',
        'is_current': true,
      };

      final session = SessionModel.fromJson(json);
      expect(session.id, equals('sess_123'));
      expect(session.deviceName, equals('Chrome Web Browser'));
      expect(session.isCurrentSession, isTrue);
    });
  });

  testWidgets('LkmBankMiniApp renders LoginScreen with institutional UI',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const LkmBankMiniApp());
    await tester.pumpAndSettle();

    expect(find.text('LKM Mitra Siswa Abadi'), findsWidgets);
    expect(find.text('Masuk ke Dashboard'), findsWidgets);
    expect(find.text('Username / NIS / No. Rekening'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);

    // Verifikasi bahwa panel demo dan pilihan role manual telah dieliminasi
    expect(find.text('Akun Resmi Admin (Laravel):'), findsNothing);
    expect(find.text('Nasabah / Siswa'), findsNothing);
    expect(find.text('Petugas / Staff'), findsNothing);
  });

  testWidgets('SplashScreen renders institutional branding and SMK N 1 Bantul identity',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const LkmBankMiniApp());
    // Pump first frame before splash delay completes
    await tester.pump();

    expect(find.text('LKM Mitra Siswa Abadi'), findsOneWidget);
    expect(find.text('Sistem Informasi Bank Mini Sekolah'), findsOneWidget);
    expect(find.text('SMK NEGERI 1 BANTUL'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Settle splash screen transition to LoginScreen
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Dashboard'), findsOneWidget);
  });

  testWidgets(
      'OnboardingScreen renders slides, handles navigation, and completes to LoginScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const LkmBankMiniApp(initialRoute: '/onboarding'));
    await tester.pumpAndSettle();

    // Verifikasi Slide 1
    expect(find.text('PERBANKAN SISWA TERPADU'), findsOneWidget);
    expect(find.text('Tabungan Sekolah Aman & Transparan'), findsOneWidget);
    expect(find.text('Buku mutasi transaksi otomatis & tercatat'), findsOneWidget);
    expect(find.text('Lewati'), findsWidgets);
    expect(find.text('Lanjut'), findsOneWidget);

    // Ketuk tombol Lanjut untuk pindah ke Slide 2
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Verifikasi Slide 2
    expect(find.text('KARTU DIGITAL & KEAMANAN'), findsOneWidget);
    expect(find.text('Identitas Kartu Digital & PIN Otorisasi'), findsOneWidget);
    expect(find.text('PIN 6-digit untuk persetujuan penarikan loket'), findsOneWidget);

    // Ketuk tombol Lanjut untuk pindah ke Slide 3
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Verifikasi Slide 3
    expect(find.text('LITERASI FINANSIAL & PRESTASI'), findsOneWidget);
    expect(find.text('Rencanakan Impian dengan Saving Goals'), findsOneWidget);
    expect(find.text('Mulai Sekarang — Masuk ke Akun'), findsOneWidget);

    // Selesaikan onboarding
    await tester.tap(find.text('Mulai Sekarang — Masuk ke Akun'));
    await tester.pumpAndSettle();

    // Verifikasi telah berhasil berpindah ke LoginScreen
    expect(find.text('Masuk ke Dashboard'), findsOneWidget);
    expect(await SessionStorage.isOnboardingCompleted(), isTrue);
  });
}
