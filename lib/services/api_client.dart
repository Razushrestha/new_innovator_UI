import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import 'auth_session.dart';

/// Shared HTTP helper with Bearer auth + ApiEnvelope parsing.
///
/// Use [ApiClient.shared] everywhere so keep-alive sockets are reused.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Process-wide client — one connection pool for all services.
  static final ApiClient shared = ApiClient();

  final http.Client _client;

  Future<ApiEnvelope<T>> get<T>(
    String baseUrl,
    String path, {
    Map<String, String>? query,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return _send(
      'GET',
      baseUrl,
      path,
      query: query,
      parse: parse,
      auth: auth,
    );
  }

  Future<ApiEnvelope<T>> post<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return _send(
      'POST',
      baseUrl,
      path,
      body: body,
      parse: parse,
      auth: auth,
    );
  }

  Future<ApiEnvelope<T>> put<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return _send(
      'PUT',
      baseUrl,
      path,
      body: body,
      parse: parse,
      auth: auth,
    );
  }

  Future<ApiEnvelope<T>> patch<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return _send(
      'PATCH',
      baseUrl,
      path,
      body: body,
      parse: parse,
      auth: auth,
    );
  }

  Future<ApiEnvelope<T>> delete<T>(
    String baseUrl,
    String path, {
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return _send(
      'DELETE',
      baseUrl,
      path,
      parse: parse,
      auth: auth,
    );
  }

  /// Multipart upload (e.g. avatar `file` field).
  Future<ApiEnvelope<T>> multipart<T>(
    String baseUrl,
    String path, {
    required String fileField,
    required Uint8List bytes,
    required String filename,
    String method = 'POST',
    Map<String, String>? fields,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) {
    return multipartForm(
      baseUrl,
      path,
      method: method,
      fields: fields,
      files: [
        http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
      ],
      parse: parse,
      auth: auth,
    );
  }

  /// Multipart with arbitrary fields + files (create post / reel).
  Future<ApiEnvelope<T>> multipartForm<T>(
    String baseUrl,
    String path, {
    String method = 'POST',
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest(method, uri);
    if (auth && AuthSession.instance.isSignedIn) {
      request.headers['Authorization'] =
          AuthSession.instance.authorizationHeader;
    }
    request.headers['Accept'] = 'application/json';
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    late http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(ApiConfig.connectTimeout);
      response = await http.Response.fromStream(streamed)
          .timeout(ApiConfig.connectTimeout);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    return _parseResponse(response, parse);
  }

  Future<ApiEnvelope<T>> _send<T>(
    String method,
    String baseUrl,
    String path, {
    Object? body,
    Map<String, String>? query,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Connection': 'keep-alive',
      if (body != null) 'Content-Type': 'application/json',
      if (auth && AuthSession.instance.isSignedIn)
        'Authorization': AuthSession.instance.authorizationHeader,
    };

    late http.Response response;
    try {
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(ApiConfig.connectTimeout);
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.connectTimeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.connectTimeout);
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.connectTimeout);
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(ApiConfig.connectTimeout);
        default:
          throw ApiException('Unsupported method $method');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    return _parseResponse(response, parse);
  }

  ApiEnvelope<T> _parseResponse<T>(
    http.Response response,
    T Function(Object? raw)? parse,
  ) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiEnvelope<T>(success: true, data: null);
      }
      throw ApiException(
        'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Invalid server response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    // Some search endpoints return a bare JSON array (not ApiEnvelope).
    if (decoded is List) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Request failed (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      final data = parse == null ? decoded as T : parse(decoded);
      return ApiEnvelope<T>(success: true, data: data);
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected response shape');
    }

    final envelope = ApiEnvelope<T>.fromJson(decoded, parse);
    if (!envelope.success ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        envelope.message ??
            envelope.errors?.join('\n') ??
            'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
        errors: envelope.errors,
      );
    }
    return envelope;
  }
}
