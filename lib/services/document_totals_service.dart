/// Resultado del cálculo de totales de un documento (factura/cotización).
class DocumentTotals {
  final double subtotal;
  final double discountAmount;
  final double total;

  const DocumentTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.total,
  });
}

/// Servicio para calcular subtotal, descuento global y total de un documento
/// a partir de sus items (cada uno con su propio descuento porcentual).
class DocumentTotalsService {
  /// Calcula los totales dado un arreglo de items (cada item tiene
  /// unitPrice, quantity, discount%) y un descuento global %.
  static DocumentTotals calculateFromItems({
    required List<Map<String, dynamic>> items,
    required double discountPercent,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) {
      final price = (item['unitPrice'] as num).toDouble();
      final quantity = item['quantity'] as int;
      final discount = (item['discount'] as num).toDouble();
      final discountAmount = price * (discount / 100);
      return sum + ((price - discountAmount) * quantity);
    });

    final globalDiscountAmount = subtotal * (discountPercent / 100);
    final total = subtotal - globalDiscountAmount;

    return DocumentTotals(
      subtotal: subtotal,
      discountAmount: globalDiscountAmount,
      total: total,
    );
  }
}
