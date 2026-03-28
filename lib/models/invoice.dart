class Invoice {
  final int? id;
  final String? customerName;
  final double subtotal;
  final double discountGlobal;
  final double total;
  final String status;
  final String paymentStatus;
  final String createdAt;

  Invoice({
    this.id,
    this.customerName,
    required this.subtotal,
    this.discountGlobal = 0,
    required this.total,
    this.status = 'active',
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';

  Invoice copyWith({
    int? id,
    String? customerName,
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
      subtotal: subtotal ?? this.subtotal,
      discountGlobal: discountGlobal ?? this.discountGlobal,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'subtotal': subtotal,
      'discount_global': discountGlobal,
      'total': total,
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      customerName: map['customer_name'],
      subtotal: map['subtotal'],
      discountGlobal: map['discount_global'] ?? 0,
      total: map['total'],
      status: map['status'] ?? 'active',
      paymentStatus: map['payment_status'] ?? 'pending',
      createdAt: map['created_at'],
    );
  }
}
