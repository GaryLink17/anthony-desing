import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Utilidad para persistir y restaurar estado de la aplicación
class StatePersistence {
  static final StatePersistence _instance = StatePersistence._internal();
  late SharedPreferences _prefs;

  factory StatePersistence() {
    return _instance;
  }

  StatePersistence._internal();

  /// Inicializa el sistema de persistencia
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- OPERACIONES BÁSICAS ----

  /// Guarda un valor de String
  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  /// Obtiene un valor de String
  String? getString(String key, {String? defaultValue}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  /// Guarda un valor boolean
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  /// Obtiene un valor boolean
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// Guarda un valor integer
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  /// Obtiene un valor integer
  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  /// Guarda un valor double
  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  /// Obtiene un valor double
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  /// Guarda una lista de String
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  /// Obtiene una lista de String
  List<String> getStringList(String key, {List<String>? defaultValue}) {
    return _prefs.getStringList(key) ?? defaultValue ?? [];
  }

  // ---- OPERACIONES AVANZADAS ----

  /// Guarda un objeto como JSON
  Future<bool> setObject(String key, dynamic object) {
    final jsonString = jsonEncode(object);
    return _prefs.setString(key, jsonString);
  }

  /// Obtiene un objeto desde JSON
  dynamic getObject(String key, {dynamic defaultValue}) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return defaultValue;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Guarda una lista de objetos como JSON
  Future<bool> setObjectList(String key, List<dynamic> objects) {
    final jsonString = jsonEncode(objects);
    return _prefs.setString(key, jsonString);
  }

  /// Obtiene una lista de objetos desde JSON
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

  /// Guarda datos con expiración automática (en segundos)
  Future<bool> setWithExpiry(
    String key,
    dynamic value,
    int expirySeconds,
  ) async {
    final expiry = DateTime.now().add(Duration(seconds: expirySeconds));
    final data = {'value': value, 'expiry': expiry.toIso8601String()};
    return setObject(key, data);
  }

  /// Obtiene datos con validación de expiración
  dynamic getWithExpiry(String key, {dynamic defaultValue}) {
    final data = getObject(key);
    if (data == null) return defaultValue;

    try {
      final expiry = DateTime.parse(data['expiry'] as String);
      if (DateTime.now().isAfter(expiry)) {
        // Datos expirados, eliminar
        remove(key);
        return defaultValue;
      }
      return data['value'];
    } catch (e) {
      return defaultValue;
    }
  }

  // ---- UTILIDADES ----

  /// Verifica si una clave existe
  bool contains(String key) {
    return _prefs.containsKey(key);
  }

  /// Elimina una clave
  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  /// Elimina todas las claves
  Future<bool> clear() {
    return _prefs.clear();
  }

  /// Obtiene todas las claves
  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  /// Obtiene todas las claves que coinciden con un patrón
  Set<String> getKeysMatching(RegExp pattern) {
    return _prefs.getKeys().where((key) => pattern.hasMatch(key)).toSet();
  }

  /// Elimina todas las claves que coinciden con un patrón
  Future<void> removeMatching(RegExp pattern) async {
    final keys = getKeysMatching(pattern);
    for (final key in keys) {
      await remove(key);
    }
  }
}
