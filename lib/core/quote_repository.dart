import 'database.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';

class QuoteRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Quote>> getAll() async {
    final db = await _db.database;
    final result = await db.query('quotes', orderBy: 'created_at DESC');
    return result.map(Quote.fromMap).toList();
  }

  Future<List<QuoteItem>> getItems(int quoteId) async {
    final db = await _db.database;
    final result = await db.query(
      'quote_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );
    return result.map(QuoteItem.fromMap).toList();
  }

  Future<Quote?> getById(int quoteId) async {
    final db = await _db.database;
    final result = await db.query(
      'quotes',
      where: 'id = ?',
      whereArgs: [quoteId],
    );
    if (result.isEmpty) return null;
    return Quote.fromMap(result.first);
  }

  Future<int> save(Quote quote, List<QuoteItem> items) async {
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
  }

  Future<void> markAsConverted(int quoteId) async {
    final db = await _db.database;
    await db.update(
      'quotes',
      {'is_converted': 1},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
  }

  Future<void> delete(int quoteId) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      await txn.delete(
        'quote_items',
        where: 'quote_id = ?',
        whereArgs: [quoteId],
      );

      await txn.delete('quotes', where: 'id = ?', whereArgs: [quoteId]);
    });
  }
}
