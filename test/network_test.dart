import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukk_bankmini/core/constants/api_constants.dart';
import 'package:ukk_bankmini/core/network/api_client.dart';
import 'package:ukk_bankmini/core/network/api_response.dart';
import 'package:ukk_bankmini/core/storage/session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tahap 2: Network & Storage Core Tests', () {
    test('ApiConstants provides valid default and endpoint paths', () {
      expect(ApiConstants.defaultBaseUrl, contains(':8000/api'));
      expect(ApiConstants.nasabahLogin, equals('/nasabah/login'));
      expect(ApiConstants.petugasLogin, equals('/petugas/login'));
      expect(ApiConstants.tellerSetor, equals('/petugas/transaksi/setor'));
      expect(ApiConstants.supervisorPengajuanKas, equals('/supervisor/pengajuan-kas'));
    });

    test('ApiResponse parses successful Laravel response format', () {
      final json = {
        'success': true,
        'message': 'Login Berhasil',
        'token': '1|example_token',
        'data': {
          'id': 1,
          'nama': 'Dewi',
        },
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
        statusCode: 200,
      );

      expect(response.success, isTrue);
      expect(response.message, equals('Login Berhasil'));
      expect(response.data?['nama'], equals('Dewi'));
      expect(response.statusCode, equals(200));
    });

    test('ApiResponse parses error Laravel response format', () {
      final json = {
        'success': false,
        'message': 'Kredensial tidak valid!',
      };

      final response = ApiResponse<dynamic>.fromJson(json, null, statusCode: 401);
      expect(response.success, isFalse);
      expect(response.message, equals('Kredensial tidak valid!'));
      expect(response.statusCode, equals(401));
    });

    test('SessionStorage saves, retrieves, and clears token and role', () async {
      expect(await SessionStorage.hasToken(), isFalse);

      await SessionStorage.saveToken('test_token_123');
      expect(await SessionStorage.getToken(), equals('test_token_123'));
      expect(await SessionStorage.hasToken(), isTrue);

      await SessionStorage.saveRole('teller');
      expect(await SessionStorage.getRole(), equals('teller'));

      await SessionStorage.saveUserData({'nama': 'Teller 1', 'role': 'teller'});
      final userData = await SessionStorage.getUserData();
      expect(userData?['nama'], equals('Teller 1'));

      await SessionStorage.clearSession();
      expect(await SessionStorage.getToken(), isNull);
      expect(await SessionStorage.getRole(), isNull);
      expect(await SessionStorage.getUserData(), isNull);
      expect(await SessionStorage.hasToken(), isFalse);
    });

    test('SessionStorage allows custom Base URL configuration', () async {
      expect(await SessionStorage.getBaseUrl(), equals(ApiConstants.defaultBaseUrl));

      await SessionStorage.saveBaseUrl('http://192.168.1.100:8000/api');
      expect(await SessionStorage.getBaseUrl(), equals('http://192.168.1.100:8000/api'));

      await SessionStorage.resetBaseUrl();
      expect(await SessionStorage.getBaseUrl(), equals(ApiConstants.defaultBaseUrl));
    });

    test('ApiClient singleton initializes with correct options and interceptors', () {
      final client = ApiClient.instance;
      expect(client.dio.options.connectTimeout, equals(const Duration(seconds: 12)));
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(2));
    });
  });
}

