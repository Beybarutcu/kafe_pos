// lib/services/database_service.dart
import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables table
    await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_number INTEGER NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        current_order_id INTEGER,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create menu_items table
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0.0,
        discount_type TEXT,
        discount_reason TEXT,
        treat_amount REAL DEFAULT 0.0,
        treat_reason TEXT,
        final_total REAL NOT NULL,
        payment_method TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (table_id) REFERENCES tables (id)
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        is_treat INTEGER DEFAULT 0,
        treat_reason TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create daily_reports table for analytics
    await db.execute('''
      CREATE TABLE daily_reports (
        date TEXT PRIMARY KEY,
        total_revenue REAL NOT NULL,
        order_count INTEGER NOT NULL,
        cash_payments REAL DEFAULT 0.0,
        card_payments REAL DEFAULT 0.0,
        total_discounts REAL DEFAULT 0.0,
        total_treats REAL DEFAULT 0.0
      )
    ''');

    // Insert default settings
    await _insertDefaultSettings(db);
    
    // Insert default tables
    await _insertDefaultTables(db);
    
    // Insert default menu items
    await _insertDefaultMenuItems(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // For now, we'll recreate everything (development phase)
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS tables');
      await db.execute('DROP TABLE IF EXISTS menu_items');
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS order_items');
      await db.execute('DROP TABLE IF EXISTS settings');
      await db.execute('DROP TABLE IF EXISTS daily_reports');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert('settings', {'key': 'table_count', 'value': '6'});
    await db.insert('settings', {'key': 'cafe_name', 'value': 'Kafem'});
    await db.insert('settings', {'key': 'currency_symbol', 'value': '₺'});
    await db.insert('settings', {'key': 'tax_rate', 'value': '0.18'});
  }

  Future<void> _insertDefaultTables(Database db) async {
    for (int i = 1; i <= 6; i++) {
      await db.insert('tables', {
        'table_number': i,
        'name': 'Masa $i',
        'status': AppConstants.tableStatusEmpty,
        'active': 1,
      });
    }
  }

  Future<void> _insertDefaultMenuItems(Database db) async {
    final defaultItems = [
      {'name': 'Türk Kahvesi', 'price': 15.0, 'category': 'Sıcak İçecekler'},
      {'name': 'Çay', 'price': 5.0, 'category': 'Sıcak İçecekler'},
      {'name': 'Espresso', 'price': 12.0, 'category': 'Sıcak İçecekler'},
      {'name': 'Cappuccino', 'price': 18.0, 'category': 'Sıcak İçecekler'},
      {'name': 'Latte', 'price': 20.0, 'category': 'Sıcak İçecekler'},
      {'name': 'Ayran', 'price': 8.0, 'category': 'Soğuk İçecekler'},
      {'name': 'Kola', 'price': 10.0, 'category': 'Soğuk İçecekler'},
      {'name': 'Su', 'price': 3.0, 'category': 'Soğuk İçecekler'},
      {'name': 'Tost', 'price': 25.0, 'category': 'Yiyecekler'},
      {'name': 'Sandviç', 'price': 30.0, 'category': 'Yiyecekler'},
      {'name': 'Börek', 'price': 20.0, 'category': 'Yiyecekler'},
      {'name': 'Kurabiye', 'price': 8.0, 'category': 'Tatlılar'},
      {'name': 'Pasta', 'price': 35.0, 'category': 'Tatlılar'},
    ];

    for (int i = 0; i < defaultItems.length; i++) {
      await db.insert('menu_items', {
        ...defaultItems[i],
        'active': 1,
        'sort_order': i,
      });
    }
  }

  // ========== TABLES OPERATIONS ==========
  
  Future<List<CafeTable>> getAllTables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'table_number ASC',
    );
    return List.generate(maps.length, (i) => CafeTable.fromMap(maps[i]));
  }

  Future<CafeTable?> getTableById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CafeTable.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertTable(CafeTable table) async {
    final db = await database;
    return await db.insert('tables', table.toMap());
  }

  Future<int> updateTable(CafeTable table) async {
    final db = await database;
    return await db.update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<int> updateTableStatus(int tableId, String status, {int? orderId}) async {
    final db = await database;
    return await db.update(
      'tables',
      {
        'status': status,
        'current_order_id': orderId,
      },
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  // ========== MENU ITEMS OPERATIONS ==========
  
  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'category ASC, sort_order ASC',
    );
    return List.generate(maps.length, (i) => MenuItem.fromMap(maps[i]));
  }

  Future<List<String>> getMenuCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM menu_items WHERE active = 1 ORDER BY category ASC',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'category = ? AND active = ?',
      whereArgs: [category, 1],
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => MenuItem.fromMap(maps[i]));
  }

  Future<int> insertMenuItem(MenuItem item) async {
    final db = await database;
    return await db.insert('menu_items', item.toMap());
  }

  Future<int> updateMenuItem(MenuItem item) async {
    final db = await database;
    return await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ========== ORDERS OPERATIONS ==========
  
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  Future<Order?> getCurrentOrderForTable(int tableId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'table_id = ? AND status IN (?, ?)',
      whereArgs: [tableId, AppConstants.orderStatusPending, AppConstants.orderStatusWaitingPayment],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int orderId) async {
    final db = await database;
    
    // First delete all order items
    await db.delete(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    
    // Then delete the order
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ========== ORDER ITEMS OPERATIONS ==========
  
  Future<int> insertOrderItem(OrderItem item) async {
    final db = await database;
    return await db.insert('order_items', item.toMap());
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  Future<int> updateOrderItem(OrderItem item) async {
    final db = await database;
    return await db.update(
      'order_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteOrderItem(int id) async {
    final db = await database;
    return await db.delete(
      'order_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== SETTINGS OPERATIONS ==========
  
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<int> setSetting(String key, String value) async {
    final db = await database;
    return await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== ANALYTICS OPERATIONS ==========
  
  Future<void> updateDailyReport(String date, double revenue, int orderCount) async {
    final db = await database;
    
    // Get existing report for the date
    final existing = await db.query(
      'daily_reports',
      where: 'date = ?',
      whereArgs: [date],
    );
    
    if (existing.isNotEmpty) {
      // Update existing report
      double existingRevenue = (existing.first['total_revenue'] as num).toDouble();
      int existingOrderCount = (existing.first['order_count'] as num).toInt();
      
      await db.update(
        'daily_reports',
        {
          'total_revenue': existingRevenue + revenue,
          'order_count': existingOrderCount + orderCount,
        },
        where: 'date = ?',
        whereArgs: [date],
      );
    } else {
      // Insert new report
      await db.insert('daily_reports', {
        'date': date,
        'total_revenue': revenue,
        'order_count': orderCount,
        'cash_payments': 0.0,
        'card_payments': 0.0,
        'total_discounts': 0.0,
        'total_treats': 0.0,
      });
    }
  }

  Future<Map<String, dynamic>?> getDailyReport(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_reports',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // ========== UTILITY OPERATIONS ==========
  
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
