import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helper.dart';

/// Widget que maneja los diferentes estados: loading, error, empty y content
class StateBuilder extends StatelessWidget {
  /// Si true, muestra loading indicator
  final bool isLoading;

  /// Si true, muestra estado vacío
  final bool isEmpty;

  /// Mensaje de error (si es null, no muestra error)
  final String? errorMessage;

  /// Icono a mostrar en estado vacío o error
  final IconData icon;

  /// Título en estado vacío o error
  final String emptyTitle;

  /// Descripción en estado vacío o error
  final String emptyDescription;

  /// Callback para reintentar en caso de error
  final VoidCallback? onRetry;

  /// Widget a mostrar cuando hay contenido
  final Widget child;

  /// Indica si es un estado de error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  const StateBuilder({
    super.key,
    required this.child,
    this.isLoading = false,
    this.isEmpty = false,
    this.errorMessage,
    required this.icon,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor),
                ),
              ),
          ],
        ),
      );
    }

    // Empty state
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ThemeHelper.getBorderColor(context)),
            const SizedBox(height: 12),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              emptyDescription,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
      );
    }

    // Content state
    return child;
  }
}
