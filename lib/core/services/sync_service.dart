import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'api_service.dart';

class SyncService {
  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keyPendingMutations = 'pending_offline_mutations';

  static SyncService? _instance;
  static SharedPreferences? _prefs;

  SyncService._();

  static Future<SyncService> getInstance() async {
    _instance ??= SyncService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Get the last recorded sync ISO timestamp
  String? getLastSyncTimestamp() {
    return _prefs?.getString(_keyLastSync);
  }

  /// Set the last recorded sync ISO timestamp
  Future<void> setLastSyncTimestamp(String isoString) async {
    await _prefs?.setString(_keyLastSync, isoString);
  }

  /// Queue an offline mutation locally until network connection is restored
  Future<void> queueMutation({
    required String collection, // 'items', 'parties', 'salesOrders', etc.
    required Map<String, dynamic> data,
  }) async {
    try {
      final raw = _prefs?.getString(_keyPendingMutations);
      Map<String, dynamic> pending = {};
      if (raw != null && raw.isNotEmpty) {
        pending = jsonDecode(raw) as Map<String, dynamic>;
      }

      final list = List<Map<String, dynamic>>.from(pending[collection] ?? []);
      // Remove existing item with same id if any, to avoid duplicate queued mutations
      final entityId = data['id'];
      if (entityId != null) {
        list.removeWhere((item) => item['id'] == entityId);
      }
      data['updatedAt'] ??= DateTime.now().toUtc().toIso8601String();
      list.add(data);
      pending[collection] = list;

      await _prefs?.setString(_keyPendingMutations, jsonEncode(pending));
      debugPrint('SyncService: Queued offline mutation for $collection ($entityId)');
    } catch (e) {
      debugPrint('SyncService Queue Error: $e');
    }
  }

  /// Retrieve all pending offline mutations
  Map<String, dynamic> getPendingMutations() {
    final raw = _prefs?.getString(_keyPendingMutations);
    if (raw == null || raw.isEmpty) {
      return {
        'items': [],
        'parties': [],
        'salesOrders': [],
        'purchaseOrders': [],
        'payments': [],
        'expenses': []
      };
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Clear pending offline mutations after successful push
  Future<void> clearPendingMutations() async {
    await _prefs?.remove(_keyPendingMutations);
  }

  /// Perform two-way delta synchronization (Push then Pull)
  Future<Map<String, dynamic>> performFullSync({String? businessId}) async {
    debugPrint('SyncService: Starting two-way delta sync...');
    final pending = getPendingMutations();

    final hasPendingMutations = (pending['items'] as List?)?.isNotEmpty == true ||
        (pending['parties'] as List?)?.isNotEmpty == true ||
        (pending['salesOrders'] as List?)?.isNotEmpty == true ||
        (pending['purchaseOrders'] as List?)?.isNotEmpty == true ||
        (pending['payments'] as List?)?.isNotEmpty == true ||
        (pending['expenses'] as List?)?.isNotEmpty == true;

    Map<String, dynamic> pushStats = {};

    // 1. Push pending offline mutations if any exist
    if (hasPendingMutations) {
      debugPrint('SyncService: Pushing pending offline mutations to cloud...');
      final pushRes = await ApiService.pushDeltaSync(
        mutations: pending,
        businessId: businessId,
      );

      if (pushRes['success'] == true) {
        await clearPendingMutations();
        pushStats = pushRes['stats'] ?? pushRes['processed'] ?? {};
        debugPrint('SyncService: Push completed successfully. Stats: $pushStats');
      } else {
        debugPrint('SyncService: Push failed: ${pushRes['message']}');
        return {
          'success': false,
          'message': 'Failed to push mutations: ${pushRes['message']}',
          'phase': 'push'
        };
      }
    }

    // 2. Pull incremental updates since last sync timestamp
    final lastSync = getLastSyncTimestamp();
    debugPrint('SyncService: Pulling updates from server since: $lastSync...');
    final pullRes = await ApiService.pullDeltaSync(
      since: lastSync,
      businessId: businessId,
    );

    if (pullRes['success'] == true) {
      final serverTimestamp = pullRes['serverTimestamp'] as String?;
      final delta = pullRes['delta'] as Map<String, dynamic>? ?? {};

      // Reconcile pulled delta into local SQLite database
      await _applyDeltaToLocalDb(delta);

      if (serverTimestamp != null) {
        await setLastSyncTimestamp(serverTimestamp);
      }
      debugPrint('SyncService: Pull & local SQLite reconciliation completed. Server timestamp: $serverTimestamp');
      return {
        'success': true,
        'pushed': pushStats,
        'delta': delta,
        'syncTimestamp': serverTimestamp,
      };
    } else {
      debugPrint('SyncService: Pull failed: ${pullRes['message']}');
      return {
        'success': false,
        'message': 'Failed to pull updates: ${pullRes['message']}',
        'phase': 'pull'
      };
    }
  }

  /// Trigger enterprise cloud backup creation
  Future<Map<String, dynamic>> createCloudBackup({
    String? backupName,
    String? deviceName,
    String? businessId,
  }) async {
    return await ApiService.createCloudBackup(
      backupName: backupName,
      deviceName: deviceName ?? 'JOYN Mobile Client',
      businessId: businessId,
    );
  }

  /// List all backups stored in cloud
  Future<List<dynamic>> listCloudBackups({String? businessId}) async {
    final res = await ApiService.listCloudBackups(businessId: businessId);
    if (res['success'] == true && res['backups'] is List) {
      return res['backups'] as List<dynamic>;
    }
    return [];
  }

  /// Restore business data from a cloud backup snapshot
  Future<Map<String, dynamic>> restoreCloudBackup({
    required String backupId,
    String? businessId,
  }) async {
    return await ApiService.restoreCloudBackup(
      backupId: backupId,
      businessId: businessId,
    );
  }

  /// Delete a cloud backup snapshot
  Future<Map<String, dynamic>> deleteCloudBackup({
    required String backupId,
    String? businessId,
  }) async {
    return await ApiService.deleteCloudBackup(
      backupId: backupId,
      businessId: businessId,
    );
  }

  /// Reconcile pulled delta into local SQLite database
  Future<void> _applyDeltaToLocalDb(Map<String, dynamic> delta) async {
    try {
      final db = await DatabaseHelper().database;
      final batch = db.batch();

      // 1. Items
      final items = (delta['items'] as List?) ?? [];
      for (final i in items) {
        final id = i['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (i['isDeleted'] == true || i['isDeleted'] == 1) {
          batch.delete('items', where: 'id = ?', whereArgs: [id]);
        } else {
          batch.insert('items', {
            'id': id,
            'name': i['name'] ?? '',
            'qty': (i['stock'] as num?)?.toInt() ?? 0,
            'barcode': i['barcode']?.toString() ?? i['sku']?.toString() ?? '',
            'unit': i['unit'] ?? 'Pcs',
            'category': i['category'] ?? 'General',
            'purchasePrice': (i['purchasePrice'] as num?)?.toDouble() ?? 0,
            'sellingPrice': (i['sellingPrice'] as num?)?.toDouble() ?? 0,
            'stock': (i['stock'] as num?)?.toInt() ?? 0,
            'createdAt': i['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 2. Parties
      final parties = (delta['parties'] as List?) ?? [];
      for (final p in parties) {
        final id = p['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (p['isDeleted'] == true || p['isDeleted'] == 1) {
          batch.delete('parties', where: 'id = ?', whereArgs: [id]);
        } else {
          batch.insert('parties', {
            'id': id,
            'name': p['name'] ?? '',
            'category': p['category'] ?? 'General',
            'contactNumber': p['contactNumber'] ?? '',
            'email': p['email'] ?? '',
            'address': p['address'] ?? '',
            'city': p['city'] ?? '',
            'partyType': p['partyType'] ?? 'customer',
            'openingBalance': (p['openingBalance'] as num?)?.toDouble() ?? 0,
            'balanceType': p['balanceType'] ?? 'toReceive',
            'creditLimit': (p['creditLimit'] as num?)?.toDouble(),
            'createdAt': p['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 3. Sales Orders
      final sales = (delta['salesOrders'] as List?) ?? [];
      for (final s in sales) {
        final id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (s['isDeleted'] == true || s['isDeleted'] == 1) {
          batch.delete('sales_orders', where: 'id = ?', whereArgs: [id]);
        } else {
          final itemsRaw = s['items'];
          final itemsJson = itemsRaw is String ? itemsRaw : jsonEncode(itemsRaw ?? []);
          batch.insert('sales_orders', {
            'id': id,
            'invoiceNo': (s['invoiceNo'] as num?)?.toInt() ?? 0,
            'date': s['date']?.toString() ?? '',
            'paymentMode': s['paymentMode']?.toString() ?? 'Cash',
            'partyId': s['partyId']?.toString() ?? '',
            'customerName': s['customerName']?.toString() ?? '',
            'items': itemsJson,
            'totalAmount': (s['totalAmount'] as num?)?.toDouble() ?? 0,
            'receivedAmount': (s['receivedAmount'] as num?)?.toDouble() ?? 0,
            'paymentType': s['paymentType']?.toString() ?? 'Cash',
            'createdAt': s['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 4. Purchase Orders
      final purchases = (delta['purchaseOrders'] as List?) ?? [];
      for (final po in purchases) {
        final id = po['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (po['isDeleted'] == true || po['isDeleted'] == 1) {
          batch.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
        } else {
          final itemsRaw = po['items'];
          final itemsJson = itemsRaw is String ? itemsRaw : jsonEncode(itemsRaw ?? []);
          batch.insert('purchase_orders', {
            'id': id,
            'orderNo': (po['orderNo'] as num?)?.toInt() ?? 0,
            'date': po['date']?.toString() ?? '',
            'partyName': po['partyName']?.toString() ?? '',
            'items': itemsJson,
            'totalAmount': (po['totalAmount'] as num?)?.toDouble() ?? 0,
            'createdAt': po['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 5. Payments
      final payments = (delta['payments'] as List?) ?? [];
      for (final pay in payments) {
        final id = pay['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (pay['isDeleted'] == true || pay['isDeleted'] == 1) {
          batch.delete('payments', where: 'id = ?', whereArgs: [id]);
        } else {
          batch.insert('payments', {
            'id': id,
            'receiptNo': (pay['receiptNo'] as num?)?.toInt() ?? 0,
            'date': pay['date']?.toString() ?? '',
            'partyId': pay['partyId']?.toString() ?? '',
            'partyName': pay['partyName']?.toString() ?? '',
            'receivedAmount': (pay['receivedAmount'] as num?)?.toDouble() ?? 0,
            'paymentType': pay['paymentType']?.toString() ?? 'Cash',
            'isPaymentOut': (pay['isPaymentOut'] == true || pay['isPaymentOut'] == 1) ? 1 : 0,
            'createdAt': pay['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
      debugPrint('SyncService: Successfully reconciled delta into local SQLite database.');
    } catch (e) {
      debugPrint('SyncService SQLite reconciliation error: $e');
    }
  }
}

