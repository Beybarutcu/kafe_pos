// lib/widgets/discount_dialog.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class DiscountDialog extends StatefulWidget {
  final double currentDiscount;
  final String? currentReason;
  final Function(double percentage, String? reason) onApply;

  const DiscountDialog({
    super.key,
    required this.currentDiscount,
    this.currentReason,
    required this.onApply,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late TextEditingController customController;
  late TextEditingController reasonController;
  double selectedDiscount = 0;
  String? reason;

  @override
  void initState() {
    super.initState();
    selectedDiscount = widget.currentDiscount;
    reason = widget.currentReason;
    customController = TextEditingController();
    reasonController = TextEditingController(text: reason ?? '');
  }

  @override
  void dispose() {
    customController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.percent, color: AppColors.emptyTable, size: 24),
          const SizedBox(width: 8),
          const Text('İndirim Uygula'),
        ],
      ),
      content: Container(
        width: 400, // Increased for tablet
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İndirim oranını seçin:',
              style: TextStyle(
                fontSize: 16, // Increased for tablet
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Preset discount buttons - Bigger for tablet
            Wrap(
              spacing: 12, // Increased spacing
              runSpacing: 12,
              children: [10, 20, 25, 50].map((percentage) {
                final isSelected = selectedDiscount == percentage;
                return SizedBox(
                  width: 91, // Increased width
                  height: 50, // Added height for better tablet touch
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDiscount = percentage.toDouble();
                        customController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                          ? AppColors.emptyTable 
                          : Colors.white,
                      foregroundColor: isSelected 
                          ? Colors.white 
                          : AppColors.emptyTable,
                      side: BorderSide(
                        color: AppColors.emptyTable,
                        width: 2,
                      ),
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '%$percentage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Increased font size for tablet
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20), // Increased spacing
            
            // Custom discount input - Bigger for tablet
            TextField(
              controller: customController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16), // Increased font size
              decoration: InputDecoration(
                labelText: 'Özel İndirim Oranı',
                labelStyle: const TextStyle(fontSize: 16),
                suffixText: '%',
                suffixStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.emptyTable, width: 2),
                ),
                prefixIcon: Icon(Icons.edit, color: AppColors.emptyTable, size: 24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Increased padding
              ),
              onChanged: (value) {
                double? custom = double.tryParse(value);
                if (custom != null && custom >= 0 && custom <= 100) {
                  setState(() {
                    selectedDiscount = custom;
                  });
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // Reason input - Bigger for tablet
            TextField(
              controller: reasonController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'İndirim Sebebi (Opsiyonel)',
                labelStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.emptyTable, width: 2),
                ),
                prefixIcon: Icon(Icons.note, color: AppColors.emptyTable, size: 24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                reason = value.isEmpty ? null : value;
              },
            ),
            
            if (selectedDiscount > 0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emptyTable.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emptyTable.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.emptyTable, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '%${selectedDiscount.toStringAsFixed(0)} indirim uygulanacak',
                        style: TextStyle(
                          color: AppColors.emptyTable,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              selectedDiscount = 0;
              reason = null;
              customController.clear();
              reasonController.clear();
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
            widget.onApply(selectedDiscount, reason);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emptyTable,
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