import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../core/invoice_repository.dart';
import '../../core/product_repository.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../../core/pdf_service.dart';
import '../../widgets/state_builder.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../services/document_totals_service.dart';
import '../../services/tax_service.dart';
import '../../services/excel_service.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/performance_helpers.dart';
import '../../widgets/documents/document_summary_rows.dart';
import 'invoice_preview_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _invoiceRepo = InvoiceRepository();
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer();
  List<Invoice> _invoices = [];
  bool _loading = true;

  static final _currency = NumberFormat.currency(
    locale: 'en_US',
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
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _printInvoice(Invoice inv) async {
    try {
      final items = await _invoiceRepo.getItems(inv.id!);
      final pdfBytes = await PdfService.generate(inv, items);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePreviewScreen(pdfBytes: pdfBytes, invoice: inv),
        ),
      );
    } on AppException catch (e) {
      NotificationService().error(e.message);
    }
  }

  Future<void> _exportExcel() async {
    try {
      final invoicesWithItems = <MapEntry<Invoice, List<InvoiceItem>>>[];
      for (final inv in _invoices) {
        final items = await _invoiceRepo.getItems(inv.id!);
        invoicesWithItems.add(MapEntry(inv, items));
      }
      final saved = await ExcelService.exportInvoices(invoicesWithItems);
      if (saved && mounted) {
        NotificationService().success('Archivo Excel exportado correctamente');
      }
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    }
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _invoiceRepo.getAll()
          : await _invoiceRepo.search(query);
      if (mounted) {
        setState(() {
          _invoices = result;
          _loading = false;
        });
      }
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
              'Facturas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            Text(
              '${_invoices.length} facturas generadas',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _invoices.isEmpty ? null : _exportExcel,
              icon: const Icon(Icons.table_chart_rounded, size: 16),
              label: const Text('Excel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF217346),
                side: const BorderSide(color: Color(0xFF217346)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openNewInvoice,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva factura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentMagenta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (q) => _debouncer(() => _load(q)),
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
    return StateBuilder(
      isLoading: _loading,
      isEmpty: _invoices.isEmpty,
      icon: Icons.receipt_long_outlined,
      emptyTitle: 'No hay facturas aún',
      emptyDescription: 'Presiona "Nueva factura" para comenzar',
      child: Container(
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
                itemCount: _invoices.length,
                itemBuilder: (_, i) => _buildRow(_invoices[i], i),
              ),
            ),
          ],
        ),
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
          SizedBox(width: 90, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text('Cliente', style: style)),
          Expanded(flex: 2, child: Text('Fecha', style: style)),
          Expanded(flex: 2, child: Text('Subtotal', style: style)),
          Expanded(flex: 2, child: Text('Descuento', style: style)),
          Expanded(flex: 2, child: Text('Total', style: style)),
          SizedBox(width: 140, child: Text('', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(Invoice inv, int index) {
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.parse(inv.createdAt));
    final isEven = index % 2 == 0;
    final isCancelled = inv.isCancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isCancelled
          ? ThemeHelper.getErrorLightBg(context).withValues(alpha: 0.3)
          : isEven
          ? Colors.transparent
          : ThemeHelper.getAltRowColor(context),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${inv.id.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.getTextLightColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFE24B4A)
                        : inv.isPaid
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isCancelled ? 'ANULADA' : inv.isPaid ? 'PAGADA' : 'PENDIENTE',
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              inv.customerName ?? 'Cliente general',
              style: TextStyle(
                fontSize: 13,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextColor(context),
                decoration: isCancelled
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(inv.subtotal),
              style: TextStyle(
                fontSize: 12,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextMediumColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              inv.discountGlobal > 0
                  ? '- ${_currency.format(inv.discountGlobal)}'
                  : '—',
              style: TextStyle(
                fontSize: 12,
                color: inv.discountGlobal > 0
                    ? ThemeHelper.getErrorTextColor(context)
                    : ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(inv.total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextColor(context),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Row(
              children: [
                IconButton(
                  onPressed: isCancelled ? null : () => _printInvoice(inv),
                  icon: Icon(
                    Icons.print_rounded,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : AppTheme.primaryBlue,
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Imprimir',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: isCancelled ? null : () => _openEditInvoice(inv),
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : AppTheme.accentOrange,
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Editar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: isCancelled ? null : () => _togglePaymentStatus(inv),
                  icon: Icon(
                    inv.isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : inv.isPaid
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                  ),
                  tooltip: isCancelled
                      ? 'Factura anulada'
                      : inv.isPaid
                          ? 'Marcar como pendiente'
                          : 'Marcar como pagada',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: isCancelled ? null : () => _confirmCancel(inv),
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : const Color(0xFFE24B4A),
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Anular',
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

  Future<void> _togglePaymentStatus(Invoice inv) async {
    final newStatus = inv.isPaid ? 'pending' : 'paid';
    try {
      await _invoiceRepo.updatePaymentStatus(inv.id!, newStatus);
      await _load(_searchCtrl.text);
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    }
  }

  void _confirmCancel(Invoice inv) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Anular factura',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.white.withAlpha(200),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Anular la factura #${inv.id.toString().padLeft(4, '0')}?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La factura quedará registrada pero marcada como anulada y no se incluirá en los reportes.',
                      style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Desea reponer el stock de los productos?',
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextMediumColor(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seleccione "Sí" si el cliente devolvió los productos.',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeHelper.getAltRowColor(context),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeHelper.getTextLightColor(context),
                          side: BorderSide(color: ThemeHelper.getBorderColor(context)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await _invoiceRepo.cancel(inv.id!, restoreStock: false);
                            NotificationService().success('Factura anulada');
                            if (mounted) { Navigator.pop(context); _load(); }
                          } on AppException catch (e) {
                            if (mounted) Navigator.pop(context);
                            NotificationService().error(e.message);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE24B4A),
                          side: const BorderSide(color: Color(0xFFE24B4A)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('No reponer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _invoiceRepo.cancel(inv.id!, restoreStock: true);
                            NotificationService().success('Factura anulada');
                            if (mounted) { Navigator.pop(context); _load(); }
                          } on AppException catch (e) {
                            if (mounted) Navigator.pop(context);
                            NotificationService().error(e.message);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Sí, reponer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewInvoice() async {
    final products = await ProductRepository().getAll();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewInvoiceDialog(
        products: products,
        onSave: (invoice, items) async {
          try {
            await _invoiceRepo.save(invoice, items);
            NotificationService().success('Factura creada correctamente');
            _load();
            _checkLowStock(items.map((i) => i.productId).toList());
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
      ),
    );
  }

  Future<void> _checkLowStock(List<int> productIds) async {
    try {
      final lowStock =
          await ProductRepository().getLowStockForProducts(productIds);
      if (lowStock.isEmpty) return;

      final names = lowStock.map((p) => p.name).take(3).join(', ');
      final extra = lowStock.length > 3 ? ' y ${lowStock.length - 3} más' : '';
      NotificationService().warning(
        'Stock bajo: $names$extra',
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      // No interrumpir el flujo principal si falla la verificación de stock
      debugPrint('[InvoicesScreen] _checkLowStock falló: $e');
    }
  }

  void _openEditInvoice(Invoice inv) async {
    final products = await ProductRepository().getAll();
    final existingItems = await _invoiceRepo.getItems(inv.id!);
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewInvoiceDialog(
        products: products,
        onSave: (updatedInvoice, items) async {
          try {
            final invoiceWithId = inv.copyWith(
              customerName: updatedInvoice.customerName,
              customerRnc: updatedInvoice.customerRnc,
              subtotal: updatedInvoice.subtotal,
              discountGlobal: updatedInvoice.discountGlobal,
              itbis: updatedInvoice.itbis,
              isr: updatedInvoice.isr,
              total: updatedInvoice.total,
            );
            await _invoiceRepo.update(invoiceWithId, items);
            NotificationService().success('Factura actualizada correctamente');
            _load();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
        existingInvoice: inv,
        existingItems: existingItems,
      ),
    );
  }
}

class _NewInvoiceDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Invoice, List<InvoiceItem>) onSave;
  final Invoice? existingInvoice;
  final List<InvoiceItem> existingItems;

  const _NewInvoiceDialog({
    required this.products,
    required this.onSave,
    this.existingInvoice,
    this.existingItems = const [],
  });

  @override
  State<_NewInvoiceDialog> createState() => _NewInvoiceDialogState();
}

class _NewInvoiceDialogState extends State<_NewInvoiceDialog> {
  String _customerName = '';
  String? _customerRnc;
  final _discountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Cada item: {product, quantity, unitPrice, discount}
  final List<Map<String, dynamic>> _items = [];
  List<Product> _filteredProducts = [];
  final bool _showProductList = true;

  TaxConfig _taxConfig = const TaxConfig(
    applyItbis: false,
    itbisRate: TaxService.defaultItbisRate,
    applyIsr: false,
    isrRate: TaxService.defaultIsrRate,
  );

  static final _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
    _loadTaxConfig();

    // Si es edición cargamos los datos existentes
    if (widget.existingInvoice != null) {
      _customerName = widget.existingInvoice!.customerName ?? '';
      _discountCtrl.text = widget.existingInvoice!.discountGlobal > 0
          ? widget.existingInvoice!.discountGlobal.toStringAsFixed(0)
          : '';

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

  Future<void> _loadTaxConfig() async {
    final config = await TaxService.getConfig();
    if (mounted) setState(() => _taxConfig = config);
  }

  DocumentTotals get _totals => DocumentTotalsService.calculateFromItems(
    items: _items,
    discountPercent: double.tryParse(_discountCtrl.text) ?? 0,
    taxConfig: _taxConfig,
  );

  double get _subtotal => _totals.subtotal;
  double get _globalDiscount => _totals.discountAmount;
  TaxResult get _taxResult => _totals.taxResult;

  double get _itbis => _taxResult.itbis;
  double get _isr => _taxResult.isr;

  // Total final (base + ITBIS - ISR)
  double get _total => _taxResult.total;

  // Filtrar productos según búsqueda
  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = widget.products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Agregar producto a la lista de items
  void _addProduct(Product p) async {
    if (p.stock <= 0) return;

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

  bool _validateStock() {
    for (final item in _items) {
      final p = item['product'] as Product;
      final qty = item['quantity'] as int;
      if (qty > p.stock) {
        return false;
      }
    }
    return true;
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _save() {
    if (_items.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_validateStock()) {
      NotificationService().error('No hay stock suficiente para algunos productos');
      return;
    }

    final invoice = Invoice(
      customerName: _customerName.trim().isEmpty
          ? null
          : _customerName.trim(),
      customerRnc: _customerRnc,
      subtotal: _subtotal,
      discountGlobal: _globalDiscount,
      itbis: _itbis,
      isr: _isr,
      total: _total,
      createdAt: DateTime.now().toIso8601String(),
    );

    final items = _items.map((item) {
      final p = item['product'] as Product;
      final price = item['unitPrice'] as double;
      final qty = item['quantity'] as int;
      final disc = item['discount'] as double;
      return InvoiceItem(
        invoiceId: 0,
        productId: p.id!,
        productName: p.name,
        quantity: qty,
        unitPrice: price,
        discountItem: disc,
        subtotal: (price * (1 - disc / 100)) * qty,
      );
    }).toList();

    widget.onSave(invoice, items);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeHelper.getCardColor(context),
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
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        border: Border(
          bottom: BorderSide(color: ThemeHelper.getBorderColor(context)),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.existingInvoice != null ? 'Editar factura' : 'Nueva factura',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: ThemeHelper.getTextLightColor(context),
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
              controller: TextEditingController(text: _customerName),
              onChanged: (v) => _customerName = v,
              style: TextStyle(
                fontSize: 13,
                color: ThemeHelper.getTextColor(context),
              ),
              decoration: InputDecoration(
                labelText: 'Nombre del cliente (opcional)',
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.getTextMediumColor(context),
                ),
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
                const Spacer(),
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
              'Items de la factura',
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
            TaxToggleRow(
              label: 'ITBIS ${_taxConfig.itbisRate.toStringAsFixed(0)}%',
              value: _taxConfig.applyItbis,
              onChanged: (v) => setState(
                () => _taxConfig = _taxConfig.copyWith(applyItbis: v),
              ),
              color: Colors.blue.shade700,
              formattedAmount: '+ ${_currency.format(_itbis.abs())}',
            ),
            TaxToggleRow(
              label: 'ISR ${_taxConfig.isrRate.toStringAsFixed(0)}% (ret.)',
              value: _taxConfig.applyIsr,
              onChanged: (v) => setState(
                () => _taxConfig = _taxConfig.copyWith(applyIsr: v),
              ),
              color: Colors.orange.shade700,
              formattedAmount: '- ${_currency.format(_isr.abs())}',
            ),
            const Divider(height: 8),
            _buildSummaryRow('Total', _total, isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _items.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMagenta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Confirmar factura'),
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
    return DocumentSummaryRow(
      label: label,
      formattedAmount: isDiscount
          ? '- ${_currency.format(amount.abs())}'
          : _currency.format(amount),
      isDiscount: isDiscount,
      isTotal: isTotal,
      textColor: ThemeHelper.getTextMediumColor(context),
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
                        if (n > widget.product.stock) return 'Stock: ${widget.product.stock}';
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
                        final text = v?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final n = double.tryParse(text);
                        if (n == null) return 'Número inválido';
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
                        'discount': double.tryParse(_discountCtrl.text) ?? 0,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentMagenta,
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
