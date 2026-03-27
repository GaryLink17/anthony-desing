import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/product_repository.dart';
import '../../models/product.dart';
import '../../app.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = ProductRepository();
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'es_DO',
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
    final result = query.isEmpty
        ? await _repo.getAll()
        : await _repo.search(query);
    setState(() {
      _products = result;
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
            const Text(
              'Inventario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2A),
              ),
            ),
            Text(
              '${_products.length} productos registrados',
              style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showProductDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nuevo producto'),
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

  Widget _buildToolbar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchController,
        onChanged: _loadProducts,
        decoration: InputDecoration(
          hintText: 'Buscar producto...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFFB4B2A9),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay productos aún',
              style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Presiona "Nuevo producto" para agregar el primero',
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
              itemCount: _products.length,
              itemBuilder: (_, i) => _buildTableRow(_products[i], i),
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
      color: isEven ? Colors.transparent : const Color(0xFFFAFAF8),
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
                      color: Color(0xFFE24B4A),
                    ),
                  ),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C2C2A),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(p.purchasePrice),
              style: const TextStyle(fontSize: 12, color: Color(0xFF444441)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(p.salePrice),
              style: const TextStyle(fontSize: 12, color: Color(0xFF444441)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  _currency.format(profit),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B6D11),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${margin.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888780),
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
                    ? const Color(0xFFFCEBEB)
                    : const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${p.stock}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: p.isLowStock
                      ? const Color(0xFFA32D2D)
                      : const Color(0xFF27500A),
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
                  color: const Color(0xFF888780),
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _repo.delete(p.id!);
              if (mounted) {
                Navigator.pop(context);
                _loadProducts();
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
          if (p.id == null) {
            await _repo.insert(p);
          } else {
            await _repo.update(p);
          }
          _loadProducts();
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Editar producto' : 'Nuevo producto',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2A),
                ),
              ),
              const SizedBox(height: 20),
              Form(
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
                            ? const Color(0xFFEAF3DE)
                            : const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ganancia por unidad:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF444441),
                            ),
                          ),
                          Text(
                            'RD\$ ${_profit.toStringAsFixed(0)}  (${_margin.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _profit >= 0
                                  ? const Color(0xFF27500A)
                                  : const Color(0xFFA32D2D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentMagenta,
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
          : null,
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
