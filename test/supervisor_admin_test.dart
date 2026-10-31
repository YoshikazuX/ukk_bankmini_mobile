import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';
import 'package:ukk_bankmini/models/petugas_model.dart';
import 'package:ukk_bankmini/screens/admin/admin_main_screen.dart';
import 'package:ukk_bankmini/screens/supervisor/supervisor_main_screen.dart';
import 'package:ukk_bankmini/services/supervisor_api_service.dart';
import 'test_api_mock_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.init();
    TestApiMockInterceptor.install();
  });

  group('Tahap 6: Modul Supervisor & Admin Tests', () {
    test('SupervisorApiService.listPengajuanKas returns valid ticket list and filters properly', () async {
      // Fetch all
      final allRes = await SupervisorApiService.listPengajuanKas();
      expect(allRes.success, isTrue);
      expect(allRes.data, isNotNull);
      expect(allRes.data!.isNotEmpty, isTrue);

      final first = allRes.data!.first;
      expect(first['nomor_pengajuan'], isNotNull);
      expect(first['nominal'], isNotNull);
      expect(first['status'], isNotNull);

      // Fetch pending filter
      final pendingRes = await SupervisorApiService.listPengajuanKas(status: 'pending');
      expect(pendingRes.success, isTrue);
      expect(pendingRes.data, isNotNull);
      for (final item in pendingRes.data!) {
        expect(item['status'], equals('pending'));
      }
    });

    test('SupervisorApiService.setujuiPengajuanKas changes status to disetujui', () async {
      final res = await SupervisorApiService.setujuiPengajuanKas(
        1,
        catatan: 'Disetujui untuk modal loket',
      );

      expect(res.success, isTrue);
      expect(res.data?['status'], equals('disetujui'));
      expect(res.message, contains('berhasil disetujui'));
    });

    test('SupervisorApiService.tolakPengajuanKas changes status to ditolak', () async {
      final res = await SupervisorApiService.tolakPengajuanKas(
        1,
        catatan: 'Kas loket masih mencukupi',
      );

      expect(res.success, isTrue);
      expect(res.data?['status'], equals('ditolak'));
      expect(res.message, contains('ditolak'));
    });

    test('SupervisorApiService.listDailyReport returns daily closing reports and filters properly', () async {
      final res = await SupervisorApiService.listDailyReport();
      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!.isNotEmpty, isTrue);

      final report = res.data!.first;
      expect(report['nama_teller'], isNotNull);
      expect(report['system_balance'], isNotNull);
      expect(report['physical_balance'], isNotNull);
      expect(report['difference'], equals(0.0));
    });

    test('SupervisorApiService.updateStatusDailyReport updates report status correctly', () async {
      final approvedRes = await SupervisorApiService.updateStatusDailyReport(
        1,
        status: 'approved',
        notes: 'Laporan fisik terverifikasi',
      );
      expect(approvedRes.success, isTrue);
      expect(approvedRes.data?['status'], equals('approved'));

      final rejectedRes = await SupervisorApiService.updateStatusDailyReport(
        1,
        status: 'rejected',
        notes: 'Selisih belum diselesaikan',
      );
      expect(rejectedRes.success, isTrue);
      expect(rejectedRes.data?['status'], equals('rejected'));
    });

    test('SupervisorApiService.getRingkasanHarian returns complete operational metrics', () async {
      final res = await SupervisorApiService.getRingkasanHarian();

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data?['nasabah']?['total_nasabah_aktif'], isNotNull);
      expect(res.data?['nasabah']?['total_dana_tabungan'], isNotNull);
      expect(res.data?['kas_operasional']?['kas_fisik_tersedia'], isNotNull);
      expect(res.data?['transaksi_hari_ini']?['frekuensi_transaksi'], isNotNull);
    });

    test('SupervisorApiService.getSaldoPerKelas returns student savings breakdown', () async {
      final res = await SupervisorApiService.getSaldoPerKelas();

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!.isNotEmpty, isTrue);

      final first = res.data!.first;
      expect(first['kelas'], isNotNull);
      expect(first['total_siswa'], isNotNull);
      expect(first['total_saldo'], isNotNull);
    });

    test('SupervisorApiService.getMutasiJurnal returns double-entry general ledger', () async {
      final res = await SupervisorApiService.getMutasiJurnal();

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data?['summary']?['total_debit'], isNotNull);
      expect(res.data?['summary']?['total_kredit'], isNotNull);

      final entries = res.data?['data'] as List?;
      expect(entries, isNotNull);
      expect(entries!.isNotEmpty, isTrue);
    });

    testWidgets('SupervisorMainScreen renders executive dashboard and navigation items', (tester) async {
      final spv = PetugasModel(
        id: 2,
        username: 'spv1',
        namaPetugas: 'Drs. Hendro Wibowo',
        role: 'supervisor',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SupervisorMainScreen(petugas: spv),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Supervisor Identity Header
      expect(find.text('SUPERVISOR'), findsOneWidget);
      expect(find.text('Drs. Hendro Wibowo'), findsOneWidget);

      // Verify Bottom Navigation items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Approval Kas'), findsOneWidget);
      expect(find.text('Review Daily'), findsOneWidget);
      expect(find.text('Buku Jurnal'), findsOneWidget);

      // Verify Dashboard Sections
      expect(find.text('PORTAL OTORISASI SUPERVISOR'), findsOneWidget);
      expect(find.text('Total Dana Tabungan'), findsOneWidget);
      expect(find.text('Kas Fisik Tersedia'), findsOneWidget);
      expect(find.text('Distribusi Simpanan Per Kelas'), findsOneWidget);
    });

    testWidgets('AdminMainScreen renders system health and RBAC directory', (tester) async {
      final admin = PetugasModel(
        id: 1,
        username: 'admin',
        namaPetugas: 'Super Administrator',
        role: 'admin',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminMainScreen(petugas: admin),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Admin Header
      expect(find.text('ADMINISTRATOR'), findsWidgets);
      expect(find.text('Super Administrator'), findsOneWidget);

      // Verify RBAC Directory for all 4 roles
      expect(find.text('Arsitektur Role-Based Access Control (RBAC)'), findsOneWidget);
      expect(find.text('Kredensial: admin / admin123'), findsOneWidget);
      expect(find.text('Kredensial: spv1 / spv123'), findsOneWidget);
      expect(find.text('Kredensial: teller1 / teller123'), findsOneWidget);
      expect(find.text('Kredensial: Handa / password123'), findsOneWidget);

      // Verify System Specifications
      expect(find.text('Spesifikasi Mesin & Environment'), findsOneWidget);
      expect(find.text('Laravel 13 (PHP 8.2+)'), findsOneWidget);
      expect(find.text('MySQL / MariaDB (db_bankmini)'), findsOneWidget);
      expect(find.text('mobile_scanner v7.4.2 (Native Barcode)'), findsOneWidget);
    });
  });
}
