import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final random = Random(42);
  final dbPath = r'C:\Users\Gary\AppData\Roaming\com.example\inventario_y_facturacion\control_gastos.db';

  final db = await databaseFactory.openDatabase(dbPath);

  final existingCount = (await db.rawQuery('SELECT COUNT(*) as cnt FROM products'))
      .first['cnt'] as int;
  print('Productos existentes: $existingCount');

  final categories = [
    'Telas', 'Hilos', 'Cierres', 'Botones', 'Elásticos',
    'Entretelas', 'Cintas', 'Bies', 'Broches', 'Cordones',
    'Encajes', 'Apliques', 'Lentejuelas', 'Pasamanería', 'Forros',
  ];

  final prefixes = [
    'Tela', 'Hilo', 'Cierre', 'Botón', 'Elástico',
    'Entretela', 'Cinta', 'Bies', 'Broche', 'Cordón',
    'Encaje', 'Aplique', 'Lentejuela', 'Pasamanería', 'Forro',
  ];

  final adjectives = [
    'Liso', 'Estampado', 'Metálico', 'Transparente', 'Doblez',
    'Reforzado', 'Decorativo', 'Clásico', 'Premium', 'Económico',
    'Industrial', 'Delgado', 'Grueso', 'Resistente', 'Suave',
    'Color', 'Neón', 'Pastel', 'Oscuro', 'Claro',
  ];

  final colors = [
    'Rojo', 'Azul', 'Verde', 'Negro', 'Blanco',
    'Amarillo', 'Rosa', 'Morado', 'Naranja', 'Gris',
    'Marrón', 'Turquesa', 'Vino', 'Mostaza', 'Celeste',
    'Beige', 'Lila', 'Coral', 'Oliva', 'Plateado',
  ];

  final measurements = ['m', 'yd', 'kg', 'g', 'pza', 'doc', 'par', 'm²'];

  final batchSize = 50;
  int inserted = 0;

  for (int i = 0; i < 1000; i += batchSize) {
    final batch = db.batch();

    for (int j = 0; j < batchSize && i + j < 1000; j++) {
      final idx = i + j;
      final prefix = prefixes[idx % prefixes.length];
      final adj = adjectives[random.nextInt(adjectives.length)];
      final color = colors[random.nextInt(colors.length)];
      final measure = measurements[random.nextInt(measurements.length)];
      final num = random.nextInt(900) + 100;

      final name = '$prefix $adj $color #$num ($measure)';
      final category = categories[idx % categories.length];

      final purchasePrice = (random.nextDouble() * 500 + 5) * 10;
      final salePrice = purchasePrice * (random.nextDouble() * 1.5 + 1.0);
      final stock = random.nextInt(200);
      final minStock = random.nextInt(20) + 2;
      final createdAt = DateTime.now()
          .subtract(Duration(days: random.nextInt(365)))
          .toIso8601String();

      batch.insert('products', {
        'name': name,
        'category': category,
        'purchase_price': purchasePrice / 10,
        'sale_price': salePrice / 10,
        'stock': stock,
        'min_stock': minStock,
        'created_at': createdAt,
      });
    }

    await batch.commit(noResult: true);
    inserted += batchSize;
    print('Insertados $inserted / 1000...');
  }

  final newCount = (await db.rawQuery('SELECT COUNT(*) as cnt FROM products'))
      .first['cnt'] as int;
  print('');
  print('=== COMPLETADO ===');
  print('Productos antes: $existingCount');
  print('Productos ahora:  $newCount');
  print('Insertados:       ${newCount - existingCount}');

  await db.close();
}
