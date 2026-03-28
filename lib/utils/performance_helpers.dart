import 'dart:async';
import 'package:flutter/material.dart';

// ---- DEBOUNCER ----

/// Utilidad para debounce que previene ejecuciones excesivas
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Ejecuta la función con debounce
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancela cualquier ejecución pendiente
  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}

// ---- THROTTLER ----

/// Utilidad para throttle que limita la frecuencia de ejecución
class Throttler {
  final Duration minDelay;
  DateTime? _lastExecutionTime;
  Timer? _timer;
  VoidCallback? _pendingCallback;

  Throttler({this.minDelay = const Duration(milliseconds: 500)});

  /// Ejecuta la función con throttle
  void call(VoidCallback callback) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!).inMilliseconds >=
            minDelay.inMilliseconds) {
      _lastExecutionTime = now;
      _pendingCallback = null;
      _timer?.cancel();
      callback();
    } else {
      // Programar la ejecución para más tarde
      _pendingCallback = callback;
      _timer?.cancel();
      _timer = Timer(
        minDelay - now.difference(_lastExecutionTime ?? DateTime.now()),
        () {
          if (_pendingCallback != null) {
            _lastExecutionTime = DateTime.now();
            _pendingCallback!();
            _pendingCallback = null;
          }
        },
      );
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

// ---- IMAGE CACHE ----

/// Helper para gestionar caché de imágenes
class ImageCacheHelper {
  static void clearImageCache() {
    imageCache.clearLiveImages();
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static void clearNetworkImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static int getCacheSize() {
    return imageCache.currentSize;
  }

  static int getMaxCacheSize() {
    return imageCache.maximumSize;
  }
}

// ---- PERFORMANCE MONITORING ----

/// Monitor de rendimiento básico
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() {
    return _instance;
  }

  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _measurements = {};

  /// Inicia la medición de un evento
  void startMeasure(String label) {
    _startTimes[label] = DateTime.now();
  }

  /// Finaliza la medición y registra el pTiempo
  int? endMeasure(String label, {bool verbose = false}) {
    final startTime = _startTimes.remove(label);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime).inMilliseconds;

    _measurements.putIfAbsent(label, () => []);
    _measurements[label]!.add(duration);

    if (verbose) {
      debugPrint('[Performance] $label: ${duration}ms');
    }

    return duration;
  }

  /// Obtiene el promedio de una medición
  double? getAverage(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;

    final sum = measurements.fold<int>(0, (a, b) => a + b);
    return sum / measurements.length;
  }

  /// Obtiene el máximo de una medición
  int? getMax(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a > b ? a : b);
  }

  /// Obtiene el mínimo de una medición
  int? getMin(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a < b ? a : b);
  }

  /// Imprime reporte de todas las mediciones
  void printReport() {
    debugPrint('=== Performance Report ===');
    for (final entry in _measurements.entries) {
      final avg = getAverage(entry.key);
      final min = getMin(entry.key);
      final max = getMax(entry.key);
      debugPrint(
        '${entry.key}: avg=${avg?.toStringAsFixed(2)}ms, '
        'min=${min}ms, max=${max}ms (${entry.value.length}x)',
      );
    }
    debugPrint('========================');
  }

  /// Limpia todas las mediciones
  void clear() {
    _startTimes.clear();
    _measurements.clear();
  }
}

// ---- CONST OPTIMIZER ----

/// Widget que no se reconstruye a menos que sus props cambien
class ConstWidget extends StatelessWidget {
  final Widget child;

  const ConstWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

// ---- LIST BUILDER OPTIMIZADO ----

/// Builder optimizado para listas grandes usando AutomaticKeepAliveClientMixin
class OptimizedListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final bool addAutomaticKeepAlives;

  const OptimizedListView({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.scrollController,
    this.padding = EdgeInsets.zero,
    this.addAutomaticKeepAlives = true,
  });

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}

// ---- LAZY IMAGE LOADER ----

/// Widget de imagen con lazy loading
class LazyImage extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyImage(
    this.imagePath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Image.network(
      widget.imagePath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            const Center(child: Icon(Icons.image_not_supported_outlined));
      },
    );
  }
}
