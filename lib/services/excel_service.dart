import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../core/app_exception.dart';

/// Servicio para exportar datos a Excel (.xlsx).
class ExcelService {
  static final _date = DateFormat('dd/MM/yyyy HH:mm');

  // ─── Estilos compartidos ────────────────────────────────────────────────────

  static CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A3A2A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle _totalStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#F0F0F0'),
      );

  // ─── Exportar Facturas ──────────────────────────────────────────────────────

  /// Exporta la lista de facturas con sus items a un archivo Excel.
  /// [invoicesWithItems] lista de pares (Invoice, List<InvoiceItem>).
  static Future<bool> exportInvoices(
    List<MapEntry<Invoice, List<InvoiceItem>>> invoicesWithItems,
  ) async {
    try {
      final excel = Excel.createExcel();

      // Hoja resumen de facturas
      final summarySheet = excel['Facturas'];
      _writeInvoiceSummary(summarySheet, invoicesWithItems);

      // Hoja detalle de items
      final detailSheet = excel['Detalle Items'];
      _writeInvoiceDetail(detailSheet, invoicesWithItems);

      // Eliminar la hoja por defecto
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      return await _saveFile(excel, 'facturas');
    } catch (e) {
      throw AppException(
        'No se pudo exportar las facturas a Excel.',
        technical: e.toString(),
      );
    }
  }

  static void _writeInvoiceSummary(
    Sheet sheet,
    List<MapEntry<Invoice, List<InvoiceItem>>> invoicesWithItems,
  ) {
    final headers = [
      '#', 'Cliente', 'Fecha', 'Subtotal', 'Descuento',
      'ITBIS', 'ISR', 'Total', 'Estado Pago', 'Estado',
    ];
    _writeHeaders(sheet, headers);

    double totalSum = 0;
    int row = 1;
    for (final entry in invoicesWithItems) {
      final inv = entry.key;
      final date = _date.format(DateTime.parse(inv.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('#${inv.id.toString().padLeft(4, '0')}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(inv.customerName ?? 'Cliente general');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = DoubleCellValue(inv.subtotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(inv.discountGlobal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = DoubleCellValue(inv.itbis);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = DoubleCellValue(inv.isr);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = DoubleCellValue(inv.total);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = TextCellValue(
            inv.isCancelled ? 'ANULADA' : inv.isPaid ? 'PAGADA' : 'PENDIENTE',
          );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
          .value = TextCellValue(inv.isCancelled ? 'Anulada' : 'Activa');

      if (!inv.isCancelled) totalSum += inv.total;
      row++;
    }

    // Fila de totales
    row++;
    final totalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
    );
    totalCell.value = TextCellValue('TOTAL ACTIVAS:');
    totalCell.cellStyle = _totalStyle();

    final totalAmountCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );
    totalAmountCell.value = DoubleCellValue(totalSum);
    totalAmountCell.cellStyle = _totalStyle();
  }

  static void _writeInvoiceDetail(
    Sheet sheet,
    List<MapEntry<Invoice, List<InvoiceItem>>> invoicesWithItems,
  ) {
    final headers = [
      'Factura #', 'Cliente', 'Producto', 'Cantidad',
      'Precio Unit.', 'Descuento %', 'Subtotal',
    ];
    _writeHeaders(sheet, headers);

    int row = 1;
    for (final entry in invoicesWithItems) {
      final inv = entry.key;
      for (final item in entry.value) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue('#${inv.id.toString().padLeft(4, '0')}');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(inv.customerName ?? 'Cliente general');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(item.productName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = IntCellValue(item.quantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = DoubleCellValue(item.unitPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = DoubleCellValue(item.discountItem);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = DoubleCellValue(item.subtotal);
        row++;
      }
    }
  }

  // ─── Exportar Inventario ────────────────────────────────────────────────────

  static Future<bool> exportInventory(List<Product> products) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventario'];

      final headers = [
        'Nombre', 'Categoría', 'Precio Compra', 'Precio Venta',
        'Stock', 'Stock Mínimo', 'Margen %', 'Estado Stock',
      ];
      _writeHeaders(sheet, headers);

      int row = 1;
      for (final p in products) {
        final margin = p.purchasePrice > 0
            ? ((p.salePrice - p.purchasePrice) / p.purchasePrice * 100)
            : 0.0;
        final stockStatus = p.stock <= 0
            ? 'Sin stock'
            : p.stock <= p.minStock
                ? 'Stock bajo'
                : 'OK';

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(p.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(p.category ?? '—');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = DoubleCellValue(p.purchasePrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(p.salePrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = IntCellValue(p.stock);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = IntCellValue(p.minStock);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = DoubleCellValue(margin.roundToDouble());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(stockStatus);
        row++;
      }

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      return await _saveFile(excel, 'inventario');
    } catch (e) {
      throw AppException(
        'No se pudo exportar el inventario a Excel.',
        technical: e.toString(),
      );
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static void _writeHeaders(Sheet sheet, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle();
    }
  }

  static Future<bool> _saveFile(Excel excel, String baseName) async {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = '${baseName}_$timestamp.xlsx';

    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Excel',
          extensions: ['xlsx'],
        ),
      ],
    );

    if (location == null) return false;

    final bytes = excel.save();
    if (bytes == null) return false;

    await File(location.path).writeAsBytes(bytes);
    return true;
  }
}
