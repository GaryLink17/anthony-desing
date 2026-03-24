class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountItem;
  final double subtotal;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountItem = 0,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_item': discountItem,
      'subtotal': subtotal,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      discountItem: map['discount_item'],
      subtotal: map['subtotal'],
    );
  }
}
