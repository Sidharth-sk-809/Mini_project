import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_service.dart';

class ApiClient {
  ApiClient._();

  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const Duration _timeout = Duration(seconds: 10);

  static String get _baseUrl {
    if (_definedBaseUrl.trim().isNotEmpty) {
      return _definedBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  static Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth && (SessionService.token ?? '').isNotEmpty) {
      headers['Authorization'] = 'Bearer ${SessionService.token}';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    Map<String, dynamic>? query,
  }) async {
    final response = await http
        .get(_uri(path, query), headers: _headers(auth: auth))
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<List<dynamic>> getList(
    String path, {
    bool auth = false,
    Map<String, dynamic>? query,
  }) async {
    final response = await http
        .get(_uri(path, query), headers: _headers(auth: auth))
        .timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(body));
    }
    if (body is List<dynamic>) {
      return body;
    }
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .post(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .put(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(_extractError(body));
    }
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw Exception('Unexpected response format');
  }

  static String _extractError(dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String) {
        return detail;
      }
    }
    return 'Request failed';
  }
}
