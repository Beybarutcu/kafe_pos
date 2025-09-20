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
import '../widgets/payment_dialog.dart';

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
  
  // Discount and treat state
  double discountPercentage = 0.0;
  String? discountReason;
  Map<int, int> treatCounts = {}; // itemId -> how many pieces are treats

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
      
      // Special handling for take away orders (table ID -1)
      if (widget.table.id == -1) {
        // For take away, always create a new order
        final orderId = await _databaseService.insertOrder(Order(
          tableId: -1, // Special table ID for take away
          subtotal: 0.0,
          finalTotal: 0.0,
          status: AppConstants.orderStatusPending,
          createdAt: DateTime.now(),
        ));
        
        currentOrder = await _databaseService.getOrderById(orderId);
        orderItems = [];
        
        // Don't update table status for take away orders
      } else {
        // Normal table order handling
        Order? existingOrder = await _databaseService.getCurrentOrderForTable(widget.table.id!);
        
        if (existingOrder != null) {
          currentOrder = existingOrder;
          orderItems = await _databaseService.getOrderItems(existingOrder.id!);
          
          // Load existing discounts
          if (existingOrder.subtotal > 0) {
            discountPercentage = existingOrder.discountAmount > 0 
                ? (existingOrder.discountAmount / existingOrder.subtotal) * 100 
                : 0.0;
          }
          discountReason = existingOrder.discountReason;
          
          // Load treat counts from database
          treatCounts.clear();
          for (final item in orderItems) {
            if (item.isTreat) {
              treatCounts[item.id!] = (treatCounts[item.id!] ?? 0) + 1;
            }
          }
        } else {
          // Create new order for normal table
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

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (orderItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: _proceedToPayment,
              tooltip: 'Ödemeye Geç',
            ),
        ],
      ),
      body: isLoadingMenu || isLoadingOrder
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildMenuSection(),
                ),
                SizedBox(
                  width: 350, // Increased width for tablet
                  child: _buildOrderSummary(),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _buildMenuItemsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(20), // Increased padding for tablet
      child: Wrap(
        spacing: 16, // Increased spacing for tablet
        runSpacing: 16,
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          final isFavorites = category == 'Favoriler';
          
          return InkWell(
            onTap: () {
              setState(() {
                selectedCategory = category;
                _filterItemsByCategory();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 140, // Increased width for tablet
              height: 80, // Increased height for tablet
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 16, // Increased font size for tablet
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemsGrid() {
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategoride ürün bulunmuyor',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20), // Increased padding for tablet
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Increased from 3 to 4 for tablet
        crossAxisSpacing: 16, // Increased spacing
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Slightly adjusted ratio
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
            padding: const EdgeInsets.all(20), // Increased padding for tablet
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 24), // Increased icon size
                const SizedBox(width: 12),
                Text(
                  'Sipariş Özeti',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Increased font size for tablet
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
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      final treatCount = getTreatCountForItem(item.id!);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16), // Increased padding
                        decoration: BoxDecoration(
                          color: treatCount > 0 
                              ? AppColors.treat.withOpacity(0.1)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: treatCount > 0 
                                ? AppColors.treat 
                                : AppColors.background, 
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
                                      fontSize: 16, // Increased font size for tablet
                                      fontWeight: FontWeight.bold,
                                      color: treatCount > 0 ? AppColors.treat : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (treatCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.treat,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${treatCount} İKRAM',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11, // Slightly increased
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () => _removeItemFromOrder(item),
                                  icon: const Icon(Icons.close),
                                  color: AppColors.occupiedTable,
                                  iconSize: 20, // Increased for tablet
                                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // Bigger touch target
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onTap: () => _updateItemQuantity(item, item.quantity - 1),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16), // Increased margin
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased padding
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(
                                          fontSize: 16, // Increased font size
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      icon: Icons.add,
                                      onTap: () => _updateItemQuantity(item, item.quantity + 1),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.formattedTotalPrice,
                                      style: const TextStyle(
                                        fontSize: 16, // Increased font size
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (treatCount > 0)
                                      Text(
                                        '-${(item.unitPrice * treatCount).toStringAsFixed(2)} ₺',
                                        style: const TextStyle(
                                          fontSize: 14, // Increased font size
                                          color: AppColors.treat,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          if (orderItems.isNotEmpty) _buildOrderTotal(),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8), // Increased padding for tablet
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20, // Increased icon size for tablet
        ),
      ),
    );
  }

  Widget _buildOrderTotal() {
    double subtotal = calculateSubtotal();
    double discountAmount = calculateDiscountAmount();
    double treatAmount = calculateTreatAmount();
    double finalTotal = calculateFinalTotal();
    int totalTreatItems = treatCounts.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.background, width: 2)),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ara Toplam:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Discount and Treat Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showDiscountDialog,
                  icon: const Icon(Icons.percent, size: 16),
                  label: Text(discountPercentage > 0 
                      ? '%${discountPercentage.toStringAsFixed(0)}'
                      : 'İndirim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: discountPercentage > 0 
                        ? AppColors.discount 
                        : AppColors.discount.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: orderItems.isNotEmpty ? _showTreatDialog : null,
                  icon: const Icon(Icons.favorite, size: 16),
                  label: Text(totalTreatItems > 0 
                      ? '${totalTreatItems} İkram'
                      : 'İkram'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: totalTreatItems > 0 
                        ? AppColors.treat 
                        : AppColors.treat.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Show applied discounts/treats
          if (discountAmount > 0)
            Row(
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
          
          if (treatAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'İkram ($totalTreatItems adet):',
                  style: const TextStyle(fontSize: 14, color: AppColors.treat),
                ),
                Text(
                  '-${treatAmount.toStringAsFixed(2)} ${TurkishStrings.currency}',
                  style: const TextStyle(fontSize: 14, color: AppColors.treat),
                ),
              ],
            ),
          
          if (discountAmount > 0 || treatAmount > 0)
            const Divider(height: 16),
          
          // Final Total
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
          
          // Payment Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proceedToPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text('Ödemeye Geç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _addItemToOrder(MenuItem menuItem) async {
    try {
      final existingIndex = orderItems.indexWhere((item) => item.menuItemName == menuItem.name);
      
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
      
      // Only update table status for normal tables, not take away
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
        // If quantity decreased, adjust treats accordingly
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
        treatCounts.remove(item.id); // Remove treat count for this item
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
    // Only check and update table status for normal tables
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

  void _proceedToPayment() {
    if (orderItems.isEmpty) {
      _showErrorSnackBar('Sipariş boş, önce ürün ekleyin');
      return;
    }
    
    final finalTotal = calculateFinalTotal();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PaymentDialog(
          totalAmount: finalTotal,
          onPaymentSelected: _processPayment,
        );
      },
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    try {
      // Close the payment dialog first
      Navigator.of(context).pop();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      );
      
      if (currentOrder == null) {
        Navigator.of(context).pop(); // Close loading
        _showErrorSnackBar('Sipariş bulunamadı');
        return;
      }
      
      // Calculate final amounts
      double subtotal = calculateSubtotal();
      double discountAmount = calculateDiscountAmount();
      double treatAmount = calculateTreatAmount();
      double finalTotal = calculateFinalTotal();
      
      // Update order with payment information
      final completedOrder = currentOrder!.copyWith(
        subtotal: subtotal,
        discountAmount: discountAmount,
        discountType: discountPercentage > 0 ? 'yüzde' : null,
        discountReason: discountReason,
        treatAmount: treatAmount,
        treatReason: treatCounts.isNotEmpty ? 'İkram (${treatCounts.values.fold(0, (sum, count) => sum + count)} adet)' : null,
        finalTotal: finalTotal,
        paymentMethod: paymentMethod,
        status: AppConstants.orderStatusCompleted,
      );
      
      // Save the completed order
      await _databaseService.updateOrder(completedOrder);
      
      // Update daily reports (optional)
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _databaseService.updateDailyReport(dateString, finalTotal, 1);
      
      // Handle table cleanup for normal tables (not take away)
      if (widget.table.id != -1) {
        // Clear table status for normal tables
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusEmpty,
        );
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      _showSuccessDialog(paymentMethod, finalTotal);
      
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      _showErrorSnackBar('Ödeme işlenirken hata oluştu: $e');
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
                // Success icon
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
                            paymentMethod == 'nakit' ? 'Nakit' : 'Kredi Kartı',
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
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _returnToTableSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tamam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _returnToTableSelection() {
    // Close success dialog
    Navigator.of(context).pop();
    
    // Return to table selection screen
    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.occupiedTable,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emptyTable,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}