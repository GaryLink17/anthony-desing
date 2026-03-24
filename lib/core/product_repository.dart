import 'database.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = DatabaseHelper.instance;

  // Obtener todos los productos
  Future<List<Product>> getAll() async {
    final db = await _db.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map(Product.fromMap).toList();
  }

  // Buscar productos por nombre
  Future<List<Product>> search(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map(Product.fromMap).toList();
  }

  // Agregar producto
  Future<int> insert(Product product) async {
    final db = await _db.database;
    return await db.insert('products', product.toMap());
  }

  // Editar producto
  Future<void> update(Product product) async {
    final db = await _db.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Eliminar producto
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Descontar stock al confirmar una factura
  Future<void> decreaseStock(int productId, int quantity) async {
    final db = await _db.database;
    await db.rawUpdate(
      '''
      UPDATE products
      SET stock = stock - ?
      WHERE id = ?
    ''',
      [quantity, productId],
    );
  }

  // Productos con stock bajo
  Future<List<Product>> getLowStock() async {
    final db = await _db.database;
    final result = await db.query(
      'products',
      where: 'stock <= min_stock',
      orderBy: 'stock ASC',
    );
    return result.map(Product.fromMap).toList();
  }

  // Obtener producto por ID
  Future<Product?> getById(int id) async {
    final db = await _db.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  // Validar si hay stock suficiente
  Future<bool> hasStock(int productId, int quantity) async {
    final product = await getById(productId);
    if (product == null) return false;
    return product.stock >= quantity;
  }
}
