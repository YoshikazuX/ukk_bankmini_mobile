/// Standard API Response Wrapper untuk konsistensi respon Laravel
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final dynamic errors;
  final dynamic raw;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.errors,
    this.raw,
  });

  /// Factory untuk parsing JSON dari response Laravel
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData)? fromJsonT, {
    int? statusCode,
  }) {
    final success = json['success'] == true ||
        json['status'] == 'healthy' ||
        json['status'] == 'operational' ||
        (statusCode != null && statusCode >= 200 && statusCode < 300);

    final message = json['message']?.toString() ??
        (json['status'] != null ? 'Status: ${json['status']}' : '');

    dynamic rawData = json['data'];
    // Jika tidak ada key 'data', periksa jika json itu sendiri adalah payload (misal healthcheck / root)
    if (rawData == null && json.containsKey('status') && !json.containsKey('data')) {
      rawData = json;
    }

    T? parsedData;
    if (rawData != null && fromJsonT != null) {
      try {
        parsedData = fromJsonT(rawData);
      } catch (e) {
        parsedData = null;
      }
    } else if (rawData != null && T == dynamic) {
      parsedData = rawData as T;
    }

    return ApiResponse<T>(
      success: success,
      message: message,
      data: parsedData,
      statusCode: statusCode,
      errors: json['errors'],
      raw: json,
    );
  }

  /// Factory untuk error kustom
  factory ApiResponse.error({
    String message = 'Terjadi kesalahan sistem',
    T? data,
    int? statusCode,
    dynamic errors,
    dynamic raw,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: data,
      statusCode: statusCode,
      errors: errors,
      raw: raw,
    );
  }

  /// Factory untuk sukses instan
  factory ApiResponse.success({
    String message = '',
    T? data,
    int? statusCode = 200,
    dynamic raw,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
      raw: raw,
    );
  }
}
