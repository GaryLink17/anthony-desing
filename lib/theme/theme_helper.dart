import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Helper para acceder a colores dinámicos según el tema actual
class ThemeHelper {
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBgColor
        : AppTheme.bgColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : Colors.white;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextLight
        : AppTheme.textDark;
  }

  static Color getTextMediumColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textMedium;
  }

  static Color getTextLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textLight;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBorderColor
        : Colors.black.withOpacity(0.20);
  }

  static Color getHintColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMedium
        : AppTheme.textLighter;
  }

  static TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: getTextColor(context),
    );
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    return TextStyle(fontSize: 13, color: getTextLightColor(context));
  }

  static TextStyle getSectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
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
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : AppTheme.altRowLight;
  }

  static Color getInteractiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.accentMagenta
        : AppTheme.primaryBlue;
  }

  static Color getSelectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D1828)
        : AppTheme.selectedLight;
  }

  static Color getUnselectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF333333)
        : AppTheme.bgLight2;
  }

  static Color getInputBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF333333)
        : Colors.white;
  }

  static Color getHoverColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
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
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6DD880)
        : AppTheme.successMedium;
  }

  static Color getErrorTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF7070)
        : AppTheme.errorDark;
  }

  static Color getWarningTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFC04D)
        : AppTheme.warningDark;
  }

  static Color getSuccessLightBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E3E1A)
        : AppTheme.successLight;
  }

  static Color getErrorLightBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A2020)
        : AppTheme.errorLight;
  }

  static Color getWarningLightBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF483320)
        : AppTheme.warningLight;
  }

  static Color getInfoLightBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E3E5A)
        : AppTheme.infoLight;
  }

  static BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: getBorderColor(context), width: 0.5),
    );
  }

  static BoxDecoration getInputDecoration(BuildContext context) {
    return BoxDecoration(
      color: getInputBgColor(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: getBorderColor(context), width: 0.5),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getBorderColor(context), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getBorderColor(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}
