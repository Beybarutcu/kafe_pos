import '../utils/constants.dart';

class CafeTable {
  final int? id;
  final int tableNumber;
  final String name;
  final String status;
  final int? currentOrderId;
  final bool active;

  CafeTable({
    this.id,
    required this.tableNumber,
    required this.name,
    required this.status,
    this.currentOrderId,
    this.active = true,
  });

  factory CafeTable.fromMap(Map<String, dynamic> map) {
    return CafeTable(
      id: map['id'],
      tableNumber: map['table_number'],
      name: map['name'],
      status: map['status'],
      currentOrderId: map['current_order_id'],
      active: map['active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_number': tableNumber,
      'name': name,
      'status': status,
      'current_order_id': currentOrderId,
      'active': active ? 1 : 0,
    };
  }

  bool get isEmpty => status == AppConstants.tableStatusEmpty;
  bool get isOccupied => status == AppConstants.tableStatusOccupied;

  CafeTable copyWith({
    int? id,
    int? tableNumber,
    String? name,
    String? status,
    int? currentOrderId,
    bool? active,
  }) {
    return CafeTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      name: name ?? this.name,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      active: active ?? this.active,
    );
  }
}