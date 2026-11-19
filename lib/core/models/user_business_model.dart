class BusinessPermissions {
  final bool accessSales;
  final bool accessPurchase;
  final bool accessInventory;
  final bool accessReports;
  final bool accessAdmin;
  final bool accessPartyDetails;

  const BusinessPermissions({
    this.accessSales = true,
    this.accessPurchase = true,
    this.accessInventory = true,
    this.accessReports = true,
    this.accessAdmin = true,
    this.accessPartyDetails = true,
  });

  factory BusinessPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BusinessPermissions();
    return BusinessPermissions(
      accessSales: map['accessSales'] == true || map['accessSales'] == 1,
      accessPurchase: map['accessPurchase'] == true || map['accessPurchase'] == 1,
      accessInventory: map['accessInventory'] == true || map['accessInventory'] == 1,
      accessReports: map['accessReports'] == true || map['accessReports'] == 1,
      accessAdmin: map['accessAdmin'] == true || map['accessAdmin'] == 1,
      accessPartyDetails: map['accessPartyDetails'] == true || map['accessPartyDetails'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessSales': accessSales,
      'accessPurchase': accessPurchase,
      'accessInventory': accessInventory,
      'accessReports': accessReports,
      'accessAdmin': accessAdmin,
      'accessPartyDetails': accessPartyDetails,
    };
  }

  factory BusinessPermissions.fromJson(Map<String, dynamic>? json) =>
      BusinessPermissions.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  static const BusinessPermissions allGranted = BusinessPermissions(
    accessSales: true,
    accessPurchase: true,
    accessInventory: true,
    accessReports: true,
    accessAdmin: true,
    accessPartyDetails: true,
  );
}

class UserBusinessModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String gstNumber;
  final String businessType;
  final String businessCategory;
  final String phone1;
  final String email;
  final String address;
  final String state;
  final String userRole;
  final bool isOwner;
  final BusinessPermissions permissions;

  const UserBusinessModel({
    required this.id,
    required this.businessName,
    this.ownerName = '',
    this.gstNumber = '',
    this.businessType = '',
    this.businessCategory = '',
    this.phone1 = '',
    this.email = '',
    this.address = '',
    this.state = '',
    this.userRole = 'Owner',
    this.isOwner = true,
    this.permissions = BusinessPermissions.allGranted,
  });

  factory UserBusinessModel.fromMap(Map<String, dynamic> map) {
    final permissionsMap = map['permissions'] as Map<String, dynamic>?;
    final isOwnerVal = map['isOwner'] == true;
    return UserBusinessModel(
      id: map['id']?.toString() ?? '',
      businessName: map['businessName']?.toString() ?? map['name']?.toString() ?? 'My Business',
      ownerName: map['ownerName']?.toString() ?? '',
      gstNumber: map['gstNumber']?.toString() ?? '',
      businessType: map['businessType']?.toString() ?? '',
      businessCategory: map['businessCategory']?.toString() ?? '',
      phone1: map['phone1']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      userRole: map['userRole']?.toString() ?? (isOwnerVal ? 'Owner' : 'Staff'),
      isOwner: isOwnerVal,
      permissions: isOwnerVal
          ? BusinessPermissions.allGranted
          : BusinessPermissions.fromMap(permissionsMap),
    );
  }

  factory UserBusinessModel.fromJson(Map<String, dynamic> json) =>
      UserBusinessModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'phone1': phone1,
      'email': email,
      'address': address,
      'state': state,
      'userRole': userRole,
      'isOwner': isOwner,
      'permissions': permissions.toMap(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
