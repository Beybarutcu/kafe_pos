// lib/widgets/treat_dialog.dart
import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../utils/colors.dart';

class TreatDialog extends StatefulWidget {
  final List<OrderItem> orderItems;
  final Map<int, int> currentTreatCounts; // itemId -> treat count
  final Function(Map<int, int> treatCounts) onApply;

  const TreatDialog({
    super.key,
    required this.orderItems,
    required this.currentTreatCounts,
    required this.onApply,
  });

  @override
  State<TreatDialog> createState() => _TreatDialogState();
}

class _TreatDialogState extends State<TreatDialog> {
  late Map<int, int> treatCounts; // itemId -> how many pieces are treats

  @override
  void initState() {
    super.initState();
    treatCounts = Map.from(widget.currentTreatCounts);
  }

  int _getTreatCountForItem(int itemId) {
    return treatCounts[itemId] ?? 0;
  }

  void _updateTreatCount(int itemId, int newCount) {
    setState(() {
      if (newCount <= 0) {
        treatCounts.remove(itemId);
      } else {
        treatCounts[itemId] = newCount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.favorite, color: AppColors.treat, size: 24),
          const SizedBox(width: 8),
          const Text('İkram Seç'),
        ],
      ),
      content: Container(
        width: 450, // Increased for tablet
        height: 500, // Increased for tablet
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Increased spacing
            Expanded(
              child: ListView.builder(
                itemCount: widget.orderItems.length,
                itemBuilder: (context, index) {
                  final item = widget.orderItems[index];
                  final currentTreatCount = _getTreatCountForItem(item.id!);
                  final maxCount = item.quantity;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16), // Increased margin
                    padding: const EdgeInsets.all(20), // Increased padding
                    decoration: BoxDecoration(
                      color: currentTreatCount > 0 
                          ? AppColors.treat.withOpacity(0.05)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentTreatCount > 0 
                            ? AppColors.treat.withOpacity(0.3)
                            : Colors.grey.shade300,
                        width: currentTreatCount > 0 ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuItemName,
                                    style: TextStyle(
                                      fontSize: 18, // Increased font size for tablet
                                      fontWeight: FontWeight.bold,
                                      color: currentTreatCount > 0 
                                          ? AppColors.treat 
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Toplam: ${maxCount} adet - ${item.formattedUnitPrice}/adet',
                                    style: const TextStyle(
                                      fontSize: 14, // Increased font size
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentTreatCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
                                decoration: BoxDecoration(
                                  color: AppColors.treat,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${currentTreatCount} İKRAM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12, // Increased font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16), // Increased spacing
                        
                        // Treat count selector
                        Row(
                          children: [
                            const Text(
                              'İkram Adedi:',
                              style: TextStyle(
                                fontSize: 16, // Increased font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            
                            // Decrease button - Bigger for tablet
                            SizedBox(
                              width: 48, // Increased size
                              height: 48,
                              child: IconButton(
                                onPressed: currentTreatCount > 0
                                    ? () => _updateTreatCount(item.id!, currentTreatCount - 1)
                                    : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: currentTreatCount > 0 
                                      ? AppColors.treat.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.remove,
                                  color: currentTreatCount > 0 
                                      ? AppColors.treat 
                                      : Colors.grey.shade400,
                                  size: 24, // Increased icon size
                                ),
                              ),
                            ),
                            
                            // Count display - Bigger for tablet
                            Container(
                              width: 80, // Increased width
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '$currentTreatCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20, // Increased font size
                                  fontWeight: FontWeight.bold,
                                  color: currentTreatCount > 0 
                                      ? AppColors.treat 
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            
                            // Increase button - Bigger for tablet
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: currentTreatCount < maxCount
                                    ? () => _updateTreatCount(item.id!, currentTreatCount + 1)
                                    : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: currentTreatCount < maxCount 
                                      ? AppColors.treat.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.add,
                                  color: currentTreatCount < maxCount 
                                      ? AppColors.treat 
                                      : Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Show individual pieces if helpful
                        if (maxCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Text(
                                  'Ödenen: ${maxCount - currentTreatCount} adet',
                                  style: const TextStyle(
                                    fontSize: 14, // Increased font size
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  'İkram: ${currentTreatCount} adet',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.treat,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              treatCounts.clear();
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Bigger for tablet
          ),
          child: Text(
            'Temizle',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'İptal',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(treatCounts);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.treat,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Bigger for tablet
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Uygula',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}