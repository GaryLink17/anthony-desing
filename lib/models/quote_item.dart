/// Modelo que representa una línea de detalle de una cotización.
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

  /// Crea una copia con algunos campos modificados.
  QuoteItem copyWith({
    int? id,
    int? quoteId,
    int? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? discountItem,
    double? subtotal,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountItem: discountItem ?? this.discountItem,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  /// Convierte el item a Map para SQLite.
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

  /// Crea un QuoteItem desde un Map de SQLite.
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
