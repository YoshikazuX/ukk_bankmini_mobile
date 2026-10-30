import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk_bankmini/main.dart';
import 'package:ukk_bankmini/services/dummy_data_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test('DummyDataService authenticates admin-created Laravel accounts', () {
    // 1. Unregistered account fails
    final failResult =
        DummyDataService.authenticate('unknown_user', 'any_password');
    expect(failResult.success, isFalse);
    expect(failResult.message, contains('tidak ditemukan'));

    // 2. Wrong password fails
    final wrongPw =
        DummyDataService.authenticate('Handa', 'wrong_pass');
    expect(wrongPw.success, isFalse);
    expect(wrongPw.message, contains('salah'));

    // 3. Official Laravel admin account (Handa / password123) succeeds
    final successResult =
        DummyDataService.authenticate('Handa', 'password123');
    expect(successResult.success, isTrue);
    expect(successResult.nasabah?.namaLengkap,
        equals('Dewi Handayani Nur Halimah'));
    expect(successResult.nasabah?.nis, equals('17763'));
    expect(successResult.nasabah?.noRekening, equals('202601001'));
    expect(successResult.nasabah?.pinKeamanan, equals('240808'));
    expect(successResult.nasabah?.totalSaldo, equals(50000));
  });

  test('New account has 1 initial deposit and locked advancement badges', () {
    final trans = DummyDataService.getTransaksiList();
    expect(trans.length, equals(1));
    expect(trans.first.jenis, equals('SETORAN'));
    expect(trans.first.jumlah, equals(50000));

    final badges = DummyDataService.getBadges();
    final unlocked = badges.where((b) => b.isUnlocked).toList();
    final locked = badges.where((b) => !b.isUnlocked).toList();

    // Only First Deposit is unlocked for new account, rest are locked
    expect(unlocked.length, equals(1));
    expect(unlocked.first.nama, equals('First Deposit'));
    expect(locked.length, equals(5));
  });

  testWidgets('LkmBankMiniApp renders LoginScreen correctly',
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
    // Verifikasi bahwa panel demo dan pilihan role sudah dieliminasi
    expect(find.text('Akun Resmi Admin (Laravel):'), findsNothing);
    expect(find.text('Nasabah / Siswa'), findsNothing);
    expect(find.text('Petugas / Staff'), findsNothing);
  });
}
