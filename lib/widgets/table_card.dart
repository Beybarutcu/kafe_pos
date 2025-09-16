// lib/widgets/table_card.dart
import 'package:flutter/material.dart';
import '../models/table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';

class TableCard extends StatefulWidget {
  final CafeTable table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final DatabaseService _databaseService = DatabaseService();
  List<OrderItem> orderItems = [];
  bool isLoadingOrder = false;

  @override
  void initState() {
    super.initState();
    if (widget.table.isOccupied) {
      _loadCurrentOrder();
    }
  }

  @override
  void didUpdateWidget(TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload order data when table status or order ID changes
    if (widget.table.currentOrderId != oldWidget.table.currentOrderId ||
        widget.table.status != oldWidget.table.status) {
      if (widget.table.isOccupied && widget.table.currentOrderId != null) {
        _loadCurrentOrder();
      } else {
        setState(() {
          orderItems = [];
        });
      }
    }
  }

  Future<void> _loadCurrentOrder() async {
    if (!widget.table.isOccupied || widget.table.currentOrderId == null) {
      return;
    }

    setState(() {
      isLoadingOrder = true;
    });

    try {
      final items = await _databaseService.getOrderItems(widget.table.currentOrderId!);
      setState(() {
        orderItems = items.take(3).toList(); // Only show first 3 items
        isLoadingOrder = false;
      });
    } catch (e) {
      setState(() {
        isLoadingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = widget.table.isEmpty ? AppColors.emptyTable : AppColors.occupiedTable;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cardColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Table name at top-center
              Text(
                widget.table.name,
                style: const TextStyle(
                  fontSize: 18, // Keep the bigger font size
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Order preview (removed status icon)
              Expanded(
                child: _buildOrderPreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderPreview() {
    if (widget.table.isEmpty) {
      return Center(
        child: Text(
          'Boş masa',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (isLoadingOrder) {
      return Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (orderItems.isEmpty) {
      return Center(
        child: Text(
          'Sipariş yükleniyor...',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order items list (only show first 3, no "..." indicator)
          ...orderItems.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.occupiedTable,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatOrderItem(item),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _formatOrderItem(OrderItem item) {
    String name = item.menuItemName;
    
    // Truncate long item names to fit better
    if (name.length > 10) {
      name = '${name.substring(0, 10)}...';
    }
    
    // Add quantity if more than 1
    if (item.quantity > 1) {
      return '${item.quantity}x $name';
    }
    
    return name;
  }
}