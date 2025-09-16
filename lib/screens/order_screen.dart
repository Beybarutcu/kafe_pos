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
import '../widgets/order_summary_card.dart';

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
      
      // Add "Favoriler" as the first category
      List<String> categoriesWithFavorites = ['Favoriler', ...loadedCategories];
      
      setState(() {
        categories = categoriesWithFavorites;
        menuItems = loadedItems;
        selectedCategory = 'Favoriler'; // Start with favorites
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
      
      // Try to get existing order for this table
      Order? existingOrder = await _databaseService.getCurrentOrderForTable(widget.table.id!);
      
      if (existingOrder != null) {
        // Load existing order
        currentOrder = existingOrder;
        orderItems = await _databaseService.getOrderItems(existingOrder.id!);
      } else {
        // Create new order
        final orderId = await _databaseService.insertOrder(Order(
          tableId: widget.table.id!,
          subtotal: 0.0,
          finalTotal: 0.0,
          status: AppConstants.orderStatusPending,
          createdAt: DateTime.now(),
        ));
        
        currentOrder = await _databaseService.getOrderById(orderId);
        orderItems = [];
        
        // Update table status
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusOccupied,
          orderId: orderId,
        );
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
      // For now, show first 6 items as favorites (you can implement a favorites system later)
      filteredItems = menuItems.take(6).toList();
    } else {
      filteredItems = menuItems.where((item) => item.category == selectedCategory).toList();
    }
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
                // Left side - Menu categories and items
                Expanded(
                  flex: 2,
                  child: _buildMenuSection(),
                ),
                
                // Right side - Order summary
                SizedBox(
                  width: 300,
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
          // Categories
          _buildCategoryTabs(),
          
          // Menu items
          Expanded(
            child: _buildMenuItemsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12, // Space between buttons horizontally
        runSpacing: 12, // Space between lines vertically
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
              width: 120, // Fixed width for all buttons
              height: 64, // Fixed height
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    fontSize: 14, // Slightly smaller to fit better
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow 2 lines for long text
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
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
          // Order header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Sipariş Özeti',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Order items
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
                      return OrderSummaryCard(
                        orderItem: orderItems[index],
                        onQuantityChanged: (newQuantity) {
                          _updateItemQuantity(orderItems[index], newQuantity);
                        },
                        onRemove: () => _removeItemFromOrder(orderItems[index]),
                      );
                    },
                  ),
          ),
          
          // Order total and actions
          if (orderItems.isNotEmpty) _buildOrderTotal(),
        ],
      ),
    );
  }

  Widget _buildOrderTotal() {
    double subtotal = orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.background, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ara Toplam:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} ${TurkishStrings.currency}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addItemToOrder(MenuItem menuItem) async {
    try {
      // Check if item already exists in order
      final existingIndex = orderItems.indexWhere((item) => item.menuItemName == menuItem.name);
      
      if (existingIndex != -1) {
        // Update quantity of existing item
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
        // Add new item to order
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
      
      // Update table status to occupied and set current order ID
      await _databaseService.updateTableStatus(
        widget.table.id!,
        AppConstants.tableStatusOccupied,
        orderId: currentOrder!.id!,
      );
      
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
        setState(() {
          orderItems[index] = updatedItem;
        });
        await _updateOrderTotal();
        
        // Force update table status to trigger table card refresh
        await _databaseService.updateTableStatus(
          widget.table.id!,
          AppConstants.tableStatusOccupied,
          orderId: currentOrder!.id!,
        );
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
      });
      
      await _updateOrderTotal();
      
      // If no items left, make table empty
      await _checkAndUpdateTableStatus();
      
      // Force update table status in database to trigger table card refresh
      if (orderItems.isNotEmpty) {
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

  Future<void> _checkAndUpdateTableStatus() async {
    if (orderItems.isEmpty && currentOrder != null) {
      try {
        // Delete empty order
        await _databaseService.deleteOrderItem(currentOrder!.id!);
        
        // Update table status to empty
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
    // Check if table should be empty when going back
    await _checkAndUpdateTableStatus();
    Navigator.of(context).pop();
  }

  Future<void> _updateOrderTotal() async {
    if (currentOrder == null) return;
    
    try {
      double subtotal = orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      final updatedOrder = currentOrder!.copyWith(
        subtotal: subtotal,
        finalTotal: subtotal, // Will be updated with discounts in payment screen
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
    
    // TODO: Navigate to payment screen
    _showInfoSnackBar('Ödeme ekranı yakında eklenecek...');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.occupiedTable,
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