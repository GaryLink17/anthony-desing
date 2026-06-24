import 'database.dart';
import 'app_exception.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';

/// Repositorio para operaciones CRUD de cotizaciones y sus líneas de detalle.
class QuoteRepository {
  final _db = DatabaseHelper.instance;

  /// Obtiene todas las cotizaciones ordenadas por fecha descendente.
  Future<List<Quote>> getAll() async {
    try {
      final db = await _db.database;
      final result = await db.query('quotes', orderBy: 'created_at DESC');
      return result.map(Quote.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudieron cargar las cotizaciones.',
        technical: e.toString(),
      );
    }
  }

  /// Busca cotizaciones por nombre de cliente.
  Future<List<Quote>> search(String query) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'quotes',
        where: 'customer_name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'created_at DESC',
      );
      return result.map(Quote.fromMap).toList();
    } catch (e) {
      throw AppException(
        'Error al buscar cotizaciones.',
        technical: e.toString(),
      );
    }
  }

  /// Obtiene las líneas de detalle (items) de una cotización.
  Future<List<QuoteItem>> getItems(int quoteId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'quote_items',
        where: 'quote_id = ?',
        whereArgs: [quoteId],
      );
      return result.map(QuoteItem.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudieron cargar los productos de la cotización.',
        technical: e.toString(),
      );
    }
  }

  /// Obtiene una cotización por su ID, o null si no existe.
  Future<Quote?> getById(int quoteId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'quotes',
        where: 'id = ?',
        whereArgs: [quoteId],
      );
      if (result.isEmpty) return null;
      return Quote.fromMap(result.first);
    } catch (e) {
      throw AppException(
        'No se pudo obtener la cotización.',
        technical: e.toString(),
      );
    }
  }

  /// Guarda una nueva cotización junto con sus items en una transacción.
  /// NOTA: a diferencia de facturas, las cotizaciones NO descuentan stock.
  Future<int> save(Quote quote, List<QuoteItem> items) async {
    try {
      final db = await _db.database;
      return await db.transaction((txn) async {
        final quoteId = await txn.insert('quotes', {
          'customer_name': quote.customerName,
          'subtotal': quote.subtotal,
          'discount_global': quote.discountGlobal,
          'total': quote.total,
          'created_at': quote.createdAt,
          'expires_at': quote.expiresAt,
          'is_converted': quote.isConverted ? 1 : 0,
        });

        for (final item in items) {
          await txn.insert('quote_items', {
            'quote_id': quoteId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'discount_item': item.discountItem,
            'subtotal': item.subtotal,
          });
        }

        return quoteId;
      });
    } catch (e) {
      throw AppException(
        'No se pudo guardar la cotización.',
        technical: e.toString(),
      );
    }
  }

  /// Actualiza una cotización existente y sus items en una transacción.
  /// A diferencia del patrón delete+save, esto es atómico y no pierde datos
  /// si falla la operación.
  Future<void> update(int quoteId, Quote quote, List<QuoteItem> items) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.update(
          'quotes',
          {
            'customer_name': quote.customerName,
            'subtotal': quote.subtotal,
            'discount_global': quote.discountGlobal,
            'total': quote.total,
            'expires_at': quote.expiresAt,
          },
          where: 'id = ?',
          whereArgs: [quoteId],
        );
        await txn.delete(
          'quote_items',
          where: 'quote_id = ?',
          whereArgs: [quoteId],
        );
        for (final item in items) {
          await txn.insert('quote_items', {
            'quote_id': quoteId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'discount_item': item.discountItem,
            'subtotal': item.subtotal,
          });
        }
      });
    } catch (e) {
      throw AppException(
        'No se pudo actualizar la cotización.',
        technical: e.toString(),
      );
    }
  }

  /// Marca una cotización como convertida a factura (is_converted = 1).
  /// Previene que se convierta dos veces.
  Future<void> markAsConverted(int quoteId) async {
    try {
      final db = await _db.database;
      await db.update(
        'quotes',
        {'is_converted': 1},
        where: 'id = ?',
        whereArgs: [quoteId],
      );
    } catch (e) {
      throw AppException(
        'No se pudo marcar la cotización como convertida.',
        technical: e.toString(),
      );
    }
  }

  /// Elimina una cotización y sus items asociados en una transacción.
  Future<void> delete(int quoteId) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete(
          'quote_items',
          where: 'quote_id = ?',
          whereArgs: [quoteId],
        );
        await txn.delete('quotes', where: 'id = ?', whereArgs: [quoteId]);
      });
    } catch (e) {
      throw AppException(
        'No se pudo eliminar la cotización.',
        technical: e.toString(),
      );
    }
  }
}
