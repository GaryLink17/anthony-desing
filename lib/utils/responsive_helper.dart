import 'package:flutter/material.dart';

/// Helper para cálculos y valores responsive
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Obtiene el tipo de pantalla basado en el ancho
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

  /// Obtiene el padding responsive basado en el tamaño de pantalla
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

  /// Obtiene el padding horizontal responsive
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

  /// Obtiene el padding vertical responsive
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

  /// Obtiene el tamaño de fuente responsive
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

  /// Calcula cuantas columnas debería tener un layout responsive
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

  /// Obtiene el ancho máximo para contenido en una pantalla
  static double getMaxContentWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return double.infinity; // Sin límite en móvil
      case ScreenType.tablet:
        return 800;
      case ScreenType.desktop:
        return 1200;
    }
  }
}

/// Tipos de pantalla para design responsivo
enum ScreenType { mobile, tablet, desktop }

/// Extensión para acceso fácil a ResponsiveHelper
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
