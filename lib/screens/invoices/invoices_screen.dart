import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/invoice_repository.dart';
import '../../core/product_repository.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../../core/pdf_service.dart';
import '../../app.dart';
import 'invoice_preview_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _invoiceRepo = InvoiceRepository();
  List<Invoice> _invoices = [];
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

  Future<void> _printInvoice(Invoice inv) async {
    final items = await _invoiceRepo.getItems(inv.id!);
    final pdfBytes = await PdfService.generate(inv, items);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(pdfBytes: pdfBytes, invoice: inv),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _invoiceRepo.getAll();
    setState(() {
      _invoices = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
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
            const Text(
              'Facturas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2A),
              ),
            ),
            Text(
              '${_invoices.length} facturas generadas',
              style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
          ],
        ),
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
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay facturas aún',
              style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Presiona "Nueva factura" para comenzar',
              style: TextStyle(fontSize: 12, color: Color(0xFFB4B2A9)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
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
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFF888780),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12000000))),
      ),
      child: const Row(
        children: [
          SizedBox(width: 70, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text('Cliente', style: style)),
          Expanded(flex: 2, child: Text('Fecha', style: style)),
          Expanded(flex: 2, child: Text('Subtotal', style: style)),
          Expanded(flex: 2, child: Text('Descuento', style: style)),
          Expanded(flex: 2, child: Text('Total', style: style)),
          SizedBox(width: 110, child: Text('', style: style)),
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
          ? const Color(0xFFFCEBEB).withOpacity(0.3)
          : isEven
          ? Colors.transparent
          : const Color(0xFFFAFAF8),
      child: Row(
        children: [
          SizedBox(
            width: isCancelled ? 90 : 70,
            child: isCancelled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${inv.id.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB4B2A9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ANULADA',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '#${inv.id.toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888780),
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              inv.customerName ?? 'Cliente general',
              style: TextStyle(
                fontSize: 13,
                color: isCancelled
                    ? const Color(0xFFB4B2A9)
                    : const Color(0xFF2C2C2A),
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
                    ? const Color(0xFFB4B2A9)
                    : const Color(0xFF888780),
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
                    ? const Color(0xFFB4B2A9)
                    : const Color(0xFF444441),
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
                    ? const Color(0xFFA32D2D)
                    : const Color(0xFFB4B2A9),
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
                    ? const Color(0xFFB4B2A9)
                    : const Color(0xFF2C2C2A),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              children: [
                IconButton(
                  onPressed: isCancelled ? null : () => _printInvoice(inv),
                  icon: Icon(
                    Icons.print_rounded,
                    size: 16,
                    color: isCancelled
                        ? const Color(0xFFB4B2A9)
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
                        ? const Color(0xFFB4B2A9)
                        : AppTheme.accentOrange,
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Editar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: isCancelled ? null : () => _confirmCancel(inv),
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: isCancelled
                        ? const Color(0xFFB4B2A9)
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La factura quedará registrada pero marcada como anulada y no se incluirá en los reportes.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¿Desea reponer el stock de los productos?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF444441)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Seleccione "Sí" si el cliente devolvió los productos.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF888780)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAF8),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF888780),
                          side: const BorderSide(color: Color(0xFFB4B2A9)),
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
                          await _invoiceRepo.cancel(
                            inv.id!,
                            restoreStock: false,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
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
                          await _invoiceRepo.cancel(
                            inv.id!,
                            restoreStock: true,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
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
          await _invoiceRepo.save(invoice, items);
          _load();
        },
      ),
    );
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
          final invoiceWithId = Invoice(
            id: inv.id,
            customerName: updatedInvoice.customerName,
            subtotal: updatedInvoice.subtotal,
            discountGlobal: updatedInvoice.discountGlobal,
            total: updatedInvoice.total,
            createdAt: inv.createdAt,
          );
          await _invoiceRepo.update(invoiceWithId, items);
          _load();
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
  final _customerCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // Cada item: {product, quantity, unitPrice, discount}
  final List<Map<String, dynamic>> _items = [];
  List<Product> _filteredProducts = [];
  bool _showProductList = false;

  final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;

    // Si es edición cargamos los datos existentes
    if (widget.existingInvoice != null) {
      _customerCtrl.text = widget.existingInvoice!.customerName ?? '';
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

  // Cálculos de resumen
  double get _subtotal => _items.fold(0, (sum, item) {
    final price = (item['unitPrice'] as double);
    final qty = (item['quantity'] as int);
    final discPct = (item['discount'] as double);
    final discAmount = price * (discPct / 100);
    return sum + ((price - discAmount) * qty);
  });

  // Descuento global en RD$
  double get _globalDiscount {
    final pct = double.tryParse(_discountCtrl.text) ?? 0;
    return _subtotal * (pct / 100);
  }

  // Total a pagar después de descuentos
  double get _total => _subtotal - _globalDiscount;

  // Filtrar productos según búsqueda
  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = widget.products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Agregar producto a la lista de items
  void _addProduct(Product p) {
    if (p.stock <= 0) return;

    setState(() {
      final existing = _items.indexWhere((i) => i['product'].id == p.id);
      if (existing >= 0) {
        final currentQty = _items[existing]['quantity'] as int;
        if (currentQty < p.stock) {
          _items[existing]['quantity']++;
        }
      } else {
        _items.add({
          'product': p,
          'quantity': 1,
          'unitPrice': p.salePrice,
          'discount': 0.0,
        });
      }
      _showProductList = false;
      _searchCtrl.clear();
      _filteredProducts = widget.products;
    });
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

    if (!_validateStock()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay stock suficiente para algunos productos'),
          backgroundColor: Color(0xFFE24B4A),
        ),
      );
      return;
    }

    final invoice = Invoice(
      customerName: _customerCtrl.text.trim().isEmpty
          ? null
          : _customerCtrl.text.trim(),
      subtotal: _subtotal,
      discountGlobal: _globalDiscount,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
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
            widget.existingInvoice != null ? 'Editar factura' : 'Nueva factura',
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
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Nombre del cliente (opcional)',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Buscador de productos
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              onChanged: (v) {
                _filterProducts(v);
                setState(() => _showProductList = v.isNotEmpty);
              },
              onTap: () => setState(() => _showProductList = true),
              decoration: InputDecoration(
                labelText: 'Buscar y agregar producto',
                labelStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            if (_showProductList) ...[
              const SizedBox(height: 4),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (_, i) {
                    final p = _filteredProducts[i];
                    final isOutOfStock = p.stock <= 0;
                    return ListTile(
                      dense: true,
                      enabled: !isOutOfStock,
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOutOfStock
                              ? const Color(0xFFB4B2A9)
                              : const Color(0xFF2C2C2A),
                        ),
                      ),
                      subtitle: Text(
                        _currency.format(p.salePrice),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOutOfStock
                              ? const Color(0xFFB4B2A9)
                              : const Color(0xFF888780),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stock: ${p.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isOutOfStock
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isOutOfStock
                                  ? const Color(0xFFE24B4A)
                                  : p.isLowStock
                                  ? const Color(0xFFA32D2D)
                                  : const Color(0xFF888780),
                            ),
                          ),
                          if (isOutOfStock) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.block_rounded,
                              size: 14,
                              color: Color(0xFFE24B4A),
                            ),
                          ],
                        ],
                      ),
                      onTap: isOutOfStock ? null : () => _addProduct(p),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Lista de items agregados
            const Text(
              'Productos en la factura',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888780),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Agrega productos usando el buscador',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB4B2A9),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _buildItemRow(i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int i) {
    final item = _items[i];
    final p = item['product'] as Product;
    final qty = item['quantity'] as int;
    final exceedsStock = qty > p.stock;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: exceedsStock ? const Color(0xFFFCEBEB) : const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: exceedsStock
              ? const Color(0xFFE24B4A).withOpacity(0.5)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (exceedsStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE24B4A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stock: ${p.stock}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () => _removeItem(i),
                icon: const Icon(Icons.close_rounded, size: 14),
                color: const Color(0xFFE24B4A),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _smallField(
                label: 'Cantidad',
                initial: '$qty',
                onChanged: (v) => setState(() {
                  _items[i]['quantity'] = int.tryParse(v) ?? 1;
                }),
                error: exceedsStock,
              ),
              const SizedBox(width: 8),
              _smallField(
                label: 'Precio unit.',
                initial: '${item['unitPrice'].toStringAsFixed(0)}',
                onChanged: (v) => setState(() {
                  _items[i]['unitPrice'] = double.tryParse(v) ?? p.salePrice;
                }),
              ),
              const SizedBox(width: 8),
              _smallField(
                label: 'Descuento',
                initial: '0',
                onChanged: (v) => setState(() {
                  _items[i]['discount'] = double.tryParse(v) ?? 0.0;
                }),
              ),
              const Spacer(),
              Text(
                _currency.format(
                  ((item['unitPrice'] as double) *
                          (1 - (item['discount'] as double) / 100)) *
                      qty,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallField({
    required String label,
    required String initial,
    required Function(String) onChanged,
    bool error = false,
  }) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? const Color(0xFFE24B4A) : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? const Color(0xFFE24B4A) : AppTheme.primaryBlue,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7F4),
        border: Border(left: BorderSide(color: Color(0x12000000))),
        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', _currency.format(_subtotal)),
          const SizedBox(height: 12),
          const Text(
            'Descuento global',
            style: TextStyle(fontSize: 11, color: Color(0xFF888780)),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _discountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: '%',
              suffixStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888780),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),

          const Divider(height: 24),
          _summaryRow(
            'Total',
            _currency.format(_total),
            bold: true,
            large: true,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _items.isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentMagenta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
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
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: bold ? const Color(0xFF2C2C2A) : const Color(0xFF888780),
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 16 : 13,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
            color: const Color(0xFF2C2C2A),
          ),
        ),
      ],
    );
  }
}
