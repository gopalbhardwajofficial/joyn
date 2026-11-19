class NotificationModel {
  final String id;
  final String businessId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? json['business_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? businessId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OverdueDebtor {
  final String id;
  final String name;
  final String category;
  final String contactNumber;
  final String email;
  final String city;
  final double balanceDue;
  final double creditLimit;
  final DateTime? lastReminderSent;
  final DateTime? updatedAt;

  OverdueDebtor({
    required this.id,
    required this.name,
    this.category = 'Customer',
    this.contactNumber = '',
    this.email = '',
    this.city = '',
    required this.balanceDue,
    this.creditLimit = 0.0,
    this.lastReminderSent,
    this.updatedAt,
  });

  factory OverdueDebtor.fromJson(Map<String, dynamic> json) {
    return OverdueDebtor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Customer',
      contactNumber: json['contactNumber']?.toString() ?? json['contact_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      balanceDue: double.tryParse(json['balanceDue']?.toString() ?? json['balance_due']?.toString() ?? '0') ?? 0.0,
      creditLimit: double.tryParse(json['creditLimit']?.toString() ?? json['credit_limit']?.toString() ?? '0') ?? 0.0,
      lastReminderSent: json['lastReminderSent'] != null
          ? DateTime.tryParse(json['lastReminderSent'].toString())
          : (json['last_reminder_sent'] != null ? DateTime.tryParse(json['last_reminder_sent'].toString()) : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null),
    );
  }
}

class PaymentReminderLog {
  final String id;
  final String partyId;
  final String partyName;
  final String partyPhone;
  final double amountDue;
  final String reminderType;
  final String channel;
  final String status;
  final DateTime? createdAt;

  PaymentReminderLog({
    required this.id,
    required this.partyId,
    required this.partyName,
    this.partyPhone = '',
    required this.amountDue,
    this.reminderType = 'MANUAL',
    this.channel = 'WHATSAPP',
    this.status = 'SENT',
    this.createdAt,
  });

  factory PaymentReminderLog.fromJson(Map<String, dynamic> json) {
    return PaymentReminderLog(
      id: json['id']?.toString() ?? '',
      partyId: json['partyId']?.toString() ?? json['party_id']?.toString() ?? '',
      partyName: json['partyName']?.toString() ?? json['party_name']?.toString() ?? '',
      partyPhone: json['partyPhone']?.toString() ?? json['party_phone']?.toString() ?? '',
      amountDue: double.tryParse(json['amountDue']?.toString() ?? json['amount_due']?.toString() ?? '0') ?? 0.0,
      reminderType: json['reminderType']?.toString() ?? json['reminder_type']?.toString() ?? 'MANUAL',
      channel: json['channel']?.toString() ?? 'WHATSAPP',
      status: json['status']?.toString() ?? 'SENT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
    );
  }
}

