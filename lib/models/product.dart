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

  // Ganancia por unidad
  double get profit => salePrice - purchasePrice;

  // Margen en porcentaje
  double get marginPercent => (profit / salePrice) * 100;

  // Si el stock está por debajo del mínimo
  bool get isLowStock => stock <= minStock;

  // Convertir a Map para guardar en SQLite
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

  // Crear un Product desde un Map que viene de SQLite
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      purchasePrice: map['purchase_price'],
      salePrice: map['sale_price'],
      stock: map['stock'],
      minStock: map['min_stock'],
      createdAt: map['created_at'],
    );
  }

  // Para hacer copias modificadas del objeto
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
