import '../utils/turkish_strings.dart';

class OrderItem {
  final int? id;
  final int orderId;
  final String menuItemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isTreat;
  final String? treatReason;

  OrderItem({
    this.id,
    required this.orderId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isTreat = false,
    this.treatReason,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      menuItemName: map['menu_item_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'].toDouble(),
      totalPrice: map['total_price'].toDouble(),
      isTreat: map['is_treat'] == 1,
      treatReason: map['treat_reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_name': menuItemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'is_treat': isTreat ? 1 : 0,
      'treat_reason': treatReason,
    };
  }

  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(2)} ${TurkishStrings.currency}';

  OrderItem copyWith({
    int? id,
    int? orderId,
    String? menuItemName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    bool? isTreat,
    String? treatReason,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemName: menuItemName ?? this.menuItemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isTreat: isTreat ?? this.isTreat,
      treatReason: treatReason ?? this.treatReason,
    );
  }
}