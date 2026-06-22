import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/models/quote_item.dart';

void main() {
  final sample = QuoteItem(
    id: 1,
    quoteId: 20,
    productId: 3,
    productName: 'Pantalón Beige',
    quantity: 2,
    unitPrice: 1200,
    discountItem: 100,
    subtotal: 2300,
  );

  group('QuoteItem', () {
    test('constructor asigna valores correctamente', () {
      expect(sample.id, 1);
      expect(sample.quoteId, 20);
      expect(sample.productId, 3);
      expect(sample.productName, 'Pantalón Beige');
      expect(sample.quantity, 2);
      expect(sample.unitPrice, 1200);
      expect(sample.discountItem, 100);
      expect(sample.subtotal, 2300);
    });

    test('discountItem tiene valor por defecto 0', () {
      final item = QuoteItem(
        quoteId: 1,
        productId: 1,
        productName: 'Test',
        quantity: 1,
        unitPrice: 100,
        subtotal: 100,
      );
      expect(item.discountItem, 0);
    });

    test('toMap convierte a Map correctamente', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['quote_id'], 20);
      expect(map['product_id'], 3);
      expect(map['product_name'], 'Pantalón Beige');
      expect(map['quantity'], 2);
      expect(map['unit_price'], 1200);
      expect(map['discount_item'], 100);
      expect(map['subtotal'], 2300);
    });

    test('fromMap reconstruye desde Map correctamente', () {
      final map = sample.toMap();
      final restored = QuoteItem.fromMap(map);
      expect(restored.id, sample.id);
      expect(restored.quoteId, sample.quoteId);
      expect(restored.productId, sample.productId);
      expect(restored.productName, sample.productName);
      expect(restored.quantity, sample.quantity);
      expect(restored.unitPrice, sample.unitPrice);
      expect(restored.discountItem, sample.discountItem);
      expect(restored.subtotal, sample.subtotal);
    });

    test('copyWith modifica solo los campos indicados', () {
      final copy = sample.copyWith(quantity: 1, subtotal: 1100);
      expect(copy.quantity, 1);
      expect(copy.subtotal, 1100);
      expect(copy.productName, 'Pantalón Beige');
      expect(copy.quoteId, 20);
    });

    test('copyWith con todos null devuelve igual', () {
      final copy = sample.copyWith();
      expect(copy.quantity, sample.quantity);
      expect(copy.subtotal, sample.subtotal);
    });
  });
}
