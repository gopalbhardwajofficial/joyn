class OrderItemModel {
  final String id;
  final String itemName;
  final String category;
  final double price;
  final int qty;

  const OrderItemModel({
    required this.id,
    required this.itemName,
    this.category = '',
    this.price = 0,
    this.qty = 1,
  });

  double get amount => price * qty;

  OrderItemModel copyWith({
    String? itemName,
    String? category,
    double? price,
    int? qty,
  }) {
    return OrderItemModel(
      id: id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      price: price ?? this.price,
      qty: qty ?? this.qty,
    );
  }
}