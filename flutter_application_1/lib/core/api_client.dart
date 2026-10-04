import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) => _send('GET', path, query: query, token: token);

  Future<dynamic> post(String path, {Object? body, String? token}) =>
      _send('POST', path, body: body, token: token);

  Future<dynamic> patch(String path, {Object? body, String? token}) =>
      _send('PATCH', path, body: body, token: token);

  Future<dynamic> delete(String path, {String? token}) =>
      _send('DELETE', path, token: token);

  Future<dynamic> postMultipart(
    String path, {
    required String field,
    required String filePath,
    required String filename,
    String? token,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.apiBaseUrl}$path');
    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..files.add(
          await http.MultipartFile.fromPath(
            field,
            filePath,
            filename: filename,
          ),
        );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final http.StreamedResponse streamed = await _http
          .send(request)
          .timeout(timeout);
      return _decode(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? token,
  }) async {
    var uri = Uri.parse('${ApiConfig.apiBaseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final http.Response response = switch (method) {
        'GET' => await _http.get(uri, headers: headers).timeout(timeout),
        'POST' =>
          await _http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout),
        'PATCH' =>
          await _http
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout),
        'DELETE' => await _http.delete(uri, headers: headers).timeout(timeout),
        _ => throw ArgumentError.value(method, 'method'),
      };
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  dynamic _decode(http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _errorMessage(bodyText));
    }
    if (bodyText.trim().isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        if (decoded.isEmpty) return null;
        if (decoded.containsKey('data')) return decoded['data'];
      }
      return decoded;
    } on FormatException {
      throw const NetworkException('Respuesta inesperada del servidor');
    }
  }

  String _errorMessage(String bodyText) {
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      return 'Error inesperado del servidor';
    }
    return 'Error inesperado del servidor';
  }
}
