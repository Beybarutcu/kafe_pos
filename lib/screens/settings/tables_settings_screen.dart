// lib/screens/settings/tables_settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/colors.dart';
import '../../models/table.dart';
import '../../utils/constants.dart';

class TablesSettingsScreen extends StatefulWidget {
  const TablesSettingsScreen({super.key});

  @override
  State<TablesSettingsScreen> createState() => _TablesSettingsScreenState();
}

class _TablesSettingsScreenState extends State<TablesSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<CafeTable> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      setState(() => isLoading = true);
      final loadedTables = await _databaseService.getAllTables();
      setState(() {
        tables = loadedTables;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Masalar yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Masa Yönetimi'),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Toplam ${tables.length} masa',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTableDialog,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Yeni Masa', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emptyTable,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildTablesGrid(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTablesGrid() {
    if (tables.isEmpty) {
      return const Center(
        child: Text(
          'Henüz masa bulunmuyor',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardWidth = 140;
        const double minSpacing = 16;
        
        int cardsPerRow = ((constraints.maxWidth + minSpacing) / (cardWidth + minSpacing)).floor();
        double actualSpacing = cardsPerRow > 1 
            ? (constraints.maxWidth - (cardsPerRow * cardWidth)) / (cardsPerRow - 1)
            : minSpacing;
        actualSpacing = actualSpacing.clamp(minSpacing, 40.0);
        
        return SingleChildScrollView(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: actualSpacing,
              runSpacing: 16,
              children: tables.map((table) => SizedBox(
                width: cardWidth,
                height: 140,
                child: _buildTableCard(table),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableCard(CafeTable table) {
    Color cardColor = table.isEmpty ? AppColors.emptyTable : AppColors.occupiedTable;

    return InkWell(
      onTap: () => _showEditTableDialog(table),
      onLongPress: table.isEmpty ? () => _showDeleteConfirmation(table) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (table.isOccupied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.occupiedTable,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DOLU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (table.isEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => _showDeleteConfirmation(table),
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

  void _showAddTableDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Masa Ekle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Masa Adı',
            hintText: 'Örn: Masa 1, Balkon 2, vb.',
            border: OutlineInputBorder(),
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
              final name = nameController.text.trim();
              
              if (name.isEmpty) {
                _showErrorSnackBar('Masa adı boş olamaz');
                return;
              }
              
              try {
                // Get the next table number
                final nextNumber = tables.isEmpty 
                    ? 1 
                    : tables.map((t) => t.tableNumber).reduce((a, b) => a > b ? a : b) + 1;
                
                await _databaseService.insertTable(CafeTable(
                  tableNumber: nextNumber,
                  name: name,
                  status: AppConstants.tableStatusEmpty,
                ));
                
                Navigator.pop(context);
                await _loadTables();
                _showSuccessSnackBar('Masa başarıyla eklendi');
              } catch (e) {
                _showErrorSnackBar('Masa eklenirken hata: $e');
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(CafeTable table) {
    final nameController = TextEditingController(text: table.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masa Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Masa Adı',
            border: OutlineInputBorder(),
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
              final name = nameController.text.trim();
              
              if (name.isEmpty) {
                _showErrorSnackBar('Masa adı boş olamaz');
                return;
              }
              
              try {
                await _databaseService.updateTable(table.copyWith(name: name));
                
                Navigator.pop(context);
                await _loadTables();
                _showSuccessSnackBar('Masa başarıyla güncellendi');
              } catch (e) {
                _showErrorSnackBar('Masa güncellenirken hata: $e');
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(CafeTable table) async {
    if (table.isOccupied) {
      _showErrorSnackBar('Dolu masa silinemez');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masa Sil'),
        content: Text('${table.name} silinecek. Emin misiniz?'),
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
        await _databaseService.updateTable(table.copyWith(active: false));
        await _loadTables();
        _showSuccessSnackBar('Masa başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Masa silinirken hata: $e');
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