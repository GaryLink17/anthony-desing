import 'database.dart';

class ReportsRepository {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getSummary(DateTime from, DateTime to) async {
    final db = await _db.database;
    final start = from.toIso8601String();
    final end = to.toIso8601String();

    final salesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) as total
      FROM invoices
      WHERE created_at BETWEEN ? AND ? AND status = 'active'
    ''',
      [start, end],
    );

    final profitResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(
        (ii.unit_price * (1 - ii.discount_item / 100) - p.purchase_price) * ii.quantity
      ), 0) as profit
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.created_at BETWEEN ? AND ? AND i.status = 'active'
    ''',
      [start, end],
    );

    final countResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM invoices
      WHERE created_at BETWEEN ? AND ? AND status = 'active'
    ''',
      [start, end],
    );

    final count = (countResult.first['count'] as num).toInt();
    final total = (salesResult.first['total'] as num).toDouble();

    return {
      'total': total,
      'profit': (profitResult.first['profit'] as num).toDouble(),
      'count': count,
      'avgTicket': count > 0 ? total / count : 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesByDay(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db.database;
    return await db.rawQuery(
      '''
      SELECT
        DATE(created_at) as day,
        COALESCE(SUM(total), 0) as total,
        COUNT(*) as count
      FROM invoices
      WHERE created_at BETWEEN ? AND ? AND status = 'active'
      GROUP BY DATE(created_at)
      ORDER BY day ASC
    ''',
      [from.toIso8601String(), to.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByMonth(int year) async {
    final db = await _db.database;
    return await db.rawQuery(
      '''
      SELECT
        STRFTIME('%m', created_at) as month,
        COALESCE(SUM(total), 0) as total,
        COUNT(*) as count
      FROM invoices
      WHERE STRFTIME('%Y', created_at) = ? AND status = 'active'
      GROUP BY STRFTIME('%m', created_at)
      ORDER BY month ASC
    ''',
      [year.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> getTopProducts(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db.database;
    return await db.rawQuery(
      '''
      SELECT
        ii.product_name,
        SUM(ii.quantity) as total_qty,
        SUM(ii.subtotal) as total_amount
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.created_at BETWEEN ? AND ? AND i.status = 'active'
      GROUP BY ii.product_name
      ORDER BY total_qty DESC
      LIMIT 5
    ''',
      [from.toIso8601String(), to.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getTopCategories(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db.database;
    return await db.rawQuery(
      '''
      SELECT
        COALESCE(p.category, 'Sin categoría') as category,
        SUM(ii.quantity) as total_qty,
        SUM(ii.subtotal) as total_amount
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.created_at BETWEEN ? AND ? AND i.status = 'active'
      GROUP BY p.category
      ORDER BY total_amount DESC
      LIMIT 5
    ''',
      [from.toIso8601String(), to.toIso8601String()],
    );
  }
}
