// In lib/features/orders/models/sales_models.dart

// Add these enums at the top
enum PriceTaxMode { withTax, withoutTax }
enum DiscountType { percentage, value }

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

  // Pricing
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
  final int? itemNumber;
  final String? itemCode;

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
    this.itemNumber,
    this.itemCode,
  });

  String get displayItemCode {
    if (itemCode != null && itemCode!.trim().isNotEmpty) {
      return itemCode!.trim();
    }
    if (itemNumber != null && itemNumber! > 0) {
      return 'ITM-$itemNumber';
    }
    if (id.isNotEmpty) {
      final digits = id.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 4) {
        return 'ITM-${digits.substring(digits.length - 4)}';
      }
    }
    return 'ITM-1001';
  }

  // Convert to database map
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
      'itemNumber': itemNumber,
      'itemCode': itemCode ?? displayItemCode,
    };
  }

  // Create from database map
  factory InventoryItemModel.fromDb(Map<String, dynamic> map) {
    final parsedNumber = (map['itemNumber'] as num?)?.toInt() ??
        (map['item_number'] as num?)?.toInt();
    final parsedCode = (map['itemCode'] as String?) ??
        (map['item_code'] as String?);

    return InventoryItemModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      barcode: map['barcode'] as String? ?? '',
      unit: map['unit'] as String? ?? 'Pcs',
      category: map['category'] as String? ?? '',
      hsnSac: map['hsnSac'] as String? ?? map['hsn_sac'] as String? ?? '',
      location: map['location'] as String? ?? '',
      barcodeMode: map['barcodeMode'] as String? ?? map['barcode_mode'] as String? ?? 'same',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? (map['purchase_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? (map['selling_price'] as num?)?.toDouble() ?? 0,
      salePriceTaxMode: (map['salePriceTaxMode'] == 'withTax' || map['sale_price_tax_mode'] == 'withTax')
          ? PriceTaxMode.withTax
          : PriceTaxMode.withoutTax,
      discountOnSalePrice: (map['discountOnSalePrice'] as num?)?.toDouble() ?? (map['discount_on_sale_price'] as num?)?.toDouble() ?? 0,
      discountType: (map['discountType'] == 'value' || map['discount_type'] == 'value')
          ? DiscountType.value
          : DiscountType.percentage,
      purchasePriceTaxMode: (map['purchasePriceTaxMode'] == 'withTax' || map['purchase_price_tax_mode'] == 'withTax')
          ? PriceTaxMode.withTax
          : PriceTaxMode.withoutTax,
      taxRateLabel: map['taxRateLabel'] as String? ?? map['tax_rate_label'] as String? ?? 'None',
      taxRatePercent: (map['taxRatePercent'] as num?)?.toDouble() ?? (map['tax_rate_percent'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? map['created_at'] as String? ?? '') ?? DateTime.now(),
      itemNumber: parsedNumber,
      itemCode: parsedCode,
    );
  }

  Map<String, dynamic> toJson() => toDb();
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) => InventoryItemModel.fromDb(json);
}