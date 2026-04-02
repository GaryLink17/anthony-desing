import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/services/document_totals_service.dart';
import 'package:inventario_y_facturacion/services/tax_service.dart';

void main() {
  test('calcula subtotal, descuento e impuestos desde items', () {
    final items = <Map<String, dynamic>>[
      {
        'unitPrice': 100.0,
        'quantity': 2,
        'discount': 10.0,
      },
      {
        'unitPrice': 50.0,
        'quantity': 1,
        'discount': 0.0,
      },
    ];

    const config = TaxConfig(
      applyItbis: true,
      itbisRate: 18,
      applyIsr: false,
      isrRate: 1,
    );

    final totals = DocumentTotalsService.calculateFromItems(
      items: items,
      discountPercent: 5,
      taxConfig: config,
    );

    expect(totals.subtotal, 230);
    expect(totals.discountAmount, 11.5);
    expect(totals.taxableBase, 218.5);
    expect(totals.itbis, 39.33);
    expect(totals.total, 257.83);
  });
}
