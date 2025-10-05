// lib/models/order_item.dart
// REPLACE YOUR ENTIRE order_item.dart FILE WITH THIS CODE
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
  final String paymentStatus; // 'unpaid', 'paid', 'partial'
  final String? paymentMethod; // 'nakit' or 'kart'
  final int paidQuantity; // How many items have been paid for

  OrderItem({
    this.id,
    required this.orderId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isTreat = false,
    this.treatReason,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paidQuantity = 0,
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
      paymentStatus: map['payment_status'] ?? 'unpaid',
      paymentMethod: map['payment_method'],
      paidQuantity: map['paid_quantity'] ?? 0,
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
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'paid_quantity': paidQuantity,
    };
  }

  // Helper getters - THESE ARE REQUIRED
  bool get isPaid => paymentStatus == 'paid' || paidQuantity >= quantity;
  bool get isPartiallyPaid => paymentStatus == 'partial' || (paidQuantity > 0 && paidQuantity < quantity);
  bool get isUnpaid => paymentStatus == 'unpaid' || paidQuantity == 0;
  int get remainingQuantity => quantity - paidQuantity;
  double get remainingAmount => unitPrice * remainingQuantity;
  double get paidAmount => unitPrice * paidQuantity;

  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedRemainingAmount => '${remainingAmount.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedPaidAmount => '${paidAmount.toStringAsFixed(2)} ${TurkishStrings.currency}';

  OrderItem copyWith({
    int? id,
    int? orderId,
    String? menuItemName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    bool? isTreat,
    String? treatReason,
    String? paymentStatus,
    String? paymentMethod,
    int? paidQuantity,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidQuantity: paidQuantity ?? this.paidQuantity,
    );
  }
}