import 'database.dart';
import 'app_exception.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Product>> getAll() async {
    try {
      final db = await _db.database;
      final result = await db.query('products', orderBy: 'name ASC');
      return result.map(Product.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudo cargar el inventario.',
        technical: e.toString(),
      );
    }
  }

  Future<List<Product>> search(String query) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'products',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      return result.map(Product.fromMap).toList();
    } catch (e) {
      throw AppException(
        'Error al buscar productos.',
        technical: e.toString(),
      );
    }
  }

  Future<int> insert(Product product) async {
    try {
      final db = await _db.database;
      return await db.insert('products', product.toMap());
    } catch (e) {
      throw AppException(
        'No se pudo agregar el producto.',
        technical: e.toString(),
      );
    }
  }

  Future<void> update(Product product) async {
    try {
      final db = await _db.database;
      await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      throw AppException(
        'No se pudo actualizar el producto.',
        technical: e.toString(),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await _db.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException(
        'No se pudo eliminar el producto.',
        technical: e.toString(),
      );
    }
  }

  Future<void> decreaseStock(int productId, int quantity) async {
    try {
      final db = await _db.database;
      await db.rawUpdate(
        'UPDATE products SET stock = stock - ? WHERE id = ?',
        [quantity, productId],
      );
    } catch (e) {
      throw AppException(
        'Error al actualizar el stock.',
        technical: e.toString(),
      );
    }
  }

  Future<List<Product>> getLowStock() async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'products',
        where: 'stock <= min_stock',
        orderBy: 'stock ASC',
      );
      return result.map(Product.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudo verificar el stock.',
        technical: e.toString(),
      );
    }
  }

  Future<Product?> getById(int id) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return Product.fromMap(result.first);
    } catch (e) {
      throw AppException(
        'No se pudo obtener el producto.',
        technical: e.toString(),
      );
    }
  }

  Future<bool> hasStock(int productId, int quantity) async {
    try {
      final product = await getById(productId);
      if (product == null) return false;
      return product.stock >= quantity;
    } catch (e) {
      throw AppException(
        'No se pudo verificar disponibilidad de stock.',
        technical: e.toString(),
      );
    }
  }

  Future<int> insertRaw({
    required String name,
    required String category,
    required double purchasePrice,
    required double salePrice,
    required int stock,
    required int minStock,
  }) async {
    try {
      final db = await _db.database;
      return await db.insert('products', {
        'name': name,
        'category': category,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'stock': stock,
        'min_stock': minStock,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw AppException(
        'No se pudo agregar el producto.',
        technical: e.toString(),
      );
    }
  }
}
