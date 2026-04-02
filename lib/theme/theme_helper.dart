import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Helper para acceder a colores dinámicos según el tema actual
class ThemeHelper {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackgroundColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkBgColor : AppTheme.bgColor;
  }

  static Color getCardColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkCardColor : Colors.white;
  }

  static Color getSidebarColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkSidebarColor : AppTheme.sidebarLight;
  }

  static Color getTextColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkTextLight : AppTheme.textDark;
  }

  static Color getTextMediumColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkTextMedium : AppTheme.textMedium;
  }

  static Color getTextLightColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkTextMedium : AppTheme.textLight;
  }

  static Color getBorderColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkBorderColor : AppTheme.borderColor;
  }

  static Color getHintColor(BuildContext context) {
    return _isDark(context) ? AppTheme.darkTextMedium : AppTheme.textLighter;
  }

  static TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: getTextColor(context),
      letterSpacing: -0.3,
    );
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    return TextStyle(fontSize: 13, color: getTextLightColor(context));
  }

  static TextStyle getSectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: getTextColor(context),
    );
  }

  static TextStyle getBodyLargeStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: getTextMediumColor(context),
    );
  }

  static TextStyle getBodyMediumStyle(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: getTextMediumColor(context),
    );
  }

  static TextStyle getBodySmallStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: getTextLightColor(context),
    );
  }

  static TextStyle getLabelSmallStyle(BuildContext context) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: getTextLightColor(context),
    );
  }

  static Color getAltRowColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2A2A2A)
        : AppTheme.altRowLight;
  }

  static Color getInteractiveColor(BuildContext context) {
    return _isDark(context) ? AppTheme.accentMagenta : AppTheme.primaryBlue;
  }

  static Color getSelectedColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF37373D)
        : AppTheme.selectedLight;
  }

  static Color getUnselectedColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2D2D2D)
        : AppTheme.bgLight2;
  }

  static Color getInputBgColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF9FAFB);
  }

  static Color getHoverColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2A2A2A)
        : AppTheme.bgLight1;
  }

  static Color getSuccessColor(BuildContext context, {required bool isDark}) {
    if (isDark) return AppTheme.successDark;
    return AppTheme.successMedium;
  }

  static Color getErrorColor(BuildContext context, {required bool isDark}) {
    if (isDark) return AppTheme.errorDark;
    return AppTheme.errorMedium;
  }

  static Color getWarningColor(BuildContext context, {required bool isDark}) {
    if (isDark) return AppTheme.warningDark;
    return AppTheme.warningColor;
  }

  static Color getSuccessTextColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF6DD880)
        : AppTheme.successMedium;
  }

  static Color getErrorTextColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFFFF7070)
        : AppTheme.errorDark;
  }

  static Color getWarningTextColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFFFFC04D)
        : AppTheme.warningDark;
  }

  static Color getSuccessLightBg(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF1E3320)
        : AppTheme.successLight;
  }

  static Color getErrorLightBg(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF3A2020)
        : AppTheme.errorLight;
  }

  static Color getWarningLightBg(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF352A1A)
        : AppTheme.warningLight;
  }

  static Color getInfoLightBg(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF1E2530)
        : AppTheme.infoLight;
  }

  /// Decoración de card moderna: sombra sutil en claro, superficie plana en oscuro
  static BoxDecoration getCardDecoration(BuildContext context) {
    if (_isDark(context)) {
      return BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12),
      );
    }
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration getInputDecoration(BuildContext context) {
    return BoxDecoration(
      color: getInputBgColor(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: getBorderColor(context)),
    );
  }

  static InputDecoration getFormFieldDecoration(
    BuildContext context, {
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: getHintColor(context)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: getInputBgColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}
