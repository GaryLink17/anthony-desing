class QuoteItem {
  final int? id;
  final int quoteId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountItem;
  final double subtotal;

  QuoteItem({
    this.id,
    required this.quoteId,
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
      'quote_id': quoteId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_item': discountItem,
      'subtotal': subtotal,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'],
      quoteId: map['quote_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      discountItem: map['discount_item'],
      subtotal: map['subtotal'],
    );
  }
}
