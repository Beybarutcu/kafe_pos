// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import '../models/table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';
import '../utils/constants.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/discount_dialog.dart';
import '../widgets/treat_dialog.dart';
import '../widgets/split_payment_dialog.dart';

class OrderScreen extends StatefulWidget {
  final CafeTable table;

  const OrderScreen({
    super.key,
    required this.table,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  List<String> categories = [];
  List<MenuItem> menuItems = [];
  List<MenuItem> filteredItems = [];
  String selectedCategory = '';
  
  Order? currentOrder;
  List<OrderItem> orderItems = [];
  
  bool isLoadingMenu = true;
  bool isLoadingOrder = false;
  bool isOrderSummaryExpanded = false;
  
  double discountPercentage = 0.0;
  String? discountReason;
  Map<int, int> treatCounts = {};

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadMenuData();
    await _loadOrCreateOrder();
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() => isLoadingMenu = true);
      
      final loadedCategories = await _databaseService.getMenuCategories();
      final loadedItems = await _databaseService.getAllMenuItems();
      
      List<String> categoriesWithFavorites = ['Favoriler', ...loadedCategories];
      
      setState(() {
        categories = categoriesWithFavorites;
        menuItems = loadedItems;
        selectedCategory = 'Favoriler';
        _filterItemsByCategory();
        isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => isLoadingMenu = false);
      _showErrorSnackBar('Menü yüklenirken hata: $e');
    }
  }

  Future<void> _loadOrCreateOrder() async {
    try {
      setState(() => isLoadingOrder = true);
      
      if (widget.table.id == -1) {
        final orderId = await _databaseService.insertOrder(Order(
          tableId: -1,
          subtotal: 0.0,
          finalTotal: 0.0,
          status: AppConstants.orderStatusPending,
          createdAt: DateTime.now(),
        ));
        
        currentOrder = await _databaseService.getOrderById(orderId);
        orderItems = [];
      } else {
        Order? existingOrder = await _databaseService.getCurrentOrderForTable(widget.table.id!);
        
        if (existingOrder != null) {
          currentOrder = existingOrder;
          orderItems = await _databaseService.getOrderItems(existingOrder.id!);
          
          if (existingOrder.subtotal > 0) {
            discountPercentage = existingOrder.discountAmount > 0 
                ? (existingOrder.discountAmount / existingOrder.subtotal) * 100 
                : 0.0;
          }
          discountReason = existingOrder.discountReason;
          
          treatCounts.clear();
          for (final item in orderItems) {
            if (item.isTreat) {
              treatCounts[item.id!] = (treatCounts[item.id!] ?? 0) + 1;
            }
          }
        } else {
          final orderId = await _databaseService.insertOrder(Order(
            tableId: widget.table.id!,
            subtotal: 0.0,
            finalTotal: 0.0,
            status: AppConstants.orderStatusPending,
            createdAt: DateTime.now(),
          ));
          
          currentOrder = await _databaseService.getOrderById(orderId);
          orderItems = [];
          
          await _databaseService.updateTableStatus(
            widget.table.id!,
            AppConstants.tableStatusOccupied,
            orderId: orderId,
          );
        }
      }
      
      setState(() => isLoadingOrder = false);
    } catch (e) {
      setState(() => isLoadingOrder = false);
      _showErrorSnackBar('Sipariş yüklenirken hata: $e');
    }
  }

  void _filterItemsByCategory() {
    if (selectedCategory.isEmpty) {
      filteredItems = menuItems;
    } else if (selectedCategory == 'Favoriler') {
      filteredItems = menuItems.take(6).toList();
    } else {
      filteredItems = menuItems.where((item) => item.category == selectedCategory).toList();
    }
  }

