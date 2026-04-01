import 'dart:async';
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

  OverlayState? _overlayState;
  final List<_NotificationItem> _active = [];
  static const int _maxVisible = 3;

  /// Establece la referencia al OverlayState
  void setOverlayState(OverlayState overlayState) {
    _overlayState = overlayState;
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

  void _removeItem(_NotificationItem item) {
    item.timer.cancel();
    try {
      item.entry.remove();
    } catch (_) {}
    _active.remove(item);
    for (final r in _active) {
      r.entry.markNeedsBuild();
    }
    item.config.onDismissed?.call();
  }

  /// Muestra una notificación
  void show(NotificationConfig config) {
    if (_overlayState == null) return;

    if (_active.length >= _maxVisible) _removeItem(_active.first);

    final color = _getColor(config.type);
    final icon = _getIcon(config.type);
    late _NotificationItem item;

    final entry = OverlayEntry(builder: (_) {
      final index = _active.indexOf(item);
      const toastHeight = 64.0;
      const gap = 8.0;
      final bottomOffset = 24.0 + (index < 0 ? 0 : index) * (toastHeight + gap);
      return Positioned(
        right: 24,
        bottom: bottomOffset,
        width: 340,
        child: _ToastWidget(
          config: config,
          color: color,
          icon: icon,
          onDismiss: () => _removeItem(item),
        ),
      );
    });

    final timer = Timer(config.duration, () => _removeItem(item));
    item = _NotificationItem(entry: entry, timer: timer, config: config);
    _active.add(item);
    _overlayState!.insert(entry);
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

  /// Oculta todas las notificaciones activas
  void dismiss() {
    for (final item in List.of(_active)) {
      _removeItem(item);
    }
  }
}

class _NotificationItem {
  final OverlayEntry entry;
  final Timer timer;
  final NotificationConfig config;

  _NotificationItem({
    required this.entry,
    required this.timer,
    required this.config,
  });
}

class _ToastWidget extends StatefulWidget {
  final NotificationConfig config;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.config,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller
        .reverse(from: _controller.value)
        .then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: widget.color,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.config.message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.config.actionLabel != null)
                  TextButton(
                    onPressed: () {
                      widget.config.onAction?.call();
                      _dismiss();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(widget.config.actionLabel!),
                  ),
                if (widget.config.dismissible)
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
