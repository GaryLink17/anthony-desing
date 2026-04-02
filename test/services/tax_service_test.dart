import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/services/tax_service.dart';

void main() {
  group('TaxService.calculate', () {
    test('calcula ITBIS e ISR correctamente', () {
      const config = TaxConfig(
        applyItbis: true,
        itbisRate: 18,
        applyIsr: true,
        isrRate: 1,
      );

      final result = TaxService.calculate(1000, config);

      expect(result.itbis, 180);
      expect(result.isr, 10);
      expect(result.total, 1170);
    });

    test('retorna total igual a base si ambos impuestos están apagados', () {
      const config = TaxConfig(
        applyItbis: false,
        itbisRate: 18,
        applyIsr: false,
        isrRate: 1,
      );

      final result = TaxService.calculate(500, config);

      expect(result.itbis, 0);
      expect(result.isr, 0);
      expect(result.total, 500);
    });
  });
}
