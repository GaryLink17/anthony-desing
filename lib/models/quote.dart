/// Modelo que representa una cotización (cabecera).
class Quote {
  final int? id;
  final String? customerName;
  // final String? customerRnc; // RNC deshabilitado
  final double subtotal;
  final double discountGlobal;
  final double total;
  final String createdAt;
  final String? expiresAt;
  final bool isConverted;

  Quote({
    this.id,
    this.customerName,
    // this.customerRnc, // RNC deshabilitado
    required this.subtotal,
    this.discountGlobal = 0,
    required this.total,
    required this.createdAt,
    this.expiresAt,
    this.isConverted = false,
  });

  /// Indica si la cotización ha expirado según su fecha de expiración.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.parse(expiresAt!).isBefore(DateTime.now());
  }

  /// Indica si la cotización sigue válida (no expirada y no convertida).
  bool get isValid => !isExpired && !isConverted;

  /// Crea una copia con algunos campos modificados.
  Quote copyWith({
    int? id,
    String? customerName,
    // String? customerRnc, // RNC deshabilitado
    double? subtotal,
    double? discountGlobal,
    double? total,
    String? createdAt,
    String? expiresAt,
    bool? isConverted,
  }) {
    return Quote(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      // customerRnc: customerRnc ?? this.customerRnc, // RNC deshabilitado
      subtotal: subtotal ?? this.subtotal,
      discountGlobal: discountGlobal ?? this.discountGlobal,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isConverted: isConverted ?? this.isConverted,
    );
  }

  /// Convierte la cotización a Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      // 'customer_rnc': customerRnc, // RNC deshabilitado
      'subtotal': subtotal,
      'discount_global': discountGlobal,
      'total': total,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'is_converted': isConverted ? 1 : 0,
    };
  }

  /// Crea una Quote desde un Map de SQLite.
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String?,
      // customerRnc: map['customer_rnc'], // RNC deshabilitado
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountGlobal: (map['discount_global'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: (map['created_at'] as String?) ?? '',
      expiresAt: map['expires_at'] as String?,
      isConverted: map['is_converted'] == 1,
    );
  }
}
