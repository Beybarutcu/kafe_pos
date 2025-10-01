// lib/screens/settings/categories_settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/colors.dart';
import '../../models/menu_item.dart';

class CategoriesSettingsScreen extends StatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  State<CategoriesSettingsScreen> createState() => _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState extends State<CategoriesSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _categoryController = TextEditingController();
  
  List<String> categories = [];
  List<MenuItem> menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadMenuItems(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => isLoading = true);
      final loadedCategories = await _databaseService.getMenuCategories();
      setState(() {
        categories = loadedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Kategoriler yüklenirken hata: $e');
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      final loadedItems = await _databaseService.getAllMenuItems();
      setState(() {
        menuItems = loadedItems;
      });
    } catch (e) {
      _showErrorSnackBar('Menü ürünleri yüklenirken hata: $e');
    }
  }

  int _getItemCountForCategory(String category) {
    return menuItems.where((item) => item.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddCategorySection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Mevcut Kategoriler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.treat.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${categories.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.treat,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildCategoriesList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAddCategorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.treat, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Yeni Kategori Ekle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'Kategori adı girin...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.treat.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.treat, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Ekle', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.treat,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz kategori bulunmuyor',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yukarıdan kategori ekleyerek başlayın',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemCount = _getItemCountForCategory(category);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.background),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showEditCategoryDialog(category),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.treat.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: AppColors.treat,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$itemCount ürün',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditCategoryDialog(category),
                    icon: const Icon(Icons.edit),
                    color: AppColors.primary,
                    tooltip: 'Düzenle',
                  ),
                  IconButton(
                    onPressed: () => _deleteCategory(category),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.occupiedTable,
                    tooltip: 'Sil',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) {
      _showErrorSnackBar('Kategori adı boş olamaz');
      return;
    }

    if (categories.contains(categoryName)) {
      _showErrorSnackBar('Bu kategori zaten mevcut');
      return;
    }

    try {
      // Create a placeholder item to establish the category
      await _databaseService.insertMenuItem(
        MenuItem(
          name: 'Örnek Ürün - $categoryName',
          price: 10.0,
          category: categoryName,
          active: true,
          sortOrder: 0,
        ),
      );

      _categoryController.clear();
      await _loadData();
      _showSuccessSnackBar('Kategori başarıyla eklendi');
    } catch (e) {
      _showErrorSnackBar('Kategori eklenirken hata: $e');
    }
  }

  void _showEditCategoryDialog(String oldCategory) {
    final controller = TextEditingController(text: oldCategory);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Yeni Kategori Adı',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCategory = controller.text.trim();
              if (newCategory.isEmpty) {
                _showErrorSnackBar('Kategori adı boş olamaz');
                return;
              }

              if (categories.contains(newCategory) && newCategory != oldCategory) {
                _showErrorSnackBar('Bu kategori zaten mevcut');
                return;
              }

              try {
                // Update all items in this category
                final items = await _databaseService.getMenuItemsByCategory(oldCategory);
                for (final item in items) {
                  await _databaseService.updateMenuItem(
                    item.copyWith(category: newCategory),
                  );
                }

                Navigator.pop(context);
                await _loadData();
                _showSuccessSnackBar('Kategori başarıyla güncellendi');
              } catch (e) {
                _showErrorSnackBar('Kategori güncellenirken hata: $e');
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String category) async {
    final itemCount = _getItemCountForCategory(category);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kategori Sil'),
          content: Text(
            '$category kategorisini silmek istediğinizden emin misiniz?\n\n'
            'Bu kategorideki $itemCount ürün de silinecektir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.occupiedTable,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Delete all menu items in this category
        final items = await _databaseService.getMenuItemsByCategory(category);
        for (final item in items) {
          await _databaseService.updateMenuItem(item.copyWith(active: false));
        }

        await _loadData();
        _showSuccessSnackBar('Kategori başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Kategori silinirken hata: $e');
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