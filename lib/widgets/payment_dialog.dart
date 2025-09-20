// lib/widgets/payment_dialog.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';

class PaymentDialog extends StatelessWidget {
  final double totalAmount;
  final Function(String paymentMethod) onPaymentSelected;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.payment, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Ödeme Yöntemi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ödenecek Tutar',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Ödeme yöntemini seçin:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment method buttons
            Row(
              children: [
                // Cash payment button
                Expanded(
                  child: _buildPaymentButton(
                    icon: Icons.money,
                    label: 'Nakit',
                    color: AppColors.emptyTable,
                    onTap: () => onPaymentSelected('nakit'),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Card payment button
                Expanded(
                  child: _buildPaymentButton(
                    icon: Icons.credit_card,
                    label: 'Kredi Kartı',
                    color: AppColors.primary,
                    onTap: () => onPaymentSelected('kart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'İptal',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}