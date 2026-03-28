import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../core/quote_repository.dart';
import '../../core/invoice_repository.dart';
import '../../core/product_repository.dart';
import '../../core/pdf_service.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../models/quote.dart';
import '../../models/quote_item.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../../utils/responsive_helper.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _quoteRepo = QuoteRepository();
  final _invoiceRepo = InvoiceRepository();
  final _searchCtrl = TextEditingController();
  List<Quote> _quotes = [];
  bool _loading = true;

  final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _quoteRepo.getAll()
          : await _quoteRepo.search(query);
      setState(() {
        _quotes = result;
        _loading = false;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _loading = false);
      NotificationService().error(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cotizaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            Text(
              '${_quotes.length} cotizaciones generadas',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openNewQuote,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nueva cotización'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _load,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente...',
          hintStyle: TextStyle(fontSize: 13, color: ThemeHelper.getHintColor(context)),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: ThemeHelper.getHintColor(context)),
          filled: true,
          fillColor: ThemeHelper.getCardColor(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ThemeHelper.getBorderColor(context), width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ThemeHelper.getBorderColor(context), width: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: ThemeHelper.getBorderColor(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay cotizaciones aún',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ThemeHelper.getTextLightColor(context)),
            ),
            const SizedBox(height: 4),
            Text(
              'Presiona "Nueva cotización" para comenzar',
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _quotes.length,
              itemBuilder: (_, i) => _buildRow(_quotes[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: ThemeHelper.getTextLightColor(context),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeHelper.getBorderColor(context))),
      ),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text('Cliente', style: style)),
          Expanded(flex: 2, child: Text('Fecha', style: style)),
          Expanded(flex: 2, child: Text('Vence', style: style)),
          Expanded(flex: 2, child: Text('Total', style: style)),
          Expanded(flex: 2, child: Text('Estado', style: style)),
          SizedBox(width: 160, child: Text('', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(Quote quote, int index) {
    final date = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.parse(quote.createdAt));
    final expiresDate = quote.expiresAt != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(quote.expiresAt!))
        : '—';
    final isEven = index % 2 == 0;

    Color statusColor;
    String statusText;
    if (quote.isConverted) {
      statusColor = const Color(0xFF888780);
      statusText = 'Convertida';
    } else if (quote.isExpired) {
      statusColor = const Color(0xFFE24B4A);
      statusText = 'Expirada';
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusText = 'Vigente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEven ? Colors.transparent : ThemeHelper.getAltRowColor(context),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '#${quote.id.toString().padLeft(4, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              quote.customerName ?? 'Cliente general',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expiresDate,
              style: TextStyle(
                fontSize: 12,
                color: quote.isExpired && !quote.isConverted
                    ? const Color(0xFFE24B4A)
                    : ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(quote.total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _printQuote(quote),
                  icon: const Icon(
                    Icons.print_rounded,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  tooltip: 'Imprimir',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: () => _openEditQuote(quote),
                  icon: const Icon(
                    Icons.visibility_rounded,
                    size: 16,
                    color: AppTheme.accentOrange,
                  ),
                  tooltip: 'Ver detalles',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                if (!quote.isConverted)
                  IconButton(
                    onPressed: () => _convertToInvoice(quote),
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    tooltip: 'Convertir a factura',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                IconButton(
                  onPressed: () => _confirmDelete(quote),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFE24B4A),
                  ),
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openNewQuote() async {
    final products = await ProductRepository().getAll();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewQuoteDialog(
        products: products,
        onSave: (quote, items) async {
          try {
            await _quoteRepo.save(quote, items);
            NotificationService().success('Cotización creada correctamente');
            _load();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
      ),
    );
  }

  void _openEditQuote(Quote quote) async {
    final products = await ProductRepository().getAll();
    final existingItems = await _quoteRepo.getItems(quote.id!);
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewQuoteDialog(
        products: products,
        onSave: (updatedQuote, items) async {
          try {
            final newQuote = quote.copyWith(
              customerName: updatedQuote.customerName,
              subtotal: updatedQuote.subtotal,
              discountGlobal: updatedQuote.discountGlobal,
              total: updatedQuote.total,
              expiresAt: updatedQuote.expiresAt,
            );
            await _quoteRepo.delete(quote.id!);
            await _quoteRepo.save(newQuote, items);
            NotificationService().success('Cotización actualizada correctamente');
            _load();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
        existingQuote: quote,
        existingItems: existingItems,
      ),
    );
  }

  Future<void> _printQuote(Quote quote) async {
    try {
      final items = await _quoteRepo.getItems(quote.id!);
      final pdfBytes = await PdfService.generateQuote(quote, items);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _QuotePreviewScreen(pdfBytes: pdfBytes, quote: quote),
        ),
      );
    } on AppException catch (e) {
      NotificationService().error(e.message);
    }
  }

  void _convertToInvoice(Quote quote) async {
    final items = await _quoteRepo.getItems(quote.id!);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convertir a factura'),
        content: Text(
          '¿Deseas convertir esta cotización en una factura?\n\n'
          'Se creará una factura y se descontará el stock de los productos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeHelper.getTextMediumColor(context)),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final invoice = Invoice(
      customerName: quote.customerName,
      subtotal: quote.subtotal,
      discountGlobal: quote.discountGlobal,
      total: quote.total,
      createdAt: DateTime.now().toIso8601String(),
    );

    final invoiceItems = items.map((item) {
      return InvoiceItem(
        invoiceId: 0,
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountItem: item.discountItem,
        subtotal: item.subtotal,
      );
    }).toList();

    try {
      await _invoiceRepo.save(invoice, invoiceItems);
      await _quoteRepo.markAsConverted(quote.id!);
      NotificationService().success('Cotización convertida a factura');
      if (mounted) _load();
    } on AppException catch (e) {
      NotificationService().error(e.message);
    }
  }

  void _confirmDelete(Quote quote) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: Text(
          '¿Eliminar cotización #${quote.id.toString().padLeft(4, '0')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: ThemeHelper.getTextMediumColor(context)),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _quoteRepo.delete(quote.id!);
                NotificationService().success('Cotización eliminada');
                _load();
              } on AppException catch (e) {
                NotificationService().error(e.message);
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFE24B4A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotePreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final Quote quote;

  const _QuotePreviewScreen({required this.pdfBytes, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: PdfPreview(
              build: (_) => pdfBytes,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName:
                  'cotizacion_${quote.id.toString().padLeft(4, '0')}.pdf',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        border: Border(
          bottom: BorderSide(color: ThemeHelper.getBorderColor(context), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            color: ThemeHelper.getTextMediumColor(context),
            tooltip: 'Volver',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          Text(
            'Vista previa — Cotización #${quote.id.toString().padLeft(4, '0')}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              await Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    'cotizacion_${quote.id.toString().padLeft(4, '0')}.pdf',
              );
            },
            icon: const Icon(Icons.save_alt_rounded, size: 16),
            label: const Text('Guardar PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewQuoteDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Quote, List<QuoteItem>) onSave;
  final Quote? existingQuote;
  final List<QuoteItem> existingItems;

  const _NewQuoteDialog({
    required this.products,
    required this.onSave,
    this.existingQuote,
    this.existingItems = const [],
  });

  @override
  State<_NewQuoteDialog> createState() => _NewQuoteDialogState();
}

class _NewQuoteDialogState extends State<_NewQuoteDialog> {
  final _customerCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  final List<Map<String, dynamic>> _items = [];
  List<Product> _filteredProducts = [];
  bool _showProductList = true;

  final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;

    if (widget.existingQuote != null) {
      _customerCtrl.text = widget.existingQuote!.customerName ?? '';
      _discountCtrl.text = widget.existingQuote!.discountGlobal > 0
          ? widget.existingQuote!.discountGlobal.toStringAsFixed(0)
          : '';
      if (widget.existingQuote!.expiresAt != null) {
        _expiresAt = DateTime.parse(widget.existingQuote!.expiresAt!);
      }

      for (final item in widget.existingItems) {
        _items.add({
          'product': widget.products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => Product(
              id: item.productId,
              name: item.productName,
              purchasePrice: 0,
              salePrice: item.unitPrice,
              stock: 0,
              createdAt: '',
            ),
          ),
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discount': item.discountItem,
        });
      }
    }
  }

  double get _subtotal => _items.fold(0, (sum, item) {
    final price = (item['unitPrice'] as double);
    final qty = (item['quantity'] as int);
    final discPct = (item['discount'] as double);
    final discAmount = price * (discPct / 100);
    return sum + ((price - discAmount) * qty);
  });

  double get _globalDiscount {
    final pct = double.tryParse(_discountCtrl.text) ?? 0;
    return _subtotal * (pct / 100);
  }

  double get _total => _subtotal - _globalDiscount;

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = widget.products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addProduct(Product p) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductConfigDialog(product: p, currency: _currency),
    );

    if (result != null) {
      setState(() {
        _items.add({
          'product': p,
          'quantity': result['quantity'],
          'unitPrice': result['unitPrice'],
          'discount': result['discount'],
        });
      });
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  void _save() {
    if (_items.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    final quote = Quote(
      customerName: _customerCtrl.text.trim().isEmpty
          ? null
          : _customerCtrl.text.trim(),
      subtotal: _subtotal,
      discountGlobal: _globalDiscount,
      total: _total,
      createdAt: DateTime.now().toIso8601String(),
      expiresAt: _expiresAt.toIso8601String(),
    );

    final items = _items.map((item) {
      final p = item['product'] as Product;
      final price = item['unitPrice'] as double;
      final qty = item['quantity'] as int;
      final disc = item['discount'] as double;
      return QuoteItem(
        quoteId: 0,
        productId: p.id!,
        productName: p.name,
        quantity: qty,
        unitPrice: price,
        discountItem: disc,
        subtotal: (price * (1 - disc / 100)) * qty,
      );
    }).toList();

    widget.onSave(quote, items);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Form(
        key: _formKey,
        child: SizedBox(
          width: 700,
          height: 580,
          child: Column(
            children: [
              _buildDialogHeader(),
              Expanded(
                child: Row(children: [_buildLeftPanel(), _buildRightPanel()]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text(
            widget.existingQuote != null
                ? 'Editar cotización'
                : 'Nueva cotización',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _customerCtrl,
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
              decoration: InputDecoration(
                labelText: 'Nombre del cliente (opcional)',
                labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Válida hasta',
                        labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_expiresAt),
                            style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                    decoration: InputDecoration(
                      labelText: 'Desc. %',
                      labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null) return 'Número inválido';
                      if (n < 0 || n > 100) return '0 - 100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Productos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              onChanged: _filterProducts,
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                hintStyle: TextStyle(fontSize: 12, color: ThemeHelper.getHintColor(context)),
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _showProductList || _searchCtrl.text.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ThemeHelper.getBorderColor(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (_, i) {
                          final p = _filteredProducts[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              p.name,
                              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                            ),
                            subtitle: Text(
                              '${_currency.format(p.salePrice)} - Stock: ${p.stock}',
                              style: TextStyle(fontSize: 11, color: ThemeHelper.getTextMediumColor(context)),
                            ),
                            onTap: p.stock > 0 ? () => _addProduct(p) : null,
                          );
                        },
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.getAltRowColor(context),
          border: Border(left: BorderSide(color: ThemeHelper.getBorderColor(context))),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items de la cotización',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'Agrega productos',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.getTextLightColor(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final p = item['product'] as Product;
                        final qty = item['quantity'] as int;
                        final price = item['unitPrice'] as double;
                        final disc = item['discount'] as double;
                        final subtotal = (price * (1 - disc / 100)) * qty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeHelper.getCardColor(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ThemeHelper.getBorderColor(context)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$qty x ${_currency.format(price)}'
                                      '${disc > 0 ? ' (-${disc.toStringAsFixed(0)}%)' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ThemeHelper.getTextLightColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _currency.format(subtotal),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _removeItem(i),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFFE24B4A),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            _buildSummaryRow('Subtotal', _subtotal),
            if (_globalDiscount > 0)
              _buildSummaryRow('Descuento', -_globalDiscount, isDiscount: true),
            _buildSummaryRow('Total', _total, isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _items.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Guardar cotización'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isDiscount
                  ? const Color(0xFFE24B4A)
                  : ThemeHelper.getTextMediumColor(context),
            ),
          ),
          Text(
            isDiscount
                ? '- ${_currency.format(amount.abs())}'
                : _currency.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isDiscount
                  ? const Color(0xFFE24B4A)
                  : ThemeHelper.getTextMediumColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductConfigDialog extends StatefulWidget {
  final Product product;
  final NumberFormat currency;

  const _ProductConfigDialog({required this.product, required this.currency});

  @override
  State<_ProductConfigDialog> createState() => _ProductConfigDialogState();
}

class _ProductConfigDialogState extends State<_ProductConfigDialog> {
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(text: '1');
    _priceCtrl = TextEditingController(
      text: widget.product.salePrice.toStringAsFixed(0),
    );
    _discountCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _subtotal {
    final qty = int.tryParse(_quantityCtrl.text) ?? 1;
    final price = double.tryParse(_priceCtrl.text) ?? widget.product.salePrice;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    return (price * (1 - disc / 100)) * qty;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              Text(
                'Stock disponible: ${widget.product.stock}',
                style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        labelStyle: TextStyle(fontSize: 11, color: ThemeHelper.getTextMediumColor(context)),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Mín. 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Desc. %',
                        labelStyle: TextStyle(fontSize: 11, color: ThemeHelper.getTextMediumColor(context)),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null) return 'Inválido';
                        if (n < 0 || n > 100) return '0 - 100';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Precio unitario',
                  labelStyle: TextStyle(fontSize: 11, color: ThemeHelper.getTextMediumColor(context)),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null) return 'Ingresa un precio válido';
                  if (n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeHelper.getAltRowColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    Text(
                      widget.currency.format(_subtotal),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: ThemeHelper.getTextMediumColor(context)),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(context, {
                        'quantity': int.parse(_quantityCtrl.text),
                        'unitPrice': double.parse(_priceCtrl.text),
                        'discount': double.parse(_discountCtrl.text),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Agregar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
