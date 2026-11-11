import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination.dart';

/// PHP REST API client. Override the default URL at build time when deploying:
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/bohol_api/api/index.php
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/tourist_guide_bohol_api/api/index.php',
  );

  Uri _uri(String resource, [Map<String, String>? extra]) {
    return Uri.parse(baseUrl).replace(
      queryParameters: {'resource': resource, ...?extra},
    );
  }

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message']?.toString() ?? 'Request failed (${response.statusCode}).');
    }
    return decoded;
  }

  Future<List<Destination>> fetchDestinations() async {
    final response = await _client.get(_uri('destinations'), headers: _headers())
        .timeout(const Duration(seconds: 8));
    final decoded = _decodeObject(response);
    final rows = decoded['data'];
    if (rows is! List) return <Destination>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Destination.fromJson)
        .toList();
  }

  Future<void> register(String fullName, String email, String password) async {
    final response = await _client.post(
      _uri('auth', {'action': 'register'}),
      headers: _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 8));
    _decodeObject(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      _uri('auth', {'action': 'login'}),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 8));
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> currentUser(String token) async {
    final response = await _client.get(
      _uri('auth', {'action': 'me'}),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 8));
    return _decodeObject(response);
  }

  Future<void> logout(String token) async {
    final response = await _client.post(
      _uri('auth', {'action': 'logout'}),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 8));
    _decodeObject(response);
  }

  Future<void> saveDestination(
    Destination destination, {
    required String token,
    required bool isUpdate,
  }) async {
    final uri = _uri('destinations', isUpdate ? {'id': destination.id} : null);
    final response = isUpdate
        ? await _client.put(uri, headers: _headers(token: token), body: jsonEncode(destination.toJson()))
        : await _client.post(uri, headers: _headers(token: token), body: jsonEncode(destination.toJson()));
    _decodeObject(response);
  }

  Future<void> deleteDestination(String id, {required String token}) async {
    final response = await _client.delete(
      _uri('destinations', {'id': id}),
      headers: _headers(token: token),
    );
    _decodeObject(response);
  }

  Future<void> recordActivity({
    required String token,
    required String eventType,
    required String description,
    String? entityType,
    String? entityId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await _client.post(
      _uri('activity'),
      headers: _headers(token: token),
      body: jsonEncode({
        'eventType': eventType,
        'description': description,
        if (entityType != null) 'entityType': entityType,
        if (entityId != null) 'entityId': entityId,
        'metadata': metadata,
      }),
    ).timeout(const Duration(seconds: 8));
    _decodeObject(response);
  }

  Future<Map<String, dynamic>> adminOverview({required String token}) async {
    final response = await _client.get(
      _uri('admin', {'action': 'overview'}),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> adminUsers({
    required String token,
    int page = 1,
    int limit = 25,
    String query = '',
  }) async {
    final response = await _client.get(
      _uri('admin', {
        'action': 'users',
        'page': '$page',
        'limit': '$limit',
        if (query.trim().isNotEmpty) 'q': query.trim(),
      }),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> adminActivities({
    required String token,
    int page = 1,
    int limit = 25,
    String query = '',
  }) async {
    final response = await _client.get(
      _uri('admin', {
        'action': 'activities',
        'page': '$page',
        'limit': '$limit',
        if (query.trim().isNotEmpty) 'q': query.trim(),
      }),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
    return _decodeObject(response);
  }

  void close() => _client.close();
}
