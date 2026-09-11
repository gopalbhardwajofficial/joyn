import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import 'package:joyn/features/orders/models/sales_models.dart';

class SalesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static bool _migrated = false;

  Future<Database> _readyDb() async {
    final db = await _dbHelper.database;
    if (_migrated) return db;

    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {
        // column already exists — fine
      }
    }

    await tryAlter("ALTER TABLE parties ADD COLUMN openingBalance REAL DEFAULT 0");
    await tryAlter("ALTER TABLE parties ADD COLUMN balanceType TEXT DEFAULT 'toReceive'");
    await tryAlter("ALTER TABLE parties ADD COLUMN creditLimit REAL");
    await tryAlter("ALTER TABLE parties ADD COLUMN city TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE parties ADD COLUMN partyType TEXT DEFAULT 'customer'");
    await tryAlter("ALTER TABLE parties ADD COLUMN priorityLevel TEXT DEFAULT 'medium'");
    await tryAlter("ALTER TABLE parties ADD COLUMN photoPath TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE parties ADD COLUMN avatarIndex INTEGER");

    await tryAlter("ALTER TABLE items ADD COLUMN qty INTEGER DEFAULT 0");
    await tryAlter("ALTER TABLE items ADD COLUMN hsnSac TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE items ADD COLUMN location TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE items ADD COLUMN barcodeMode TEXT DEFAULT 'same'");
    await tryAlter("ALTER TABLE items ADD COLUMN salePriceTaxMode TEXT DEFAULT 'withoutTax'");
    await tryAlter("ALTER TABLE items ADD COLUMN discountOnSalePrice REAL DEFAULT 0");
    await tryAlter("ALTER TABLE items ADD COLUMN discountType TEXT DEFAULT 'percentage'");
    await tryAlter("ALTER TABLE items ADD COLUMN purchasePriceTaxMode TEXT DEFAULT 'withoutTax'");
    await tryAlter("ALTER TABLE items ADD COLUMN taxRateLabel TEXT DEFAULT 'None'");
    await tryAlter("ALTER TABLE items ADD COLUMN taxRatePercent REAL DEFAULT 0");

    await tryAlter("ALTER TABLE sales_orders ADD COLUMN partyId TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE sales_orders ADD COLUMN receivedAmount REAL DEFAULT 0");
    await tryAlter("ALTER TABLE sales_orders ADD COLUMN paymentType TEXT DEFAULT 'Cash'");
    await tryAlter("ALTER TABLE sales_orders ADD COLUMN stateOfSupply TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE sales_orders ADD COLUMN description TEXT DEFAULT ''");
    await tryAlter("ALTER TABLE sales_orders ADD COLUMN termsAndConditions TEXT DEFAULT ''");

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

    // ======= FIX: Ensure categories table exists and has defaults =======
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    final catCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    if (catCount == 0) {
      final now = DateTime.now().toIso8601String();
      final defaults = ['Grocery', 'Electronics', 'Garments', 'Stationery', 'Other'];
      for (final c in defaults) {
        await db.insert('categories', {'name': c, 'createdAt': now}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // ======= FIX: Ensure locations table exists and has defaults =======
    await db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    final locCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM locations')) ?? 0;
    if (locCount == 0) {
      final now = DateTime.now().toIso8601String();
      final defaults = ['Select Location', 'Rack A1', 'Rack A2', 'Warehouse 1', 'Store Front'];
      for (final l in defaults) {
        await db.insert('locations', {'name': l, 'createdAt': now}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    _migrated = true;
    return db;
  }

  // ============ PARTIES ============

  Future<List<PartyModel>> getParties() async {
    final db = await _readyDb();
    final maps = await db.query('parties', orderBy: 'name ASC');
    return maps.map((map) => PartyModel.fromDb(map)).toList();
  }

  Future<void> insertParty(PartyModel party) async {
    final db = await _readyDb();
    await db.insert('parties', party.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateParty(PartyModel party) async {
    final db = await _readyDb();
    await db.update('parties', party.toDb(), where: 'id = ?', whereArgs: [party.id]);
  }

  Future<void> deleteParty(String id) async {
    final db = await _readyDb();
    await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Map<String, dynamic>>> getAllPartyBalances() async {
    final parties = await getParties();
    final result = <String, Map<String, dynamic>>{};
    for (final p in parties) {
      result[p.id] = await getPartyBalance(p.id);
    }
    return result;
  }

  // ============ ITEMS ============

  Future<List<InventoryItemModel>> getItems() async {
    final db = await _readyDb();
    final maps = await db.query('items', orderBy: 'name ASC');
    return maps.map((map) => InventoryItemModel.fromDb(map)).toList();
  }

  Future<void> insertItem(InventoryItemModel item) async {
    final db = await _readyDb();
    await db.insert('items', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(InventoryItemModel item) async {
    final db = await _readyDb();
    await db.update('items', item.toDb(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    final db = await _readyDb();
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllItems() async {
    final db = await _readyDb();
    await db.delete('items');
  }

  Future<void> updateItemStock(String itemId, int newStock) async {
    final db = await _readyDb();
    await db.update('items', {'stock': newStock}, where: 'id = ?', whereArgs: [itemId]);
  }

  // ============ SALES ORDERS ============

  Future<List<SaleOrderModel>> getSaleOrders() async {
    final db = await _readyDb();
    final maps = await db.query('sales_orders', orderBy: 'createdAt DESC');
    return maps.map((map) => SaleOrderModel.fromDb(map)).toList();
  }

  Future<List<SaleOrderModel>> getSaleOrdersForParty(String partyId) async {
    final db = await _readyDb();
    final maps = await db.query('sales_orders', where: 'partyId = ?', whereArgs: [partyId], orderBy: 'createdAt DESC');
    return maps.map((map) => SaleOrderModel.fromDb(map)).toList();
  }

  Future<int> getNextInvoiceNo() async {
    final db = await _readyDb();
    final result = await db.rawQuery('SELECT MAX(invoiceNo) as maxNo FROM sales_orders');
    final maxNo = (result.first['maxNo'] as int?) ?? 0;
    return maxNo + 1;
  }

  Future<void> insertSaleOrder(SaleOrderModel order) async {
    final db = await _readyDb();
    await db.insert('sales_orders', order.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateInventoryForSale(order.items);
  }

  Future<void> updateSaleOrder(SaleOrderModel order) async {
    final db = await _readyDb();
    await db.update('sales_orders', order.toDb(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<void> deleteSaleOrder(String id) async {
    final db = await _readyDb();
    await db.delete('sales_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _updateInventoryForSale(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final allItems = await getItems();
    for (final soldItem in items) {
      final itemName = soldItem['name'] as String? ?? '';
      final qty = (soldItem['qty'] as num?)?.toInt() ?? 0;
      for (final invItem in allItems) {
        if (invItem.name.toLowerCase() == itemName.toLowerCase()) {
          await updateItemStock(invItem.id, invItem.stock - qty);
          break;
        }
      }
    }
  }

  // ============ PAYMENTS ============

  Future<List<PaymentModel>> getPaymentsForParty(String partyId) async {
    final db = await _readyDb();
    final maps = await db.query('payments', where: 'partyId = ?', whereArgs: [partyId], orderBy: 'createdAt DESC');
    return maps.map((map) => PaymentModel.fromDb(map)).toList();
  }

  Future<int> getNextReceiptNo() async {
    final db = await _readyDb();
    final result = await db.rawQuery('SELECT MAX(receiptNo) as maxNo FROM payments');
    final maxNo = (result.first['maxNo'] as int?) ?? 0;
    return maxNo + 1;
  }

  Future<void> insertPayment(PaymentModel payment) async {
    final db = await _readyDb();
    await db.insert('payments', payment.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePayment(String id) async {
    final db = await _readyDb();
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getPartyBalance(String partyId) async {
    final sales = await getSaleOrdersForParty(partyId);
    final payments = await getPaymentsForParty(partyId);

    double dueFromSales = 0;
    for (final s in sales) {
      dueFromSales += s.balanceDue;
    }
    double totalPayments = 0;
    for (final p in payments) {
      totalPayments += p.isPaymentOut ? -p.receivedAmount : p.receivedAmount;
    }

    final net = dueFromSales - totalPayments;
    return {
      'balance': net.abs(),
      'isReceivable': net >= 0,
    };
  }

  // ============ PURCHASE ORDERS ============

  Future<List<PurchaseOrderModel>> getPurchaseOrders() async {
    final db = await _readyDb();
    final maps = await db.query('purchase_orders', orderBy: 'createdAt DESC');
    return maps.map((map) => PurchaseOrderModel.fromDb(map)).toList();
  }

  Future<void> insertPurchaseOrder(PurchaseOrderModel order) async {
    final db = await _readyDb();
    await db.insert('purchase_orders', order.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateInventoryForPurchase(order.items);
  }

  Future<void> updatePurchaseOrder(PurchaseOrderModel order) async {
    final db = await _readyDb();
    await db.update('purchase_orders', order.toDb(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<void> deletePurchaseOrder(String id) async {
    final db = await _readyDb();
    await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _updateInventoryForPurchase(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final allItems = await getItems();
    for (final purchasedItem in items) {
      final itemName = purchasedItem['name'] as String? ?? '';
      final qty = (purchasedItem['qty'] as num?)?.toInt() ?? 0;
      for (final invItem in allItems) {
        if (invItem.name.toLowerCase() == itemName.toLowerCase()) {
          await updateItemStock(invItem.id, invItem.stock + qty);
          break;
        }
      }
    }
  }

  // ============ REPORTS DATA ============

  Future<Map<String, dynamic>> getReportsData() async {
    return {
      'youllGet': await getYoullGet(),
      'youllGive': await getYoullGive(),
      'saleOverview': await getSaleOverview(),
      'purchasesThisMonth': await getPurchasesThisMonth(),
      'expensesThisMonth': 0.0,
      'cashInHand': await getCashInHand(),
      'inventorySummary': await getInventorySummary(),
      'lowStockItems': await getLowStockItems(),
      'mostSellingItems': await getMostSellingItems(),
      'openPurchaseOrders': await getOpenPurchaseOrders(),
      'expenses': [],
    };
  }

  Future<Map<String, double>> getSaleOverview() async {
    final db = await _readyDb();
    final now = DateTime.now();
    final result = <String, double>{};

    for (int i = 2; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);
      final monthName = _getMonthName(month.month);

      final monthStartStr = '${month.day.toString().padLeft(2, '0')}/${month.month.toString().padLeft(2, '0')}/${month.year}';
      final monthEndStr = '${monthEnd.day.toString().padLeft(2, '0')}/${monthEnd.month.toString().padLeft(2, '0')}/${monthEnd.year}';

      try {
        final sales = await db.rawQuery(
          'SELECT SUM(totalAmount) as total FROM sales_orders WHERE date >= ? AND date <= ?',
          [monthStartStr, monthEndStr],
        );
        result[monthName] = (sales.first['total'] as double?) ?? 0.0;
      } catch (e) {
        result[monthName] = 0.0;
      }
    }
    return result;
  }

  Future<double> getYoullGet() async {
    final db = await _readyDb();
    try {
      final result = await db.rawQuery('SELECT SUM(totalAmount) as total FROM sales_orders WHERE paymentMode = "Credit"');
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getYoullGive() async {
    final db = await _readyDb();
    try {
      final result = await db.rawQuery('SELECT SUM(totalAmount) as total FROM purchase_orders');
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getPurchasesThisMonth() async {
    final db = await _readyDb();
    final now = DateTime.now();
    final monthStart = '01/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final monthEnd = '${DateTime(now.year, now.month + 1, 0).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    try {
      final result = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM purchase_orders WHERE date >= ? AND date <= ?',
        [monthStart, monthEnd],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getCashInHand() async {
    final db = await _readyDb();
    try {
      final cashSales = await db.rawQuery('SELECT SUM(totalAmount) as total FROM sales_orders WHERE paymentMode = "Cash"');
      return (cashSales.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await _readyDb();
    try {
      final stockValue = await db.rawQuery('SELECT SUM(stock * purchasePrice) as total FROM items');
      final noOfItems = await db.rawQuery('SELECT COUNT(*) as count FROM items');
      return {
        'stockValue': (stockValue.first['total'] as double?) ?? 0.0,
        'noOfItems': (noOfItems.first['count'] as int?) ?? 0,
      };
    } catch (e) {
      return {'stockValue': 0.0, 'noOfItems': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await _readyDb();
    try {
      return await db.rawQuery('SELECT name, stock FROM items ORDER BY stock ASC LIMIT 5');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMostSellingItems() async {
    final db = await _readyDb();
    try {
      final saleOrders = await db.query('sales_orders');
      final itemSales = <String, Map<String, double>>{};

      for (final order in saleOrders) {
        final items = jsonDecode(order['items'] as String? ?? '[]') as List;
        for (final item in items) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          final name = itemMap['name'] as String? ?? 'Unknown';
          final qty = (itemMap['qty'] as num?)?.toDouble() ?? 0.0;
          final amount = (itemMap['amount'] as num?)?.toDouble() ?? 0.0;

          itemSales.putIfAbsent(name, () => {'quantity': 0, 'revenue': 0});
          itemSales[name]!['quantity'] = itemSales[name]!['quantity']! + qty;
          itemSales[name]!['revenue'] = itemSales[name]!['revenue']! + amount;
        }
      }

      final sortedItems = itemSales.entries.toList()
        ..sort((a, b) => b.value['quantity']!.compareTo(a.value['quantity']!));

      return sortedItems.take(5).map((entry) => {
        'name': entry.key,
        'quantity': entry.value['quantity'],
        'revenue': entry.value['revenue'],
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getOpenPurchaseOrders() async {
    final db = await _readyDb();
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count, SUM(totalAmount) as total_amount FROM purchase_orders');
      return {
        'count': (result.first['count'] as int?) ?? 0,
        'amount': (result.first['total_amount'] as double?) ?? 0.0,
      };
    } catch (e) {
      return {'count': 0, 'amount': 0.0};
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // ============ CATEGORIES & LOCATIONS ============

  Future<List<String>> getCategories() async {
    final db = await _readyDb();
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> insertCategory(String name) async {
    final db = await _readyDb();
    await db.insert(
      'categories',
      {'name': name, 'createdAt': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteCategory(String name) async {
    final db = await _readyDb();
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  Future<List<String>> getLocations() async {
    final db = await _readyDb();
    final maps = await db.query('locations', orderBy: 'name ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> insertLocation(String name) async {
    final db = await _readyDb();
    await db.insert(
      'locations',
      {'name': name, 'createdAt': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteLocation(String name) async {
    final db = await _readyDb();
    await db.delete('locations', where: 'name = ?', whereArgs: [name]);
  }
}