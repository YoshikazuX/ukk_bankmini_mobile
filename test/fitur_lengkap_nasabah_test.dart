import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';
import 'package:ukk_bankmini/models/badge_model.dart';
import 'package:ukk_bankmini/models/nasabah_model.dart';
import 'package:ukk_bankmini/models/notifikasi_model.dart';
import 'package:ukk_bankmini/models/saving_goal_model.dart';
import 'package:ukk_bankmini/models/session_model.dart';
import 'package:ukk_bankmini/services/nasabah_api_service.dart';
import 'test_api_mock_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.init();
    TestApiMockInterceptor.install();
  });

  group('Penyempurnaan Modul Nasabah: Saving Goals, Badges, Sessions & Freeze', () {
    test('SavingGoalModel calculates progress and handles edge cases', () {
      final goalZero = SavingGoalModel(
        id: '1',
        nama: 'Laptop SMK',
        targetAmount: 0,
        currentAmount: 0,
      );
      expect(goalZero.progressPercent, equals(0.0));
      expect(goalZero.remaining, equals(0.0));

      final goalActive = SavingGoalModel(
        id: '2',
        nama: 'Buku Akuntansi',
        targetAmount: 200000,
        currentAmount: 150000,
      );
      expect(goalActive.progressPercent, equals(75.0));
      expect(goalActive.remaining, equals(50000.0));
      expect(goalActive.isCompleted, isFalse);

      final json = goalActive.toJson();
      final fromJson = SavingGoalModel.fromJson(json);
      expect(fromJson.nama, equals('Buku Akuntansi'));
      expect(fromJson.targetAmount, equals(200000.0));
    });

    test('BadgeModel evaluates tiers and unlocked criteria', () {
      final goldBadge = BadgeModel(
        id: 'badge_6',
        nama: 'Duta Literasi',
        deskripsi: 'Saldo Rp 5.000.000 dan aktif menabung',
        icon: 'diamond',
        tier: 'gold',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 10, 31),
      );

      expect(goldBadge.tier, equals('gold'));
      expect(goldBadge.isUnlocked, isTrue);

      final json = goldBadge.toJson();
      final fromJson = BadgeModel.fromJson(json);
      expect(fromJson.nama, equals('Duta Literasi'));
      expect(fromJson.isUnlocked, isTrue);
    });

    test('SessionModel handles Sanctum token metadata correctly', () {
      final json = {
        'id': '10',
        'device_name': 'Infinix Note 40 (Official App)',
        'device_type': 'android',
        'ip_address': '192.168.1.45',
        'location': 'SMK N 1 Bantul',
        'last_access': '2026-10-31T08:00:00Z',
        'is_current': true,
      };

      final session = SessionModel.fromJson(json);
      expect(session.deviceName, contains('Infinix'));
      expect(session.deviceType, equals('android'));
      expect(session.isCurrentSession, isTrue);
    });

    test('NotifikasiModel parses transaction alerts and unread state', () {
      final json = {
        'id': 'notif_101',
        'title': 'Setoran Berhasil',
        'message': 'Setoran tunai Rp 50.000 di loket teller berhasil disahkan.',
        'jenis': 'SETORAN',
        'created_at': '2026-10-31T09:00:00Z',
        'is_read': false,
      };

      final notif = NotifikasiModel.fromJson(json);
      expect(notif.title, equals('Setoran Berhasil'));
      expect(notif.jenis, equals('SETORAN'));
      expect(notif.isRead, isFalse);

      notif.isRead = true;
      expect(notif.isRead, isTrue);
    });

    test('NasabahModel status blocked correctly reflects NONAKTIF status', () {
      final nasabahActive = NasabahModel(
        id: '1',
        noRekening: '202601001',
        nis: '17763',
        namaLengkap: 'Handa',
        kelas: 'XII AKL 1',
        jurusan: 'Akuntansi',
        totalSaldo: 50000,
        status: 'AKTIF',
      );
      expect(nasabahActive.isBlocked, isFalse);
      expect(nasabahActive.isActive, isTrue);

      final nasabahFrozen = nasabahActive.copyWith(status: 'NONAKTIF');
      expect(nasabahFrozen.isBlocked, isTrue);
      expect(nasabahFrozen.isActive, isFalse);
    });
  });
}

