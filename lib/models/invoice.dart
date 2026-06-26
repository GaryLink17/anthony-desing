/// Modelo que representa una factura (cabecera).
class Invoice {
  final int? id;
  final String? customerName;
  // final String? customerRnc; // RNC deshabilitado
  final double subtotal;
  final double discountGlobal;
  final double total;
  final String status;
  final String paymentStatus;
  final String createdAt;

  Invoice({
    this.id,
    this.customerName,
    // this.customerRnc, // RNC deshabilitado
    required this.subtotal,
    this.discountGlobal = 0,
    required this.total,
    this.status = 'active',
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  /// La factura fue anulada.
  bool get isCancelled => status == 'cancelled';

  /// La factura está activa (no anulada).
  bool get isActive => status == 'active';

  /// El pago fue realizado.
  bool get isPaid => paymentStatus == 'paid';

  /// El pago está pendiente.
  bool get isPending => paymentStatus == 'pending';

  /// Crea una copia con algunos campos modificados.
  Invoice copyWith({
    int? id,
    String? customerName,
    // String? customerRnc, // RNC deshabilitado
    double? subtotal,
    double? discountGlobal,
    double? total,
    String? status,
    String? paymentStatus,
    String? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      // customerRnc: customerRnc ?? this.customerRnc, // RNC deshabilitado
      subtotal: subtotal ?? this.subtotal,
      discountGlobal: discountGlobal ?? this.discountGlobal,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convierte la factura a Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      // 'customer_rnc': customerRnc, // RNC deshabilitado
      'subtotal': subtotal,
      'discount_global': discountGlobal,
      'total': total,
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt,
    };
  }

  /// Crea una Invoice desde un Map de SQLite.
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String?,
      // customerRnc: map['customer_rnc'], // RNC deshabilitado
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountGlobal: (map['discount_global'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: (map['status'] as String?) ?? 'active',
      paymentStatus: (map['payment_status'] as String?) ?? 'pending',
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }
}
