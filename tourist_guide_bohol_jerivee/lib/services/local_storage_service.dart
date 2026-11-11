import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';

/// Stores small user preferences in browser storage on Flutter Web.
/// For a production offline catalogue, move full records to IndexedDB.
class LocalStorageService {
  LocalStorageService(this._preferences);

  final SharedPreferences _preferences;

  static Future<LocalStorageService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStorageService(preferences);
  }

  Set<String> readSet(String key) =>
      (_preferences.getStringList(key) ?? <String>[]).toSet();

  String? readString(String key) => _preferences.getString(key);

  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  Future<void> remove(String key) => _preferences.remove(key);

  Future<void> writeSet(String key, Set<String> values) =>
      _preferences.setStringList(key, values.toList());

  List<Destination> readCustomDestinations() {
    final raw = _preferences.getString('custom_destinations');
    if (raw == null || raw.isEmpty) return <Destination>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Destination.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Destination>[];
    }
  }

  Future<void> writeCustomDestinations(List<Destination> destinations) {
    final raw = jsonEncode(destinations.map((item) => item.toJson()).toList());
    return _preferences.setString('custom_destinations', raw);
  }
}
