import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que maneja el estado del tema (claro/oscuro) con persistencia
/// en SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  SharedPreferences? _prefs;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _initialized;

  /// Inicializa el provider y carga la preferencia guardada
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs!.getBool('isDarkMode') ?? false;
    _initialized = true;
    notifyListeners();
  }

  /// Alterna entre modo claro y oscuro
  Future<void> toggleTheme() async {
    if (!_initialized) return;
    _isDarkMode = !_isDarkMode;
    await _prefs!.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Establece el modo explícitamente
  Future<void> setDarkMode(bool isDark) async {
    if (!_initialized) return;
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs!.setBool('isDarkMode', isDark);
      notifyListeners();
    }
  }
}
