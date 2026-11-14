import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// An error from the Cabo API, with a message that can be shown to the user.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fields = const {},
    this.data,
  });

  final String message;

  /// HTTP status, or null when the request never reached the server.
  final int? statusCode;

  /// Validation errors by field name, from a 422 response.
  final Map<String, String> fields;

  /// The decoded response body, when there was one.
  final Map<String, dynamic>? data;

  bool get isOffline => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// JSON client for the Cabo backend. Adds the sign-in token to every request
/// and turns error responses into [ApiException]s.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? kApiBaseUrl;

  final http.Client _http;
  final String baseUrl;

  /// Bearer token for the signed-in user, or null when signed out.
  String? token;

  /// Called when the server rejects the token, so the app can sign out.
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 25);

  /// Site root, used to resolve image paths such as /images/places/x.jpg.
  String get origin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final clean = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: clean.isEmpty ? null : clean);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(
    () =>
        _http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})),
  );

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => _send(
    () =>
        _http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})),
  );

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) => _send(
    () => _http.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    ),
  );

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers));

  /// Uploads one file with extra form fields (multipart/form-data).
  Future<dynamic> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        })
        ..fields.addAll(fields)
        ..files.add(
          http.MultipartFile.fromBytes(field, bytes, filename: filename),
        );
      return http.Response.fromStream(await _http.send(request));
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        'Cabo is taking too long to respond. Check your connection and try again.',
      );
    } on SocketException {
      throw ApiException(
        'No internet connection. Check your connection and try again.',
      );
    } on http.ClientException {
      throw ApiException(
        'Could not reach Cabo. Check your connection and try again.',
      );
    }

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        body = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    final map = body is Map<String, dynamic> ? body : null;
    final fields = <String, String>{};
    final errors = map?['errors'];
    if (errors is Map) {
      for (final e in errors.entries) {
        final v = e.value;
        fields['${e.key}'] = v is List && v.isNotEmpty ? '${v.first}' : '$v';
      }
    }
    final message = switch (response.statusCode) {
      401 => 'Your session has ended. Please sign in again.',
      429 => 'Too many attempts. Wait a minute and try again.',
      >= 500 => 'Something went wrong at Cabo. Please try again in a moment.',
      _ =>
        (map?['message'] as String?) ??
            'Something went wrong. Please try again.',
    };
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(
      // A 422 with one field error reads better as that field's message.
      response.statusCode == 422 && fields.length == 1
          ? fields.values.first
          : message,
      statusCode: response.statusCode,
      fields: fields,
      data: map,
    );
  }
}

/// Convenience readers for decoded JSON objects.
typedef Json = Map<String, dynamic>;

extension JsonRead on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    return v == null ? fallback : '$v';
  }

  String? strOrNull(String key) {
    final v = this[key];
    return v == null || '$v'.isEmpty ? null : '$v';
  }

  int integer(String key, [int fallback = 0]) {
    final v = this[key];
    if (v is num) return v.round();
    return int.tryParse('$v') ?? double.tryParse('$v')?.round() ?? fallback;
  }

  double number(String key, [double fallback = 0]) {
    final v = this[key];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  double? numberOrNull(String key) {
    final v = this[key];
    if (v is num) return v.toDouble();
    return v == null ? null : double.tryParse('$v');
  }

  bool flag(String key) =>
      this[key] == true || this[key] == 1 || this[key] == '1';

  Json? obj(String key) {
    final v = this[key];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  List<Json> list(String key) => asJsonList(this[key]);

  List<String> strings(String key) {
    final v = this[key];
    return v is List ? [for (final x in v) '$x'] : const [];
  }

  DateTime? date(String key) {
    final v = this[key];
    return v == null ? null : DateTime.tryParse('$v')?.toLocal();
  }
}

List<Json> asJsonList(dynamic value) => value is List
    ? [
        for (final x in value)
          if (x is Map) Map<String, dynamic>.from(x),
      ]
    : const [];

/// Unwraps `{data: ...}` responses. Paginated lists also keep their rows in `data`.
dynamic unwrap(dynamic body) =>
    body is Map && body.containsKey('data') ? body['data'] : body;
