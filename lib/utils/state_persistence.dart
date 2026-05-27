import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves de SharedPreferences usadas en la aplicación.
class StorageKeys {
  static const lastRoute = 'last_route';
}

/// Singleton para persistir y restaurar estado de la aplicación
/// usando SharedPreferences. Soporta tipos básicos, JSON y datos con expiración.
class StatePersistence {
  static final StatePersistence _instance = StatePersistence._internal();
  late SharedPreferences _prefs;

  factory StatePersistence() {
    return _instance;
  }

  StatePersistence._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- OPERACIONES BÁSICAS ----

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  String? getString(String key, {String? defaultValue}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key, {List<String>? defaultValue}) {
    return _prefs.getStringList(key) ?? defaultValue ?? [];
  }

  // ---- OPERACIONES AVANZADAS ----

  /// Guarda un objeto serializado como JSON.
  Future<bool> setObject(String key, dynamic object) {
    final jsonString = jsonEncode(object);
    return _prefs.setString(key, jsonString);
  }

  /// Recupera un objeto desde JSON almacenado.
  dynamic getObject(String key, {dynamic defaultValue}) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return defaultValue;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Guarda una lista de objetos serializada como JSON.
  Future<bool> setObjectList(String key, List<dynamic> objects) {
    final jsonString = jsonEncode(objects);
    return _prefs.setString(key, jsonString);
  }

  /// Recupera una lista de objetos desde JSON.
  List<dynamic> getObjectList(String key, {List<dynamic>? defaultValue}) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return defaultValue ?? [];
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      return defaultValue ?? [];
    }
  }

  // ---- GESTIÓN DE CACHÉ ----

  /// Guarda datos con fecha de expiración (en segundos desde ahora).
  Future<bool> setWithExpiry(
    String key,
    dynamic value,
    int expirySeconds,
  ) async {
    final expiry = DateTime.now().add(Duration(seconds: expirySeconds));
    final data = {'value': value, 'expiry': expiry.toIso8601String()};
    return setObject(key, data);
  }

  /// Recupera datos validando expiración. Si expiró, elimina la clave.
  dynamic getWithExpiry(String key, {dynamic defaultValue}) {
    final data = getObject(key);
    if (data == null) return defaultValue;

    try {
      final expiry = DateTime.parse(data['expiry'] as String);
      if (DateTime.now().isAfter(expiry)) {
        remove(key);
        return defaultValue;
      }
      return data['value'];
    } catch (e) {
      return defaultValue;
    }
  }

  // ---- UTILIDADES ----

  bool contains(String key) {
    return _prefs.containsKey(key);
  }

  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  Future<bool> clear() {
    return _prefs.clear();
  }

  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  Set<String> getKeysMatching(RegExp pattern) {
    return _prefs.getKeys().where((key) => pattern.hasMatch(key)).toSet();
  }

  Future<void> removeMatching(RegExp pattern) async {
    final keys = getKeysMatching(pattern);
    for (final key in keys) {
      await remove(key);
    }
  }
}
