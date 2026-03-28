import 'database.dart';
import 'app_exception.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';

class QuoteRepository {
  final _db = DatabaseHelper.instance;

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
