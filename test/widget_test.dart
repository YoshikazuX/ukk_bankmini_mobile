import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk_bankmini/main.dart';
import 'package:ukk_bankmini/models/badge_model.dart';
import 'package:ukk_bankmini/models/nasabah_model.dart';
import 'package:ukk_bankmini/models/saving_goal_model.dart';
import 'package:ukk_bankmini/models/session_model.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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
}
