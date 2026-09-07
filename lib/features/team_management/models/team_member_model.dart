import 'package:flutter/material.dart';

class RoleModel {
  final String id;
  final String name;
  final bool accessSales;
  final bool accessPurchase;
  final bool accessInventory;
  final bool accessReports;
  final bool accessAdmin;
  final bool accessPartyDetails;
  final DateTime? createdAt;

  const RoleModel({
    required this.id,
    required this.name,
    this.accessSales = false,
    this.accessPurchase = false,
    this.accessInventory = false,
    this.accessReports = false,
    this.accessAdmin = false,
    this.accessPartyDetails = false,
    this.createdAt,
  });

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'accessSales': accessSales ? 1 : 0,
      'accessPurchase': accessPurchase ? 1 : 0,
      'accessInventory': accessInventory ? 1 : 0,
      'accessReports': accessReports ? 1 : 0,
      'accessAdmin': accessAdmin ? 1 : 0,
      'accessPartyDetails': accessPartyDetails ? 1 : 0,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory RoleModel.fromDb(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      accessSales: (map['accessSales'] ?? 0) == 1,
      accessPurchase: (map['accessPurchase'] ?? 0) == 1,
      accessInventory: (map['accessInventory'] ?? 0) == 1,
      accessReports: (map['accessReports'] ?? 0) == 1,
      accessAdmin: (map['accessAdmin'] ?? 0) == 1,
      accessPartyDetails: (map['accessPartyDetails'] ?? 0) == 1,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => toDb();

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel.fromDb(json);
  }

  RoleModel copyWith({
    String? name,
    bool? accessSales,
    bool? accessPurchase,
    bool? accessInventory,
    bool? accessReports,
    bool? accessAdmin,
    bool? accessPartyDetails,
  }) {
    return RoleModel(
      id: id,
      name: name ?? this.name,
      accessSales: accessSales ?? this.accessSales,
      accessPurchase: accessPurchase ?? this.accessPurchase,
      accessInventory: accessInventory ?? this.accessInventory,
      accessReports: accessReports ?? this.accessReports,
      accessAdmin: accessAdmin ?? this.accessAdmin,
      accessPartyDetails: accessPartyDetails ?? this.accessPartyDetails,
      createdAt: createdAt,
    );
  }
}

class TeamMemberModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String roleId;
  final String roleName;
  final bool isActive;
  final String? photoPath;
  final DateTime? lastLoginTime;
  final DateTime createdAt;

  TeamMemberModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    required this.roleId,
    required this.roleName,
    this.isActive = true,
    this.photoPath,
    this.lastLoginTime,
    required this.createdAt,
  });

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'roleId': roleId,
      'roleName': roleName,
      'isActive': isActive ? 1 : 0,
      'photoPath': photoPath,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TeamMemberModel.fromDb(Map<String, dynamic> map) {
    return TeamMemberModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      isActive: (map['isActive'] ?? 1) == 1,
      photoPath: map['photoPath'] as String?,
      lastLoginTime: map['lastLoginTime'] != null ? DateTime.parse(map['lastLoginTime'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => toDb();

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel.fromDb(json);
  }

  TeamMemberModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? roleId,
    String? roleName,
    bool? isActive,
    String? photoPath,
    DateTime? lastLoginTime,
  }) {
    return TeamMemberModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      photoPath: photoPath ?? this.photoPath,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      createdAt: createdAt,
    );
  }
}

// Default roles for initial setup
const List<RoleModel> kDefaultRoles = [
  RoleModel(
    id: 'role_admin',
    name: 'Admin',
    accessSales: true,
    accessPurchase: true,
    accessInventory: true,
    accessReports: true,
    accessAdmin: true,
    accessPartyDetails: true,
  ),
  RoleModel(
    id: 'role_manager',
    name: 'Manager',
    accessSales: true,
    accessPurchase: true,
    accessInventory: true,
    accessReports: true,
    accessAdmin: false,
    accessPartyDetails: true,
  ),
  RoleModel(
    id: 'role_cashier',
    name: 'Cashier',
    accessSales: true,
    accessPurchase: false,
    accessInventory: false,
    accessReports: false,
    accessAdmin: false,
    accessPartyDetails: false,
  ),
];