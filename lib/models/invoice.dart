class Invoice {
  final int? id;
  final String? customerName;
  final String? customerRnc;
  final double subtotal;
  final double discountGlobal;
  final double itbis;
  final double isr;
  final double total;
  final String status;
  final String paymentStatus;
  final String createdAt;

  Invoice({
    this.id,
    this.customerName,
    this.customerRnc,
    required this.subtotal,
    this.discountGlobal = 0,
    this.itbis = 0,
    this.isr = 0,
    required this.total,
    this.status = 'active',
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';

  /// Base imponible: subtotal menos descuento global
  double get taxableBase => subtotal - discountGlobal;

  Invoice copyWith({
    int? id,
    String? customerName,
    String? customerRnc,
    double? subtotal,
    double? discountGlobal,
    double? itbis,
    double? isr,
    double? total,
    String? status,
    String? paymentStatus,
    String? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerRnc: customerRnc ?? this.customerRnc,
      subtotal: subtotal ?? this.subtotal,
      discountGlobal: discountGlobal ?? this.discountGlobal,
      itbis: itbis ?? this.itbis,
      isr: isr ?? this.isr,
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
      'customer_rnc': customerRnc,
      'subtotal': subtotal,
      'discount_global': discountGlobal,
      'itbis': itbis,
      'isr': isr,
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
      customerRnc: map['customer_rnc'],
      subtotal: (map['subtotal'] as num).toDouble(),
      discountGlobal: (map['discount_global'] as num? ?? 0).toDouble(),
      itbis: (map['itbis'] as num? ?? 0).toDouble(),
      isr: (map['isr'] as num? ?? 0).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] ?? 'active',
      paymentStatus: map['payment_status'] ?? 'pending',
      createdAt: map['created_at'],
    );
  }
}
