import 'package:flutter/material.dart';

enum ReportTimeRange {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisQuarter('This Quarter'),
  thisFinancialYear('This FY'),
  custom('Custom');

  final String label;
  const ReportTimeRange(this.label);

  DateTimeRange toDateRange({DateTimeRange? customRange}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportTimeRange.today:
        return DateTimeRange(start: today, end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case ReportTimeRange.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: startOfWeek,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportTimeRange.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportTimeRange.thisQuarter:
        final qStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, qStartMonth, 1),
          end: DateTime(now.year, qStartMonth + 3, 0, 23, 59, 59),
        );
      case ReportTimeRange.thisFinancialYear:
        final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
        return DateTimeRange(
          start: DateTime(fyStartYear, 4, 1),
          end: DateTime(fyStartYear + 1, 3, 31, 23, 59, 59),
        );
      case ReportTimeRange.custom:
        if (customRange != null) {
          return DateTimeRange(
            start: DateTime(customRange.start.year, customRange.start.month, customRange.start.day),
            end: DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59),
          );
        }
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  /// Calculates the previous equivalent period for growth comparison
  DateTimeRange toPreviousDateRange(DateTimeRange currentRange) {
    final duration = currentRange.end.difference(currentRange.start);
    final prevEnd = currentRange.start.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return DateTimeRange(start: prevStart, end: prevEnd);
  }
}

class ItemSalesMetric {
  final String id;
  final String itemCode;
  final String name;
  final String unit;
  final double qtySold;
  final double totalRevenue;
  final double grossProfit;
  final double percentageShare;

  const ItemSalesMetric({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.unit,
    required this.qtySold,
    required this.totalRevenue,
    this.grossProfit = 0.0,
    this.percentageShare = 0.0,
  });
}

class DeadStockMetric {
  final String id;
  final String itemCode;
  final String name;
  final String unit;
  final int currentStock;
  final double purchasePrice;
  final double lockedCapital;
  final int daysWithoutSale;
  final String? lastSaleDate;

  const DeadStockMetric({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.purchasePrice,
    required this.lockedCapital,
    required this.daysWithoutSale,
    this.lastSaleDate,
  });
}

class StockAlertMetric {
  final String id;
  final String itemCode;
  final String name;
  final int currentStock;
  final String unit;
  final int minAlert;
  final double purchasePrice;
  final double sellingPrice;
  final bool isOutOfStock;

  const StockAlertMetric({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.currentStock,
    required this.unit,
    this.minAlert = 5,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    required this.isOutOfStock,
  });
}

class PartySalesMetric {
  final String partyId;
  final String partyCode;
  final String name;
  final String partyType;
  final String contactNumber;
  final double totalVolume;
  final int orderCount;
  final double balanceDue;

  const PartySalesMetric({
    required this.partyId,
    required this.partyCode,
    required this.name,
    required this.partyType,
    this.contactNumber = '',
    required this.totalVolume,
    required this.orderCount,
    this.balanceDue = 0.0,
  });
}

class DailyTrendPoint {
  final DateTime date;
  final String dayLabel;
  final double sales;
  final double purchases;
  final double expenses;

  double get netMargin => sales - purchases - expenses;

  const DailyTrendPoint({
    required this.date,
    required this.dayLabel,
    required this.sales,
    required this.purchases,
    required this.expenses,
  });
}

class KpiExecutiveSummary {
  // Pillar 1: Sales & Revenue Velocity
  final double grossSales;
  final double netSalesRealized;
  final double creditSales;
  final int invoicesCount;
  final double aov;
  final double salesGrowthPercent;
  final double prevPeriodSales;

  // Pillar 2: Working Capital & Liquidity
  final double youllGet;
  final double youllGive;
  final double cashInHand;
  final double bankBalance;

  // Pillar 3: Profitability & Margins
  final double grossProfit;
  final double grossMarginPercent;
  final double totalExpenses;
  final double netProfit;
  final double netMarginPercent;

  // Pillar 4: Inventory Intelligence & Valuation
  final double totalStockValuationCost;
  final double potentialStockValuationSale;
  final int totalItemsCount;
  final int outOfStockCount;
  final int lowStockCount;

  // Ranked Intelligence Lists
  final List<ItemSalesMetric> mostSellingItems;
  final List<DeadStockMetric> leastSellingItems;
  final List<StockAlertMetric> outOfStockItems;
  final List<StockAlertMetric> lowStockItems;
  final List<PartySalesMetric> topCustomers;
  final List<PartySalesMetric> topSuppliers;

  // Payment Breakdown & Trends
  final Map<String, double> paymentModeBreakdown;
  final List<DailyTrendPoint> trendPoints;
  final Map<String, double> creditAging;

  const KpiExecutiveSummary({
    required this.grossSales,
    required this.netSalesRealized,
    required this.creditSales,
    required this.invoicesCount,
    required this.aov,
    required this.salesGrowthPercent,
    required this.prevPeriodSales,
    required this.youllGet,
    required this.youllGive,
    required this.cashInHand,
    required this.bankBalance,
    required this.grossProfit,
    required this.grossMarginPercent,
    required this.totalExpenses,
    required this.netProfit,
    required this.netMarginPercent,
    required this.totalStockValuationCost,
    required this.potentialStockValuationSale,
    required this.totalItemsCount,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.mostSellingItems,
    required this.leastSellingItems,
    required this.outOfStockItems,
    required this.lowStockItems,
    required this.topCustomers,
    required this.topSuppliers,
    required this.paymentModeBreakdown,
    required this.trendPoints,
    required this.creditAging,
  });

  factory KpiExecutiveSummary.empty() {
    return const KpiExecutiveSummary(
      grossSales: 0,
      netSalesRealized: 0,
      creditSales: 0,
      invoicesCount: 0,
      aov: 0,
      salesGrowthPercent: 0,
      prevPeriodSales: 0,
      youllGet: 0,
      youllGive: 0,
      cashInHand: 0,
      bankBalance: 0,
      grossProfit: 0,
      grossMarginPercent: 0,
      totalExpenses: 0,
      netProfit: 0,
      netMarginPercent: 0,
      totalStockValuationCost: 0,
      potentialStockValuationSale: 0,
      totalItemsCount: 0,
      outOfStockCount: 0,
      lowStockCount: 0,
      mostSellingItems: [],
      leastSellingItems: [],
      outOfStockItems: [],
      lowStockItems: [],
      topCustomers: [],
      topSuppliers: [],
      paymentModeBreakdown: {},
      trendPoints: [],
      creditAging: {},
    );
  }
}

