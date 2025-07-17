class Shipment {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> productIds; // IDs of products originally in the shipment
  final List<String> checkedInProductIds; // IDs of products that were checked in
  final bool isCompleted;

  Shipment({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.productIds,
    List<String>? checkedInProductIds,
    this.isCompleted = false,
  }) : checkedInProductIds = checkedInProductIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'productIds': productIds,
      'checkedInProductIds': checkedInProductIds,
      'isCompleted': isCompleted,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map, String id) {
    return Shipment(
      id: id,
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      productIds: List<String>.from(map['productIds'] ?? []),
      checkedInProductIds: List<String>.from(map['checkedInProductIds'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Shipment copyWith({
    String? name,
    List<String>? productIds,
    List<String>? checkedInProductIds,
    bool? isCompleted,
  }) {
    return Shipment(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      productIds: productIds ?? this.productIds,
      checkedInProductIds: checkedInProductIds ?? this.checkedInProductIds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
