// lib/widgets/order/order_summary_section.dart
import 'package:flutter/material.dart';
import '../../models/order_item.dart';
import '../../utils/colors.dart';

class OrderSummarySection extends StatelessWidget {
  final List<OrderItem> orderItems;
  final Map<int, int> treatCounts;
  final double discountPercentage;
  final String? discountReason;
  final double subtotal;
  final double discountAmount;
  final double treatAmount;
  final double finalTotal;
  final Function(OrderItem, int) onUpdateQuantity;
  final Function(OrderItem) onRemoveItem;
  final VoidCallback onDiscountTap;
  final VoidCallback onTreatTap;
  final VoidCallback onPaymentTap;

  const OrderSummarySection({
    super.key,
    required this.orderItems,
    required this.treatCounts,
    required this.discountPercentage,
    required this.discountReason,
    required this.subtotal,
    required this.discountAmount,
    required this.treatAmount,
    required this.finalTotal,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onDiscountTap,
    required this.onTreatTap,
    required this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildOrderItemsList()),
          _buildTotalsAndActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: const Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text('Sipariş Özeti', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList() {
    if (orderItems.isEmpty) {
      return const Center(
        child: Text('Henüz ürün eklenmedi', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orderItems.length,
      itemBuilder: (context, index) {
        final item = orderItems[index];
        final treatCount = treatCounts[item.id!] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: treatCount > 0 ? AppColors.treat.withOpacity(0.1) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: treatCount > 0 ? AppColors.treat : AppColors.background,
              width: treatCount > 0 ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.menuItemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: treatCount > 0 ? AppColors.treat : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.occupiedTable),
                    onPressed: () => onRemoveItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => onUpdateQuantity(item, item.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => onUpdateQuantity(item, item.quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    '${item.totalPrice.toStringAsFixed(2)} ₺',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (treatCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'İkram: $treatCount adet',
                  style: const TextStyle(fontSize: 12, color: AppColors.treat, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalsAndActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Ara Toplam:', subtotal, AppColors.textSecondary),
          if (discountPercentage > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('İndirim (%${discountPercentage.toStringAsFixed(0)}):', -discountAmount, AppColors.discount),
          ],
          if (treatAmount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('İkram:', -treatAmount, AppColors.treat),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Toplam:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('${finalTotal.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.percent,
                isActive: discountPercentage > 0,
                activeColor: AppColors.discount,
                onTap: onDiscountTap,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.favorite,
                isActive: treatCounts.isNotEmpty,
                activeColor: AppColors.treat,
                onTap: onTreatTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPaymentTap,
                  icon: const Icon(Icons.payment, size: 22),
                  label: const Text('Öde', style: TextStyle(fontSize: 17)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: color)),
        Text(
          '${amount < 0 ? '' : ''}${amount.abs().toStringAsFixed(2)} ₺',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? activeColor : AppColors.textSecondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        color: isActive ? activeColor : AppColors.textSecondary,
        padding: EdgeInsets.zero,
      ),
    );
  }
}