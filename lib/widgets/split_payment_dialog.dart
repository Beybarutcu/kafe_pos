// lib/widgets/split_payment_dialog.dart
// UPDATED WITH BETTER DESIGN
import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';

class SplitPaymentDialog extends StatefulWidget {
  final List<OrderItem> orderItems;
  final Function(List<OrderItem> paidItems, String paymentMethod) onPaymentComplete;

  const SplitPaymentDialog({
    super.key,
    required this.orderItems,
    required this.onPaymentComplete,
  });

  @override
  State<SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<SplitPaymentDialog> {
  Map<int, int> selectedQuantities = {}; // item.id -> quantity to pay

  @override
  void initState() {
    super.initState();
    // Initialize all unpaid items with their full remaining quantity selected
    for (var item in widget.orderItems) {
      if (!item.isPaid) {
        selectedQuantities[item.id!] = item.remainingQuantity; // Auto-select all remaining
      }
    }
  }

  double get totalSelectedAmount {
    double total = 0.0;
    for (var item in widget.orderItems) {
      if (item.id != null && selectedQuantities[item.id!] != null) {
        total += item.unitPrice * selectedQuantities[item.id!]!;
      }
    }
    return total;
  }

  int get totalSelectedItems {
    return selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  void _incrementItem(OrderItem item) {
    setState(() {
      int current = selectedQuantities[item.id!] ?? 0;
      if (current < item.remainingQuantity) {
        selectedQuantities[item.id!] = current + 1;
      }
    });
  }

  void _decrementItem(OrderItem item) {
    setState(() {
      int current = selectedQuantities[item.id!] ?? 0;
      if (current > 0) {
        selectedQuantities[item.id!] = current - 1;
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (var item in widget.orderItems) {
        if (!item.isPaid) {
          selectedQuantities[item.id!] = item.remainingQuantity;
        }
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (var key in selectedQuantities.keys) {
        selectedQuantities[key] = 0;
      }
    });
  }

  void _processPayment() {
    if (totalSelectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ödeme yapılacak ürünleri seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment method selection dialog
    _showPaymentMethodDialog();
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.payment, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ödeme Yöntemi Seçin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Amount to pay
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ödenecek Tutar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${totalSelectedAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Payment method buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _confirmPayment('nakit');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.emptyTable,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emptyTable.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.money,
                                size: 48,
                                color: AppColors.emptyTable,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Nakit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _confirmPayment('kart');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.credit_card,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Kart',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPayment(String paymentMethod) {
    List<OrderItem> paidItems = [];
    for (var item in widget.orderItems) {
      int qtyToPay = selectedQuantities[item.id!] ?? 0;
      if (qtyToPay > 0) {
        int newPaidQty = item.paidQuantity + qtyToPay;
        String newStatus = newPaidQty >= item.quantity ? 'paid' : 'partial';
        
        paidItems.add(item.copyWith(
          paidQuantity: newPaidQty,
          paymentStatus: newStatus,
          paymentMethod: paymentMethod,
        ));
      }
    }

    widget.onPaymentComplete(paidItems, paymentMethod);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unpaidItems = widget.orderItems.where((item) => !item.isPaid).toList();
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payments_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ödeme',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.check_box, size: 18),
                      label: const Text('Tümünü Seç'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Temizle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Items list
            Expanded(
              child: unpaidItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Tüm ürünler ödendi',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: unpaidItems.length,
                      itemBuilder: (context, index) {
                        final item = unpaidItems[index];
                        final selected = selectedQuantities[item.id!] ?? 0;
                        final isSelected = selected > 0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _incrementItem(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Checkbox indicator
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.menuItemName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${item.formattedUnitPrice}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    ' × ${item.remainingQuantity} kalan',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.isPartiallyPaid)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.emptyTable.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${item.paidQuantity} adet ödendi',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.emptyTable,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          item.formattedRemainingAmount,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    
                                    // Quantity selector
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Ödenecek Adet:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline),
                                                onPressed: selected > 0 
                                                    ? () => _decrementItem(item)
                                                    : null,
                                                iconSize: 24,
                                                padding: const EdgeInsets.all(8),
                                                color: selected > 0 ? AppColors.primary : Colors.grey,
                                              ),
                                              Container(
                                                width: 50,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$selected',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline),
                                                onPressed: selected < item.remainingQuantity
                                                    ? () => _incrementItem(item)
                                                    : null,
                                                iconSize: 24,
                                                padding: const EdgeInsets.all(8),
                                                color: selected < item.remainingQuantity ? AppColors.primary : Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (selected > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary.withOpacity(0.1),
                                                AppColors.primary.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.2),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.shopping_cart, 
                                                    size: 16, 
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Seçilen Tutar:',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${(item.unitPrice * selected).toStringAsFixed(2)} ${TurkishStrings.currency}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Total and confirm button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalSelectedItems Ürün Seçildi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalSelectedAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: totalSelectedAmount > 0 ? _processPayment : null,
                      icon: const Icon(Icons.arrow_forward, size: 24),
                      label: const Text(
                        'Ödemeye Geç',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}