import 'dart:convert';

/// Phase 11: Quotation / Estimate Item Model
class QuotationItemModel {
  final String? itemId;
  final String name;
  final double quantity;
  final double rate;
  final double taxPercent;
  final double total;

  QuotationItemModel({
    this.itemId,
    required this.name,
    required this.quantity,
    required this.rate,
    this.taxPercent = 0.0,
    required this.total,
  });

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      itemId: json['item_id']?.toString() ?? json['itemId']?.toString(),
      name: json['name'] ?? json['item_name'] ?? 'Item',
      quantity: (json['quantity'] ?? json['qty'] ?? 1).toDouble(),
      rate: (json['rate'] ?? json['price'] ?? 0).toDouble(),
      taxPercent: (json['tax_percent'] ?? json['taxPercent'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'taxPercent': taxPercent,
      'total': total,
    };
  }
}

/// Phase 11: Quotation / Estimate Model
class QuotationModel {
  final String id;
  final String businessId;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final String quotationNo;
  final String status; // DRAFT, SENT, ACCEPTED, REJECTED, EXPIRED, CONVERTED
  final DateTime? validUntil;
  final String? notes;
  final String? terms;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? convertedToInvoiceId;
  final DateTime? convertedAt;
  final List<QuotationItemModel> items;
  final DateTime createdAt;

