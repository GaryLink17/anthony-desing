import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/models/product.dart';

void main() {
  final sample = Product(
    id: 1,
    name: 'Camisa',
    category: 'Ropa',
    purchasePrice: 500,
    salePrice: 800,
    stock: 10,
    minStock: 5,
    createdAt: '2025-01-01',
  );

  group('Product', () {
    test('constructor asigna valores correctamente', () {
      expect(sample.id, 1);
      expect(sample.name, 'Camisa');
      expect(sample.purchasePrice, 500);
      expect(sample.salePrice, 800);
      expect(sample.stock, 10);
      expect(sample.minStock, 5);
    });

    test('profit se calcula como salePrice - purchasePrice', () {
      expect(sample.profit, 300);
    });

    test('marginPercent se calcula correctamente', () {
      expect(sample.marginPercent, closeTo(37.5, 0.01));
    });

    test('isLowStock es true cuando stock <= minStock', () {
      expect(sample.isLowStock, false);
      final lowStock = sample.copyWith(stock: 4);
      expect(lowStock.isLowStock, true);
      final equalStock = sample.copyWith(stock: 5);
      expect(equalStock.isLowStock, true);
    });

    test('minStock tiene valor por defecto 5', () {
      final p = Product(
        name: 'Test',
        purchasePrice: 100,
        salePrice: 150,
        stock: 10,
        createdAt: '2025-01-01',
      );
      expect(p.minStock, 5);
    });

    test('toMap convierte a Map correctamente', () {
      final map = sample.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Camisa');
      expect(map['category'], 'Ropa');
      expect(map['purchase_price'], 500);
      expect(map['sale_price'], 800);
      expect(map['stock'], 10);
      expect(map['min_stock'], 5);
      expect(map['created_at'], '2025-01-01');
    });

    test('fromMap reconstruye desde Map correctamente', () {
      final map = sample.toMap();
      final restored = Product.fromMap(map);
      expect(restored.id, sample.id);
      expect(restored.name, sample.name);
      expect(restored.purchasePrice, sample.purchasePrice);
      expect(restored.salePrice, sample.salePrice);
      expect(restored.stock, sample.stock);
      expect(restored.createdAt, sample.createdAt);
    });

    test('copyWith conserva valores no modificados', () {
      final copy = sample.copyWith(name: 'Pantalón');
      expect(copy.name, 'Pantalón');
      expect(copy.purchasePrice, 500);
      expect(copy.id, 1);
    });

    test('copyWith con todos null devuelve igual', () {
      final copy = sample.copyWith();
      expect(copy.name, sample.name);
      expect(copy.id, sample.id);
    });
  });
}
