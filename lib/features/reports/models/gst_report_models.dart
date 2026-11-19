class Gstr1Summary {
  final int totalInvoices;
  final double totalTaxableValue;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTaxLiability;
  final double totalInvoiceValue;

  Gstr1Summary({
    required this.totalInvoices,
    required this.totalTaxableValue,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTaxLiability,
    required this.totalInvoiceValue,
  });

  factory Gstr1Summary.fromJson(Map<String, dynamic> json) {
    return Gstr1Summary(
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      totalTaxableValue: (json['totalTaxableValue'] as num?)?.toDouble() ?? 0.0,
      totalCgst: (json['totalCgst'] as num?)?.toDouble() ?? 0.0,
      totalSgst: (json['totalSgst'] as num?)?.toDouble() ?? 0.0,
      totalIgst: (json['totalIgst'] as num?)?.toDouble() ?? 0.0,
      totalTaxLiability: (json['totalTaxLiability'] as num?)?.toDouble() ?? 0.0,
      totalInvoiceValue: (json['totalInvoiceValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class B2bInvoice {
  final String id;
  final int invoiceNo;
  final String date;
  final String customerName;
  final String customerGstin;
  final String stateOfSupply;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalAmount;

  B2bInvoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.customerName,
    required this.customerGstin,
    required this.stateOfSupply,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
  });

  factory B2bInvoice.fromJson(Map<String, dynamic> json) {
    return B2bInvoice(
      id: json['id']?.toString() ?? '',
      invoiceNo: (json['invoiceNo'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerGstin: json['customerGstin']?.toString() ?? '',
      stateOfSupply: json['stateOfSupply']?.toString() ?? '',
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (json['igst'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HsnSummaryItem {
  final String hsnCode;
  final String description;
  final String unit;
  final double totalQuantity;
  final double taxableValue;
  final double taxRatePercent;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double additionalCess;
  final double floodCess;
  final double otherTaxes;
  final double totalValue;

  HsnSummaryItem({
    required this.hsnCode,
    required this.description,
    this.unit = 'PCS',
    required this.totalQuantity,
    required this.taxableValue,
    required this.taxRatePercent,
    required this.cgst,
    required this.sgst,
    required this.igst,
    this.cess = 0.0,
    this.additionalCess = 0.0,
    this.floodCess = 0.0,
    this.otherTaxes = 0.0,
    required this.totalValue,
  });

  factory HsnSummaryItem.fromJson(Map<String, dynamic> json) {
    return HsnSummaryItem(
      hsnCode: json['hsnCode']?.toString() ?? 'NA',
      description: json['description']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (json['igst'] as num?)?.toDouble() ?? 0.0,
      cess: (json['cess'] as num?)?.toDouble() ?? 0.0,
      additionalCess: (json['additionalCess'] as num?)?.toDouble() ?? 0.0,
      floodCess: (json['floodCess'] as num?)?.toDouble() ?? 0.0,
      otherTaxes: (json['otherTaxes'] as num?)?.toDouble() ?? 0.0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RateWiseItem {
  final double rate;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;

  RateWiseItem({
    required this.rate,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalTax,
  });

  factory RateWiseItem.fromJson(Map<String, dynamic> json) {
    return RateWiseItem(
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (json['igst'] as num?)?.toDouble() ?? 0.0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Gstr1ReportModel {
  final String businessName;
  final String businessGstin;
  final String startDate;
  final String endDate;
  final Gstr1Summary summary;
  final List<B2bInvoice> b2bInvoices;
  final List<HsnSummaryItem> hsnSummary;
  final List<RateWiseItem> rateWiseBreakup;

  Gstr1ReportModel({
    required this.businessName,
    required this.businessGstin,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.b2bInvoices,
    required this.hsnSummary,
    required this.rateWiseBreakup,
  });

  factory Gstr1ReportModel.fromJson(Map<String, dynamic> json) {
    return Gstr1ReportModel(
      businessName: json['businessName']?.toString() ?? '',
      businessGstin: json['businessGstin']?.toString() ?? '',
      startDate: json['dateRange']?['start']?.toString() ?? '',
      endDate: json['dateRange']?['end']?.toString() ?? '',
      summary: Gstr1Summary.fromJson(json['summary'] ?? {}),
      b2bInvoices: (json['b2bSummary']?['invoices'] as List<dynamic>? ?? [])
          .map((i) => B2bInvoice.fromJson(i as Map<String, dynamic>))
          .toList(),
      hsnSummary: (json['hsnSummary'] as List<dynamic>? ?? [])
          .map((h) => HsnSummaryItem.fromJson(h as Map<String, dynamic>))
          .toList(),
      rateWiseBreakup: (json['rateWiseBreakup'] as List<dynamic>? ?? [])
          .map((r) => RateWiseItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InwardSupplyItem {
  final String id;
  final int orderNo;
  final String date;
  final String supplierName;
  final String supplierGstin;
  final double taxableValue;
  final double itcCgst;
  final double itcSgst;
  final double itcIgst;
  final double totalItc;
  final double totalAmount;

  InwardSupplyItem({
    required this.id,
    required this.orderNo,
    required this.date,
    required this.supplierName,
    required this.supplierGstin,
    required this.taxableValue,
    required this.itcCgst,
    required this.itcSgst,
    required this.itcIgst,
    required this.totalItc,
    required this.totalAmount,
  });

  factory InwardSupplyItem.fromJson(Map<String, dynamic> json) {
    return InwardSupplyItem(
      id: json['id']?.toString() ?? '',
      orderNo: (json['orderNo'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      supplierGstin: json['supplierGstin']?.toString() ?? '',
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      itcCgst: (json['itcCgst'] as num?)?.toDouble() ?? 0.0,
      itcSgst: (json['itcSgst'] as num?)?.toDouble() ?? 0.0,
      itcIgst: (json['itcIgst'] as num?)?.toDouble() ?? 0.0,
      totalItc: (json['totalItc'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Gstr2ReportModel {
  final String businessName;
  final String businessGstin;
  final String startDate;
  final String endDate;
  final int totalPurchaseOrders;
  final double totalPurchaseAmount;
  final double totalTaxablePurchase;
  final double totalEligibleItc;
  final double eligibleItcCgst;
  final double eligibleItcSgst;
  final double eligibleItcIgst;
  final List<InwardSupplyItem> inwardSupplies;

  Gstr2ReportModel({
    required this.businessName,
    required this.businessGstin,
    required this.startDate,
    required this.endDate,
    required this.totalPurchaseOrders,
    required this.totalPurchaseAmount,
    required this.totalTaxablePurchase,
    required this.totalEligibleItc,
    required this.eligibleItcCgst,
    required this.eligibleItcSgst,
    required this.eligibleItcIgst,
    required this.inwardSupplies,
  });

  factory Gstr2ReportModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    return Gstr2ReportModel(
      businessName: json['businessName']?.toString() ?? '',
      businessGstin: json['businessGstin']?.toString() ?? '',
      startDate: json['dateRange']?['start']?.toString() ?? '',
      endDate: json['dateRange']?['end']?.toString() ?? '',
      totalPurchaseOrders: (s['totalPurchaseOrders'] as num?)?.toInt() ?? 0,
      totalPurchaseAmount: (s['totalPurchaseAmount'] as num?)?.toDouble() ?? 0.0,
      totalTaxablePurchase: (s['totalTaxablePurchase'] as num?)?.toDouble() ?? 0.0,
      totalEligibleItc: (s['totalEligibleItc'] as num?)?.toDouble() ?? 0.0,
      eligibleItcCgst: (s['eligibleItcCgst'] as num?)?.toDouble() ?? 0.0,
      eligibleItcSgst: (s['eligibleItcSgst'] as num?)?.toDouble() ?? 0.0,
      eligibleItcIgst: (s['eligibleItcIgst'] as num?)?.toDouble() ?? 0.0,
      inwardSupplies: (json['inwardSupplies'] as List<dynamic>? ?? [])
          .map((i) => InwardSupplyItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Gstr3bReportModel {
  final String startDate;
  final String endDate;
  final double outwardTaxableTurnover;
  final double outwardCgst;
  final double outwardSgst;
  final double outwardIgst;
  final double totalOutwardTax;
  final double itcTaxablePurchases;
  final double itcCgst;
  final double itcSgst;
  final double itcIgst;
  final double totalEligibleItc;
  final double netCgstPayable;
  final double netSgstPayable;
  final double netIgstPayable;
  final double totalNetPayable;
  final double excessItcCarriedForward;
  final String status;

  Gstr3bReportModel({
    required this.startDate,
    required this.endDate,
    required this.outwardTaxableTurnover,
    required this.outwardCgst,
    required this.outwardSgst,
    required this.outwardIgst,
    required this.totalOutwardTax,
    required this.itcTaxablePurchases,
    required this.itcCgst,
    required this.itcSgst,
    required this.itcIgst,
    required this.totalEligibleItc,
    required this.netCgstPayable,
    required this.netSgstPayable,
    required this.netIgstPayable,
    required this.totalNetPayable,
    required this.excessItcCarriedForward,
    required this.status,
  });

  factory Gstr3bReportModel.fromJson(Map<String, dynamic> json) {
    final o = json['outwardSupplies'] ?? {};
    final i = json['eligibleItc'] ?? {};
    final n = json['netTaxLiability'] ?? {};

    return Gstr3bReportModel(
      startDate: json['dateRange']?['start']?.toString() ?? '',
      endDate: json['dateRange']?['end']?.toString() ?? '',
      outwardTaxableTurnover: (o['taxableTurnover'] as num?)?.toDouble() ?? 0.0,
      outwardCgst: (o['cgst'] as num?)?.toDouble() ?? 0.0,
      outwardSgst: (o['sgst'] as num?)?.toDouble() ?? 0.0,
      outwardIgst: (o['igst'] as num?)?.toDouble() ?? 0.0,
      totalOutwardTax: (o['totalTaxLiability'] as num?)?.toDouble() ?? 0.0,
      itcTaxablePurchases: (i['taxablePurchases'] as num?)?.toDouble() ?? 0.0,
      itcCgst: (i['itcCgst'] as num?)?.toDouble() ?? 0.0,
      itcSgst: (i['itcSgst'] as num?)?.toDouble() ?? 0.0,
      itcIgst: (i['itcIgst'] as num?)?.toDouble() ?? 0.0,
      totalEligibleItc: (i['totalEligibleItc'] as num?)?.toDouble() ?? 0.0,
      netCgstPayable: (n['cgstPayable'] as num?)?.toDouble() ?? 0.0,
      netSgstPayable: (n['sgstPayable'] as num?)?.toDouble() ?? 0.0,
      netIgstPayable: (n['igstPayable'] as num?)?.toDouble() ?? 0.0,
      totalNetPayable: (n['totalNetPayable'] as num?)?.toDouble() ?? 0.0,
      excessItcCarriedForward: (n['excessItcCarriedForward'] as num?)?.toDouble() ?? 0.0,
      status: n['status']?.toString() ?? 'TAX_PAYABLE',
    );
  }
}

class Gstr9ReportModel {
  final String financialYear;
  final String businessName;
  final String businessGstin;
  final String startDate;
  final String endDate;

  // Outward Supplies
  final double b2bTaxableTurnover;
  final double b2bCgst;
  final double b2bSgst;
  final double b2bIgst;
  final double b2cTaxableTurnover;
  final double b2cCgst;
  final double b2cSgst;
  final double b2cIgst;
  final double totalTaxableTurnover;
  final double totalGrossTurnover;
  final double totalOutwardCgst;
  final double totalOutwardSgst;
  final double totalOutwardIgst;
  final double totalOutwardTaxLiability;

  // Input Tax Credit (ITC)
  final double totalTaxablePurchases;
  final double totalPurchasesGross;
  final double itcCgst;
  final double itcSgst;
  final double itcIgst;
  final double totalEligibleItcAvailed;

  // Tax Computation
  final double totalTaxPayable;
  final double totalItcUtilized;
  final double netTaxPayableCash;
  final double excessItcCarriedForward;

  Gstr9ReportModel({
    required this.financialYear,
    required this.businessName,
    required this.businessGstin,
    required this.startDate,
    required this.endDate,
    required this.b2bTaxableTurnover,
    required this.b2bCgst,
    required this.b2bSgst,
    required this.b2bIgst,
    required this.b2cTaxableTurnover,
    required this.b2cCgst,
    required this.b2cSgst,
    required this.b2cIgst,
    required this.totalTaxableTurnover,
    required this.totalGrossTurnover,
    required this.totalOutwardCgst,
    required this.totalOutwardSgst,
    required this.totalOutwardIgst,
    required this.totalOutwardTaxLiability,
    required this.totalTaxablePurchases,
    required this.totalPurchasesGross,
    required this.itcCgst,
    required this.itcSgst,
    required this.itcIgst,
    required this.totalEligibleItcAvailed,
    required this.totalTaxPayable,
    required this.totalItcUtilized,
    required this.netTaxPayableCash,
    required this.excessItcCarriedForward,
  });

  factory Gstr9ReportModel.fromJson(Map<String, dynamic> json) {
    final o = json['outwardSupplies'] ?? {};
    final i = json['inputTaxCredit'] ?? {};
    final t = json['taxComputation'] ?? {};

    return Gstr9ReportModel(
      financialYear: json['financialYear']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      businessGstin: json['businessGstin']?.toString() ?? '',
      startDate: json['dateRange']?['start']?.toString() ?? '',
      endDate: json['dateRange']?['end']?.toString() ?? '',
      b2bTaxableTurnover: (o['b2bTaxableTurnover'] as num?)?.toDouble() ?? 0.0,
      b2bCgst: (o['b2bCgst'] as num?)?.toDouble() ?? 0.0,
      b2bSgst: (o['b2bSgst'] as num?)?.toDouble() ?? 0.0,
      b2bIgst: (o['b2bIgst'] as num?)?.toDouble() ?? 0.0,
      b2cTaxableTurnover: (o['b2cTaxableTurnover'] as num?)?.toDouble() ?? 0.0,
      b2cCgst: (o['b2cCgst'] as num?)?.toDouble() ?? 0.0,
      b2cSgst: (o['b2cSgst'] as num?)?.toDouble() ?? 0.0,
      b2cIgst: (o['b2cIgst'] as num?)?.toDouble() ?? 0.0,
      totalTaxableTurnover: (o['totalTaxableTurnover'] as num?)?.toDouble() ?? 0.0,
      totalGrossTurnover: (o['totalGrossTurnover'] as num?)?.toDouble() ?? 0.0,
      totalOutwardCgst: (o['totalOutwardCgst'] as num?)?.toDouble() ?? 0.0,
      totalOutwardSgst: (o['totalOutwardSgst'] as num?)?.toDouble() ?? 0.0,
      totalOutwardIgst: (o['totalOutwardIgst'] as num?)?.toDouble() ?? 0.0,
      totalOutwardTaxLiability: (o['totalOutwardTaxLiability'] as num?)?.toDouble() ?? 0.0,
      totalTaxablePurchases: (i['totalTaxablePurchases'] as num?)?.toDouble() ?? 0.0,
      totalPurchasesGross: (i['totalPurchasesGross'] as num?)?.toDouble() ?? 0.0,
      itcCgst: (i['itcCgst'] as num?)?.toDouble() ?? 0.0,
      itcSgst: (i['itcSgst'] as num?)?.toDouble() ?? 0.0,
      itcIgst: (i['itcIgst'] as num?)?.toDouble() ?? 0.0,
      totalEligibleItcAvailed: (i['totalEligibleItcAvailed'] as num?)?.toDouble() ?? 0.0,
      totalTaxPayable: (t['totalTaxPayable'] as num?)?.toDouble() ?? 0.0,
      totalItcUtilized: (t['totalItcUtilized'] as num?)?.toDouble() ?? 0.0,
      netTaxPayableCash: (t['netTaxPayableCash'] as num?)?.toDouble() ?? 0.0,
      excessItcCarriedForward: (t['excessItcCarriedForward'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseModel {
  final String id;
  final String category;
  final String type;
  final double amount;
  final String paymentMode;
  final String notes;
  final String expenseDate;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.category,
    this.type = 'Indirect',
    required this.amount,
    this.paymentMode = 'CASH',
    this.notes = '',
    required this.expenseDate,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? json['expense_category']?.toString() ?? 'General',
      type: json['type']?.toString() ?? json['expense_type']?.toString() ?? 'Indirect',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? json['payment_mode']?.toString() ?? 'CASH',
      notes: json['notes']?.toString() ?? '',
      expenseDate: json['expenseDate']?.toString() ?? json['expense_date']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
    );
  }
}

class ExpenseCategorySummary {
  final String category;
  final String type;
  final int count;
  final double totalAmount;

  ExpenseCategorySummary({
    required this.category,
    this.type = 'Indirect',
    required this.count,
    required this.totalAmount,
  });

  factory ExpenseCategorySummary.fromJson(Map<String, dynamic> json) {
    return ExpenseCategorySummary(
      category: json['category']?.toString() ?? 'General',
      type: json['type']?.toString() ?? 'Indirect',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

