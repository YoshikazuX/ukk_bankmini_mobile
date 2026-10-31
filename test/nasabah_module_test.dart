import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';
import 'package:ukk_bankmini/models/nasabah_model.dart';
import 'package:ukk_bankmini/models/transaksi_model.dart';
import 'package:ukk_bankmini/services/nasabah_api_service.dart';
import 'test_api_mock_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.init();
    await SessionStorage.clearSession();
    TestApiMockInterceptor.install();
  });

  group('Tahap 4: Modul Nasabah & Live API Service Tests', () {
    test('TransaksiModel parses Laravel JSON response format correctly', () {
      final laravelJson = {
        'id': 101,
        'nasabah_id': 1,
        'jenis_transaksi': 'transfer_masuk',
        'nominal': 75000,
        'keterangan': 'Transfer dari Siti Rahmawati (Uang Kas)',
        'nama_petugas': null,
        'created_at': '2026-10-30T10:00:00.000000Z',
        'no_rekening': '202601001',
        'nama_siswa': 'Handa',
      };

      final trx = TransaksiModel.fromJson(laravelJson);

      expect(trx.id, equals('101'));
      expect(trx.noRekening, equals('202601001'));
      expect(trx.jumlah, equals(75000.0));
      expect(trx.isSetoran, isTrue);
      expect(trx.isTransferMasuk, isTrue);
      expect(trx.displayBadge, equals('TRANSFER MASUK'));
      expect(trx.keterangan, contains('Siti Rahmawati'));
    });

    test('TransaksiModel correctly detects debit/outgoing transfer', () {
      final laravelJson = {
        'id': 102,
        'jenis_transaksi': 'transfer_keluar',
        'nominal': 25000,
        'keterangan': 'Transfer ke Budi Santoso',
        'created_at': '2026-10-30T11:00:00.000000Z',
        'no_rekening': '202601001',
      };

      final trx = TransaksiModel.fromJson(laravelJson);

      expect(trx.isPenarikan, isTrue);
      expect(trx.isTransferKeluar, isTrue);
      expect(trx.displayBadge, equals('TRANSFER KELUAR'));
      expect(trx.jumlah, equals(25000.0));
    });

    test('NasabahModel correctly computes saldo efektif with minimum mengendap', () {
      final nasabah = NasabahModel(
        id: '1',
        namaLengkap: 'Handa Test',
        nis: '10293847',
        noRekening: '202601001',
        kelas: 'XII RPL 1',
        jurusan: 'Rekayasa Perangkat Lunak',
        totalSaldo: 60000,
        status: 'Aktif',
      );

      expect(nasabah.saldoMengendap, equals(10000.0));
      expect(nasabah.saldoEfektif, equals(50000.0));
      expect(nasabah.canWithdraw(50000.0), isTrue);
      expect(nasabah.canWithdraw(50001.0), isFalse);
    });

    test('Fitur transfer antar siswa dinonaktifkan secara aman', () async {
      final res = await NasabahApiService.transfer(
        noRekeningTujuan: '202601002',
        nominal: 20000,
        pin: '240808',
      );
      expect(res.success, isFalse);
      expect(res.message, contains('dinonaktifkan'));
    });

    test('PIN verification validates 6-digit requirements and authentication', () async {
      // Kurang dari 6 digit
      final shortPin = await NasabahApiService.verifyPin('123');
      expect(shortPin.success, isFalse);

      // PIN resmi Laravel Handa
      final validPin = await NasabahApiService.verifyPin('240808');
      expect(validPin.success, isTrue);

      // PIN salah
      final wrongPin = await NasabahApiService.verifyPin('999999');
      expect(wrongPin.success, isFalse);
    });
  });
}