  double calculateSubtotal() {
    return orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double calculateDiscountAmount() {
    double subtotal = calculateSubtotal();
    return (subtotal * discountPercentage) / 100;
  }

  double calculateTreatAmount() {
    double total = 0.0;
    for (final item in orderItems) {
      int treatCount = treatCounts[item.id!] ?? 0;
      if (treatCount > 0) {
        total += (item.unitPrice * treatCount);
      }
    }
    return total;
  }

  int getTreatCountForItem(int itemId) {
    return treatCounts[itemId] ?? 0;
  }

  double calculateFinalTotal() {
    double subtotal = calculateSubtotal();
    double discountAmount = calculateDiscountAmount();
    double treatAmount = calculateTreatAmount();
    return subtotal - discountAmount - treatAmount;
  }

  int _turkishCompare(String a, String b) {
    const turkishOrder = 'AaBbCcÇçDdEeFfGgĞğHhIıİiJjKkLlMmNnOoÖöPpRrSsŞşTtUuÜüVvYyZz';
    
    int minLength = a.length < b.length ? a.length : b.length;
    
    for (int i = 0; i < minLength; i++) {
      int indexA = turkishOrder.indexOf(a[i]);
      int indexB = turkishOrder.indexOf(b[i]);
      
      if (indexA == -1) indexA = 1000 + a.codeUnitAt(i);
      if (indexB == -1) indexB = 1000 + b.codeUnitAt(i);
      
      if (indexA != indexB) {
        return indexA - indexB;
      }
    }
    
    return a.length - b.length;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.table.name} - Sipariş'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPress,
        ),
      ),
      body: isLoadingMenu || isLoadingOrder
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isPortrait ? _buildVerticalLayout() : _buildHorizontalLayout(),
    );
  }

  // VERTICAL LAYOUT
  Widget _buildVerticalLayout() {
    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(
          child: _buildScrollableMenuList(),
        ),
        if (orderItems.isNotEmpty) _buildExpandableOrderSummary(),
      ],
    );
  }

  Widget _buildScrollableMenuList() {
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategoride ürün bulunmuyor',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final sortedItems = List<MenuItem>.from(filteredItems);
    sortedItems.sort((a, b) => _turkishCompare(a.name, b.name));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 items per row
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Slightly taller than square
      ),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return _buildSquareMenuItem(item);
      },
    );
  }

  // SQUARE MENU ITEM CARD (4 per row)
  Widget _buildSquareMenuItem(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addItemToOrder(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item name (top)
                Expanded(
                  child: Center(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Price (middle)
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Add button (bottom)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ekle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // EXPANDABLE ORDER SUMMARY
  Widget _buildExpandableOrderSummary() {
    double finalTotal = calculateFinalTotal();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  isOrderSummaryExpanded = !isOrderSummaryExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isOrderSummaryExpanded ? Icons.expand_more : Icons.expand_less,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sipariş Özeti',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${orderItems.length} Ürün',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${finalTotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isOrderSummaryExpanded ? 300 : 0,
              child: isOrderSummaryExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: orderItems.length,
                            itemBuilder: (context, index) {
                              return _buildVerticalOrderItem(orderItems[index]);
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        _buildOrderSummaryTotals(),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showDiscountDialog,
                    icon: const Icon(Icons.percent),
                    color: discountPercentage > 0 ? AppColors.discount : AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: discountPercentage > 0 
                          ? AppColors.discount.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showTreatDialog,
                    icon: const Icon(Icons.favorite),
                    color: treatCounts.isNotEmpty ? AppColors.treat : AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: treatCounts.isNotEmpty 
                          ? AppColors.treat.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showSplitPaymentDialog,
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text('Ödeme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildVerticalOrderItem(OrderItem item) {
    final treatCount = getTreatCountForItem(item.id!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isPaid 
            ? Colors.grey.shade100 
            : (item.isPartiallyPaid ? Colors.blue.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isPaid 
              ? Colors.grey.shade300 
              : (item.isPartiallyPaid ? Colors.blue.shade200 : Colors.grey.shade200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.menuItemName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: item.isPaid ? TextDecoration.lineThrough : null,
                            color: item.isPaid ? Colors.grey : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: Colors.green.shade700),
                              const SizedBox(width: 2),
                              Text(
                                'Ödendi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (item.isPartiallyPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Kısmi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        item.formattedUnitPrice,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ' × ${item.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (item.isPartiallyPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${item.paidQuantity} ödendi, ${item.remainingQuantity} kaldı',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (treatCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 11, color: AppColors.treat),
                          const SizedBox(width: 4),
                          Text(
                            'İkram: $treatCount adet',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.treat,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: item.isPaid ? null : () => _updateItemQuantity(item, item.quantity - 1),
                        iconSize: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: item.isPaid ? null : () => _updateItemQuantity(item, item.quantity + 1),
                        iconSize: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.formattedTotalPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.isPaid ? Colors.grey : AppColors.primary,
                    decoration: item.isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.isPartiallyPaid)
                  Text(
                    'Kalan: ${item.formattedRemainingAmount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                if (!item.isPaid)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItemFromOrder(item),
                    color: Colors.red.shade400,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryTotals() {
    double subtotal = calculateSubtotal();
    double discountAmount = calculateDiscountAmount();
    double treatAmount = calculateTreatAmount();
    double finalTotal = calculateFinalTotal();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ara Toplam:', style: TextStyle(fontSize: 14)),
              Text(
                '${subtotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (discountAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'İndirim (%${discountPercentage.toStringAsFixed(0)}):',
                  style: const TextStyle(fontSize: 14, color: AppColors.discount),
                ),
                Text(
                  '-${discountAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                  style: const TextStyle(fontSize: 14, color: AppColors.discount, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (treatAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('İkram:', style: TextStyle(fontSize: 14, color: AppColors.treat)),
                Text(
                  '-${treatAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                  style: const TextStyle(fontSize: 14, color: AppColors.treat, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (discountAmount > 0 || treatAmount > 0) const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${finalTotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HORIZONTAL LAYOUT
  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildMenuSection(),
        ),
        SizedBox(
          width: 350,
          child: _buildOrderSummary(),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _buildMenuItemsGrid(crossAxisCount: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = category == selectedCategory;
            final isFavorites = category == 'Favoriler';
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      _filterItemsByCategory();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isFavorites ? AppColors.treat : AppColors.primary)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected 
                            ? (isFavorites ? AppColors.treat : AppColors.primary)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
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
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItemsGrid({required int crossAxisCount}) {
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategoride ürün bulunmuyor',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return MenuItemCard(
          menuItem: filteredItems[index],
          onTap: (item) => _addItemToOrder(item),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Sipariş Özeti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: orderItems.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz ürün eklenmedi',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) => _buildOrderItem(orderItems[index]),
                  ),
          ),
          
          if (orderItems.isNotEmpty) _buildOrderTotal(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final treatCount = getTreatCountForItem(item.id!);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: item.isPaid ? 0 : 2,
      color: item.isPaid 
          ? Colors.grey.shade100 
          : (item.isPartiallyPaid ? Colors.blue.shade50 : Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      decoration: item.isPaid ? TextDecoration.lineThrough : null,
                      color: item.isPaid ? Colors.grey : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (item.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Ödendi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (item.isPartiallyPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Kısmi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Text(
                  item.formattedUnitPrice,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: item.isPaid ? null : () => _updateItemQuantity(item, item.quantity - 1),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 30),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: item.isPaid ? null : () => _updateItemQuantity(item, item.quantity + 1),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.formattedTotalPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.isPaid ? Colors.grey : AppColors.primary,
                        decoration: item.isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (item.isPartiallyPaid)
                      Text(
                        'Kalan: ${item.formattedRemainingAmount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                if (!item.isPaid)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItemFromOrder(item),
                    color: Colors.red.shade400,
                    iconSize: 22,
                  ),
              ],
            ),
            
            if (item.isPartiallyPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              '${item.paidQuantity} adet ödendi, ${item.remainingQuantity} adet kaldı',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (treatCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.treat.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.treat.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 14, color: AppColors.treat),
                      const SizedBox(width: 6),
                      Text(
                        'İkram: $treatCount adet',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.treat,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal() {
    double subtotal = calculateSubtotal();
    double discountAmount = calculateDiscountAmount();
    double treatAmount = calculateTreatAmount();
    double finalTotal = calculateFinalTotal();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ara Toplam:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          
          if (discountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İndirim (%${discountPercentage.toStringAsFixed(0)}):',
                    style: const TextStyle(fontSize: 14, color: AppColors.discount),
                  ),
                  Text(
                    '-${discountAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                    style: const TextStyle(fontSize: 14, color: AppColors.discount),
                  ),
                ],
              ),
            ),
          
          if (treatAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'İkram:',
                    style: TextStyle(fontSize: 14, color: AppColors.treat),
                  ),
                  Text(
                    '-${treatAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                    style: const TextStyle(fontSize: 14, color: AppColors.treat),
                  ),
                ],
              ),
            ),
          
          if (discountAmount > 0 || treatAmount > 0)
            const Divider(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${finalTotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              IconButton(
                onPressed: _showDiscountDialog,
                icon: const Icon(Icons.percent),
                color: discountPercentage > 0 ? AppColors.discount : AppColors.textSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: discountPercentage > 0 
                      ? AppColors.discount.withOpacity(0.1)
                      : Colors.transparent,
                ),
              ),
              
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: _showTreatDialog,
                icon: const Icon(Icons.favorite),
                color: treatCounts.isNotEmpty ? AppColors.treat : AppColors.textSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: treatCounts.isNotEmpty 
                      ? AppColors.treat.withOpacity(0.1)
                      : Colors.transparent,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showSplitPaymentDialog,
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('Ödeme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DiscountDialog(
          currentDiscount: discountPercentage,
          currentReason: discountReason,
          onApply: (percentage, reason) {
            setState(() {
              discountPercentage = percentage;
              discountReason = reason;
            });
            _updateOrderTotal();
          },
        );
      },
    );
  }

  void _showTreatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TreatDialog(
          orderItems: orderItems,
          currentTreatCounts: treatCounts,
          onApply: (newTreatCounts) {
            setState(() {
              treatCounts = newTreatCounts;
            });
            _updateTreatItems();
          },
        );
      },
    );
  }

  void _showSplitPaymentDialog() {
    if (orderItems.isEmpty) {
      _showErrorSnackBar('Sipariş boş, önce ürün ekleyin');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SplitPaymentDialog(
          orderItems: orderItems,
          onPaymentComplete: _processSplitPayment,
        );
      },
    );
  }

  Future<void> _processSplitPayment(List<OrderItem> paidItems, String paymentMethod) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      );
      
      double paidAmount = 0.0;
      
      for (var item in paidItems) {
        await _databaseService.updateOrderItem(item);
        
        final oldItem = orderItems.firstWhere((i) => i.id == item.id);
        int justPaidQty = item.paidQuantity - oldItem.paidQuantity;
        paidAmount += item.unitPrice * justPaidQty;
        
        final index = orderItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          setState(() {
            orderItems[index] = item;
          });
        }
      }
      
      bool allPaid = orderItems.every((item) => item.isPaid);
      
      if (allPaid) {
        await _completeFullOrder();
      } else {
        await _updateOrderTotal();
        
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ödeme alındı: ${paidAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Ödeme işlenirken hata: $e');
    }
  }

  Future<void> _completeFullOrder() async {
    try {
      if (currentOrder == null) return;
      
      double subtotal = calculateSubtotal();
      double discountAmount = calculateDiscountAmount();
      double treatAmount = calculateTreatAmount();
      double finalTotal = calculateFinalTotal();
      
      final completedOrder = currentOrder!.copyWith(
        subtotal: subtotal,
        discountAmount: discountAmount,
        discountType: discountPercentage > 0 ? 'yüzde' : null,
        discountReason: discountReason,
        treatAmount: treatAmount,
        treatReason: treatCounts.isNotEmpty 
            ? 'İkram (${treatCounts.values.fold(0, (sum, count) => sum + count)} adet)' 
            : null,
        finalTotal: finalTotal,
        paymentMethod: 'karışık',
        status: AppConstants.orderStatusCompleted,
      );
      
      await _databaseService.updateOrder(completedOrder);
      
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _databaseService.updateDailyReport(dateString, finalTotal, 1);
      
      if (widget.table.id != -1) {
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusEmpty,
        );
      }
      
      Navigator.of(context).pop();
      
      _showSuccessDialog('karışık', finalTotal);
      
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Sipariş tamamlanırken hata: $e');
    }
  }

  Future<void> _addItemToOrder(MenuItem menuItem) async {
    try {
      final existingIndex = orderItems.indexWhere((item) => 
        item.menuItemName == menuItem.name && !item.isPaid
      );
      
      if (existingIndex != -1) {
        final existingItem = orderItems[existingIndex];
        final newQuantity = existingItem.quantity + 1;
        final newTotalPrice = menuItem.price * newQuantity;
        
        final updatedItem = existingItem.copyWith(
          quantity: newQuantity,
          totalPrice: newTotalPrice,
        );
        
        await _databaseService.updateOrderItem(updatedItem);
        
        setState(() {
          orderItems[existingIndex] = updatedItem;
        });
      } else {
        final orderItem = OrderItem(
          orderId: currentOrder!.id!,
          menuItemName: menuItem.name,
          quantity: 1,
          unitPrice: menuItem.price,
          totalPrice: menuItem.price,
        );
        
        final itemId = await _databaseService.insertOrderItem(orderItem);
        final newItem = orderItem.copyWith(id: itemId);
        
        setState(() {
          orderItems.add(newItem);
        });
      }
      
      await _updateOrderTotal();
      
      if (widget.table.id != -1) {
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusOccupied,
          orderId: currentOrder!.id!,
        );
      }
      
    } catch (e) {
      _showErrorSnackBar('Ürün eklenirken hata: $e');
    }
  }

  Future<void> _updateItemQuantity(OrderItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItemFromOrder(item);
      return;
    }
    
    try {
      final newTotalPrice = item.unitPrice * newQuantity;
      final updatedItem = item.copyWith(
        quantity: newQuantity,
        totalPrice: newTotalPrice,
      );
      
      await _databaseService.updateOrderItem(updatedItem);
      
      final index = orderItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final currentTreatCount = getTreatCountForItem(item.id!);
        if (currentTreatCount > newQuantity) {
          setState(() {
            treatCounts[item.id!] = newQuantity;
          });
        }
        
        setState(() {
          orderItems[index] = updatedItem;
        });
        
        await _updateOrderTotal();
        
        if (widget.table.id != -1) {
          await _databaseService.updateTableStatus(
            widget.table.id!,
            AppConstants.tableStatusOccupied,
            orderId: currentOrder!.id!,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ürün güncellenirken hata: $e');
    }
  }

  Future<void> _removeItemFromOrder(OrderItem item) async {
    try {
      await _databaseService.deleteOrderItem(item.id!);
      
      setState(() {
        orderItems.removeWhere((i) => i.id == item.id);
        treatCounts.remove(item.id);
      });
      
      await _updateOrderTotal();
      await _checkAndUpdateTableStatus();
      
      if (orderItems.isNotEmpty && widget.table.id != -1) {
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusOccupied,
          orderId: currentOrder!.id!,
        );
      }
      
    } catch (e) {
      _showErrorSnackBar('Ürün silinirken hata: $e');
    }
  }

  Future<void> _updateTreatItems() async {
    try {
      for (final item in orderItems) {
        final treatCount = getTreatCountForItem(item.id!);
        final shouldHaveTreatFlag = treatCount > 0;
        
        if (item.isTreat != shouldHaveTreatFlag) {
          final updatedItem = item.copyWith(
            isTreat: shouldHaveTreatFlag,
            treatReason: shouldHaveTreatFlag ? 'İkram ($treatCount adet)' : null,
          );
          await _databaseService.updateOrderItem(updatedItem);
          
          final index = orderItems.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            orderItems[index] = updatedItem;
          }
        }
      }
      
      await _updateOrderTotal();
    } catch (e) {
      _showErrorSnackBar('İkramlar güncellenirken hata: $e');
    }
  }

  Future<void> _checkAndUpdateTableStatus() async {
    if (orderItems.isEmpty && currentOrder != null && widget.table.id != -1) {
      try {
        await _databaseService.deleteOrder(currentOrder!.id!);
        
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusEmpty,
        );
        
        setState(() {
          currentOrder = null;
        });
      } catch (e) {
        print('Error updating table status: $e');
      }
    }
  }

  Future<void> _handleBackPress() async {
    if (widget.table.id != -1) {
      await _checkAndUpdateTableStatus();
    }
    Navigator.of(context).pop();
  }

  Future<void> _updateOrderTotal() async {
    if (currentOrder == null) return;
    
    try {
      double subtotal = calculateSubtotal();
      double discountAmount = calculateDiscountAmount();
      double treatAmount = calculateTreatAmount();
      double finalTotal = calculateFinalTotal();
      
      final updatedOrder = currentOrder!.copyWith(
        subtotal: subtotal,
        discountAmount: discountAmount,
        discountType: discountPercentage > 0 ? 'yüzde' : null,
        discountReason: discountReason,
        treatAmount: treatAmount,
        treatReason: treatCounts.isNotEmpty ? 'İkram (${treatCounts.values.fold(0, (sum, count) => sum + count)} adet)' : null,
        finalTotal: finalTotal,
      );
      
      await _databaseService.updateOrder(updatedOrder);
      
      setState(() {
        currentOrder = updatedOrder;
      });
    } catch (e) {
      _showErrorSnackBar('Sipariş güncellenirken hata: $e');
    }
  }

  void _showSuccessDialog(String paymentMethod, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.emptyTable.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: AppColors.emptyTable,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Ödeme Tamamlandı!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ödeme Yöntemi:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            paymentMethod == 'nakit' ? 'Nakit' : paymentMethod == 'kart' ? 'Kredi Kartı' : 'Karışık',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tutar:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${amount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}