import 'package:flutter/material.dart';

/// Enum para los tipos de notificación
enum NotificationType { success, error, warning, info }

/// Clase para configurar una notificación
class NotificationConfig {
  final String message;
  final NotificationType type;
  final Duration duration;
  final bool dismissible;
  final VoidCallback? onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NotificationConfig({
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.dismissible = true,
    this.onDismissed,
    this.actionLabel,
    this.onAction,
  });
}

/// Servicio global para mostrar notificaciones
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  ScaffoldMessengerState? _scaffoldMessenger;

  /// Establece la referencia a ScaffoldMessenger
  void setScaffoldMessenger(ScaffoldMessengerState scaffoldMessenger) {
    _scaffoldMessenger = scaffoldMessenger;
  }

  /// Obtiene el color según el tipo de notificación
  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF0F6E56);
      case NotificationType.error:
        return const Color(0xFFE24B4A);
      case NotificationType.warning:
        return const Color(0xFFEF9F27);
      case NotificationType.info:
        return const Color(0xFF1B3A6B);
    }
  }

  /// Obtiene el icono según el tipo de notificación
  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  /// Muestra una notificación
  void show(NotificationConfig config) {
    if (_scaffoldMessenger == null) return;

    final color = _getColor(config.type);
    final icon = _getIcon(config.type);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      duration: config.duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: config.actionLabel != null
          ? SnackBarAction(
              label: config.actionLabel!,
              textColor: Colors.white,
              onPressed: () {
                config.onAction?.call();
                _scaffoldMessenger?.hideCurrentSnackBar();
              },
            )
          : null,
      onVisible: () {
        // Notificación mostrada
      },
    );

    _scaffoldMessenger?.showSnackBar(snackBar);
  }

  /// Muestra notificación de éxito
  void success(
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      NotificationConfig(
        message: message,
        type: NotificationType.success,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Muestra notificación de error
  void error(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      NotificationConfig(
        message: message,
        type: NotificationType.error,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Muestra notificación de advertencia
  void warning(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      NotificationConfig(
        message: message,
        type: NotificationType.warning,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Muestra notificación de información
  void info(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      NotificationConfig(
        message: message,
        type: NotificationType.info,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Oculta la notificación actual
  void dismiss() {
    _scaffoldMessenger?.hideCurrentSnackBar();
  }
}
