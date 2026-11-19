import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';
import '../../../features/orders/data/sales_repository.dart';
import '../models/kpi_analytics_models.dart';

class KpiAnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime parseAnyDate(dynamic dateVal, [DateTime? fallback]) {
    if (dateVal == null) return fallback ?? DateTime.now();
    final str = dateVal.toString().trim();
    if (str.isEmpty) return fallback ?? DateTime.now();

    // Check DD/MM/YYYY or DD-MM-YYYY
    if (str.contains('/') || (str.contains('-') && str.indexOf('-') <= 2)) {
      final sep = str.contains('/') ? '/' : '-';
      final parts = str.split(sep);
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed;
    return fallback ?? DateTime.now();
  }

  Future<KpiExecutiveSummary> getExecutiveAnalytics({
    required DateTimeRange range,
    DateTimeRange? prevRange,
    String? partyId,
    String? category,
    String? paymentMode,
  }) async {
    final startIso = range.start.toIso8601String().substring(0, 10);
    final endIso = range.end.toIso8601String().substring(0, 10);

    // 1. Attempt Cloud API first (Enterprise Cloud Real-Time Analytics)
    try {
      final cloudRes = await ApiService.fetchExecutiveAnalytics(
        startDate: startIso,
        endDate: endIso,
        partyId: partyId,
        category: category,
        paymentMode: paymentMode,
      );

      if (cloudRes['success'] == true && cloudRes['kpis'] != null) {
        final kpis = cloudRes['kpis'] as Map<String, dynamic>;
        return _parseCloudKpis(kpis);
      }
    } catch (_) {
      // Seamless offline fallback
    }

    // 2. Local-First SQLite Fallback Engine
    return _computeLocalAnalytics(
      range: range,
      prevRange: prevRange,
      partyIdFilter: partyId,
      categoryFilter: category,
      paymentModeFilter: paymentMode,
    );
  }

