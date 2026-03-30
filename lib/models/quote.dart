class Quote {
  final int? id;
  final String? customerName;
  final double subtotal;
  final double discountGlobal;
  final double itbis;
  final double isr;
  final double total;
  final String createdAt;
  final String? expiresAt;
  final bool isConverted;

  Quote({
    this.id,
    this.customerName,
    required this.subtotal,
    this.discountGlobal = 0,
    this.itbis = 0,
    this.isr = 0,
    required this.total,
    required this.createdAt,
    this.expiresAt,
    this.isConverted = false,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.parse(expiresAt!).isBefore(DateTime.now());
  }

  bool get isValid => !isExpired && !isConverted;

  /// Base imponible: subtotal menos descuento global
  double get taxableBase => subtotal - discountGlobal;

  Quote copyWith({
    int? id,
    String? customerName,
    double? subtotal,
    double? discountGlobal,
    double? itbis,
    double? isr,
    double? total,
    String? createdAt,
    String? expiresAt,
    bool? isConverted,
  }) {
    return Quote(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      discountGlobal: discountGlobal ?? this.discountGlobal,
      itbis: itbis ?? this.itbis,
      isr: isr ?? this.isr,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isConverted: isConverted ?? this.isConverted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'subtotal': subtotal,
      'discount_global': discountGlobal,
      'itbis': itbis,
      'isr': isr,
      'total': total,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'is_converted': isConverted ? 1 : 0,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      customerName: map['customer_name'],
      subtotal: (map['subtotal'] as num).toDouble(),
      discountGlobal: (map['discount_global'] as num? ?? 0).toDouble(),
      itbis: (map['itbis'] as num? ?? 0).toDouble(),
      isr: (map['isr'] as num? ?? 0).toDouble(),
      total: (map['total'] as num).toDouble(),
      createdAt: map['created_at'],
      expiresAt: map['expires_at'],
      isConverted: map['is_converted'] == 1,
    );
  }
}
