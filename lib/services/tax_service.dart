import 'package:shared_preferences/shared_preferences.dart';

/// Configuración y cálculo de impuestos para RD (ITBIS e ISR).
///
/// Las tasas se almacenan en SharedPreferences para que el usuario
/// pueda configurarlas desde Ajustes. Nuevas tasas solo aplican a
/// documentos creados desde ese momento.
class TaxService {
  static const _keyApplyItbis = 'tax_apply_itbis';
  static const _keyItbisRate = 'tax_itbis_rate';
  static const _keyApplyIsr = 'tax_apply_isr';
  static const _keyIsrRate = 'tax_isr_rate';

  static const double defaultItbisRate = 18.0;
  static const double defaultIsrRate = 1.0;

  static Future<TaxConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return TaxConfig(
      applyItbis: prefs.getBool(_keyApplyItbis) ?? false,
      itbisRate: prefs.getDouble(_keyItbisRate) ?? defaultItbisRate,
      applyIsr: prefs.getBool(_keyApplyIsr) ?? false,
      isrRate: prefs.getDouble(_keyIsrRate) ?? defaultIsrRate,
    );
  }

  static Future<void> saveConfig(TaxConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyApplyItbis, config.applyItbis);
    await prefs.setDouble(_keyItbisRate, config.itbisRate);
    await prefs.setBool(_keyApplyIsr, config.applyIsr);
    await prefs.setDouble(_keyIsrRate, config.isrRate);
  }

  /// Calcula los montos de impuestos dado una base imponible.
  static TaxResult calculate(double taxableBase, TaxConfig config) {
    final itbis = config.applyItbis
        ? _round(taxableBase * (config.itbisRate / 100))
        : 0.0;
    final isr = config.applyIsr
        ? _round(taxableBase * (config.isrRate / 100))
        : 0.0;
    // ITBIS se suma, ISR se retiene (resta al total a cobrar)
    final total = _round(taxableBase + itbis - isr);
    return TaxResult(itbis: itbis, isr: isr, total: total);
  }

  static double _round(double value) =>
      (value * 100).roundToDouble() / 100;
}

class TaxConfig {
  final bool applyItbis;
  final double itbisRate;
  final bool applyIsr;
  final double isrRate;

  const TaxConfig({
    required this.applyItbis,
    required this.itbisRate,
    required this.applyIsr,
    required this.isrRate,
  });

  TaxConfig copyWith({
    bool? applyItbis,
    double? itbisRate,
    bool? applyIsr,
    double? isrRate,
  }) {
    return TaxConfig(
      applyItbis: applyItbis ?? this.applyItbis,
      itbisRate: itbisRate ?? this.itbisRate,
      applyIsr: applyIsr ?? this.applyIsr,
      isrRate: isrRate ?? this.isrRate,
    );
  }
}

class TaxResult {
  final double itbis;
  final double isr;
  final double total;

  const TaxResult({
    required this.itbis,
    required this.isr,
    required this.total,
  });
}