  KpiExecutiveSummary _parseCloudKpis(Map<String, dynamic> k) {
    return KpiExecutiveSummary(
      grossSales: (k['grossSales'] as num?)?.toDouble() ?? 0.0,
      netSalesRealized: (k['netSalesRealized'] as num?)?.toDouble() ?? 0.0,
      creditSales: (k['creditSales'] as num?)?.toDouble() ?? 0.0,
      invoicesCount: (k['invoicesCount'] as num?)?.toInt() ?? 0,
      aov: (k['aov'] as num?)?.toDouble() ?? 0.0,
      salesGrowthPercent: (k['salesGrowthPercent'] as num?)?.toDouble() ?? 0.0,
      prevPeriodSales: (k['prevPeriodSales'] as num?)?.toDouble() ?? 0.0,
      youllGet: (k['youllGet'] as num?)?.toDouble() ?? 0.0,
      youllGive: (k['youllGive'] as num?)?.toDouble() ?? 0.0,
      cashInHand: (k['cashInHand'] as num?)?.toDouble() ?? 0.0,
      bankBalance: (k['bankBalance'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (k['grossProfit'] as num?)?.toDouble() ?? 0.0,
      grossMarginPercent: (k['grossMarginPercent'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (k['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (k['netProfit'] as num?)?.toDouble() ?? 0.0,
      netMarginPercent: (k['netMarginPercent'] as num?)?.toDouble() ?? 0.0,
      totalStockValuationCost: (k['totalStockValuationCost'] as num?)?.toDouble() ?? 0.0,
      potentialStockValuationSale: (k['potentialStockValuationSale'] as num?)?.toDouble() ?? 0.0,
      totalItemsCount: (k['totalItemsCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (k['outOfStockCount'] as num?)?.toInt() ?? 0,
      lowStockCount: (k['lowStockCount'] as num?)?.toInt() ?? 0,
      mostSellingItems: (k['mostSellingItems'] as List? ?? []).map((i) {
        final m = Map<String, dynamic>.from(i as Map);
        return ItemSalesMetric(
          id: (m['id'] ?? '').toString(),
          itemCode: (m['itemCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          unit: (m['unit'] ?? 'Pcs').toString(),
          qtySold: (m['qtySold'] as num?)?.toDouble() ?? 0.0,
          totalRevenue: (m['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          grossProfit: (m['grossProfit'] as num?)?.toDouble() ?? 0.0,
          percentageShare: (m['percentageShare'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      leastSellingItems: (k['leastSellingItems'] as List? ?? []).map((i) {
        final m = Map<String, dynamic>.from(i as Map);
        return DeadStockMetric(
          id: (m['id'] ?? '').toString(),
          itemCode: (m['itemCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          unit: (m['unit'] ?? 'Pcs').toString(),
          currentStock: (m['currentStock'] as num?)?.toInt() ?? 0,
          purchasePrice: (m['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          lockedCapital: (m['lockedCapital'] as num?)?.toDouble() ?? 0.0,
          daysWithoutSale: (m['daysWithoutSale'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      outOfStockItems: (k['outOfStockItems'] as List? ?? []).map((i) {
        final m = Map<String, dynamic>.from(i as Map);
        return StockAlertMetric(
          id: (m['id'] ?? '').toString(),
          itemCode: (m['itemCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          currentStock: (m['currentStock'] as num?)?.toInt() ?? 0,
          unit: (m['unit'] ?? 'Pcs').toString(),
          minAlert: (m['minAlert'] as num?)?.toInt() ?? 5,
          purchasePrice: (m['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (m['sellingPrice'] as num?)?.toDouble() ?? 0.0,
          isOutOfStock: true,
        );
      }).toList(),
      lowStockItems: (k['lowStockItems'] as List? ?? []).map((i) {
        final m = Map<String, dynamic>.from(i as Map);
        return StockAlertMetric(
          id: (m['id'] ?? '').toString(),
          itemCode: (m['itemCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          currentStock: (m['currentStock'] as num?)?.toInt() ?? 0,
          unit: (m['unit'] ?? 'Pcs').toString(),
          minAlert: (m['minAlert'] as num?)?.toInt() ?? 5,
          purchasePrice: (m['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (m['sellingPrice'] as num?)?.toDouble() ?? 0.0,
          isOutOfStock: false,
        );
      }).toList(),
      topCustomers: (k['topCustomers'] as List? ?? []).map((c) {
        final m = Map<String, dynamic>.from(c as Map);
        return PartySalesMetric(
          partyId: (m['partyId'] ?? '').toString(),
          partyCode: (m['partyCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          partyType: (m['partyType'] ?? 'customer').toString(),
          contactNumber: (m['contactNumber'] ?? '').toString(),
          totalVolume: (m['totalVolume'] as num?)?.toDouble() ?? 0.0,
          orderCount: (m['orderCount'] as num?)?.toInt() ?? 0,
          balanceDue: (m['balanceDue'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      topSuppliers: (k['topSuppliers'] as List? ?? []).map((s) {
        final m = Map<String, dynamic>.from(s as Map);
        return PartySalesMetric(
          partyId: (m['partyId'] ?? '').toString(),
          partyCode: (m['partyCode'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          partyType: 'supplier',
          contactNumber: (m['contactNumber'] ?? '').toString(),
          totalVolume: (m['totalVolume'] as num?)?.toDouble() ?? 0.0,
          orderCount: (m['orderCount'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      paymentModeBreakdown: (k['paymentModeBreakdown'] as Map? ?? {}).map(
        (key, val) => MapEntry(key.toString(), (val as num?)?.toDouble() ?? 0.0),
      ),
      trendPoints: (k['trendPoints'] as List? ?? []).map((pt) {
        final m = Map<String, dynamic>.from(pt as Map);
        return DailyTrendPoint(
          date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
          dayLabel: (m['dayLabel'] ?? '').toString(),
          sales: (m['sales'] as num?)?.toDouble() ?? 0.0,
          purchases: (m['purchases'] as num?)?.toDouble() ?? 0.0,
          expenses: (m['expenses'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      creditAging: (k['creditAging'] as Map? ?? {}).map(
        (key, val) => MapEntry(key.toString(), (val as num?)?.toDouble() ?? 0.0),
      ),
    );
  }

  Future<KpiExecutiveSummary> _computeLocalAnalytics({
    required DateTimeRange range,
    DateTimeRange? prevRange,
    String? partyIdFilter,
    String? categoryFilter,
    String? paymentModeFilter,
  }) async {
    final db = await _dbHelper.database;

    // 1. Fetch raw data from SQLite
    final salesRows = await db.query('sales_orders');
    final purchaseRows = await db.query('purchase_orders');
    final itemRows = await db.query('items');
    final partyRows = await db.query('parties');

    // 2. Fetch expenses from Cloud API (with graceful local fallback)
    List<Map<String, dynamic>> expenses = [];
    try {
      final expRes = await ApiService.getExpenses(
        startDate: range.start.toIso8601String().substring(0, 10),
        endDate: range.end.toIso8601String().substring(0, 10),
        limit: 500,
      );
      if (expRes['success'] == true && expRes['expenses'] != null) {
        expenses = List<Map<String, dynamic>>.from(expRes['expenses'] as List);
      }
    } catch (_) {
      expenses = [];
    }

    // 3. Create Item Lookup Maps for fast pricing & code retrieval
    final itemById = <String, Map<String, dynamic>>{};
    final itemByName = <String, Map<String, dynamic>>{};
    for (final itm in itemRows) {
      final id = (itm['id'] ?? '').toString();
      final name = (itm['name'] ?? '').toString().trim().toLowerCase();
      if (id.isNotEmpty) itemById[id] = itm;
      if (name.isNotEmpty) itemByName[name] = itm;
    }

    // 4. Create Party Lookup Maps
    final partyById = <String, Map<String, dynamic>>{};
    final partyByName = <String, Map<String, dynamic>>{};
    for (final p in partyRows) {
      final id = (p['id'] ?? '').toString();
      final name = (p['name'] ?? '').toString().trim().toLowerCase();
      if (id.isNotEmpty) partyById[id] = p;
      if (name.isNotEmpty) partyByName[name] = p;
    }

    // Date boundaries
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);

    final prevStart = prevRange != null
        ? DateTime(prevRange.start.year, prevRange.start.month, prevRange.start.day)
        : null;
    final prevEnd = prevRange != null
        ? DateTime(prevRange.end.year, prevRange.end.month, prevRange.end.day, 23, 59, 59)
        : null;

    // 5. Aggregate Sales in Range and Previous Range
    double grossSales = 0.0;
    double netSalesRealized = 0.0;
    double creditSales = 0.0;
    int invoicesCount = 0;
    double prevPeriodSales = 0.0;

    final Map<String, double> paymentModeBreakdown = {
      'Cash': 0.0,
      'UPI / Online': 0.0,
      'Bank': 0.0,
      'Credit': 0.0,
    };

    // Item sales tracking: key = itemName or id
    final itemSalesMap = <String, _ItemAgg>{};
    // Party sales tracking: key = partyId or name
    final customerSalesMap = <String, _PartyAgg>{};

    // Credit Aging buckets (all open credit sales)
    final Map<String, double> creditAging = {
      '0 - 15 Days': 0.0,
      '16 - 30 Days': 0.0,
      '31 - 60 Days': 0.0,
      '60+ Days': 0.0,
    };

    double cashInHand = 0.0;
    double bankBalance = 0.0;
    double totalGrossProfit = 0.0;

    final now = DateTime.now();

    for (final row in salesRows) {
      final dateStr = row['date'] as String?;
      final createdAtStr = row['createdAt'] as String?;
      final fallbackDate = DateTime.tryParse(createdAtStr ?? '') ?? now;
      final saleDate = parseAnyDate(dateStr, fallbackDate);

      final total = (row['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final received = (row['receivedAmount'] as num?)?.toDouble() ?? 0.0;
      final due = (total - received).clamp(0.0, double.infinity);
      final paymentMode = (row['paymentMode'] as String? ?? 'Cash').trim();
      final paymentType = (row['paymentType'] as String? ?? 'Cash').trim();

      // Cash tracking
      if (paymentMode.toLowerCase() == 'cash' || paymentType.toLowerCase() == 'cash') {
        cashInHand += received;
      } else if (paymentType.toLowerCase().contains('upi') ||
          paymentType.toLowerCase().contains('online')) {
        bankBalance += received;
      } else if (paymentType.toLowerCase().contains('bank') ||
          paymentType.toLowerCase().contains('cheque')) {
        bankBalance += received;
      }

      // Overdue credit aging
      if (due > 0) {
        final ageDays = now.difference(saleDate).inDays;
        if (ageDays <= 15) {
          creditAging['0 - 15 Days'] = (creditAging['0 - 15 Days'] ?? 0) + due;
        } else if (ageDays <= 30) {
          creditAging['16 - 30 Days'] = (creditAging['16 - 30 Days'] ?? 0) + due;
        } else if (ageDays <= 60) {
          creditAging['31 - 60 Days'] = (creditAging['31 - 60 Days'] ?? 0) + due;
        } else {
          creditAging['60+ Days'] = (creditAging['60+ Days'] ?? 0) + due;
        }
      }

      // Check if in previous period
      if (prevStart != null && prevEnd != null) {
        if (!saleDate.isBefore(prevStart) && !saleDate.isAfter(prevEnd)) {
          prevPeriodSales += total;
        }
      }

      // Check if in selected period
      if (!saleDate.isBefore(start) && !saleDate.isAfter(end)) {
        grossSales += total;
        netSalesRealized += received;
        creditSales += due;
        invoicesCount += 1;

        // Payment mode breakdown
        if (paymentMode.toLowerCase() == 'credit' && received < total) {
          paymentModeBreakdown['Credit'] = (paymentModeBreakdown['Credit'] ?? 0) + due;
          if (received > 0) {
            paymentModeBreakdown['Cash'] = (paymentModeBreakdown['Cash'] ?? 0) + received;
          }
        } else if (paymentType.toLowerCase().contains('upi') ||
            paymentType.toLowerCase().contains('online')) {
          paymentModeBreakdown['UPI / Online'] = (paymentModeBreakdown['UPI / Online'] ?? 0) + total;
        } else if (paymentType.toLowerCase().contains('bank') ||
            paymentType.toLowerCase().contains('cheque')) {
          paymentModeBreakdown['Bank'] = (paymentModeBreakdown['Bank'] ?? 0) + total;
        } else {
          paymentModeBreakdown['Cash'] = (paymentModeBreakdown['Cash'] ?? 0) + total;
        }

        // Parse sold items for Star items and profit calculation
        final rawItems = row['items'] as String? ?? '[]';
        List itemsList = [];
        try {
          itemsList = jsonDecode(rawItems) as List;
        } catch (_) {
          itemsList = [];
        }

        for (final item in itemsList) {
          if (item is! Map) continue;
          final itemMap = Map<String, dynamic>.from(item);
          final id = (itemMap['id'] ?? itemMap['itemId'] ?? '').toString();
          final name = (itemMap['name'] ?? itemMap['itemName'] ?? 'Unknown').toString().trim();
          final qty = (itemMap['qty'] as num?)?.toDouble() ?? 1.0;
          final itemTotal = (itemMap['total'] ?? itemMap['amount'] as num?)?.toDouble() ??
              (qty * ((itemMap['rate'] ?? itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0));

          // Look up purchase price
          Map<String, dynamic>? dbItem = itemById[id] ?? itemByName[name.toLowerCase()];
          final purchasePrice = (dbItem?['purchasePrice'] as num?)?.toDouble() ?? 0.0;
          final sellingPrice = (dbItem?['sellingPrice'] as num?)?.toDouble() ??
              (qty > 0 ? itemTotal / qty : 0.0);
          final itemProfit = (sellingPrice - purchasePrice) * qty;
          totalGrossProfit += itemProfit > 0 ? itemProfit : (itemTotal * 0.15); // Fallback 15% margin if purchase price unset

          final unit = (dbItem?['unit'] ?? itemMap['unit'] ?? 'Pcs').toString();
          final itemCode = (dbItem?['itemCode'] ?? '').toString();

          final key = id.isNotEmpty ? id : name.toLowerCase();
          final agg = itemSalesMap.putIfAbsent(
            key,
            () => _ItemAgg(
              id: id,
              itemCode: itemCode,
              name: name,
              unit: unit,
            ),
          );
          agg.qtySold += qty;
          agg.totalRevenue += itemTotal;
          agg.grossProfit += itemProfit;
        }

        // Customer Sales aggregation
        final partyId = (row['partyId'] ?? '').toString();
        final customerName = (row['customerName'] ?? 'Walk-in Customer').toString().trim();
        final partyKey = partyId.isNotEmpty ? partyId : customerName.toLowerCase();

        Map<String, dynamic>? dbParty = partyById[partyId] ?? partyByName[customerName.toLowerCase()];
        final partyCode = (dbParty?['partyCode'] ?? '').toString();
        final partyType = (dbParty?['partyType'] ?? 'customer').toString();
        final contactNumber = (dbParty?['contactNumber'] ?? row['customerPhone'] ?? '').toString();

        final pAgg = customerSalesMap.putIfAbsent(
          partyKey,
          () => _PartyAgg(
            partyId: partyId,
            partyCode: partyCode,
            name: customerName,
            partyType: partyType,
            contactNumber: contactNumber,
          ),
        );
        pAgg.totalVolume += total;
        pAgg.orderCount += 1;
        pAgg.balanceDue += due;
      }
    }

    // 6. Aggregate Purchases for Date Range
    final supplierSalesMap = <String, _PartyAgg>{};

    for (final pRow in purchaseRows) {
      final total = (pRow['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final pDateStr = pRow['date'] as String?;
      final pCreatedAt = pRow['createdAt'] as String?;
      final pDate = parseAnyDate(pDateStr, DateTime.tryParse(pCreatedAt ?? ''));

      if (!pDate.isBefore(start) && !pDate.isAfter(end)) {
        final supplierName = (pRow['partyName'] ?? 'Supplier').toString().trim();
        final sKey = supplierName.toLowerCase();
        Map<String, dynamic>? dbParty = partyByName[sKey];

        final sAgg = supplierSalesMap.putIfAbsent(
          sKey,
          () => _PartyAgg(
            partyId: (dbParty?['id'] ?? '').toString(),
            partyCode: (dbParty?['partyCode'] ?? '').toString(),
            name: supplierName,
            partyType: 'supplier',
            contactNumber: (dbParty?['contactNumber'] ?? '').toString(),
          ),
        );
        sAgg.totalVolume += total;
        sAgg.orderCount += 1;
      }
    }

    // Exact ledger-accurate party receivables and payables matching Parties List cards
    double totalReceivablesAllTime = 0.0;
    double totalPayablesAllTime = 0.0;
    try {
      final allPartyBalances = await SalesRepository().getAllPartyBalances();
      for (final b in allPartyBalances.values) {
        final bal = (b['balance'] as num?)?.toDouble() ?? 0.0;
        final isRec = b['isReceivable'] as bool? ?? true;
        if (bal > 0) {
          if (isRec) {
            totalReceivablesAllTime += bal;
          } else {
            totalPayablesAllTime += bal;
          }
        }
      }
    } catch (_) {}

    // 7. Aggregate Expenses in Range
    double totalExpenses = 0.0;
    for (final exp in expenses) {
      final amt = (exp['amount'] as num?)?.toDouble() ?? 0.0;
      totalExpenses += amt;
    }

    // Deduct cash expenses from cashInHand
    cashInHand = (cashInHand - totalExpenses).clamp(0.0, double.infinity);

    // 8. Profitability & Margins
    final grossProfit = totalGrossProfit;
    final grossMarginPercent = grossSales > 0 ? (grossProfit / grossSales) * 100 : 0.0;
    final netProfit = grossProfit - totalExpenses;
    final netMarginPercent = grossSales > 0 ? (netProfit / grossSales) * 100 : 0.0;
    final aov = invoicesCount > 0 ? (grossSales / invoicesCount) : 0.0;

    final salesGrowthPercent = prevPeriodSales > 0
        ? (((grossSales - prevPeriodSales) / prevPeriodSales) * 100)
        : (grossSales > 0 ? 100.0 : 0.0);

    // 9. Inventory Intelligence & Stock Valuation
    double totalStockValuationCost = 0.0;
    double potentialStockValuationSale = 0.0;
    int outOfStockCount = 0;
    int lowStockCount = 0;
    final List<StockAlertMetric> outOfStockItems = [];
    final List<StockAlertMetric> lowStockItems = [];
    final List<DeadStockMetric> leastSellingItems = [];

    // Track which items had sales in range
    final soldItemKeys = <String>{};
    for (final entry in itemSalesMap.entries) {
      if (entry.value.qtySold > 0) {
        soldItemKeys.add(entry.value.id);
        soldItemKeys.add(entry.value.name.toLowerCase());
      }
    }

    for (final item in itemRows) {
      final id = (item['id'] ?? '').toString();
      final name = (item['name'] ?? '').toString();
      final unit = (item['unit'] ?? 'Pcs').toString();
      final itemCode = (item['itemCode'] ?? '').toString();
      final stock = (item['stock'] as num?)?.toInt() ?? 0;
      final purchasePrice = (item['purchasePrice'] as num?)?.toDouble() ?? 0.0;
      final sellingPrice = (item['sellingPrice'] as num?)?.toDouble() ?? 0.0;

      if (stock > 0) {
        totalStockValuationCost += (stock * purchasePrice);
        potentialStockValuationSale += (stock * sellingPrice);
      }

      if (stock <= 0) {
        outOfStockCount++;
        outOfStockItems.add(StockAlertMetric(
          id: id,
          itemCode: itemCode,
          name: name,
          currentStock: stock,
          unit: unit,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          isOutOfStock: true,
        ));
      } else if (stock <= 5) {
        lowStockCount++;
        lowStockItems.add(StockAlertMetric(
          id: id,
          itemCode: itemCode,
          name: name,
          currentStock: stock,
          unit: unit,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          isOutOfStock: false,
        ));
      }

      // Dead Stock: Has stock > 0, but had 0 sales in selected period!
      final hasSold = soldItemKeys.contains(id) || soldItemKeys.contains(name.toLowerCase());
      if (!hasSold && stock > 0) {
        final lockedCapital = stock * purchasePrice;
        leastSellingItems.add(DeadStockMetric(
          id: id,
          itemCode: itemCode,
          name: name,
          unit: unit,
          currentStock: stock,
          purchasePrice: purchasePrice,
          lockedCapital: lockedCapital,
          daysWithoutSale: range.end.difference(range.start).inDays,
        ));
      }
    }

    // Sort dead stock by highest capital locked
    leastSellingItems.sort((a, b) => b.lockedCapital.compareTo(a.lockedCapital));

    // Sort star items by highest quantity sold
    final sortedItemSales = itemSalesMap.values.toList()
      ..sort((a, b) => b.qtySold.compareTo(a.qtySold));

    final mostSellingItems = sortedItemSales.map((itm) {
      final share = grossSales > 0 ? (itm.totalRevenue / grossSales) * 100 : 0.0;
      return ItemSalesMetric(
        id: itm.id,
        itemCode: itm.itemCode,
        name: itm.name,
        unit: itm.unit,
        qtySold: itm.qtySold,
        totalRevenue: itm.totalRevenue,
        grossProfit: itm.grossProfit,
        percentageShare: share,
      );
    }).toList();

    // Sort top parties
    final topCustomers = customerSalesMap.values
        .map((p) => PartySalesMetric(
              partyId: p.partyId,
              partyCode: p.partyCode,
              name: p.name,
              partyType: p.partyType,
              contactNumber: p.contactNumber,
              totalVolume: p.totalVolume,
              orderCount: p.orderCount,
              balanceDue: p.balanceDue,
            ))
        .toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    final topSuppliers = supplierSalesMap.values
        .map((s) => PartySalesMetric(
              partyId: s.partyId,
              partyCode: s.partyCode,
              name: s.name,
              partyType: s.partyType,
              contactNumber: s.contactNumber,
              totalVolume: s.totalVolume,
              orderCount: s.orderCount,
            ))
        .toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    // 10. Compute Daily/Monthly Trend Points for Interactive Line Chart
    final trendPoints = _computeTrendPoints(
      range: range,
      salesRows: salesRows,
      purchaseRows: purchaseRows,
      expenses: expenses,
    );

    return KpiExecutiveSummary(
      grossSales: grossSales,
      netSalesRealized: netSalesRealized,
      creditSales: creditSales,
      invoicesCount: invoicesCount,
      aov: aov,
      salesGrowthPercent: salesGrowthPercent,
      prevPeriodSales: prevPeriodSales,
      youllGet: totalReceivablesAllTime,
      youllGive: totalPayablesAllTime,
      cashInHand: cashInHand,
      bankBalance: bankBalance,
      grossProfit: grossProfit,
      grossMarginPercent: grossMarginPercent,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      netMarginPercent: netMarginPercent,
      totalStockValuationCost: totalStockValuationCost,
      potentialStockValuationSale: potentialStockValuationSale,
      totalItemsCount: itemRows.length,
      outOfStockCount: outOfStockCount,
      lowStockCount: lowStockCount,
      mostSellingItems: mostSellingItems,
      leastSellingItems: leastSellingItems,
      outOfStockItems: outOfStockItems,
      lowStockItems: lowStockItems,
      topCustomers: topCustomers,
      topSuppliers: topSuppliers,
      paymentModeBreakdown: paymentModeBreakdown,
      trendPoints: trendPoints,
      creditAging: creditAging,
    );
  }

  List<DailyTrendPoint> _computeTrendPoints({
    required DateTimeRange range,
    required List<Map<String, dynamic>> salesRows,
    required List<Map<String, dynamic>> purchaseRows,
    required List<Map<String, dynamic>> expenses,
  }) {
    final daysCount = range.end.difference(range.start).inDays + 1;
    final List<DailyTrendPoint> points = [];

    // Map: dateKey -> {sales: double, purchases: double, expenses: double}
    final bucket = <String, Map<String, double>>{};

    // If span <= 31 days: bucket by individual days
    if (daysCount <= 31) {
      for (int i = 0; i < daysCount; i++) {
        final d = range.start.add(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        bucket[key] = {'sales': 0.0, 'purchases': 0.0, 'expenses': 0.0};
      }

      for (final s in salesRows) {
        final d = parseAnyDate(s['date'], DateTime.tryParse(s['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (s['totalAmount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['sales'] = bucket[key]!['sales']! + amt;
        }
      }

      for (final p in purchaseRows) {
        final d = parseAnyDate(p['date'], DateTime.tryParse(p['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (p['totalAmount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['purchases'] = bucket[key]!['purchases']! + amt;
        }
      }

      for (final e in expenses) {
        final d = parseAnyDate(e['expenseDate'] ?? e['expense_date'], DateTime.tryParse(e['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['expenses'] = bucket[key]!['expenses']! + amt;
        }
      }

      bucket.forEach((key, map) {
        final parts = key.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final dayLabel = '${d.day} ${_monthShort(d.month)}';
        points.add(DailyTrendPoint(
          date: d,
          dayLabel: dayLabel,
          sales: map['sales']!,
          purchases: map['purchases']!,
          expenses: map['expenses']!,
        ));
      });
    } else {
      // Bucket by Month (e.g. for FY or Quarter)
      DateTime cursor = DateTime(range.start.year, range.start.month, 1);
      final endMonth = DateTime(range.end.year, range.end.month, 1);

      while (!cursor.isAfter(endMonth)) {
        final key = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
        bucket[key] = {'sales': 0.0, 'purchases': 0.0, 'expenses': 0.0};
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      for (final s in salesRows) {
        final d = parseAnyDate(s['date'], DateTime.tryParse(s['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (s['totalAmount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['sales'] = bucket[key]!['sales']! + amt;
        }
      }

      for (final p in purchaseRows) {
        final d = parseAnyDate(p['date'], DateTime.tryParse(p['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (p['totalAmount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['purchases'] = bucket[key]!['purchases']! + amt;
        }
      }

      for (final e in expenses) {
        final d = parseAnyDate(e['expenseDate'] ?? e['expense_date'], DateTime.tryParse(e['createdAt'] ?? ''));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        if (bucket.containsKey(key)) {
          final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
          bucket[key]!['expenses'] = bucket[key]!['expenses']! + amt;
        }
      }

      bucket.forEach((key, map) {
        final parts = key.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
        final dayLabel = _monthShort(d.month);
        points.add(DailyTrendPoint(
          date: d,
          dayLabel: dayLabel,
          sales: map['sales']!,
          purchases: map['purchases']!,
          expenses: map['expenses']!,
        ));
      });
    }

    return points;
  }

  String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[(month - 1).clamp(0, 11)];
  }
}

class _ItemAgg {
  final String id;
  final String itemCode;
  final String name;
  final String unit;
  double qtySold = 0.0;
  double totalRevenue = 0.0;
  double grossProfit = 0.0;

  _ItemAgg({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.unit,
  });
}

class _PartyAgg {
  final String partyId;
  final String partyCode;
  final String name;
  final String partyType;
  final String contactNumber;
  double totalVolume = 0.0;
  int orderCount = 0;
  double balanceDue = 0.0;

  _PartyAgg({
    required this.partyId,
    required this.partyCode,
    required this.name,
    required this.partyType,
    required this.contactNumber,
  });
}

