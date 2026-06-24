import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_helper.dart';
import '../../../utils/currency_config.dart';

/// Diálogo modal para crear o editar un producto del inventario.
///
/// Muestra campos de nombre, categoría, precios y stock, con cálculo
/// en tiempo real de la ganancia y margen por unidad.
class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _canPop = false;

  double _profit = 0;
  double _margin = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      // Modo edición: precargar datos del producto existente.
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _purchaseCtrl.dispose();
    _saleCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  /// Recalcula ganancia y margen cada vez que cambia precio de compra o venta.
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

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Descartar cambios?'),
                content: const Text('Los datos ingresados se perderán.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Seguir editando'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            );
            if (confirm == true && mounted) {
              setState(() => _canPop = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
            }
          },
          child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
                    isEdit ? 'Editar producto' : 'Nuevo producto',
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
                            allowZero: false,
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
                            isInteger: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _minStockCtrl,
                            'Stock mínimo',
                            number: true,
                            isInteger: true,
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
                            '${currencyFormatter().format(_profit)}  (${_margin.toStringAsFixed(1)}%)',
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
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                ThemeHelper.getTextMediumColor(context),
                            side: BorderSide(
                              color: ThemeHelper.getBorderColor(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentMagenta,
                            foregroundColor: Colors.white,
                            elevation: 0,
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
        ),
      ),
    );
  }

  /// Construye un campo de formulario reutilizable con validación integrada.
  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool number = false,
    bool isInteger = false,
    bool allowZero = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: ThemeHelper.getTextMediumColor(context),
        ),
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
          if (isInteger) {
            final n = int.tryParse(text);
            if (n == null) return 'Solo números enteros';
            if (allowZero ? n < 0 : n <= 0) {
              return allowZero ? 'Debe ser 0 o mayor' : 'Debe ser mayor a 0';
            }
          } else {
            final n = double.tryParse(text);
            if (n == null) return 'Ingresa un número válido';
            if (allowZero ? n < 0 : n <= 0) {
              return allowZero ? 'Debe ser 0 o mayor' : 'Debe ser mayor a 0';
            }
          }
        }
        return null;
      },
    );
  }

  /// Valida el formulario, construye el objeto [Product] y lo entrega
  /// mediante el callback [onSave].
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
      createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
    );
    widget.onSave(product);
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }
}
