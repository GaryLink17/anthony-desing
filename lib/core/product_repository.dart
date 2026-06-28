import 'database.dart';
import 'app_exception.dart';
import '../models/product.dart';

/// Repositorio para operaciones CRUD de productos en el inventario.
class ProductRepository {
  final _db = DatabaseHelper.instance;

  /// Obtiene todos los productos ordenados por nombre.
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

  /// Busca productos cuyo nombre contenga [query].
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
      throw AppException('Error al buscar productos.', technical: e.toString());
    }
  }

  /// Inserta un nuevo producto y retorna su ID generado.
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

  /// Actualiza los datos de un producto existente.
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

  /// Elimina un producto por su ID.
  /// Lanza [AppException] si el producto está referenciado en facturas o cotizaciones.
  Future<void> delete(int id) async {
    try {
      final db = await _db.database;

      final invCount = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM invoice_items WHERE product_id = ?',
        [id],
      );
      if ((invCount.first['cnt'] as num).toInt() > 0) {
        throw const AppException(
          'No se puede eliminar el producto porque está registrado en una o más facturas.',
        );
      }

      final quoteCount = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM quote_items WHERE product_id = ?',
        [id],
      );
      if ((quoteCount.first['cnt'] as num).toInt() > 0) {
        throw const AppException(
          'No se puede eliminar el producto porque está registrado en una o más cotizaciones.',
        );
      }

      await db.delete('products', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'No se pudo eliminar el producto.',
        technical: e.toString(),
      );
    }
  }

  /// Reduce el stock de un producto en [quantity] unidades.
  Future<void> decreaseStock(int productId, int quantity) async {
    try {
      final db = await _db.database;
      await db.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [
        quantity,
        productId,
      ]);
    } catch (e) {
      throw AppException(
        'Error al actualizar el stock.',
        technical: e.toString(),
      );
    }
  }

  /// Obtiene productos cuyo stock está por debajo del mínimo.
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

  /// Verifica cuáles de los [productIds] dados quedaron con stock bajo
  /// después de una venta. Útil para alertar inmediatamente post-factura.
  Future<List<Product>> getLowStockForProducts(List<int> productIds) async {
    if (productIds.isEmpty) return [];
    try {
      final db = await _db.database;
      final placeholders = productIds.map((_) => '?').join(',');
      final result = await db.rawQuery(
        'SELECT * FROM products '
        'WHERE id IN ($placeholders) AND stock <= min_stock '
        'ORDER BY stock ASC',
        productIds,
      );
      return result.map(Product.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudo verificar el stock.',
        technical: e.toString(),
      );
    }
  }

  /// Obtiene un producto por su ID, o null si no existe.
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

  /// Verifica si hay suficiente stock disponible para [quantity] unidades.
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

  /// Inserta un producto usando valores planos (sin modelo).
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
