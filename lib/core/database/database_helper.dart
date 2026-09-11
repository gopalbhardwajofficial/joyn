import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'joyn_database.db');

    return await openDatabase(
      path,
      version: 5, // Changed from 2 to 5 to trigger table creation
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Roles Table
    await db.execute('''
      CREATE TABLE roles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        accessSales INTEGER DEFAULT 0,
        accessPurchase INTEGER DEFAULT 0,
        accessInventory INTEGER DEFAULT 0,
        accessReports INTEGER DEFAULT 0,
        accessAdmin INTEGER DEFAULT 0,
        accessPartyDetails INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Team Members Table
    await db.execute('''
      CREATE TABLE team_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        roleId TEXT,
        roleName TEXT,
        isActive INTEGER DEFAULT 1,
        photoPath TEXT,
        lastLoginTime TEXT,
        createdAt TEXT,
        FOREIGN KEY (roleId) REFERENCES roles (id)
      )
    ''');

    // Business Profile Table
    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        businessName TEXT,
        ownerName TEXT,
        gstNumber TEXT,
        businessType TEXT,
        businessCategory TEXT,
        phone1 TEXT,
        phone2 TEXT,
        email TEXT,
        website TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        pincode TEXT,
        country TEXT,
        description TEXT,
        booksStartDate TEXT,
        logoPath TEXT,
        signaturePath TEXT,
        showGstOnCard INTEGER DEFAULT 0,
        showBusinessTypeOnCard INTEGER DEFAULT 0,
        showCategoryOnCard INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Parties Table
    await db.execute('''
      CREATE TABLE parties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        contactNumber TEXT,
        email TEXT,
        address TEXT,
        openingBalance REAL DEFAULT 0,
        balanceType TEXT DEFAULT 'toReceive',
        creditLimit REAL,
        createdAt TEXT
      )
    ''');

    // Items/Inventory Table
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        qty INTEGER DEFAULT 0,
        barcode TEXT,
        unit TEXT DEFAULT 'Pcs',
        category TEXT,
        hsnSac TEXT,
        location TEXT,
        barcodeMode TEXT DEFAULT 'same',
        photoPath TEXT DEFAULT '',
        purchasePrice REAL DEFAULT 0,
        sellingPrice REAL DEFAULT 0,
        salePriceTaxMode TEXT DEFAULT 'withoutTax',
        discountOnSalePrice REAL DEFAULT 0,
        discountType TEXT DEFAULT 'percentage',
        purchasePriceTaxMode TEXT DEFAULT 'withoutTax',
        taxRateLabel TEXT DEFAULT 'None',
        taxRatePercent REAL DEFAULT 0,
        stock INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    // Locations Table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    // Sales Orders Table
    await db.execute('''
      CREATE TABLE sales_orders (
        id TEXT PRIMARY KEY,
        invoiceNo INTEGER,
        date TEXT,
        paymentMode TEXT,
        isOneTimeCustomer INTEGER DEFAULT 0,
        partyId TEXT DEFAULT '',
        customerName TEXT,
        customerPhone TEXT,
        items TEXT,
        totalAmount REAL DEFAULT 0,
        receivedAmount REAL DEFAULT 0,
        paymentType TEXT DEFAULT 'Cash',
        stateOfSupply TEXT DEFAULT '',
        description TEXT DEFAULT '',
        termsAndConditions TEXT DEFAULT '',
        createdAt TEXT
      )
    ''');

    // Purchase Orders Table
    await db.execute('''
      CREATE TABLE purchase_orders (
        id TEXT PRIMARY KEY,
        orderNo INTEGER,
        date TEXT,
        dueDate TEXT,
        partyName TEXT,
        items TEXT,
        totalAmount REAL DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        receiptNo INTEGER,
        date TEXT,
        partyId TEXT,
        partyName TEXT,
        partyPhone TEXT,
        receivedAmount REAL,
        paymentType TEXT,
        isPaymentOut INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Insert default roles and categories
    await _insertDefaultRoles(db);
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to parties
      try {
        await db.execute("ALTER TABLE parties ADD COLUMN openingBalance REAL DEFAULT 0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE parties ADD COLUMN balanceType TEXT DEFAULT 'toReceive'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE parties ADD COLUMN creditLimit REAL");
      } catch (_) {}
    }

    if (oldVersion < 3) {
      // Add new columns to sales_orders
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN partyId TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN receivedAmount REAL DEFAULT 0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN paymentType TEXT DEFAULT 'Cash'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN stateOfSupply TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN description TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sales_orders ADD COLUMN termsAndConditions TEXT DEFAULT ''");
      } catch (_) {}

      // Create payments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id TEXT PRIMARY KEY,
          receiptNo INTEGER,
          date TEXT,
          partyId TEXT,
          partyName TEXT,
          partyPhone TEXT,
          receivedAmount REAL,
          paymentType TEXT,
          isPaymentOut INTEGER DEFAULT 0,
          createdAt TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      // Drop old items table and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS items');
      await db.execute('''
        CREATE TABLE items (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          qty INTEGER DEFAULT 0,
          barcode TEXT,
          unit TEXT DEFAULT 'Pcs',
          category TEXT,
          hsnSac TEXT,
          location TEXT,
          barcodeMode TEXT DEFAULT 'same',
          photoPath TEXT DEFAULT '',
          purchasePrice REAL DEFAULT 0,
          sellingPrice REAL DEFAULT 0,
          salePriceTaxMode TEXT DEFAULT 'withoutTax',
          discountOnSalePrice REAL DEFAULT 0,
          discountType TEXT DEFAULT 'percentage',
          purchasePriceTaxMode TEXT DEFAULT 'withoutTax',
          taxRateLabel TEXT DEFAULT 'None',
          taxRatePercent REAL DEFAULT 0,
          stock INTEGER DEFAULT 0,
          createdAt TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      try {
        // Create categories table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            createdAt TEXT
          )
        ''');

        // Create locations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            createdAt TEXT
          )
        ''');

        // Insert default categories
        await _insertDefaultCategories(db);
      } catch (e) {
        debugPrint('Error upgrading database to version 5: $e');
      }
    }
  }

  Future<void> _insertDefaultRoles(Database db) async {
    final now = DateTime.now().toIso8601String();

    final defaultRoles = [
      {
        'id': 'role_admin',
        'name': 'Admin',
        'accessSales': 1,
        'accessPurchase': 1,
        'accessInventory': 1,
        'accessReports': 1,
        'accessAdmin': 1,
        'accessPartyDetails': 1,
        'createdAt': now,
      },
      {
        'id': 'role_manager',
        'name': 'Manager',
        'accessSales': 1,
        'accessPurchase': 1,
        'accessInventory': 1,
        'accessReports': 1,
        'accessAdmin': 0,
        'accessPartyDetails': 1,
        'createdAt': now,
      },
      {
        'id': 'role_cashier',
        'name': 'Cashier',
        'accessSales': 1,
        'accessPurchase': 0,
        'accessInventory': 0,
        'accessReports': 0,
        'accessAdmin': 0,
        'accessPartyDetails': 0,
        'createdAt': now,
      },
    ];

    Batch batch = db.batch();
    for (var role in defaultRoles) {
      batch.insert('roles', role, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultCategories = ['Grocery', 'Electronics', 'Garments', 'Stationery', 'Other'];
    final defaultLocations = ['Select Location', 'Rack A1', 'Rack A2', 'Warehouse 1', 'Store Front'];

    Batch batch = db.batch();
    for (var category in defaultCategories) {
      batch.insert(
        'categories',
        {'name': category, 'createdAt': now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (var location in defaultLocations) {
      batch.insert(
        'locations',
        {'name': location, 'createdAt': now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // Method to force recreate database
  Future<void> forceRecreateDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'joyn_database.db');

    // Close existing database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete database file
    try {
      await deleteDatabase(path);
      debugPrint('Old database deleted successfully');
    } catch (e) {
      debugPrint('Error deleting old database: $e');
    }

    // Recreate with fresh schema
    _database = await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );

    debugPrint('New database created successfully');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}