  QuotationModel({
    required this.id,
    required this.businessId,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    required this.quotationNo,
    required this.status,
    this.validUntil,
    this.notes,
    this.terms,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.convertedToInvoiceId,
    this.convertedAt,
    required this.items,
    required this.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    List<QuotationItemModel> parsedItems = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        parsedItems = (json['items'] as List)
            .map((item) => QuotationItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['items'] is String) {
        try {
          final List decoded = jsonDecode(json['items']);
          parsedItems = decoded.map((i) => QuotationItemModel.fromJson(i)).toList();
        } catch (_) {}
      }
    }

    return QuotationModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      partyId: json['party_id']?.toString() ?? json['partyId']?.toString(),
      partyName: json['party_name'] ?? json['partyName'] ?? 'Walk-in Customer',
      partyPhone: json['party_phone'] ?? json['partyPhone'],
      quotationNo: json['quotation_no'] ?? json['quotationNo'] ?? 'EST-001',
      status: (json['status'] ?? 'DRAFT').toString().toUpperCase(),
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until'].toString()) : null,
      notes: json['notes'],
      terms: json['terms'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? json['totalAmount'] ?? 0).toDouble(),
      convertedToInvoiceId: json['converted_to_invoice_id']?.toString() ?? json['convertedToInvoiceId']?.toString(),
      convertedAt: json['converted_at'] != null ? DateTime.tryParse(json['converted_at'].toString()) : null,
      items: parsedItems,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Phase 11: Credit Note Item (Sales Return)
class CreditNoteItemModel {
  final String? itemId;
  final String name;
  final double quantity;
  final double rate;
  final double taxPercent;
  final double total;

  CreditNoteItemModel({
    this.itemId,
    required this.name,
    required this.quantity,
    required this.rate,
    this.taxPercent = 0.0,
    required this.total,
  });

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) {
    return CreditNoteItemModel(
      itemId: json['item_id']?.toString() ?? json['itemId']?.toString(),
      name: json['name'] ?? json['item_name'] ?? 'Item',
      quantity: (json['quantity'] ?? json['qty'] ?? 1).toDouble(),
      rate: (json['rate'] ?? json['price'] ?? 0).toDouble(),
      taxPercent: (json['tax_percent'] ?? json['taxPercent'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'taxPercent': taxPercent,
      'total': total,
    };
  }
}

/// Phase 11: Credit Note Model (Sales Return)
class CreditNoteModel {
  final String id;
  final String businessId;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final String? invoiceId;
  final String? invoiceNo;
  final String noteNo;
  final DateTime noteDate;
  final String reason;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final List<CreditNoteItemModel> items;
  final DateTime createdAt;

  CreditNoteModel({
    required this.id,
    required this.businessId,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    this.invoiceId,
    this.invoiceNo,
    required this.noteNo,
    required this.noteDate,
    required this.reason,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) {
    List<CreditNoteItemModel> parsedItems = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        parsedItems = (json['items'] as List)
            .map((item) => CreditNoteItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['items'] is String) {
        try {
          final List decoded = jsonDecode(json['items']);
          parsedItems = decoded.map((i) => CreditNoteItemModel.fromJson(i)).toList();
        } catch (_) {}
      }
    }

    return CreditNoteModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      partyId: json['party_id']?.toString() ?? json['partyId']?.toString(),
      partyName: json['party_name'] ?? json['partyName'] ?? 'Customer',
      partyPhone: json['party_phone'] ?? json['partyPhone'],
      invoiceId: json['invoice_id']?.toString() ?? json['invoiceId']?.toString(),
      invoiceNo: json['invoice_no'] ?? json['invoiceNo'],
      noteNo: json['note_no'] ?? json['noteNo'] ?? 'CN-001',
      noteDate: json['note_date'] != null ? DateTime.tryParse(json['note_date'].toString()) ?? DateTime.now() : DateTime.now(),
      reason: json['reason'] ?? 'Goods Damaged / Return',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? json['totalAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      items: parsedItems,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Phase 11: Debit Note Item (Purchase Return)
class DebitNoteItemModel {
  final String? itemId;
  final String name;
  final double quantity;
  final double rate;
  final double taxPercent;
  final double total;

  DebitNoteItemModel({
    this.itemId,
    required this.name,
    required this.quantity,
    required this.rate,
    this.taxPercent = 0.0,
    required this.total,
  });

  factory DebitNoteItemModel.fromJson(Map<String, dynamic> json) {
    return DebitNoteItemModel(
      itemId: json['item_id']?.toString() ?? json['itemId']?.toString(),
      name: json['name'] ?? json['item_name'] ?? 'Item',
      quantity: (json['quantity'] ?? json['qty'] ?? 1).toDouble(),
      rate: (json['rate'] ?? json['price'] ?? 0).toDouble(),
      taxPercent: (json['tax_percent'] ?? json['taxPercent'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'taxPercent': taxPercent,
      'total': total,
    };
  }
}

/// Phase 11: Debit Note Model (Purchase Return)
class DebitNoteModel {
  final String id;
  final String businessId;
  final String? supplierId;
  final String supplierName;
  final String? purchaseId;
  final String? purchaseNo;
  final String noteNo;
  final DateTime noteDate;
  final String reason;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final List<DebitNoteItemModel> items;
  final DateTime createdAt;

  DebitNoteModel({
    required this.id,
    required this.businessId,
    this.supplierId,
    required this.supplierName,
    this.purchaseId,
    this.purchaseNo,
    required this.noteNo,
    required this.noteDate,
    required this.reason,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory DebitNoteModel.fromJson(Map<String, dynamic> json) {
    List<DebitNoteItemModel> parsedItems = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        parsedItems = (json['items'] as List)
            .map((item) => DebitNoteItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['items'] is String) {
        try {
          final List decoded = jsonDecode(json['items']);
          parsedItems = decoded.map((i) => DebitNoteItemModel.fromJson(i)).toList();
        } catch (_) {}
      }
    }

    return DebitNoteModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString() ?? json['supplierId']?.toString(),
      supplierName: json['supplier_name'] ?? json['supplierName'] ?? 'Supplier',
      purchaseId: json['purchase_id']?.toString() ?? json['purchaseId']?.toString(),
      purchaseNo: json['purchase_no'] ?? json['purchaseNo'],
      noteNo: json['note_no'] ?? json['noteNo'] ?? 'DN-001',
      noteDate: json['note_date'] != null ? DateTime.tryParse(json['note_date'].toString()) ?? DateTime.now() : DateTime.now(),
      reason: json['reason'] ?? 'Goods Damaged / Purchase Return',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? json['totalAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      items: parsedItems,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

