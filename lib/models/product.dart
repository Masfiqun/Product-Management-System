class Product {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final DateTime? checkedOutAt;
  final DateTime? checkedInAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    this.checkedOutAt,
    this.checkedInAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    DateTime? checkedOutAt,
    DateTime? checkedInAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'checkedOutAt': checkedOutAt?.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'],
      description: map['description'],
      quantity: map['quantity'],
      checkedOutAt: map['checkedOutAt'] != null
          ? DateTime.parse(map['checkedOutAt'])
          : null,
      checkedInAt: map['checkedInAt'] != null
          ? DateTime.parse(map['checkedInAt'])
          : null,
    );
  }
}
