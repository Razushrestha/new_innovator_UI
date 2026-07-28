class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final List<String>? errors;

  @override
  String toString() => message;
}

class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  final bool success;
  final String? message;
  final T? data;
  final List<String>? errors;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw)? parseData,
  ) {
    final rawErrors = json['errors'];
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: json['message'] as String?,
      data: parseData == null ? json['data'] as T? : parseData(json['data']),
      errors: rawErrors is List
          ? rawErrors.map((e) => e.toString()).toList()
          : null,
    );
  }
}
