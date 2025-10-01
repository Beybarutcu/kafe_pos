// lib/screens/settings/menu_settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/colors.dart';
import '../../models/menu_item.dart';

class MenuSettingsScreen extends StatefulWidget {
  const MenuSettingsScreen({super.key});

  @override
  State<MenuSettingsScreen> createState() => _MenuSettingsScreenState();
}

class _MenuSettingsScreenState extends State<MenuSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<MenuItem> menuItems = [];
  List<MenuItem> filteredItems = [];
  List<String> categories = [];
  String selectedCategory = 'Tümü';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMenuItems(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadMenuItems() async {
    try {
      setState(() => isLoading = true);
      final loadedItems = await _databaseService.getAllMenuItems();
      setState(() {
        menuItems = loadedItems;
        _filterItems();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Menü ürünleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await _databaseService.getMenuCategories();
      setState(() {
        categories = loadedCategories;
      });
    } catch (e) {
      _showErrorSnackBar('Kategoriler yüklenirken hata: $e');
    }
  }

  void _filterItems() {
    if (selectedCategory == 'Tümü') {
      filteredItems = menuItems;
    } else {
      filteredItems = menuItems.where((item) => item.category == selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menü Yönetimi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header with count and add button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedCategory == 'Tümü'
                              ? 'Toplam ${menuItems.length} ürün'
                              : '$selectedCategory - ${filteredItems.length} ürün',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: categories.isEmpty 
                            ? null 
                            : _showAddMenuItemDialog,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Yeni Ürün', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category filter tabs
                if (categories.isNotEmpty)
                  Container(
                    color: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('Tümü'),
                          const SizedBox(width: 12),
                          ...categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildCategoryChip(category),
                          )),
                        ],
                      ),
                    ),
                  ),
                
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.occupiedTable.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.occupiedTable.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: AppColors.occupiedTable),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Önce kategori oluşturun',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.occupiedTable,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Items grid
                Expanded(
                  child: _buildMenuItemsGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = category == selectedCategory;
    final count = category == 'Tümü' 
        ? menuItems.length 
        : menuItems.where((item) => item.category == category).length;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
          _filterItems();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemsGrid() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              selectedCategory == 'Tümü' 
                  ? 'Henüz ürün bulunmuyor'
                  : '$selectedCategory kategorisinde ürün bulunmuyor',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Yeni Ürün butonuna tıklayarak başlayın',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildMenuItemCard(item);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return InkWell(
      onTap: () => _showEditMenuItemDialog(item),
      onLongPress: () => _showDeleteConfirmation(item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Product name
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emptyTable.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emptyTable,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => _showDeleteConfirmation(item),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.occupiedTable,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenuItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategoryDialog = categories.isNotEmpty ? categories.first : '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Ürün Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryDialog.isNotEmpty ? selectedCategoryDialog : null,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedCategoryDialog = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiyat',
                    suffixText: '₺',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                
                if (name.isEmpty || price == null || selectedCategoryDialog.isEmpty) {
                  _showErrorSnackBar('Lütfen tüm alanları doldurun');
                  return;
                }
                
                if (price <= 0) {
                  _showErrorSnackBar('Fiyat 0\'dan büyük olmalı');
                  return;
                }
                
                try {
                  await _databaseService.insertMenuItem(MenuItem(
                    name: name,
                    price: price,
                    category: selectedCategoryDialog,
                  ));
                  
                  Navigator.pop(context);
                  await _loadMenuItems();
                  _showSuccessSnackBar('Ürün başarıyla eklendi');
                } catch (e) {
                  _showErrorSnackBar('Ürün eklenirken hata: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMenuItemDialog(MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    String selectedCategoryDialog = item.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ürün Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryDialog,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedCategoryDialog = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiyat',
                    suffixText: '₺',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                
                if (name.isEmpty || price == null) {
                  _showErrorSnackBar('Lütfen tüm alanları doldurun');
                  return;
                }
                
                if (price <= 0) {
                  _showErrorSnackBar('Fiyat 0\'dan büyük olmalı');
                  return;
                }
                
                try {
                  await _databaseService.updateMenuItem(item.copyWith(
                    name: name,
                    price: price,
                    category: selectedCategoryDialog,
                  ));
                  
                  Navigator.pop(context);
                  await _loadMenuItems();
                  _showSuccessSnackBar('Ürün başarıyla güncellendi');
                } catch (e) {
                  _showErrorSnackBar('Ürün güncellenirken hata: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Sil'),
        content: Text('${item.name} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.occupiedTable,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.updateMenuItem(item.copyWith(active: false));
        await _loadMenuItems();
        _showSuccessSnackBar('Ürün başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Ürün silinirken hata: $e');
      }
    }
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
}