import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/utils/currency_config.dart';

void main() {
  group('currencyFormatter', () {
    test('formatea valores enteros sin decimales', () {
      final formatted = currencyFormatter().format(1500);
      expect(formatted, 'RD\$ 1,500.00');
    });

    test('formatea cero correctamente', () {
      final formatted = currencyFormatter().format(0);
      expect(formatted, 'RD\$ 0.00');
    });

    test('formatea valores grandes con separadores de miles', () {
      final formatted = currencyFormatter().format(1234567);
      expect(formatted, 'RD\$ 1,234,567.00');
    });

    test('usa locale en_US (coma como separador de miles)', () {
      final formatted = currencyFormatter().format(10000);
      expect(formatted, 'RD\$ 10,000.00');
    });
  });
}
