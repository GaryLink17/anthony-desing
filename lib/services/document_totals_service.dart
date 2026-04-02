import 'tax_service.dart';

class DocumentTotals {
  final double subtotal;
  final double discountAmount;
  final double taxableBase;
  final TaxResult taxResult;

  const DocumentTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.taxableBase,
    required this.taxResult,
  });

  double get total => taxResult.total;
  double get itbis => taxResult.itbis;
  double get isr => taxResult.isr;
}

class DocumentTotalsService {
  static DocumentTotals calculateFromItems({
    required List<Map<String, dynamic>> items,
    required double discountPercent,
    required TaxConfig taxConfig,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) {
      final price = (item['unitPrice'] as num).toDouble();
      final quantity = item['quantity'] as int;
      final discount = (item['discount'] as num).toDouble();
      final discountAmount = price * (discount / 100);
      return sum + ((price - discountAmount) * quantity);
    });

    final globalDiscountAmount = subtotal * (discountPercent / 100);
    final taxableBase = subtotal - globalDiscountAmount;
    final taxResult = TaxService.calculate(taxableBase, taxConfig);

    return DocumentTotals(
      subtotal: subtotal,
      discountAmount: globalDiscountAmount,
      taxableBase: taxableBase,
      taxResult: taxResult,
    );
  }
}
