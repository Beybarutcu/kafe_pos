// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'settings/tables_settings_screen.dart';
import 'settings/menu_settings_screen.dart';
import 'settings/categories_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yönetmek istediğiniz bölümü seçin',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSettingsButton(
              context,
              icon: Icons.table_restaurant,
              title: 'Masa Yönetimi',
              subtitle: 'Masa ekle, düzenle veya sil',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TablesSettingsScreen(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildSettingsButton(
              context,
              icon: Icons.restaurant_menu,
              title: 'Menü Yönetimi',
              subtitle: 'Ürün ekle, düzenle veya sil',
              color: AppColors.emptyTable,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuSettingsScreen(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildSettingsButton(
              context,
              icon: Icons.category,
              title: 'Kategori Yönetimi',
              subtitle: 'Kategori ekle, düzenle veya sil',
              color: AppColors.treat,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesSettingsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}