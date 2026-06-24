/// Modelo que representa un producto del inventario.
class Product {
  final int? id;
  final String name;
  final String? category;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final int minStock;
  final String createdAt;

  Product({
    this.id,
    required this.name,
    this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    this.minStock = 5,
    required this.createdAt,
  });

  /// Ganancia por unidad (precio_venta - precio_compra).
  double get profit => salePrice - purchasePrice;

  /// Margen de ganancia como porcentaje del precio de venta.
  double get marginPercent => (profit / salePrice) * 100;

  /// Indica si el stock actual está por debajo del mínimo permitido.
  bool get isLowStock => stock <= minStock;

  /// Convierte el producto a Map para guardar en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock': stock,
      'min_stock': minStock,
      'created_at': createdAt,
    };
  }

  /// Crea un Product desde un Map devuelto por SQLite.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      category: map['category'] as String?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      minStock: (map['min_stock'] as num?)?.toInt() ?? 5,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  /// Crea una copia del producto con algunos campos modificados.
  Product copyWith({
    int? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    int? minStock,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
