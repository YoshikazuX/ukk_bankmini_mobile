import 'package:dio/dio.dart';
import '../storage/session_storage.dart';

/// Interceptor otomatis untuk injeksi header Bearer Token & deteksi sesi kedaluwarsa
class AuthInterceptor extends Interceptor {
  final void Function()? onSessionExpired;

  AuthInterceptor({this.onSessionExpired});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Standarisasi header request
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    // 2. Injeksi Bearer Token jika tersimpan di sesi
    final token = await SessionStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Tangani HTTP 401 Unauthorized (Token dicabut atau kedaluwarsa)
    if (err.response?.statusCode == 401) {
      await SessionStorage.clearSession();
      if (onSessionExpired != null) {
        onSessionExpired!();
      }
    }

    return handler.next(err);
  }
}

