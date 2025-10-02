// lib/widgets/order/menu_section.dart
import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../utils/colors.dart';

class MenuSection extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<MenuItem> filteredItems;
  final Function(String) onCategorySelected;
  final Function(MenuItem) onItemTap;

  const MenuSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.filteredItems,
    required this.onCategorySelected,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(child: _buildItemsGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minCategoryWidth = 100;
          const double spacing = 12;
          int maxCategoriesPerRow = ((constraints.maxWidth + spacing) / (minCategoryWidth + spacing)).floor();
          bool useWrap = categories.length > maxCategoriesPerRow;
          
          if (useWrap) {
            return Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: categories.map((category) => _buildCategoryButton(category)).toList(),
            );
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: spacing),
                  child: _buildCategoryButton(category),
                )).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = category == selectedCategory;
    final isFavorites = category == 'Favoriler';
    
    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isFavorites ? AppColors.treat : AppColors.primary)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (isFavorites ? AppColors.treat : AppColors.primary)
                : AppColors.background,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildItemsGrid() {
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text('Bu kategoride ürün bulunmuyor', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardWidth = 140;
        const double minSpacing = 16;
        
        int cardsPerRow = ((constraints.maxWidth + minSpacing) / (cardWidth + minSpacing)).floor();
        if (cardsPerRow < 1) cardsPerRow = 1;
        
        double actualSpacing = cardsPerRow > 1 
            ? (constraints.maxWidth - (cardsPerRow * cardWidth)) / (cardsPerRow - 1)
            : minSpacing;
        actualSpacing = actualSpacing.clamp(minSpacing, 40.0);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: actualSpacing,
              runSpacing: 16,
              children: filteredItems.map((item) => SizedBox(
                width: cardWidth,
                height: 140,
                child: _buildItemCard(item),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return InkWell(
      onTap: () => onItemTap(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${item.price.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}