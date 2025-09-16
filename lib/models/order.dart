import '../utils/constants.dart';
import '../utils/turkish_strings.dart';
import 'order_item.dart';

class Order {
  final int? id;
  final int tableId;
  final double subtotal;
  final double discountAmount;
  final String? discountType;
  final String? discountReason;
  final double treatAmount;
  final String? treatReason;
  final double finalTotal;
  final String? paymentMethod;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.tableId,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.discountType,
    this.discountReason,
    this.treatAmount = 0.0,
    this.treatReason,
    required this.finalTotal,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      tableId: map['table_id'],
      subtotal: map['subtotal'].toDouble(),
      discountAmount: map['discount_amount']?.toDouble() ?? 0.0,
      discountType: map['discount_type'],
      discountReason: map['discount_reason'],
      treatAmount: map['treat_amount']?.toDouble() ?? 0.0,
      treatReason: map['treat_reason'],
      finalTotal: map['final_total'].toDouble(),
      paymentMethod: map['payment_method'],
      status: map['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_id': tableId,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'discount_reason': discountReason,
      'treat_amount': treatAmount,
      'treat_reason': treatReason,
      'final_total': finalTotal,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  bool get isPending => status == AppConstants.orderStatusPending;
  bool get isWaitingPayment => status == AppConstants.orderStatusWaitingPayment;
  bool get isPaid => status == AppConstants.orderStatusPaid;
  bool get isCompleted => status == AppConstants.orderStatusCompleted;

  String get formattedSubtotal => '${subtotal.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedDiscountAmount => '${discountAmount.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedTreatAmount => '${treatAmount.toStringAsFixed(2)} ${TurkishStrings.currency}';
  String get formattedFinalTotal => '${finalTotal.toStringAsFixed(2)} ${TurkishStrings.currency}';

  double calculateFinalTotal() {
    return subtotal - discountAmount - treatAmount;
  }

  Order copyWith({
    int? id,
    int? tableId,
    double? subtotal,
    double? discountAmount,
    String? discountType,
    String? discountReason,
    double? treatAmount,
    String? treatReason,
    double? finalTotal,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      discountReason: discountReason ?? this.discountReason,
      treatAmount: treatAmount ?? this.treatAmount,
      treatReason: treatReason ?? this.treatReason,
      finalTotal: finalTotal ?? this.finalTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}