class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? rnc;
  final String? address;
  final String createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.rnc,
    this.address,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? rnc,
    String? address,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rnc: rnc ?? this.rnc,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'rnc': rnc,
      'address': address,
      'created_at': createdAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      rnc: map['rnc'],
      address: map['address'],
      createdAt: map['created_at'],
    );
  }

  @override
  String toString() => name;
}
