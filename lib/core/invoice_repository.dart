import 'database.dart';
import 'app_exception.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

/// Repositorio para operaciones CRUD de facturas y sus líneas de detalle.
class InvoiceRepository {
  final _db = DatabaseHelper.instance;

  /// Obtiene todas las facturas ordenadas por fecha descendente.
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

  /// Actualiza solo el estado de pago de una factura.
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

  /// Busca facturas por nombre de cliente.
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

  /// Obtiene las líneas de detalle (items) de una factura.
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

  /// Obtiene una factura por su ID, o null si no existe.
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

  /// Guarda una nueva factura junto con sus items en una transacción.
  /// Descuenta automáticamente el stock de los productos vendidos.
  Future<int> save(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final db = await _db.database;
      return await db.transaction((txn) async {
        final invoiceId = await txn.insert('invoices', {
          'customer_name': invoice.customerName,
          // 'customer_rnc': invoice.customerRnc, // RNC deshabilitado
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

  /// Anula una factura (status = 'cancelled') y opcionalmente restaura el stock.
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

  /// Elimina permanentemente una factura y sus items, con opción a restaurar stock.
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

  /// Actualiza una factura existente: restaura stock anterior,
  /// reemplaza items y descuenta el nuevo stock, todo en una transacción.
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
            // 'customer_rnc': invoice.customerRnc, // RNC deshabilitado
            'subtotal': invoice.subtotal,
            'discount_global': invoice.discountGlobal,
            'total': invoice.total,
            'status': invoice.status,
            'payment_status': invoice.paymentStatus,
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
