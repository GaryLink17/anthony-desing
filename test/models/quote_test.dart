import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/models/quote.dart';

void main() {
  final sample = Quote(
    id: 1,
    customerName: 'María García',
    subtotal: 2000,
    discountGlobal: 200,
    total: 1800,
    createdAt: '2025-02-01',
    expiresAt: '2027-03-01',
    isConverted: false,
  );

  group('Quote', () {
    test('constructor asigna valores correctamente', () {
      expect(sample.id, 1);
      expect(sample.customerName, 'María García');
      expect(sample.subtotal, 2000);
      expect(sample.discountGlobal, 200);
      expect(sample.total, 1800);
      expect(sample.isConverted, false);
    });

    test('isValid es true cuando no expirada y no convertida', () {
      expect(sample.isValid, true);
    });

    test('isValid es false cuando convertida', () {
      final converted = sample.copyWith(isConverted: true);
      expect(converted.isValid, false);
    });

    test('isExpired es true cuando expiresAt ya pasó', () {
      final expired = sample.copyWith(expiresAt: '2020-01-01');
      expect(expired.isExpired, true);
    });

    test('isExpired es false cuando expiresAt en el futuro', () {
      final futureExpiry = sample.copyWith(expiresAt: '2030-06-01');
      expect(futureExpiry.isExpired, false);
    });

    test('isExpired es false cuando expiresAt futuro', () {
      const future = '2099-12-31';
      final notExpired = sample.copyWith(expiresAt: future);
      expect(notExpired.isExpired, false);
    });

    test('discountGlobal e isConverted tienen valores por defecto', () {
      final quote = Quote(
        subtotal: 500,
        total: 500,
        createdAt: '2025-01-01',
      );
      expect(quote.discountGlobal, 0);
      expect(quote.isConverted, false);
    });

    test('toMap convierte a Map correctamente', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['customer_name'], 'María García');
      expect(map['subtotal'], 2000);
      expect(map['discount_global'], 200);
      expect(map['total'], 1800);
      expect(map['is_converted'], 0);
    });

    test('fromMap reconstruye desde Map correctamente', () {
      final map = sample.toMap();
      final restored = Quote.fromMap(map);
      expect(restored.id, sample.id);
      expect(restored.customerName, sample.customerName);
      expect(restored.subtotal, sample.subtotal);
      expect(restored.total, sample.total);
      expect(restored.isConverted, sample.isConverted);
    });

    test('fromMap maneja is_converted como entero 0/1', () {
      final convertedMap = <String, dynamic>{
        'id': 1,
        'customer_name': null,
        'subtotal': 500.0,
        'discount_global': 0.0,
        'total': 500.0,
        'created_at': '2025-01-01',
        'expires_at': null,
        'is_converted': 1,
      };
      final converted = Quote.fromMap(convertedMap);
      expect(converted.isConverted, true);
    });

    test('fromMap maneja is_converted como 0', () {
      final notConvertedMap = <String, dynamic>{
        'id': 2,
        'customer_name': null,
        'subtotal': 500.0,
        'discount_global': null,
        'total': 500.0,
        'created_at': '2025-01-01',
        'expires_at': null,
        'is_converted': 0,
      };
      final notConverted = Quote.fromMap(notConvertedMap);
      expect(notConverted.isConverted, false);
    });

    test('copyWith modifica solo los campos indicados', () {
      final copy = sample.copyWith(total: 1500, discountGlobal: 500);
      expect(copy.total, 1500);
      expect(copy.discountGlobal, 500);
      expect(copy.subtotal, 2000);
    });
  });
}
