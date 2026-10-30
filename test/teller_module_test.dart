import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';
import 'package:ukk_bankmini/services/teller_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.init();
  });

  group('Tahap 5: Modul Teller POS & Operasional Loket Tests', () {
    test('searchNasabah returns matching student profiles', () async {
      final res = await TellerApiService.searchNasabah(query: 'Handa');

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!.isNotEmpty, isTrue);
      expect(res.data!.first['nama_siswa'], contains('Handa'));
      expect(res.data!.first['no_rekening'], equals('202601001'));
    });

    test('getDetailNasabah calculates saldo dapat ditarik with Rp 10.000 minimum', () async {
      final res = await TellerApiService.getDetailNasabah('202601001');

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!['no_rekening'], equals('202601001'));
      expect(res.data!['saldo_mengendap_min'], equals(10000.0));
      expect(res.data!['saldo_dapat_ditarik'], isNotNull);
    });

    test('setorTunai validates minimum amount and produces valid receipt 101', () async {
      // Under minimum Rp 1.000
      final minRes = await TellerApiService.setorTunai(
        noRekening: '202601001',
        nominal: 500,
      );
      expect(minRes.success, isFalse);

      // Valid setoran Rp 50.000
      final validRes = await TellerApiService.setorTunai(
        noRekening: '202601001',
        nominal: 50000,
        keterangan: 'Setoran tabungan wajib',
      );
      expect(validRes.success, isTrue);
      expect(validRes.data?['kode_sandi'], equals('101'));
      expect(validRes.data?['nominal'], equals(50000.0));
    });

    test('tarikTunai validates PIN, drawer cash, and produces valid receipt 201', () async {
      // Under minimum
      final minRes = await TellerApiService.tarikTunai(
        noRekening: '202601001',
        nominal: 500,
        pin: '240808',
      );
      expect(minRes.success, isFalse);

      // Wrong PIN
      final wrongPinRes = await TellerApiService.tarikTunai(
        noRekening: '202601001',
        nominal: 20000,
        pin: '999999',
      );
      expect(wrongPinRes.success, isFalse);

      // Valid penarikan Rp 20.000
      final validRes = await TellerApiService.tarikTunai(
        noRekening: '202601001',
        nominal: 20000,
        pin: '240808',
      );
      expect(validRes.success, isTrue);
      expect(validRes.data?['kode_sandi'], equals('201'));
      expect(validRes.data?['nominal'], equals(20000.0));
    });

    test('getStatusKas returns drawer physical cash details', () async {
      final res = await TellerApiService.getStatusKas();

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!['saldo_awal'], isNotNull);
      expect(res.data!['kas_tersedia'], isNotNull);
    });

    test('kirimPengajuanKas validates minimum nominal and reason', () async {
      // Below min Rp 10.000
      final minRes = await TellerApiService.kirimPengajuanKas(
        nominal: 5000,
        alasan: 'Tambahan kas',
      );
      expect(minRes.success, isFalse);

      // Empty reason
      final emptyReason = await TellerApiService.kirimPengajuanKas(
        nominal: 500000,
        alasan: '',
      );
      expect(emptyReason.success, isFalse);

      // Valid ticket
      final validTicket = await TellerApiService.kirimPengajuanKas(
        nominal: 1000000,
        alasan: 'Antrean penarikan siswa tinggi di loket 1',
      );
      expect(validTicket.success, isTrue);
      expect(validTicket.data?['nominal'], equals(1000000.0));
      expect(validTicket.data?['status'], equals('pending'));
    });

    test('submitDailyReport records closing and calculates physical difference', () async {
      final res = await TellerApiService.submitDailyReport(
        physicalBalance: 2250000,
        notes: 'Semua transaksi klop dan terverifikasi',
      );

      expect(res.success, isTrue);
      expect(res.data?['physical_balance'], equals(2250000.0));
      expect(res.data?['difference'], equals(0.0));
    });
  });
}

