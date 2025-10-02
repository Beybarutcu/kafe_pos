// lib/screens/order_screen.dart - Complete working version with horizontal layout
import 'package:flutter/material.dart';
import '../models/table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';
import '../utils/constants.dart';
import '../widgets/discount_dialog.dart';
import '../widgets/treat_dialog.dart';
import '../widgets/payment_dialog.dart';

class OrderScreen extends StatefulWidget {
  final CafeTable table;

  const OrderScreen({super.key, required this.table});

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
      
      setState(() {
        categories = ['Favoriler', ...loadedCategories];
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
          await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusOccupied, orderId: orderId);
        }
      }
      
      setState(() => isLoadingOrder = false);
    } catch (e) {
      setState(() => isLoadingOrder = false);
      _showErrorSnackBar('Sipariş yüklenirken hata: $e');
    }
  }

  void _filterItemsByCategory() {
    if (selectedCategory == 'Favoriler') {
      filteredItems = menuItems.take(6).toList();
    } else {
      filteredItems = menuItems.where((item) => item.category == selectedCategory).toList();
    }
    // TURKISH ALPHABETICAL SORTING
    filteredItems.sort((a, b) => _turkishCompare(a.name, b.name));
  }

  int _turkishCompare(String a, String b) {
    const turkishOrder = 'AaBbCcÇçDdEeFfGgĞğHhIıİiJjKkLlMmNnOoÖöPpRrSsŞşTtUuÜüVvYyZz';
    int minLength = a.length < b.length ? a.length : b.length;
    
    for (int i = 0; i < minLength; i++) {
      int indexA = turkishOrder.indexOf(a[i]);
      int indexB = turkishOrder.indexOf(b[i]);
      
      if (indexA == -1) indexA = 1000 + a.codeUnitAt(i);
      if (indexB == -1) indexB = 1000 + b.codeUnitAt(i);
      
      if (indexA != indexB) return indexA - indexB;
    }
    return a.length - b.length;
  }

  double calculateSubtotal() => orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double calculateDiscountAmount() => calculateSubtotal() * (discountPercentage / 100);
  
  double calculateTreatAmount() {
    double total = 0.0;
    for (final item in orderItems) {
      int treatCount = treatCounts[item.id!] ?? 0;
      if (treatCount > 0) total += (item.unitPrice * treatCount);
    }
    return total;
  }
  
  int getTreatCountForItem(int itemId) => treatCounts[itemId] ?? 0;
  double calculateFinalTotal() => calculateSubtotal() - calculateDiscountAmount() - calculateTreatAmount();

  Future<void> _addItemToOrder(MenuItem menuItem) async {
    try {
      final existingIndex = orderItems.indexWhere((item) => item.menuItemName == menuItem.name);
      
      if (existingIndex != -1) {
        final existingItem = orderItems[existingIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
          totalPrice: menuItem.price * (existingItem.quantity + 1),
        );
        await _databaseService.updateOrderItem(updatedItem);
        setState(() => orderItems[existingIndex] = updatedItem);
      } else {
        final orderItem = OrderItem(
          orderId: currentOrder!.id!,
          menuItemName: menuItem.name,
          quantity: 1,
          unitPrice: menuItem.price,
          totalPrice: menuItem.price,
        );
        final itemId = await _databaseService.insertOrderItem(orderItem);
        setState(() => orderItems.add(orderItem.copyWith(id: itemId)));
      }
      
      await _updateOrderTotal();
      if (widget.table.id != -1) {
        await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusOccupied, orderId: currentOrder!.id!);
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
      final updatedItem = item.copyWith(
        quantity: newQuantity,
        totalPrice: item.unitPrice * newQuantity,
      );
      await _databaseService.updateOrderItem(updatedItem);
      
      final index = orderItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final currentTreatCount = getTreatCountForItem(item.id!);
        if (currentTreatCount > newQuantity) {
          setState(() => treatCounts[item.id!] = newQuantity);
        }
        setState(() => orderItems[index] = updatedItem);
        await _updateOrderTotal();
        
        if (widget.table.id != -1) {
          await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusOccupied, orderId: currentOrder!.id!);
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
        await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusOccupied, orderId: currentOrder!.id!);
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
          if (index != -1) orderItems[index] = updatedItem;
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
        await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusEmpty);
        setState(() => currentOrder = null);
      } catch (e) {
        print('Error updating table status: $e');
      }
    }
  }

  Future<void> _updateOrderTotal() async {
    if (currentOrder == null) return;
    
    try {
      final updatedOrder = currentOrder!.copyWith(
        subtotal: calculateSubtotal(),
        discountAmount: calculateDiscountAmount(),
        discountType: discountPercentage > 0 ? 'yüzde' : null,
        discountReason: discountReason,
        treatAmount: calculateTreatAmount(),
        treatReason: treatCounts.isNotEmpty ? 'İkram uygulandı' : null,
        finalTotal: calculateFinalTotal(),
      );
      
      await _databaseService.updateOrder(updatedOrder);
      setState(() => currentOrder = updatedOrder);
    } catch (e) {
      _showErrorSnackBar('Sipariş güncellenirken hata: $e');
    }
  }

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        currentDiscount: discountPercentage,
        currentReason: discountReason,
        onApply: (percentage, reason) {
          setState(() {
            discountPercentage = percentage;
            discountReason = reason;
          });
          _updateOrderTotal();
        },
      ),
    );
  }

  void _showTreatDialog() {
    showDialog(
      context: context,
      builder: (context) => TreatDialog(
        orderItems: orderItems,
        currentTreatCounts: treatCounts,
        onApply: (newTreatCounts) {
          setState(() => treatCounts = newTreatCounts);
          _updateTreatItems();
        },
      ),
    );
  }

  void _proceedToPayment() {
    if (orderItems.isEmpty) {
      _showErrorSnackBar('Sipariş boş, önce ürün ekleyin');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PaymentDialog(
        totalAmount: calculateFinalTotal(),
        onPaymentSelected: _processPayment,
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    try {
      Navigator.of(context).pop();
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
      
      if (currentOrder == null) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Sipariş bulunamadı');
        return;
      }
      
      final completedOrder = currentOrder!.copyWith(
        subtotal: calculateSubtotal(),
        discountAmount: calculateDiscountAmount(),
        discountType: discountPercentage > 0 ? 'yüzde' : null,
        discountReason: discountReason,
        treatAmount: calculateTreatAmount(),
        treatReason: treatCounts.isNotEmpty ? 'İkram (${treatCounts.values.fold(0, (sum, count) => sum + count)} adet)' : null,
        finalTotal: calculateFinalTotal(),
        paymentMethod: paymentMethod,
        status: AppConstants.orderStatusCompleted,
      );
      
      await _databaseService.updateOrder(completedOrder);
      
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _databaseService.updateDailyReport(dateString, completedOrder.finalTotal, 1);
      
      if (widget.table.id != -1) {
        await _databaseService.updateTableStatus(widget.table.id!, AppConstants.tableStatusEmpty);
      }
      
      Navigator.of(context).pop();
      _showSuccessDialog(paymentMethod, completedOrder.finalTotal);
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Ödeme işlenirken hata oluştu: $e');
    }
  }

  void _showSuccessDialog(String paymentMethod, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.emptyTable.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 50, color: AppColors.emptyTable),
              ),
              const SizedBox(height: 20),
              const Text('Ödeme Tamamlandı!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Text('${amount.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(paymentMethod == 'nakit' ? 'Nakit Ödeme' : 'Kredi Kartı', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emptyTable,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.occupiedTable, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.table.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoadingMenu
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Row(
              children: [
                Expanded(flex: 2, child: _buildMenuSection()),
                SizedBox(width: 350, child: _buildOrderSummary()),
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
          Expanded(child: _buildScrollableItemsGrid()),
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
      onTap: () {
        setState(() {
          selectedCategory = category;
          _filterItemsByCategory();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isFavorites ? AppColors.treat : AppColors.primary) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? (isFavorites ? AppColors.treat : AppColors.primary) : AppColors.background, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(category, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildScrollableItemsGrid() {
    if (filteredItems.isEmpty) {
      return const Center(child: Text('Bu kategoride ürün bulunmuyor', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)));
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
              children: filteredItems.map((item) => SizedBox(width: cardWidth, height: 140, child: _buildItemCard(item))).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return InkWell(
      onTap: () => _addItemToOrder(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('${item.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
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
            child: const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('Sipariş Özeti', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: orderItems.isEmpty
                ? const Center(child: Text('Henüz ürün eklenmedi', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      final treatCount = getTreatCountForItem(item.id!);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: treatCount > 0 ? AppColors.treat.withOpacity(0.1) : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: treatCount > 0 ? AppColors.treat : AppColors.background, width: treatCount > 0 ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.menuItemName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: treatCount > 0 ? AppColors.treat : AppColors.textPrimary)),
                                ),
                                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.occupiedTable), onPressed: () => _removeItemFromOrder(item), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(onPressed: () => _updateItemQuantity(item, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline), color: AppColors.primary),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                IconButton(onPressed: () => _updateItemQuantity(item, item.quantity + 1), icon: const Icon(Icons.add_circle_outline), color: AppColors.primary),
                                const Spacer(),
                                Text('${item.totalPrice.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            if (treatCount > 0) ...[
                              const SizedBox(height: 4),
                              Text('İkram: $treatCount adet', style: const TextStyle(fontSize: 12, color: AppColors.treat, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _buildTotalsAndActions(),
        ],
      ),
    );
  }

  Widget _buildTotalsAndActions() {
    double subtotal = calculateSubtotal();
    double discountAmount = calculateDiscountAmount();
    double treatAmount = calculateTreatAmount();
    double finalTotal = calculateFinalTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ara Toplam:', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              Text('${subtotal.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          if (discountPercentage > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('İndirim (%${discountPercentage.toStringAsFixed(0)}):', style: const TextStyle(fontSize: 16, color: AppColors.discount)),
                Text('-${discountAmount.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.discount)),
              ],
            ),
          ],
          if (treatAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('İkram:', style: TextStyle(fontSize: 16, color: AppColors.treat)),
                Text('-${treatAmount.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.treat)),
              ],
            ),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: discountPercentage > 0 ? AppColors.discount.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: discountPercentage > 0 ? AppColors.discount : AppColors.textSecondary.withOpacity(0.3), width: 2),
                ),
                child: IconButton(
                  onPressed: _showDiscountDialog,
                  icon: const Icon(Icons.percent, size: 28),
                  color: discountPercentage > 0 ? AppColors.discount : AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: treatCounts.isNotEmpty ? AppColors.treat.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: treatCounts.isNotEmpty ? AppColors.treat : AppColors.textSecondary.withOpacity(0.3), width: 2),
                ),
                child: IconButton(
                  onPressed: _showTreatDialog,
                  icon: const Icon(Icons.favorite, size: 28),
                  color: treatCounts.isNotEmpty ? AppColors.treat : AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proceedToPayment,
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
}