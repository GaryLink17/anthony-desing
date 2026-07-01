// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath = r'C:\Users\Gary\AppData\Roaming\com.example\inventario_y_facturacion\control_gastos.db';
  final db = await databaseFactory.openDatabase(dbPath);

  print('=== TOTALES ===');
  final total = (await db.rawQuery('SELECT COUNT(*) as cnt FROM products'))
      .first['cnt'] as int;
  print('Productos: $total');

  final cats = await db.rawQuery(
    'SELECT category, COUNT(*) as cnt FROM products GROUP BY category ORDER BY cnt DESC LIMIT 10',
  );
  print('\n=== TOP 10 CATEGORÍAS ===');
  for (final row in cats) {
    print('  ${row['category']}: ${row['cnt']}');
  }

  final prices = await db.rawQuery(
    'SELECT MIN(sale_price) as min, MAX(sale_price) as max, AVG(sale_price) as avg FROM products',
  );
  print('\n=== PRECIOS ===');
  final p = prices.first;
  print('  Mín: RD\$ ${(p['min'] as num).toStringAsFixed(2)}');
  print('  Máx: RD\$ ${(p['max'] as num).toStringAsFixed(2)}');
  print('  Prom: RD\$ ${(p['avg'] as num).toStringAsFixed(2)}');

  final stocks = await db.rawQuery(
    'SELECT MIN(stock) as min, MAX(stock) as max, AVG(stock) as avg FROM products',
  );
  print('\n=== STOCK ===');
  final s = stocks.first;
  print('  Mín: ${s['min']}');
  print('  Máx: ${s['max']}');
  print('  Prom: ${(s['avg'] as num).toStringAsFixed(1)}');

  print('\n=== MUESTRA (10 productos) ===');
  final sample = await db.rawQuery(
    'SELECT id, name, category, purchase_price, sale_price, stock FROM products ORDER BY RANDOM() LIMIT 10',
  );
  for (final row in sample) {
    print('  #${row['id']}: ${row['name']}');
    print('      Cat: ${row['category']}  '
        'Compra: RD\$${(row['purchase_price'] as num).toStringAsFixed(2)}  '
        'Venta: RD\$${(row['sale_price'] as num).toStringAsFixed(2)}  '
        'Stock: ${row['stock']}');
  }

  await db.close();
}
