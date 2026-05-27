import 'package:flutter/material.dart';

/// Helper para diseño responsive con breakpoints mobile/tablet/desktop.
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Determina el tipo de pantalla según el ancho del viewport.
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(20);
      case ScreenType.desktop:
        return const EdgeInsets.all(28);
    }
  }

  static double getResponsivePaddingHorizontal(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 16;
      case ScreenType.tablet:
        return 20;
      case ScreenType.desktop:
        return 28;
    }
  }

  static double getResponsivePaddingVertical(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 16;
      case ScreenType.tablet:
        return 20;
      case ScreenType.desktop:
        return 28;
    }
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  static int getResponsiveColumns(
    BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobileColumns;
      case ScreenType.tablet:
        return tabletColumns;
      case ScreenType.desktop:
        return desktopColumns;
    }
  }

  static double getMaxContentWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return double.infinity;
      case ScreenType.tablet:
        return 800;
      case ScreenType.desktop:
        return 1200;
    }
  }
}

/// Tipos de pantalla para diseño responsive.
enum ScreenType { mobile, tablet, desktop }

/// Extensiones de BuildContext para acceso directo a helpers responsive.
extension ResponsiveContext on BuildContext {
  ScreenType get screenType => ResponsiveHelper.getScreenType(this);
  EdgeInsets get responsivePadding =>
      ResponsiveHelper.getResponsivePadding(this);
  double get responsivePaddingHorizontal =>
      ResponsiveHelper.getResponsivePaddingHorizontal(this);
  double get responsivePaddingVertical =>
      ResponsiveHelper.getResponsivePaddingVertical(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
}
