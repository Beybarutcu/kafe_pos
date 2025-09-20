// lib/screens/table_selection_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../models/table.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../utils/turkish_strings.dart';
import '../utils/constants.dart';
import '../widgets/table_card.dart';
import '../screens/order_screen.dart';
import '../screens/settings_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<CafeTable> tables = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload tables every time we enter this screen
    if (!isLoading) {
      print('Table selection screen appeared - reloading tables');
      _loadTables();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize database first
      await _databaseService.database;
      
      // TEMPORARILY SHOW DATABASE PATH IN TERMINAL
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, AppConstants.dbName);
      print('========================================');
      print('DATABASE PATH: $dbPath');
      print('DATABASE DIRECTORY: $databasesPath');
      print('========================================');
      
      // Small delay to ensure database is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load tables
      await _loadTables();
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Uygulama başlatılırken hata oluştu: $e';
      });
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final sourcePath = path.join(databasesPath, AppConstants.dbName);
      final sourceFile = File(sourcePath);
      
      if (await sourceFile.exists()) {
        // Copy to Desktop
        final username = Platform.environment['USERNAME'] ?? 'User';
        final desktopPath = 'C:\\Users\\$username\\Desktop\\kafe_pos_backup.db';
        await sourceFile.copy(desktopPath);
        
        _showSuccessSnackBar('Database exported to Desktop: kafe_pos_backup.db');
      } else {
        _showErrorSnackBar('Database not found at: $sourcePath');
      }
    } catch (e) {
      print('Export error: $e');
      _showErrorSnackBar('Export error: $e');
    }
  }

  Future<void> _showDatabasePath() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, AppConstants.dbName);
      
      print('Database path: $dbPath');
      print('Databases directory: $databasesPath');
      
      // Check if file exists
      final file = File(dbPath);
      final exists = await file.exists();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Database Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exists: $exists'),
              const SizedBox(height: 8),
              const Text('Path:'),
              SelectableText(
                dbPath,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text('Directory:'),
              SelectableText(
                databasesPath,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _exportDatabase();
              },
              child: const Text('Export to Desktop'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error finding database: $e');
      _showErrorSnackBar('Database path error: $e');
    }
  }

  Future<void> _loadTables() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // FORCE RELOAD FROM DATABASE EVERY TIME
      final loadedTables = await _databaseService.getAllTables();
      print('Reloaded ${loadedTables.length} tables from database');
      
      // Log table statuses for debugging
      for (final table in loadedTables) {
        print('Table ${table.name}: ${table.status}, OrderID: ${table.currentOrderId}');
      }
      
      setState(() {
        tables = loadedTables;
        isLoading = false;
      });

    } catch (e) {
      print('Load tables error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Masalar yüklenirken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          TurkishStrings.appTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshTables,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: _showReports,
            tooltip: TurkishStrings.reports,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
            tooltip: TurkishStrings.settings,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Uygulama başlatılıyor...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.occupiedTable,
              ),
              const SizedBox(height: 16),
              Text(
                'Hata!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.occupiedTable,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and small stats
          _buildHeaderStats(),
          const SizedBox(height: 16),
          
          // Take Away Button - Full width with same height as table cards
          _buildTakeAwayButton(),
          const SizedBox(height: 16),
          
          // Tables grid
          Expanded(
            child: tables.isEmpty ? _buildEmptyTablesView() : _buildTablesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeAwayButton() {
    return Container(
      width: double.infinity, // Full width
      height: 140, // Same height as table cards
      child: InkWell(
        onTap: _handleTakeAwayTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Take Away',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    int emptyTables = tables.where((table) => table.isEmpty).length;
    int occupiedTables = tables.where((table) => table.isOccupied).length;
    
    return Row(
      children: [
        const Text(
          TurkishStrings.tableSelection,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        _buildSmallStatChip(
          TurkishStrings.emptyTable,
          emptyTables.toString(),
          AppColors.emptyTable,
          Icons.event_seat,
        ),
        const SizedBox(width: 8),
        _buildSmallStatChip(
          TurkishStrings.occupiedTable,
          occupiedTables.toString(),
          AppColors.occupiedTable,
          Icons.people,
        ),
      ],
    );
  }

  Widget _buildSmallStatChip(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTablesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.table_restaurant,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Masa Bulunamadı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Henüz masa tanımlanmamış.\nAyarlardan masa ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Ayarlara Git'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardWidth = 140;
        const double minSpacing = 16;
        
        // Calculate how many cards can fit in one row
        int cardsPerRow = ((constraints.maxWidth + minSpacing) / (cardWidth + minSpacing)).floor();
        
        // Calculate the actual spacing to distribute cards evenly
        double actualSpacing = cardsPerRow > 1 
            ? (constraints.maxWidth - (cardsPerRow * cardWidth)) / (cardsPerRow - 1)
            : minSpacing;
        
        // Ensure spacing doesn't get too large
        actualSpacing = actualSpacing.clamp(minSpacing, 40.0);
        
        return SingleChildScrollView(
          child: Center( // Center the entire wrap content
            child: Wrap(
              alignment: WrapAlignment.center, // Center align the cards
              spacing: actualSpacing, // Dynamic horizontal spacing
              runSpacing: 16, // Fixed vertical spacing
              children: tables.map((table) => SizedBox(
                width: cardWidth, // Fixed width for each card
                height: 140, // Fixed height for each card
                child: TableCard(
                  table: table,
                  onTap: () => _handleTableTap(table),
                ),
              )).toList(),
            ),
          ),
        );
      },
    );
  }

  void _handleTableTap(CafeTable table) {
    if (table.isEmpty) {
      _startNewOrder(table);
    } else {
      _continueOrder(table);
    }
  }

  void _handleTakeAwayTap() async {
    try {
      // Create a special "table" for take away orders with a proper ID
      final takeAwayTable = CafeTable(
        id: -1, // Special ID for take away orders
        tableNumber: 0, // Special number for take away
        name: 'Take Away',
        status: AppConstants.tableStatusEmpty,
      );
      
      _navigateToOrderScreen(takeAwayTable);
    } catch (e) {
      _showErrorSnackBar('Take away siparişi başlatılırken hata: $e');
    }
  }

  void _startNewOrder(CafeTable table) {
    // Directly navigate to order screen without confirmation
    _navigateToOrderScreen(table);
  }

  void _continueOrder(CafeTable table) {
    _navigateToOrderScreen(table);
  }

  Future<void> _navigateToOrderScreen(CafeTable table) async {
    try {
      // Navigate to order screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderScreen(table: table),
        ),
      );
      
      // Refresh tables when returning from order screen
      await _refreshTables();
    } catch (e) {
      _showErrorSnackBar('Sipariş ekranına geçilirken hata oluştu: $e');
    }
  }

  Future<void> _refreshTables() async {
    await _loadTables();
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showReports() {
    _showInfoSnackBar('Raporlar ekranı yakında eklenecek...');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.occupiedTable,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emptyTable,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}