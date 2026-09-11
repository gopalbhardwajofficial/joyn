// lib/features/orders/models/sales_models.dart

import 'dart:convert';

enum PriceTaxMode { withTax, withoutTax }
enum DiscountType { percentage, value }

// ==================== PartyModel ====================
class PartyModel {
  final String id;
  final String name;
  final String category;
  final String contactNumber;
  final String email;
  final String address;
  final String city;
  final String partyType;
  final String priorityLevel;
  final String photoPath;
  final int? avatarIndex;
  final DateTime createdAt;
  final double openingBalance;
  final String balanceType;
  final double? creditLimit;

  PartyModel({
    required this.id,
    required this.name,
    this.category = '',
    this.contactNumber = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.partyType = 'customer',
    this.priorityLevel = 'medium',
    this.photoPath = '',
    this.avatarIndex,
    required this.createdAt,
    this.openingBalance = 0,
    this.balanceType = 'toReceive',
    this.creditLimit,
  });

  PartyModel copyWith({
    String? name,
    String? category,
    String? contactNumber,
    String? email,
    String? address,
    String? city,
    String? partyType,
    String? priorityLevel,
    String? photoPath,
    int? avatarIndex,
    double? openingBalance,
    String? balanceType,
    double? creditLimit,
  }) {
    return PartyModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      partyType: partyType ?? this.partyType,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      photoPath: photoPath ?? this.photoPath,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      createdAt: createdAt,
      openingBalance: openingBalance ?? this.openingBalance,
      balanceType: balanceType ?? this.balanceType,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'city': city,
      'partyType': partyType,
      'priorityLevel': priorityLevel,
      'photoPath': photoPath,
      'avatarIndex': avatarIndex,
      'createdAt': createdAt.toIso8601String(),
      'openingBalance': openingBalance,
      'balanceType': balanceType,
      'creditLimit': creditLimit,
    };
  }

  factory PartyModel.fromDb(Map<String, dynamic> map) {
    return PartyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? '',
      contactNumber: map['contactNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      partyType: map['partyType'] as String? ?? 'customer',
      priorityLevel: map['priorityLevel'] as String? ?? 'medium',
      photoPath: map['photoPath'] as String? ?? '',
      avatarIndex: (map['avatarIndex'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0,
      balanceType: map['balanceType'] as String? ?? 'toReceive',
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toDb();
  factory PartyModel.fromJson(Map<String, dynamic> json) => PartyModel.fromDb(json);
}

// ==================== InventoryItemModel ====================
class InventoryItemModel {
  final String id;
  final String name;
  final int qty;
  final String barcode;
  final String unit;
  final String category;
  final String hsnSac;
  final String location;
  final String barcodeMode;
  final String photoPath;

  final double purchasePrice;
  final double sellingPrice;
  final PriceTaxMode salePriceTaxMode;
  final double discountOnSalePrice;
  final DiscountType discountType;
  final PriceTaxMode purchasePriceTaxMode;
  final String taxRateLabel;
  final double taxRatePercent;

  final int stock;
  final DateTime createdAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    this.qty = 0,
    this.barcode = '',
    this.unit = 'Pcs',
    this.category = '',
    this.hsnSac = '',
    this.location = '',
    this.barcodeMode = 'same',
    this.photoPath = '',
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.salePriceTaxMode = PriceTaxMode.withoutTax,
    this.discountOnSalePrice = 0,
    this.discountType = DiscountType.percentage,
    this.purchasePriceTaxMode = PriceTaxMode.withoutTax,
    this.taxRateLabel = 'None',
    this.taxRatePercent = 0,
    this.stock = 0,
    required this.createdAt,
  });

  InventoryItemModel copyWith({
    String? name,
    int? qty,
    String? barcode,
    String? unit,
    String? category,
    String? hsnSac,
    String? location,
    String? barcodeMode,
    String? photoPath,
    double? purchasePrice,
    double? sellingPrice,
    PriceTaxMode? salePriceTaxMode,
    double? discountOnSalePrice,
    DiscountType? discountType,
    PriceTaxMode? purchasePriceTaxMode,
    String? taxRateLabel,
    double? taxRatePercent,
    int? stock,
  }) {
    return InventoryItemModel(
      id: id,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      hsnSac: hsnSac ?? this.hsnSac,
      location: location ?? this.location,
      barcodeMode: barcodeMode ?? this.barcodeMode,
      photoPath: photoPath ?? this.photoPath,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      salePriceTaxMode: salePriceTaxMode ?? this.salePriceTaxMode,
      discountOnSalePrice: discountOnSalePrice ?? this.discountOnSalePrice,
      discountType: discountType ?? this.discountType,
      purchasePriceTaxMode: purchasePriceTaxMode ?? this.purchasePriceTaxMode,
      taxRateLabel: taxRateLabel ?? this.taxRateLabel,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      stock: stock ?? this.stock,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'qty': qty,
      'barcode': barcode,
      'unit': unit,
      'category': category,
      'hsnSac': hsnSac,
      'location': location,
      'barcodeMode': barcodeMode,
      'photoPath': photoPath,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'salePriceTaxMode': salePriceTaxMode.name,
      'discountOnSalePrice': discountOnSalePrice,
      'discountType': discountType.name,
      'purchasePriceTaxMode': purchasePriceTaxMode.name,
      'taxRateLabel': taxRateLabel,
      'taxRatePercent': taxRatePercent,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryItemModel.fromDb(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      barcode: map['barcode'] as String? ?? '',
      unit: map['unit'] as String? ?? 'Pcs',
      category: map['category'] as String? ?? '',
      hsnSac: map['hsnSac'] as String? ?? '',
      location: map['location'] as String? ?? '',
      barcodeMode: map['barcodeMode'] as String? ?? 'same',
      photoPath: map['photoPath'] as String? ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      salePriceTaxMode: map['salePriceTaxMode'] == 'withTax' ? PriceTaxMode.withTax : PriceTaxMode.withoutTax,
      discountOnSalePrice: (map['discountOnSalePrice'] as num?)?.toDouble() ?? 0,
      discountType: map['discountType'] == 'value' ? DiscountType.value : DiscountType.percentage,
      purchasePriceTaxMode: map['purchasePriceTaxMode'] == 'withTax' ? PriceTaxMode.withTax : PriceTaxMode.withoutTax,
      taxRateLabel: map['taxRateLabel'] as String? ?? 'None',
      taxRatePercent: (map['taxRatePercent'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toDb();
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) => InventoryItemModel.fromDb(json);
}

// ==================== OrderItemModel – FIXED ====================
class OrderItemModel {
  final String id;
  final String itemName;
  final String category;
  final double unitPrice;
  final int qty;
  final double discountAmount;
  final double taxAmount;
  final double taxRate;
  final bool taxInclusive;
  final String unit;

  const OrderItemModel({
    required this.id,
    required this.itemName,
    this.category = '',
    this.unitPrice = 0,
    this.qty = 1,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.taxRate = 0,
    this.taxInclusive = false,
    this.unit = '',
  });

  double get subtotal => unitPrice * qty;
  double get total => subtotal - discountAmount + taxAmount;
  double get amount => total;

  OrderItemModel copyWith({
    String? id,
    String? itemName,
    String? category,
    double? unitPrice,
    int? qty,
    double? discountAmount,
    double? taxAmount,
    double? taxRate,
    bool? taxInclusive,
    String? unit,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      unit: unit ?? this.unit,
    );
  }

  // ✅ JSON methods matching the stored format in SaleOrderModel / PurchaseOrderModel
  Map<String, dynamic> toJson() => {
    'name': itemName,
    'category': category,
    'unitPrice': unitPrice,
    'qty': qty,
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'taxRate': taxRate,
    'taxInclusive': taxInclusive ? 1 : 0,
    'unit': unit,
  };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      itemName: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      taxInclusive: (json['taxInclusive'] is int)
          ? (json['taxInclusive'] as int) == 1
          : (json['taxInclusive'] as bool? ?? false),
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

// ==================== SaleOrderModel ====================
class SaleOrderModel {
  final String id;
  final int invoiceNo;
  final String date;
  final String paymentMode;
  final bool isOneTimeCustomer;
  final String partyId;
  final String customerName;
  final String customerPhone;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final double receivedAmount;
  final String paymentType;
  final String stateOfSupply;
  final String description;
  final String termsAndConditions;
  final DateTime createdAt;

  SaleOrderModel({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.paymentMode,
    this.isOneTimeCustomer = false,
    this.partyId = '',
    this.customerName = '',
    this.customerPhone = '',
    required this.items,
    required this.totalAmount,
    this.receivedAmount = 0,
    this.paymentType = 'Cash',
    this.stateOfSupply = '',
    this.description = '',
    this.termsAndConditions = '',
    required this.createdAt,
  });

  double get balanceDue => (totalAmount - receivedAmount).clamp(0, double.infinity);

  SaleOrderModel copyWith({
    int? invoiceNo,
    String? date,
    String? paymentMode,
    String? partyId,
    String? customerName,
    String? customerPhone,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    double? receivedAmount,
    String? paymentType,
    String? stateOfSupply,
    String? description,
    String? termsAndConditions,
  }) {
    return SaleOrderModel(
      id: id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      isOneTimeCustomer: isOneTimeCustomer,
      partyId: partyId ?? this.partyId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentType: paymentType ?? this.paymentType,
      stateOfSupply: stateOfSupply ?? this.stateOfSupply,
      description: description ?? this.description,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'date': date,
      'paymentMode': paymentMode,
      'isOneTimeCustomer': isOneTimeCustomer ? 1 : 0,
      'partyId': partyId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': jsonEncode(items),
      'totalAmount': totalAmount,
      'receivedAmount': receivedAmount,
      'paymentType': paymentType,
      'stateOfSupply': stateOfSupply,
      'description': description,
      'termsAndConditions': termsAndConditions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SaleOrderModel.fromDb(Map<String, dynamic> map) {
    return SaleOrderModel(
      id: map['id'] as String,
      invoiceNo: map['invoiceNo'] as int? ?? 0,
      date: map['date'] as String? ?? '',
      paymentMode: map['paymentMode'] as String? ?? 'Credit',
      isOneTimeCustomer: (map['isOneTimeCustomer'] ?? 0) == 1,
      partyId: map['partyId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      items: (jsonDecode(map['items'] as String? ?? '[]') as List).cast<Map<String, dynamic>>(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      receivedAmount: (map['receivedAmount'] as num?)?.toDouble() ?? 0,
      paymentType: map['paymentType'] as String? ?? 'Cash',
      stateOfSupply: map['stateOfSupply'] as String? ?? '',
      description: map['description'] as String? ?? '',
      termsAndConditions: map['termsAndConditions'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ==================== PaymentModel ====================
class PaymentModel {
  final String id;
  final int receiptNo;
  final String date;
  final String partyId;
  final String partyName;
  final String partyPhone;
  final double receivedAmount;
  final String paymentType;
  final bool isPaymentOut;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.receiptNo,
    required this.date,
    required this.partyId,
    required this.partyName,
    this.partyPhone = '',
    required this.receivedAmount,
    this.paymentType = 'Cash',
    this.isPaymentOut = false,
    required this.createdAt,
  });

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'receiptNo': receiptNo,
      'date': date,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'receivedAmount': receivedAmount,
      'paymentType': paymentType,
      'isPaymentOut': isPaymentOut ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromDb(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      receiptNo: map['receiptNo'] as int? ?? 0,
      date: map['date'] as String? ?? '',
      partyId: map['partyId'] as String? ?? '',
      partyName: map['partyName'] as String? ?? '',
      partyPhone: map['partyPhone'] as String? ?? '',
      receivedAmount: (map['receivedAmount'] as num?)?.toDouble() ?? 0,
      paymentType: map['paymentType'] as String? ?? 'Cash',
      isPaymentOut: (map['isPaymentOut'] ?? 0) == 1,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ==================== PurchaseOrderModel ====================
class PurchaseOrderModel {
  final String id;
  final int orderNo;
  final String date;
  final String dueDate;
  final String partyName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final DateTime createdAt;

  PurchaseOrderModel({
    required this.id,
    required this.orderNo,
    required this.date,
    required this.dueDate,
    required this.partyName,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'orderNo': orderNo,
      'date': date,
      'dueDate': dueDate,
      'partyName': partyName,
      'items': jsonEncode(items),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseOrderModel.fromDb(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      id: map['id'] as String,
      orderNo: map['orderNo'] as int? ?? 0,
      date: map['date'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      partyName: map['partyName'] as String? ?? '',
      items: (jsonDecode(map['items'] as String? ?? '[]') as List).cast<Map<String, dynamic>>(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}