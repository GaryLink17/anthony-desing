import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/product_repository.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/state_builder.dart';
import '../../utils/responsive_helper.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../services/excel_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = ProductRepository();
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts([String query = '']) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _repo.getAll()
          : await _repo.search(query);
      if (mounted) setState(() { _products = result; _loading = false; });
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
            _buildToolbar(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
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
              'Inventario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            Text(
              '${_products.length} productos registrados',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _products.isEmpty ? null : _exportExcel,
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
          onPressed: () => _showProductDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nuevo producto'),
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

  Future<void> _exportExcel() async {
    try {
      final saved = await ExcelService.exportInventory(_products);
      if (saved && mounted) {
        NotificationService().success('Inventario exportado a Excel correctamente');
      }
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    }
  }

  Widget _buildToolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchController,
        onChanged: _loadProducts,
        decoration: InputDecoration(
          hintText: 'Buscar producto...',
          hintStyle: TextStyle(fontSize: 13, color: ThemeHelper.getHintColor(context)),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: ThemeHelper.getHintColor(context),
          ),
          filled: true,
          fillColor: ThemeHelper.getCardColor(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: ThemeHelper.getBorderColor(context),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: ThemeHelper.getBorderColor(context),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return StateBuilder(
      isLoading: _loading,
      isEmpty: _products.isEmpty,
      icon: Icons.inventory_2_outlined,
      emptyTitle: 'No hay productos aún',
      emptyDescription: 'Presiona "Nuevo producto" para agregar el primero',
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
                itemCount: _products.length,
                itemBuilder: (_, i) => _buildTableRow(_products[i], i),
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
          Expanded(flex: 3, child: Text('Producto', style: style)),
          Expanded(flex: 2, child: Text('Categoría', style: style)),
          Expanded(flex: 2, child: Text('P. Compra', style: style)),
          Expanded(flex: 2, child: Text('P. Venta', style: style)),
          Expanded(flex: 2, child: Text('Ganancia', style: style)),
          Expanded(flex: 1, child: Text('Stock', style: style)),
          SizedBox(width: 80, child: Text('Acciones', style: style)),
        ],
      ),
    );
  }

  Widget _buildTableRow(Product p, int index) {
    final isEven = index % 2 == 0;
    final profit = p.salePrice - p.purchasePrice;
    final margin = p.salePrice > 0 ? (profit / p.salePrice * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEven ? Colors.transparent : ThemeHelper.getAltRowColor(context),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (p.isLowStock)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppTheme.errorMedium,
                    ),
                  ),
                Expanded(
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeHelper.getTextColor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              p.category ?? '—',
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(p.purchasePrice),
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(p.salePrice),
              style: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  _currency.format(profit),
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeHelper.getSuccessTextColor(context),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${margin.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: ThemeHelper.getTextLightColor(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.isLowStock
                    ? ThemeHelper.getErrorLightBg(context)
                    : ThemeHelper.getSuccessLightBg(context),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${p.stock}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: p.isLowStock
                      ? ThemeHelper.getErrorTextColor(context)
                      : ThemeHelper.getSuccessTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showProductDialog(product: p),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: ThemeHelper.getTextLightColor(context),
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _confirmDelete(p),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: const Color(0xFFE24B4A),
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

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: ThemeHelper.getTextMediumColor(context)),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _repo.delete(p.id!);
                NotificationService().success('Producto eliminado');
                if (mounted) { Navigator.pop(context); _loadProducts(); }
              } on AppException catch (e) {
                if (mounted) Navigator.pop(context);
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

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(
        product: product,
        onSave: (p) async {
          try {
            if (p.id == null) {
              await _repo.insert(p);
              NotificationService().success('Producto agregado');
            } else {
              await _repo.update(p);
              NotificationService().success('Producto actualizado');
            }
            _loadProducts();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const _ProductDialog({this.product, required this.onSave});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _profit = 0;
  double _margin = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _categoryCtrl.text = p.category ?? '';
      _purchaseCtrl.text = p.purchasePrice.toStringAsFixed(0);
      _saleCtrl.text = p.salePrice.toStringAsFixed(0);
      _stockCtrl.text = p.stock.toString();
      _minStockCtrl.text = p.minStock.toString();
      _updateProfit();
    }
    _purchaseCtrl.addListener(_updateProfit);
    _saleCtrl.addListener(_updateProfit);
  }

  void _updateProfit() {
    final purchase = double.tryParse(_purchaseCtrl.text) ?? 0;
    final sale = double.tryParse(_saleCtrl.text) ?? 0;
    setState(() {
      _profit = sale - purchase;
      _margin = sale > 0 ? (_profit / sale * 100) : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header azul
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Editar producto' : 'Nuevo producto',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(_nameCtrl, 'Nombre del producto', required: true),
                    const SizedBox(height: 12),
                    _field(_categoryCtrl, 'Categoría (opcional)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _purchaseCtrl,
                            'Precio de compra',
                            number: true,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _saleCtrl,
                            'Precio de venta',
                            number: true,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _stockCtrl,
                            'Stock actual',
                            number: true,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _minStockCtrl,
                            'Stock mínimo',
                            number: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _profit >= 0
                            ? ThemeHelper.getSuccessLightBg(context)
                            : ThemeHelper.getErrorLightBg(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ganancia por unidad:',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeHelper.getTextMediumColor(context),
                            ),
                          ),
                          Text(
                            'RD\$ ${_profit.toStringAsFixed(0)}  (${_margin.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _profit >= 0
                                  ? ThemeHelper.getSuccessTextColor(context)
                                  : ThemeHelper.getErrorTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isEdit ? 'Guardar cambios' : 'Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: (v) {
        final text = v?.trim() ?? '';
        if (required && text.isEmpty) return 'Campo requerido';
        if (number && text.isNotEmpty) {
          final n = double.tryParse(text);
          if (n == null) return 'Ingresa un número válido';
          if (n < 0) return 'Debe ser 0 o mayor';
        }
        return null;
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty
          ? null
          : _categoryCtrl.text.trim(),
      purchasePrice: double.parse(_purchaseCtrl.text),
      salePrice: double.parse(_saleCtrl.text),
      stock: int.parse(_stockCtrl.text),
      minStock: int.tryParse(_minStockCtrl.text) ?? 5,
      createdAt: DateTime.now().toIso8601String(),
    );
    widget.onSave(product);
    Navigator.pop(context);
  }
}
