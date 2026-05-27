import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/services/document_totals_service.dart';

void main() {
  test('calcula subtotal, descuento y total desde items', () {
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

    final totals = DocumentTotalsService.calculateFromItems(
      items: items,
      discountPercent: 5,
    );

    expect(totals.subtotal, 230);
    expect(totals.discountAmount, 11.5);
    expect(totals.total, 218.5);
  });
}
