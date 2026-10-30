import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/session_storage.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';

/// Singleton Client HTTP (Dio) terintegrasi untuk seluruh pemanggilan REST API
class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Pasang interceptor autentikasi Sanctum
    _dio.interceptors.add(AuthInterceptor());

    // Pasang interceptor logging ringkas untuk mode debug
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Dapatkan instance tunggal ApiClient
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Akses instance Dio mentah jika diperlukan
  Dio get dio => _dio;

  /// Perbarui Base URL aktif (misal saat pengguna mengubah setting IP)
  Future<void> updateBaseUrl() async {
    final activeBaseUrl = await SessionStorage.getBaseUrl();
    _dio.options.baseUrl = activeBaseUrl;
  }

  // =========================================================================
  // HELPER METHOD HTTP REQUEST
  // =========================================================================

  /// HTTP GET Request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    await updateBaseUrl();

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// HTTP POST Request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    await updateBaseUrl();

    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// HTTP PUT Request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    await updateBaseUrl();

    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// HTTP DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    await updateBaseUrl();

    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  // =========================================================================
  // PARSER RESPON & PENANGAN ERROR
  // =========================================================================

  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    if (response.data is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<T>(
      success: response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300,
      message: 'Sukses (${response.statusCode})',
      data: response.data as T?,
      statusCode: response.statusCode,
    );
  }

  ApiResponse<T> _handleDioError<T>(DioException e) {
    String errorMessage = 'Koneksi ke server gagal. Harap periksa jaringan Anda.';
    int? statusCode = e.response?.statusCode;
    dynamic errors;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Waktu koneksi habis (Timeout). Pastikan server backend sedang aktif.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Tidak dapat terhubung ke server Laravel (${_dio.options.baseUrl}). Pastikan `php artisan serve` aktif.';
    } else if (e.response != null) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        errorMessage = body['message']?.toString() ??
            body['error']?.toString() ??
            'Error dari server: HTTP $statusCode';
        errors = body['errors'];
      } else {
        errorMessage = 'Terjadi kesalahan pada server (HTTP $statusCode)';
      }
    }

    return ApiResponse<T>.error(
      message: errorMessage,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

