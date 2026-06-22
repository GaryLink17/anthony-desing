import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/models/invoice_item.dart';

void main() {
  final sample = InvoiceItem(
    id: 1,
    invoiceId: 10,
    productId: 5,
    productName: 'Camisa Azul',
    quantity: 3,
    unitPrice: 800,
    discountItem: 50,
    subtotal: 2350,
  );

  group('InvoiceItem', () {
    test('constructor asigna valores correctamente', () {
      expect(sample.id, 1);
      expect(sample.invoiceId, 10);
      expect(sample.productId, 5);
      expect(sample.productName, 'Camisa Azul');
      expect(sample.quantity, 3);
      expect(sample.unitPrice, 800);
      expect(sample.discountItem, 50);
      expect(sample.subtotal, 2350);
    });

    test('discountItem tiene valor por defecto 0', () {
      final item = InvoiceItem(
        invoiceId: 1,
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
      expect(map['invoice_id'], 10);
      expect(map['product_id'], 5);
      expect(map['product_name'], 'Camisa Azul');
      expect(map['quantity'], 3);
      expect(map['unit_price'], 800);
      expect(map['discount_item'], 50);
      expect(map['subtotal'], 2350);
    });

    test('fromMap reconstruye desde Map correctamente', () {
      final map = sample.toMap();
      final restored = InvoiceItem.fromMap(map);
      expect(restored.id, sample.id);
      expect(restored.invoiceId, sample.invoiceId);
      expect(restored.productId, sample.productId);
      expect(restored.productName, sample.productName);
      expect(restored.quantity, sample.quantity);
      expect(restored.unitPrice, sample.unitPrice);
      expect(restored.discountItem, sample.discountItem);
      expect(restored.subtotal, sample.subtotal);
    });

    test('copyWith modifica solo los campos indicados', () {
      final copy = sample.copyWith(quantity: 5, subtotal: 3950);
      expect(copy.quantity, 5);
      expect(copy.subtotal, 3950);
      expect(copy.productName, 'Camisa Azul');
      expect(copy.invoiceId, 10);
    });

    test('copyWith con todos null devuelve igual', () {
      final copy = sample.copyWith();
      expect(copy.quantity, sample.quantity);
      expect(copy.subtotal, sample.subtotal);
    });
  });
}
