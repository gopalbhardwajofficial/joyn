import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/sync_service.dart';
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
      } catch (_) {}
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

    // ✅ purchase_orders me partyId column
    await tryAlter("ALTER TABLE purchase_orders ADD COLUMN partyId TEXT DEFAULT ''");

    // ✅ Unique ID and Numbers for Parties and Items
    await tryAlter("ALTER TABLE parties ADD COLUMN partyNumber INTEGER");
    await tryAlter("ALTER TABLE parties ADD COLUMN partyCode TEXT");
    await tryAlter("ALTER TABLE items ADD COLUMN itemNumber INTEGER");
    await tryAlter("ALTER TABLE items ADD COLUMN itemCode TEXT");

    // Backfill existing parties missing numbers
    try {
      final partiesMissing = await db.query('parties',
          where: 'partyNumber IS NULL OR partyNumber = 0',
          orderBy: 'createdAt ASC');
      if (partiesMissing.isNotEmpty) {
        int currentPartyNum = (Sqflite.firstIntValue(
                await db.rawQuery('SELECT MAX(partyNumber) FROM parties')) ?? 1000);
        if (currentPartyNum < 1000) currentPartyNum = 1000;
        for (final p in partiesMissing) {
          currentPartyNum++;
          final id = p['id'] as String;
          final code = 'PRT-$currentPartyNum';
          await db.update('parties', {'partyNumber': currentPartyNum, 'partyCode': code},
              where: 'id = ?', whereArgs: [id]);
        }
      }
    } catch (e) {
      debugPrint('Party backfill error: $e');
    }

    // Backfill existing items missing numbers
    try {
      final itemsMissing = await db.query('items',
          where: 'itemNumber IS NULL OR itemNumber = 0',
          orderBy: 'createdAt ASC');
      if (itemsMissing.isNotEmpty) {
        int currentItemNum = (Sqflite.firstIntValue(
                await db.rawQuery('SELECT MAX(itemNumber) FROM items')) ?? 1000);
        if (currentItemNum < 1000) currentItemNum = 1000;
        for (final i in itemsMissing) {
          currentItemNum++;
          final id = i['id'] as String;
          final code = 'ITM-$currentItemNum';
          await db.update('items', {'itemNumber': currentItemNum, 'itemCode': code},
              where: 'id = ?', whereArgs: [id]);
        }
      }
    } catch (e) {
      debugPrint('Item backfill error: $e');
    }

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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    final catCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    if (catCount == 0) {
      final now = DateTime.now().toIso8601String();
      final defaults = ['Grocery', 'Electronics', 'Garments', 'Stationery', 'Other'];
      for (final c in defaults) {
        await db.insert('categories', {'name': c, 'createdAt': now},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT
      )
    ''');

    final locCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM locations')) ?? 0;
    if (locCount == 0) {
      final now = DateTime.now().toIso8601String();
      final defaults = ['Select Location', 'Rack A1', 'Rack A2', 'Warehouse 1', 'Store Front'];
      for (final l in defaults) {
        await db.insert('locations', {'name': l, 'createdAt': now},
            conflictAlgorithm: ConflictAlgorithm.ignore);
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

  Future<PartyModel?> getPartyById(String id) async {
    if (id.isEmpty) return null;
    final db = await _readyDb();
    final maps = await db.query('parties', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return PartyModel.fromDb(maps.first);
  }

  Future<void> insertParty(PartyModel party) async {
    final db = await _readyDb();
    int partyNum = party.partyNumber ?? 0;
    String partyCode = party.partyCode ?? '';
    if (partyNum <= 0) {
      final maxVal = Sqflite.firstIntValue(
              await db.rawQuery('SELECT MAX(partyNumber) FROM parties')) ?? 1000;
      partyNum = (maxVal < 1000 ? 1000 : maxVal) + 1;
      partyCode = 'PRT-$partyNum';
    }
    final partyToSave = party.copyWith(partyNumber: partyNum, partyCode: partyCode);

    await db.insert('parties', partyToSave.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    final apiPayload = {
      'id': partyToSave.id,
      'name': partyToSave.name,
      'category': partyToSave.category,
      'contact_number': partyToSave.contactNumber,
      'email': partyToSave.email,
      'billing_address': partyToSave.address,
      'city': partyToSave.city,
      'party_type': partyToSave.partyType,
      'opening_balance': partyToSave.openingBalance,
      'balance_type': partyToSave.balanceType,
      'credit_limit': partyToSave.creditLimit ?? 0,
      'party_number': partyNum,
      'party_code': partyCode,
    };

    try {
      ApiService.createParty(apiPayload).then((res) async {
        if (res['success'] != true) {
          final sync = await SyncService.getInstance();
          await sync.queueMutation(collection: 'parties', data: apiPayload);
        }
      }).catchError((_) async {
        final sync = await SyncService.getInstance();
        await sync.queueMutation(collection: 'parties', data: apiPayload);
      });
    } catch (_) {
      SyncService.getInstance().then((sync) => sync.queueMutation(collection: 'parties', data: apiPayload));
    }
  }

  Future<void> updateParty(PartyModel party) async {
    final db = await _readyDb();
    await db.update('parties', party.toDb(),
        where: 'id = ?', whereArgs: [party.id]);
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
    int itemNum = item.itemNumber ?? 0;
    String itemCode = item.itemCode ?? '';
    if (itemNum <= 0) {
      final maxVal = Sqflite.firstIntValue(
              await db.rawQuery('SELECT MAX(itemNumber) FROM items')) ?? 1000;
      itemNum = (maxVal < 1000 ? 1000 : maxVal) + 1;
      itemCode = 'ITM-$itemNum';
    }
    final itemToSave = item.copyWith(itemNumber: itemNum, itemCode: itemCode);

    await db.insert('items', itemToSave.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    final apiPayload = {
      'id': itemToSave.id,
      'name': itemToSave.name,
      'sku': itemToSave.barcode,
      'barcode': itemToSave.barcode,
      'selling_price': itemToSave.sellingPrice,
      'purchase_price': itemToSave.purchasePrice,
      'tax_rate': itemToSave.taxRatePercent,
      'current_stock': itemToSave.stock,
      'unit': itemToSave.unit,
      'category': itemToSave.category,
      'hsn_sac': itemToSave.hsnSac,
      'item_number': itemNum,
      'item_code': itemCode,
    };

    try {
      ApiService.createItem(apiPayload).then((res) async {
        if (res['success'] != true) {
          final sync = await SyncService.getInstance();
          await sync.queueMutation(collection: 'items', data: apiPayload);
        }
      }).catchError((_) async {
        final sync = await SyncService.getInstance();
        await sync.queueMutation(collection: 'items', data: apiPayload);
      });
    } catch (_) {
      SyncService.getInstance().then((sync) => sync.queueMutation(collection: 'items', data: apiPayload));
    }
  }

  Future<void> updateItem(InventoryItemModel item) async {
    final db = await _readyDb();
    await db.update('items', item.toDb(),
        where: 'id = ?', whereArgs: [item.id]);
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
    await db.update('items', {'stock': newStock},
        where: 'id = ?', whereArgs: [itemId]);
  }

  // ============ SALES ORDERS ============

  Future<List<SaleOrderModel>> getSaleOrders() async {
    final db = await _readyDb();
    final maps = await db.query('sales_orders', orderBy: 'createdAt DESC');
    return maps.map((map) => SaleOrderModel.fromDb(map)).toList();
  }

  // ✅ partyId se match karega, agar khaali ho to customerName se fallback
  Future<List<SaleOrderModel>> getSaleOrdersForParty(
      String partyId, String partyName) async {
    final db = await _readyDb();
    final nameKey = partyName.trim().toLowerCase();
    final List<Map<String, Object?>> maps;

    try {
      // Primary: partyId match OR (partyId empty aur customerName match)
      maps = await db.query(
        'sales_orders',
        where:
        'partyId = ? OR (COALESCE(partyId, "") = "" AND TRIM(LOWER(customerName)) = ?)',
        whereArgs: [partyId, nameKey],
        orderBy: 'createdAt DESC',
      );
      debugPrint('🔎 getSaleOrdersForParty("$partyId","$partyName") → ${maps.length} rows');
      return maps.map((map) => SaleOrderModel.fromDb(map)).toList();
    } catch (e) {
      debugPrint('⚠️ Sale primary failed: $e');
      try {
        final fallback = await db.query(
          'sales_orders',
          where: 'TRIM(LOWER(customerName)) = ?',
          whereArgs: [nameKey],
          orderBy: 'createdAt DESC',
        );
        debugPrint('🔎 Sale fallback → ${fallback.length} rows');
        return fallback.map((map) => SaleOrderModel.fromDb(map)).toList();
      } catch (e2) {
        debugPrint('❌ Sale fallback failed: $e2');
        return [];
      }
    }
  }

  // Overload: calls with only partyId → fetch party name from DB
  Future<List<SaleOrderModel>> getSaleOrdersForPartyById(String partyId) async {
    final db = await _readyDb();
    String partyName = '';
    try {
      final partyRows = await db.query('parties',
          where: 'id = ?', whereArgs: [partyId], limit: 1);
      if (partyRows.isNotEmpty) {
        partyName = (partyRows.first['name'] as String? ?? '');
      }
    } catch (_) {}
    return getSaleOrdersForParty(partyId, partyName);
  }

  Future<int> getNextInvoiceNo() async {
    final db = await _readyDb();
    final result =
    await db.rawQuery('SELECT MAX(invoiceNo) as maxNo FROM sales_orders');
    final maxNo = (result.first['maxNo'] as int?) ?? 0;
    return maxNo + 1;
  }

  Future<void> insertSaleOrder(SaleOrderModel order) async {
    final db = await _readyDb();
    await db.insert('sales_orders', order.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateInventoryForSale(order.items);

    // Cloud Sync to Backend API with offline queueing
    final apiPayload = order.toApiJson();
    try {
      ApiService.createSaleOrder(apiPayload).then((res) async {
        if (res['success'] == true) {
          debugPrint('✅ Sales invoice #${order.invoiceNo} synced to cloud backend.');
        } else {
          final sync = await SyncService.getInstance();
          await sync.queueMutation(collection: 'salesOrders', data: apiPayload);
        }
      }).catchError((e) async {
        final sync = await SyncService.getInstance();
        await sync.queueMutation(collection: 'salesOrders', data: apiPayload);
      });
    } catch (_) {
      SyncService.getInstance().then((sync) => sync.queueMutation(collection: 'salesOrders', data: apiPayload));
    }
  }

  /// Phase 3: Sync Sale Orders from Cloud Backend into SQLite
  Future<List<SaleOrderModel>> syncSaleOrdersFromCloud([String? businessId]) async {
    try {
      final res = await ApiService.fetchSaleOrders(businessId);
      if (res['success'] == true && res['orders'] is List) {
        final db = await _readyDb();
        final cloudOrders = (res['orders'] as List)
            .map((o) => SaleOrderModel.fromApi(o as Map<String, dynamic>))
            .toList();
        for (final o in cloudOrders) {
          await db.insert('sales_orders', o.toDb(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return cloudOrders;
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing sale orders from cloud: $e');
    }
    return getSaleOrders();
  }

  Future<void> updateSaleOrder(SaleOrderModel order) async {
    final db = await _readyDb();

    final oldMaps = await db.query('sales_orders',
        where: 'id = ?', whereArgs: [order.id]);
    if (oldMaps.isNotEmpty) {
      final oldOrder = SaleOrderModel.fromDb(oldMaps.first);
      await _reverseInventoryForSale(oldOrder.items);
    }

    await db.update('sales_orders', order.toDb(),
        where: 'id = ?', whereArgs: [order.id]);

    await _updateInventoryForSale(order.items);
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

  Future<void> _reverseInventoryForSale(
      List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final allItems = await getItems();
    for (final soldItem in items) {
      final itemName = soldItem['name'] as String? ?? '';
      final qty = (soldItem['qty'] as num?)?.toInt() ?? 0;
      for (final invItem in allItems) {
        if (invItem.name.toLowerCase() == itemName.toLowerCase()) {
          await updateItemStock(invItem.id, invItem.stock + qty);
          break;
        }
      }
    }
  }

  // ============ PAYMENTS ============
  Future<List<PaymentModel>> getPaymentsForParty(String partyId) async {
    final db = await _readyDb();
    final maps = await db.query('payments',
        where: 'partyId = ?', whereArgs: [partyId], orderBy: 'createdAt DESC');
    return maps.map((map) => PaymentModel.fromDb(map)).toList();
  }

  Future<int> getNextReceiptNo() async {
    final db = await _readyDb();
    final result =
    await db.rawQuery('SELECT MAX(receiptNo) as maxNo FROM payments');
    final maxNo = (result.first['maxNo'] as int?) ?? 0;
    return maxNo + 1;
  }

  Future<void> insertPayment(PaymentModel payment) async {
    final db = await _readyDb();
    await db.insert('payments', payment.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Cloud Sync to Backend API with offline queueing
    final apiPayload = payment.toApiJson();
    try {
      ApiService.createPayment(apiPayload).then((res) async {
        if (res['success'] == true) {
          debugPrint('✅ Payment receipt #${payment.receiptNo} synced to cloud backend.');
        } else {
          final sync = await SyncService.getInstance();
          await sync.queueMutation(collection: 'payments', data: apiPayload);
        }
      }).catchError((e) async {
        final sync = await SyncService.getInstance();
        await sync.queueMutation(collection: 'payments', data: apiPayload);
      });
    } catch (_) {
      SyncService.getInstance().then((sync) => sync.queueMutation(collection: 'payments', data: apiPayload));
    }
  }

  /// Phase 3: Sync Payments from Cloud Backend into SQLite
  Future<List<PaymentModel>> syncPaymentsFromCloud([String? businessId, String? partyId]) async {
    try {
      final res = await ApiService.fetchPayments(businessId, partyId);
      if (res['success'] == true && res['payments'] is List) {
        final db = await _readyDb();
        final cloudPayments = (res['payments'] as List)
            .map((p) => PaymentModel.fromApi(p as Map<String, dynamic>))
            .toList();
        for (final p in cloudPayments) {
          await db.insert('payments', p.toDb(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return cloudPayments;
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing payments from cloud: $e');
    }
    return [];
  }

  Future<void> deletePayment(String id) async {
    final db = await _readyDb();
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getPartyBalance(String partyId) async {
    // Pehle party name nikaalo
    String partyName = '';
    try {
      final db = await _readyDb();
      final rows = await db.query('parties',
          where: 'id = ?', whereArgs: [partyId], limit: 1);
      if (rows.isNotEmpty) partyName = (rows.first['name'] as String? ?? '');
    } catch (_) {}

    final sales = await getSaleOrdersForParty(partyId, partyName);
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

  // ✅ Purchase: partyId match, ya partyName match (case-insensitive, trimmed)
  Future<List<PurchaseOrderModel>> getPurchaseOrdersForParty(
      String partyId, String partyName) async {
    final db = await _readyDb();
    final nameKey = partyName.trim().toLowerCase();

    try {
      final maps = await db.query(
        'purchase_orders',
        where:
        'partyId = ? OR (COALESCE(partyId, "") = "" AND TRIM(LOWER(partyName)) = ?)',
        whereArgs: [partyId, nameKey],
        orderBy: 'createdAt DESC',
      );
      debugPrint('🔎 getPurchaseOrdersForParty("$partyId","$partyName") → ${maps.length} rows');
      return maps.map((map) => PurchaseOrderModel.fromDb(map)).toList();
    } catch (e) {
      debugPrint('⚠️ Purchase primary failed: $e');
      try {
        final fallback = await db.query(
          'purchase_orders',
          where: 'TRIM(LOWER(partyName)) = ?',
          whereArgs: [nameKey],
          orderBy: 'createdAt DESC',
        );
        debugPrint('🔎 Purchase fallback → ${fallback.length} rows');
        return fallback.map((map) => PurchaseOrderModel.fromDb(map)).toList();
      } catch (e2) {
        debugPrint('❌ Purchase fallback failed: $e2');
        return [];
      }
    }
  }

  // 🔍 DEBUG helpers
  Future<void> debugPrintAllSales() async {
    try {
      final db = await _readyDb();
      final rows = await db.rawQuery(
          'SELECT invoiceNo, partyId, customerName FROM sales_orders ORDER BY createdAt DESC LIMIT 20');
      debugPrint('=== ALL SALES (max 20) ===');
      if (rows.isEmpty) {
        debugPrint('  (sales_orders EMPTY)');
      } else {
        for (final r in rows) {
          debugPrint('  inv#${r['invoiceNo']} | partyId="${r['partyId']}" | name="${r['customerName']}"');
        }
      }
      debugPrint('=== END SALES ===');
    } catch (e) {
      debugPrint('❌ debugPrintAllSales: $e');
    }
  }

  Future<void> debugPrintAllPurchaseParties() async {
    try {
      final db = await _readyDb();
      final rows = await db.rawQuery(
          'SELECT orderNo, partyName, partyId FROM purchase_orders ORDER BY createdAt DESC LIMIT 20');
      debugPrint('=== ALL PURCHASES (max 20) ===');
      if (rows.isEmpty) {
        debugPrint('  (purchase_orders EMPTY)');
      } else {
        for (final r in rows) {
          debugPrint('  order#${r['orderNo']} | partyName="${r['partyName']}" | partyId="${r['partyId']}"');
        }
      }
      debugPrint('=== END PURCHASES ===');
    } catch (e) {
      debugPrint('❌ debugPrintAllPurchaseParties: $e');
    }
  }

  Future<void> insertPurchaseOrder(PurchaseOrderModel order) async {
    final db = await _readyDb();
    await db.insert('purchase_orders', order.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateInventoryForPurchase(order.items);

    // Cloud Sync to Backend API with offline queueing
    final apiPayload = order.toApiJson();
    try {
      ApiService.createPurchaseOrder(apiPayload).then((res) async {
        if (res['success'] == true) {
          debugPrint('✅ Purchase order #${order.orderNo} synced to cloud backend.');
        } else {
          final sync = await SyncService.getInstance();
          await sync.queueMutation(collection: 'purchaseOrders', data: apiPayload);
        }
      }).catchError((e) async {
        final sync = await SyncService.getInstance();
        await sync.queueMutation(collection: 'purchaseOrders', data: apiPayload);
      });
    } catch (_) {
      SyncService.getInstance().then((sync) => sync.queueMutation(collection: 'purchaseOrders', data: apiPayload));
    }
  }

  /// Phase 3: Sync Purchase Orders from Cloud Backend into SQLite
  Future<List<PurchaseOrderModel>> syncPurchaseOrdersFromCloud([String? businessId]) async {
    try {
      final res = await ApiService.fetchPurchaseOrders(businessId);
      if (res['success'] == true && res['orders'] is List) {
        final db = await _readyDb();
        final cloudOrders = (res['orders'] as List)
            .map((o) => PurchaseOrderModel.fromApi(o as Map<String, dynamic>))
            .toList();
        for (final o in cloudOrders) {
          await db.insert('purchase_orders', o.toDb(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return cloudOrders;
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing purchase orders from cloud: $e');
    }
    return getPurchaseOrders();
  }

  Future<void> updatePurchaseOrder(PurchaseOrderModel order) async {
    final db = await _readyDb();

    final oldMaps = await db.query('purchase_orders',
        where: 'id = ?', whereArgs: [order.id]);
    if (oldMaps.isNotEmpty) {
      final oldOrder = PurchaseOrderModel.fromDb(oldMaps.first);
      await _reverseInventoryForPurchase(oldOrder.items);
    }

    await db.update('purchase_orders', order.toDb(),
        where: 'id = ?', whereArgs: [order.id]);

    await _updateInventoryForPurchase(order.items);
  }

  Future<void> deletePurchaseOrder(String id) async {
    final db = await _readyDb();
    await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _updateInventoryForPurchase(
      List<Map<String, dynamic>> items) async {
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

  Future<void> _reverseInventoryForPurchase(
      List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final allItems = await getItems();
    for (final purchasedItem in items) {
      final itemName = purchasedItem['name'] as String? ?? '';
      final qty = (purchasedItem['qty'] as num?)?.toInt() ?? 0;
      for (final invItem in allItems) {
        if (invItem.name.toLowerCase() == itemName.toLowerCase()) {
          await updateItemStock(invItem.id, invItem.stock - qty);
          break;
        }
      }
    }
  }

  // ============ REPORTS ============
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
      final monthStartStr =
          '${month.day.toString().padLeft(2, '0')}/${month.month.toString().padLeft(2, '0')}/${month.year}';
      final monthEndStr =
          '${monthEnd.day.toString().padLeft(2, '0')}/${monthEnd.month.toString().padLeft(2, '0')}/${monthEnd.year}';
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
      final result = await db.rawQuery(
          'SELECT SUM(totalAmount) as total FROM sales_orders WHERE paymentMode = "Credit"');
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getYoullGive() async {
    final db = await _readyDb();
    try {
      final result = await db
          .rawQuery('SELECT SUM(totalAmount) as total FROM purchase_orders');
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getPurchasesThisMonth() async {
    final db = await _readyDb();
    final now = DateTime.now();
    final monthStart = '01/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final monthEnd =
        '${DateTime(now.year, now.month + 1, 0).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
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
      final cashSales = await db.rawQuery(
          'SELECT SUM(totalAmount) as total FROM sales_orders WHERE paymentMode = "Cash"');
      return (cashSales.first['total'] as double?) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await _readyDb();
    try {
      final stockValue = await db
          .rawQuery('SELECT SUM(stock * purchasePrice) as total FROM items');
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
      return await db.rawQuery(
          'SELECT name, stock FROM items ORDER BY stock ASC LIMIT 5');
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
      return sortedItems
          .take(5)
          .map((entry) => {
        'name': entry.key,
        'quantity': entry.value['quantity'],
        'revenue': entry.value['revenue'],
      })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getOpenPurchaseOrders() async {
    final db = await _readyDb();
    try {
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count, SUM(totalAmount) as total_amount FROM purchase_orders');
      return {
        'count': (result.first['count'] as int?) ?? 0,
        'amount': (result.first['total_amount'] as double?) ?? 0.0,
      };
    } catch (e) {
      return {'count': 0, 'amount': 0.0};
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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