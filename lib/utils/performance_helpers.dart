import 'dart:async';
import 'package:flutter/material.dart';

// ---- DEBOUNCER ----

/// Retrasa la ejecución de un callback hasta que pasa un tiempo
/// sin nuevas invocaciones. Útil para búsquedas en tiempo real.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}

// ---- PERFORMANCE MONITORING ----

/// Monitor singleton para medir tiempos de ejecución de operaciones.
/// Almacea hasta [_maxMeasurementsPerLabel] muestras por etiqueta.
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() {
    return _instance;
  }

  PerformanceMonitor._internal();

  static const _maxMeasurementsPerLabel = 100;

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _measurements = {};

  void startMeasure(String label) {
    _startTimes[label] = DateTime.now();
  }

  int? endMeasure(String label, {bool verbose = false}) {
    final startTime = _startTimes.remove(label);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime).inMilliseconds;

    _measurements.putIfAbsent(label, () => []);
    final list = _measurements[label]!;
    if (list.length >= _maxMeasurementsPerLabel) list.removeAt(0);
    list.add(duration);

    if (verbose) {
      debugPrint('[Performance] $label: ${duration}ms');
    }

    return duration;
  }

  double? getAverage(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;

    final sum = measurements.fold<int>(0, (a, b) => a + b);
    return sum / measurements.length;
  }

  int? getMax(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a > b ? a : b);
  }

  int? getMin(String label) {
    final measurements = _measurements[label];
    if (measurements == null || measurements.isEmpty) return null;
    return measurements.reduce((a, b) => a < b ? a : b);
  }

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

  void clear() {
    _startTimes.clear();
    _measurements.clear();
  }
}


