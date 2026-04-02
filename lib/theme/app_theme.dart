import 'package:flutter/material.dart';

/// Clase centralizada para manejo de temas de la aplicación
class AppTheme {
  // ---- COLORES PRINCIPALES ----
  static const Color primaryBlue = Color(0xFF1B3A6B);
  static const Color accentMagenta = Color(0xFFB83268);
  static const Color accentOrange = Color(0xFFD4881A);
  static const Color bgColor = Color(0xFFF5F7FA);

  // ---- COLORES SECUNDARIOS (fondos claros) ----
  static const Color lightBlue = Color(0xFFE6EEF8);
  static const Color lightMagenta = Color(0xFFF5E0EA);
  static const Color lightOrange = Color(0xFFF5E8D0);

  // ---- COLORES ESTADOS ----
  static const Color successColor = Color(0xFF0F6E56);
  static const Color errorColor = Color(0xFFE24B4A);
  static const Color warningColor = Color(0xFFEF9F27);
  static const Color infoColor = Color(0xFF1B3A6B);

  // ---- COLORES GRISES ----
  static const Color textDark = Color(0xFF111827);
  static const Color textMedium = Color(0xFF374151);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textLighter = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);

  // ---- SIDEBAR CLARO ----
  static const Color sidebarLight = Color(0xFFFFFFFF);
  static const Color sidebarBorderLight = Color(0xFFE5E7EB);

  // ---- COLORES ADICIONALES (LIGHT MODE) ----
  static const Color bgLight1 = Color(0xFFEEF2F7);
  static const Color bgLight2 = Color(0xFFF9FAFB);
  static const Color bgLight3 = Color(0xFFFAFAFB);
  static const Color bgLight4 = Color(0xFFEEF2F7);
  static const Color selectedLight = Color(0xFFEBF5FF);
  static const Color altRowLight = Color(0xFFF9FAFB);

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
      // Tema de cards — sin borde, sombra sutil
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Tema de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentMagenta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Tema de botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMedium,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Tema de date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.2,
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
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textLighter, fontSize: 13),
        labelStyle: const TextStyle(color: textLight, fontSize: 13),
      ),
    );
  }

  // ---- COLORES OSCUROS (estilo VS Code) ----
  static const Color darkBgColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF252526);
  static const Color darkSidebarColor = Color(0xFF252526);
  static const Color darkBorderColor = Color(0xFF3E3E42);
  static const Color darkTextLight = Color(0xFFD4D4D4);
  static const Color darkTextMedium = Color(0xFF9D9D9D);

  /// Genera el tema oscuro de la aplicación
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgColor,
      colorScheme: const ColorScheme.dark(
        primary: accentMagenta,
        secondary: accentMagenta,
        tertiary: accentOrange,
        surface: darkCardColor,
        error: errorColor,
      ),
      // Tema de cards — sin borde, sombra sutil
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Tema de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentMagenta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Tema de botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextMedium,
          side: const BorderSide(color: darkBorderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Tema de date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextLight,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextLight,
          letterSpacing: -0.2,
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
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
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
  Color get primaryBlue => AppTheme.primaryBlue;
  Color get accentMagenta => AppTheme.accentMagenta;
  Color get accentOrange => AppTheme.accentOrange;

  Color get bgColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkBgColor
        : AppTheme.bgColor;
  }

  Color get cardColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : Colors.white;
  }

  Color get textDark {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextLight
        : AppTheme.textDark;
  }

  Color get textMedium {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textMedium;
  }

  Color get textLight {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textLight;
  }

  Color get borderColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkBorderColor
        : AppTheme.borderColor;
  }

  Color get successColor => AppTheme.successColor;
  Color get errorColor => AppTheme.errorColor;
}
