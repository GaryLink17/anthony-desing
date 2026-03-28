import 'database.dart';
import 'app_exception.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Invoice>> getAll() async {
    try {
      final db = await _db.database;
      final result = await db.query('invoices', orderBy: 'created_at DESC');
      return result.map(Invoice.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudieron cargar las facturas.',
        technical: e.toString(),
      );
    }
  }

  Future<void> updatePaymentStatus(int invoiceId, String paymentStatus) async {
    try {
      final db = await _db.database;
      await db.update(
        'invoices',
        {'payment_status': paymentStatus},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    } catch (e) {
      throw AppException(
        'No se pudo actualizar el estado de pago.',
        technical: e.toString(),
      );
    }
  }

  Future<List<Invoice>> search(String query) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'invoices',
        where: 'customer_name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'created_at DESC',
      );
      return result.map(Invoice.fromMap).toList();
    } catch (e) {
      throw AppException(
        'Error al buscar facturas.',
        technical: e.toString(),
      );
    }
  }

  Future<List<InvoiceItem>> getItems(int invoiceId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      return result.map(InvoiceItem.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudieron cargar los productos de la factura.',
        technical: e.toString(),
      );
    }
  }

  Future<Invoice?> getById(int invoiceId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      if (result.isEmpty) return null;
      return Invoice.fromMap(result.first);
    } catch (e) {
      throw AppException(
        'No se pudo obtener la factura.',
        technical: e.toString(),
      );
    }
  }

  Future<int> save(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final db = await _db.database;
      return await db.transaction((txn) async {
        final invoiceId = await txn.insert('invoices', {
          'customer_name': invoice.customerName,
          'subtotal': invoice.subtotal,
          'discount_global': invoice.discountGlobal,
          'total': invoice.total,
          'status': invoice.status,
          'payment_status': invoice.paymentStatus,
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

          await txn.rawUpdate(
            'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
            [item.quantity, item.productId],
          );
        }

        return invoiceId;
      });
    } catch (e) {
      throw AppException(
        'No se pudo guardar la factura.',
        technical: e.toString(),
      );
    }
  }

  Future<void> cancel(int invoiceId, {bool restoreStock = true}) async {
    try {
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
              'UPDATE products SET stock = stock + ? WHERE id = ?',
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
    } catch (e) {
      throw AppException(
        'No se pudo anular la factura.',
        technical: e.toString(),
      );
    }
  }

  Future<void> delete(int invoiceId, {bool restoreStock = true}) async {
    try {
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
              'UPDATE products SET stock = stock + ? WHERE id = ?',
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
    } catch (e) {
      throw AppException(
        'No se pudo eliminar la factura.',
        technical: e.toString(),
      );
    }
  }

  Future<void> update(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        final oldItems = await txn.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final item in oldItems) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        }

        await txn.delete(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );

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
            'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      });
    } catch (e) {
      throw AppException(
        'No se pudo actualizar la factura.',
        technical: e.toString(),
      );
    }
  }
}
