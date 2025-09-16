import '../utils/turkish_strings.dart';

class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String category;
  final bool active;
  final int sortOrder;

  MenuItem({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    this.active = true,
    this.sortOrder = 0,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
      category: map['category'],
      active: map['active'] == 1,
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'active': active ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  String get formattedPrice => '${price.toStringAsFixed(2)} ${TurkishStrings.currency}';

  MenuItem copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    bool? active,
    int? sortOrder,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}