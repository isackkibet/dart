import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/app_failure.dart';
import '../models/result.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  final String baseUrl;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;

  Future<Result<Map<String, dynamic>>> getJson(String path) async {
    return _sendJson(method: 'GET', path: path);
  }

  Future<Result<Map<String, dynamic>>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJson(method: 'POST', path: path, body: body);
  }

  Future<Result<Map<String, dynamic>>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJson(method: 'PATCH', path: path, body: body);
  }

  Future<Result<Map<String, dynamic>>> deleteJson(String path) async {
    return _sendJson(method: 'DELETE', path: path);
  }

  Future<Result<Map<String, dynamic>>> _sendJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final token = await _tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Success(decoded);
      }
      return Failure(
        AppFailure(
          message: decoded['message']?.toString() ?? 'Request failed.',
          code: decoded['code']?.toString() ?? response.statusCode.toString(),
          details: decoded,
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Network request failed.',
          code: 'network_error',
          details: error,
        ),
      );
    }
  }
}
