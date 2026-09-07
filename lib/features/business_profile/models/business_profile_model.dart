class BusinessProfileModel {
  final int? id;
  final String businessName;
  final String ownerName;
  final String gstNumber;
  final String businessType;
  final String businessCategory;
  final String phone1;
  final String phone2;
  final String email;
  final String website;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String description;
  final String booksStartDate;
  final String? logoPath;
  final String? signaturePath;
  final bool showGstOnCard;
  final bool showBusinessTypeOnCard;
  final bool showCategoryOnCard;
  final DateTime updatedAt;

  BusinessProfileModel({
    this.id,
    required this.businessName,
    required this.ownerName,
    required this.gstNumber,
    required this.businessType,
    required this.businessCategory,
    required this.phone1,
    required this.phone2,
    required this.email,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.description,
    required this.booksStartDate,
    this.logoPath,
    this.signaturePath,
    required this.showGstOnCard,
    required this.showBusinessTypeOnCard,
    required this.showCategoryOnCard,
    required this.updatedAt,
  });

  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'businessName': businessName,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'description': description,
      'booksStartDate': booksStartDate,
      'logoPath': logoPath,
      'signaturePath': signaturePath,
      'showGstOnCard': showGstOnCard ? 1 : 0,
      'showBusinessTypeOnCard': showBusinessTypeOnCard ? 1 : 0,
      'showCategoryOnCard': showCategoryOnCard ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessProfileModel.fromDb(Map<String, dynamic> map) {
    return BusinessProfileModel(
      id: map['id'] as int?,
      businessName: map['businessName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      gstNumber: map['gstNumber'] ?? '',
      businessType: map['businessType'] ?? 'Retail Business',
      businessCategory: map['businessCategory'] ?? 'Kirana/ General Merchant',
      phone1: map['phone1'] ?? '',
      phone2: map['phone2'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? 'Delhi',
      pincode: map['pincode'] ?? '',
      country: map['country'] ?? 'India',
      description: map['description'] ?? '',
      booksStartDate: map['booksStartDate'] ?? '28/07/2026',
      logoPath: map['logoPath'],
      signaturePath: map['signaturePath'],
      showGstOnCard: (map['showGstOnCard'] ?? 0) == 1,
      showBusinessTypeOnCard: (map['showBusinessTypeOnCard'] ?? 0) == 1,
      showCategoryOnCard: (map['showCategoryOnCard'] ?? 0) == 1,
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}