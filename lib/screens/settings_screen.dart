// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../models/menu_item.dart';
import '../utils/turkish_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _categoryController = TextEditingController();
  
  List<String> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
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
                  const Text(
                    'Kategori Yönetimi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Add category section
                  _buildAddCategorySection(),
                  
                  const SizedBox(height: 24),
                  
                  // Categories list
                  const Text(
                    'Mevcut Kategoriler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
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
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Yeni Kategori Ekle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'Kategori adı girin...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emptyTable,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Henüz kategori bulunmuyor',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.background),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _deleteCategory(category),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.occupiedTable,
                tooltip: 'Kategoriyi Sil',
              ),
            ],
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
      // Create a sample menu item with the new category to make it appear in the database
      // This creates a visible placeholder item that can be edited/replaced later
      await _databaseService.insertMenuItem(
        MenuItem(
          name: 'Yeni Ürün - $categoryName',
          price: 10.0,
          category: categoryName,
          active: true, // Make it active so the category shows up
          sortOrder: 0,
        ),
      );

      _categoryController.clear();
      await _loadCategories();
      _showSuccessSnackBar('Kategori başarıyla eklendi. Menü ürünlerini bu kategoriye ekleyebilirsiniz.');
    } catch (e) {
      _showErrorSnackBar('Kategori eklenirken hata: $e');
    }
  }

  Future<void> _deleteCategory(String category) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kategori Sil'),
          content: Text('$category kategorisini silmek istediğinizden emin misiniz?\n\nBu kategorideki tüm ürünler de silinecektir.'),
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
        // Delete all menu items in this category by setting them inactive
        final items = await _databaseService.getMenuItemsByCategory(category);
        for (final item in items) {
          await _databaseService.updateMenuItem(item.copyWith(active: false));
        }

        await _loadCategories();
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

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}