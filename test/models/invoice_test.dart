import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/models/invoice.dart';

void main() {
  final sample = Invoice(
    id: 1,
    customerName: 'Juan Pérez',
    subtotal: 1000,
    discountGlobal: 100,
    total: 900,
    status: 'active',
    paymentStatus: 'pending',
    createdAt: '2025-01-15',
  );

  group('Invoice', () {
    test('constructor asigna valores correctamente', () {
      expect(sample.id, 1);
      expect(sample.customerName, 'Juan Pérez');
      expect(sample.subtotal, 1000);
      expect(sample.discountGlobal, 100);
      expect(sample.total, 900);
      expect(sample.status, 'active');
      expect(sample.paymentStatus, 'pending');
    });

    test('isActive es true cuando status es active', () {
      expect(sample.isActive, true);
      expect(sample.isCancelled, false);
    });

    test('isCancelled es true cuando status es cancelled', () {
      final cancelled = sample.copyWith(status: 'cancelled');
      expect(cancelled.isCancelled, true);
      expect(cancelled.isActive, false);
    });

    test('isPaid es true cuando paymentStatus es paid', () {
      final paid = sample.copyWith(paymentStatus: 'paid');
      expect(paid.isPaid, true);
      expect(paid.isPending, false);
    });

    test('discountGlobal y status tienen valores por defecto', () {
      final invoice = Invoice(
        subtotal: 500,
        total: 500,
        createdAt: '2025-01-01',
      );
      expect(invoice.discountGlobal, 0);
      expect(invoice.status, 'active');
      expect(invoice.paymentStatus, 'pending');
    });

    test('toMap convierte a Map correctamente', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['customer_name'], 'Juan Pérez');
      expect(map['subtotal'], 1000);
      expect(map['discount_global'], 100);
      expect(map['total'], 900);
      expect(map['status'], 'active');
      expect(map['payment_status'], 'pending');
    });

    test('fromMap reconstruye desde Map correctamente', () {
      final map = sample.toMap();
      final restored = Invoice.fromMap(map);
      expect(restored.id, sample.id);
      expect(restored.customerName, sample.customerName);
      expect(restored.subtotal, sample.subtotal);
      expect(restored.total, sample.total);
    });

    test('fromMap maneja valores nulos correctamente', () {
      final restored = Invoice.fromMap({
        'id': 2,
        'customer_name': null,
        'subtotal': 500.0,
        'discount_global': null,
        'total': 500.0,
        'status': null,
        'payment_status': null,
        'created_at': '2025-02-01',
      });
      expect(restored.id, 2);
      expect(restored.customerName, null);
      expect(restored.discountGlobal, 0);
      expect(restored.status, 'active');
      expect(restored.paymentStatus, 'pending');
    });

    test('copyWith modifica solo los campos indicados', () {
      final copy = sample.copyWith(total: 800, status: 'paid');
      expect(copy.total, 800);
      expect(copy.status, 'paid');
      expect(copy.subtotal, 1000);
      expect(copy.id, 1);
    });
  });
}
