import 'database.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceRepository {
  final _db = DatabaseHelper.instance;

  // Obtener todas las facturas
  Future<List<Invoice>> getAll() async {
    final db = await _db.database;
    final result = await db.query('invoices', orderBy: 'created_at DESC');
    return result.map(Invoice.fromMap).toList();
  }

  // Obtener los items de una factura
  Future<List<InvoiceItem>> getItems(int invoiceId) async {
    final db = await _db.database;
    final result = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return result.map(InvoiceItem.fromMap).toList();
  }

  // Obtener una factura por ID
  Future<Invoice?> getById(int invoiceId) async {
    final db = await _db.database;
    final result = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    if (result.isEmpty) return null;
    return Invoice.fromMap(result.first);
  }

  // Guardar factura completa y descontar stock
  Future<int> save(Invoice invoice, List<InvoiceItem> items) async {
    final db = await _db.database;

    // Usamos una transacción para que todo se guarde junto
    // o nada si algo falla
    return await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', {
        'customer_name': invoice.customerName,
        'subtotal': invoice.subtotal,
        'discount_global': invoice.discountGlobal,
        'total': invoice.total,
        'status': invoice.status,
        'created_at': invoice.createdAt,
      });

      for (final item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount_item': item.discountItem,
          'subtotal': item.subtotal,
        });

        // Descontar stock del producto (no permite pasar de cero)
        await txn.rawUpdate(
          '''
          UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?
        ''',
          [item.quantity, item.productId],
        );
      }

      return invoiceId;
    });
  }

  // Anular factura y reponer stock
  Future<void> cancel(int invoiceId, {bool restoreStock = true}) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      if (restoreStock) {
        final items = await txn.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );

        for (final item in items) {
          await txn.rawUpdate(
            '''
            UPDATE products SET stock = stock + ? WHERE id = ?
          ''',
            [item['quantity'], item['product_id']],
          );
        }
      }

      await txn.update(
        'invoices',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  // Eliminar factura completamente (solo para casos extremos)
  Future<void> delete(int invoiceId, {bool restoreStock = true}) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      if (restoreStock) {
        final items = await txn.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );

        for (final item in items) {
          await txn.rawUpdate(
            '''
            UPDATE products SET stock = stock + ? WHERE id = ?
          ''',
            [item['quantity'], item['product_id']],
          );
        }
      }

      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  Future<void> update(Invoice invoice, List<InvoiceItem> items) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Primero reponemos el stock de los items originales
      final oldItems = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      for (final item in oldItems) {
        await txn.rawUpdate(
          '''
        UPDATE products SET stock = stock + ? WHERE id = ?
      ''',
          [item['quantity'], item['product_id']],
        );
      }

      // Eliminamos los items viejos
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      // Actualizamos la factura
      await txn.update(
        'invoices',
        {
          'customer_name': invoice.customerName,
          'subtotal': invoice.subtotal,
          'discount_global': invoice.discountGlobal,
          'total': invoice.total,
        },
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Insertamos los items nuevos y descontamos stock
      for (final item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoice.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount_item': item.discountItem,
          'subtotal': item.subtotal,
        });

        await txn.rawUpdate(
          '''
        UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?
      ''',
          [item.quantity, item.productId],
        );
      }
    });
  }
}
