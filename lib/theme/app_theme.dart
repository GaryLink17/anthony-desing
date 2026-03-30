import 'package:flutter/material.dart';

/// Clase centralizada para manejo de temas de la aplicación
/// Facilita cambios de tema y reutilización de estilos
class AppTheme {
  // ---- COLORES PRINCIPALES ----
  static const Color primaryBlue = Color(0xFF1B3A6B);
  static const Color accentMagenta = Color(0xFFE8147A);
  static const Color accentOrange = Color(0xFFF5A623);
  static const Color bgColor = Color(0xFFF5F4F0);

  // ---- COLORES SECUNDARIOS (fondos claros) ----
  static const Color lightBlue = Color(0xFFE6EEF8);
  static const Color lightMagenta = Color(0xFFFDE8F2);
  static const Color lightOrange = Color(0xFFFEF3E2);

  // ---- COLORES ESTADOS ----
  static const Color successColor = Color(0xFF0F6E56);
  static const Color errorColor = Color(0xFFE24B4A);
  static const Color warningColor = Color(0xFFEF9F27);
  static const Color infoColor = Color(0xFF1B3A6B);

  // ---- COLORES GRISES ----
  static const Color textDark = Color(0xFF2C2C2A);
  static const Color textMedium = Color(0xFF444441);
  static const Color textLight = Color(0xFF888780);
  static const Color textLighter = Color(0xFFB4B2A9);
  static const Color borderColor = Color(0x33000000);

  // ---- COLORES ADICIONALES (LIGHT MODE) ----
  static const Color bgLight1 = Color(0xFFF0EEE8);
  static const Color bgLight2 = Color(0xFFF8F7F4);
  static const Color bgLight3 = Color(0xFFFAFAF8);
  static const Color bgLight4 = Color(0xFFF1EFE8);
  static const Color selectedLight = Color(0xFFE1F5EE);
  static const Color altRowLight = Color(0xFFFAFAF8);

  // ---- COLORES ESTADOS (VARIANTES) ----
  static const Color successDark = Color(0xFF27500A);
  static const Color successMedium = Color(0xFF3B6D11);
  static const Color successLight = Color(0xFFEAF3DE);
  static const Color errorDark = Color(0xFFA32D2D);
  static const Color errorMedium = Color(0xFFE24B4A);
  static const Color errorLight = Color(0xFFFCEBEB);
  static const Color warningDark = Color(0xFFBA7517);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color infoLight = Color(0xFFE6F1FB);

  /// Genera el tema claro de la aplicación
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentMagenta,
        tertiary: accentOrange,
        surface: Colors.white,
        error: errorColor,
      ),
      // Tema de cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      // Tema de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentMagenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Tema de botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMedium,
          side: const BorderSide(color: textLighter),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Tema de date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        headerBackgroundColor: primaryBlue,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontSize: 13),
        yearStyle: const TextStyle(fontSize: 13),
        surfaceTintColor: Colors.transparent,
        cancelButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(primaryBlue),
        ),
        confirmButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(primaryBlue),
        ),
      ),
      // Tema de textos
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMedium,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textMedium,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textLight,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textLighter, fontSize: 13),
        labelStyle: const TextStyle(color: textMedium, fontSize: 13),
      ),
    );
  }

  // ---- COLORES OSCUROS ----
  static const Color darkBgColor = Color(0xFF1A1A1A);
  static const Color darkCardColor = Color(0xFF2A2A2A);
  static const Color darkTextLight = Color(0xFFE0E0E0);
  static const Color darkTextMedium = Color(0xFFC0C0C0);
  static const Color darkBorderColor = Color(0xFF404040);

  /// Genera el tema oscuro de la aplicación
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentMagenta,
        tertiary: accentOrange,
        surface: darkCardColor,
        error: errorColor,
      ),
      // Tema de cards
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorderColor, width: 0.5),
        ),
      ),
      // Tema de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentMagenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Tema de botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextMedium,
          side: const BorderSide(color: darkBorderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Tema de date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        headerBackgroundColor: primaryBlue,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontSize: 13, color: darkTextLight),
        yearStyle: const TextStyle(fontSize: 13, color: darkTextLight),
        surfaceTintColor: Colors.transparent,
        cancelButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(accentMagenta),
        ),
        confirmButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(accentMagenta),
        ),
      ),
      // Tema de textos
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextLight,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextLight,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextMedium,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkTextMedium,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextMedium,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkTextMedium,
        ),
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF333333),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentMagenta, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextMedium, fontSize: 13),
        labelStyle: const TextStyle(color: darkTextMedium, fontSize: 13),
      ),
    );
  }
}

/// Extensión para acceso fácil a los colores del tema desde BuildContext
extension ThemeColors on BuildContext {
  /// Obtiene el color primario
  Color get primaryBlue => AppTheme.primaryBlue;

  /// Obtiene el color de acento magenta
  Color get accentMagenta => AppTheme.accentMagenta;

  /// Obtiene el color de acento naranja
  Color get accentOrange => AppTheme.accentOrange;

  /// Obtiene el color de fondo dinámico según el tema
  Color get bgColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkBgColor
        : AppTheme.bgColor;
  }

  /// Obtiene el color de tarjeta dinámico según el tema
  Color get cardColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : Colors.white;
  }

  /// Obtiene el color de texto dinámico según el tema
  Color get textDark {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextLight
        : AppTheme.textDark;
  }

  /// Obtiene el color de texto medio dinámico según el tema
  Color get textMedium {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textMedium;
  }

  /// Obtiene el color de texto claro dinámico según el tema
  Color get textLight {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textLight;
  }

  /// Obtiene el color de borde dinámico según el tema
  Color get borderColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkBorderColor
        : AppTheme.borderColor;
  }

  Color get successColor => AppTheme.successColor;
  Color get errorColor => AppTheme.errorColor;
}
