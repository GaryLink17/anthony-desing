import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import 'dart:typed_data';

class PdfService {
  static Future<void> generateAndPrint(
    Invoice invoice,
    List<InvoiceItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Leer datos de configuración
    final companyName = prefs.getString('company_name') ?? 'Mi Negocio';
    final companyPhone = prefs.getString('company_phone') ?? '';
    final companyRnc = prefs.getString('company_rnc') ?? '';
    final companyAddress = prefs.getString('company_address') ?? '';
    final companyEmail = prefs.getString('company_email') ?? '';
    final logoPath = prefs.getString('company_logo');
    final footerMessage =
        prefs.getString('footer_message') ?? '¡Gracias por su compra!';
    final footerTerms = prefs.getString('footer_terms') ?? '';

    final currency = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$ ',
      decimalDigits: 0,
    );

    // Cargar logo si existe
    pw.ImageProvider? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabecera
            _buildHeader(
              companyName,
              companyPhone,
              companyRnc,
              companyAddress,
              companyEmail,
              logoImage,
              invoice,
              currency,
            ),
            pw.SizedBox(height: 24),
            // Tabla de productos
            _buildItemsTable(items, currency),
            pw.SizedBox(height: 16),
            // Totales
            _buildTotals(invoice, currency),
            pw.Spacer(),
            // Pie de página
            _buildFooter(footerMessage, footerTerms),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.Widget _buildHeader(
    String companyName,
    String companyPhone,
    String companyRnc,
    String companyAddress,
    String companyEmail,
    pw.ImageProvider? logo,
    Invoice invoice,
    NumberFormat currency,
  ) {
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.parse(invoice.createdAt));

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo y datos del negocio
        pw.Row(
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (companyRnc.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'RNC: $companyRnc',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
                if (companyAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    companyAddress,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
                if (companyEmail.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    companyEmail,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
                if (companyPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Tel: $companyPhone',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ],
            ),
          ],
        ),
        // Número y fecha de factura
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'FACTURA',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '#${invoice.id.toString().padLeft(4, '0')}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              date,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            if (invoice.customerName != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Cliente: ${invoice.customerName}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
            if (invoice.customerRnc != null && invoice.customerRnc!.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'RNC: ${invoice.customerRnc}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    List<InvoiceItem> items,
    NumberFormat currency,
  ) {
    const headerStyle = pw.TextStyle(color: PdfColors.white, fontSize: 11);

    const cellStyle = pw.TextStyle(fontSize: 11);

    const headerColor = PdfColor.fromInt(0xFF1a3a2a);
    const evenColor = PdfColor.fromInt(0xFFF8F7F4);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: [
            _cell('Producto', headerStyle),
            _cell('Cant.', headerStyle, center: true),
            _cell('Precio unit.', headerStyle, center: true),
            _cell('Desc.', headerStyle, center: true),
            _cell('Subtotal', headerStyle, right: true),
          ],
        ),
        // Filas de productos
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isEven = i % 2 == 0;
          final discAmount = item.unitPrice * (item.discountItem / 100);
          final lineTotal = (item.unitPrice - discAmount) * item.quantity;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : evenColor,
            ),
            children: [
              _cell(item.productName, cellStyle),
              _cell('${item.quantity}', cellStyle, center: true),
              _cell(currency.format(item.unitPrice), cellStyle, center: true),
              _cell(
                item.discountItem > 0
                    ? '${item.discountItem.toStringAsFixed(0)}%'
                    : '-',
                cellStyle,
                center: true,
              ),
              _cell(currency.format(lineTotal), cellStyle, right: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotals(Invoice invoice, NumberFormat currency) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', currency.format(invoice.subtotal)),
            if (invoice.discountGlobal > 0)
              _totalRow(
                'Descuento (${invoice.subtotal > 0 ? (invoice.discountGlobal / invoice.subtotal * 100).toStringAsFixed(0) : '0'}%)',
                '- ${currency.format(invoice.discountGlobal)}',
                color: PdfColors.red700,
              ),
            if (invoice.itbis > 0)
              _totalRow(
                'ITBIS (18%)',
                '+ ${currency.format(invoice.itbis)}',
                color: PdfColors.blue700,
              ),
            if (invoice.isr > 0)
              _totalRow(
                'Retención ISR (1%)',
                '- ${currency.format(invoice.isr)}',
                color: PdfColors.orange700,
              ),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              'TOTAL',
              currency.format(invoice.total),
              bold: true,
              large: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(String message, String terms) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            message,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          if (terms.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              terms,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool center = false,
    bool right = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: style,
        textAlign: right
            ? pw.TextAlign.right
            : center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontSize: large ? 13 : 11,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static Future<Uint8List> generate(
    Invoice invoice,
    List<InvoiceItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final companyName = prefs.getString('company_name') ?? 'Mi Negocio';
    final companyPhone = prefs.getString('company_phone') ?? '';
    final companyRnc = prefs.getString('company_rnc') ?? '';
    final companyAddress = prefs.getString('company_address') ?? '';
    final companyEmail = prefs.getString('company_email') ?? '';
    final logoPath = prefs.getString('company_logo');
    final footerMessage =
        prefs.getString('footer_message') ?? '¡Gracias por su compra!';
    final footerTerms = prefs.getString('footer_terms') ?? '';

    final currency = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$ ',
      decimalDigits: 0,
    );

    pw.ImageProvider? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(
              companyName,
              companyPhone,
              companyRnc,
              companyAddress,
              companyEmail,
              logoImage,
              invoice,
              currency,
            ),
            pw.SizedBox(height: 24),
            _buildItemsTable(items, currency),
            pw.SizedBox(height: 16),
            _buildTotals(invoice, currency),
            pw.Spacer(),
            _buildFooter(footerMessage, footerTerms),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateQuote(
    Quote quote,
    List<QuoteItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final companyName = prefs.getString('company_name') ?? 'Mi Negocio';
    final companyPhone = prefs.getString('company_phone') ?? '';
    final companyRnc = prefs.getString('company_rnc') ?? '';
    final companyAddress = prefs.getString('company_address') ?? '';
    final companyEmail = prefs.getString('company_email') ?? '';
    final logoPath = prefs.getString('company_logo');
    final footerMessage = prefs.getString('footer_message') ?? '¡Gracias por su preferencia!';
    final footerTerms = prefs.getString('footer_terms') ?? '';

    final currency = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$ ',
      decimalDigits: 0,
    );

    pw.ImageProvider? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildQuoteHeader(companyName, companyPhone, companyRnc, companyAddress, companyEmail, logoImage, quote, currency),
            pw.SizedBox(height: 24),
            _buildQuoteItemsTable(items, currency),
            pw.SizedBox(height: 16),
            _buildQuoteTotals(quote, currency),
            pw.Spacer(),
            _buildQuoteFooter(footerMessage, footerTerms, quote),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildQuoteHeader(
    String companyName,
    String companyPhone,
    String companyRnc,
    String companyAddress,
    String companyEmail,
    pw.ImageProvider? logo,
    Quote quote,
    NumberFormat currency,
  ) {
    final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(quote.createdAt));
    final expiresDate = quote.expiresAt != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(quote.expiresAt!))
        : 'N/A';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (companyRnc.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'RNC: $companyRnc',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
                if (companyAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    companyAddress,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
                if (companyEmail.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    companyEmail,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
                if (companyPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Tel: $companyPhone',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'COTIZACIÓN',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '#${quote.id.toString().padLeft(4, '0')}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Fecha: $date',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Válida hasta: $expiresDate',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            if (quote.customerName != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Cliente: ${quote.customerName}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
            if (quote.customerRnc != null && quote.customerRnc!.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'RNC: ${quote.customerRnc}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildQuoteItemsTable(
    List<QuoteItem> items,
    NumberFormat currency,
  ) {
    const headerStyle = pw.TextStyle(color: PdfColors.white, fontSize: 11);
    const cellStyle = pw.TextStyle(fontSize: 11);
    const headerColor = PdfColor.fromInt(0xFF1B3A6B);
    const evenColor = PdfColor.fromInt(0xFFF8F7F4);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: [
            _cell('Producto', headerStyle),
            _cell('Cant.', headerStyle, center: true),
            _cell('Precio unit.', headerStyle, center: true),
            _cell('Desc.', headerStyle, center: true),
            _cell('Subtotal', headerStyle, right: true),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isEven = i % 2 == 0;
          final discAmount = item.unitPrice * (item.discountItem / 100);
          final lineTotal = (item.unitPrice - discAmount) * item.quantity;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : evenColor,
            ),
            children: [
              _cell(item.productName, cellStyle),
              _cell('${item.quantity}', cellStyle, center: true),
              _cell(currency.format(item.unitPrice), cellStyle, center: true),
              _cell(
                item.discountItem > 0
                    ? '${item.discountItem.toStringAsFixed(0)}%'
                    : '-',
                cellStyle,
                center: true,
              ),
              _cell(currency.format(lineTotal), cellStyle, right: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildQuoteTotals(Quote quote, NumberFormat currency) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', currency.format(quote.subtotal)),
            if (quote.discountGlobal > 0)
              _totalRow(
                'Descuento (${quote.subtotal > 0 ? (quote.discountGlobal / quote.subtotal * 100).toStringAsFixed(0) : '0'}%)',
                '- ${currency.format(quote.discountGlobal)}',
                color: PdfColors.red700,
              ),
            if (quote.itbis > 0)
              _totalRow(
                'ITBIS (18%)',
                '+ ${currency.format(quote.itbis)}',
                color: PdfColors.blue700,
              ),
            if (quote.isr > 0)
              _totalRow(
                'Retención ISR (1%)',
                '- ${currency.format(quote.isr)}',
                color: PdfColors.orange700,
              ),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              'TOTAL',
              currency.format(quote.total),
              bold: true,
              large: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildQuoteFooter(
    String message,
    String terms,
    Quote quote,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            message,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          if (terms.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              terms,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
