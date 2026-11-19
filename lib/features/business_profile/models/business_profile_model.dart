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

  // Phase 8: Branding, Bank Details & Invoice Customization
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String upiId;
  final String invoiceTheme;
  final String invoiceColorHex;
  final String invoiceTerms;
  final bool showUpiQr;
  final String? logoUrl;
  final String? signatureUrl;

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
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.branchName = '',
    this.upiId = '',
    this.invoiceTheme = 'classic_blue',
    this.invoiceColorHex = '#4338CA',
    this.invoiceTerms = '',
    this.showUpiQr = true,
    this.logoUrl,
    this.signatureUrl,
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
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'upiId': upiId,
      'invoiceTheme': invoiceTheme,
      'invoiceColorHex': invoiceColorHex,
      'invoiceTerms': invoiceTerms,
      'showUpiQr': showUpiQr ? 1 : 0,
      'logoUrl': logoUrl,
      'signatureUrl': signatureUrl,
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
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      ifscCode: map['ifscCode'] ?? '',
      branchName: map['branchName'] ?? '',
      upiId: map['upiId'] ?? '',
      invoiceTheme: map['invoiceTheme'] ?? 'classic_blue',
      invoiceColorHex: map['invoiceColorHex'] ?? '#4338CA',
      invoiceTerms: map['invoiceTerms'] ?? '',
      showUpiQr: map['showUpiQr'] == null ? true : (map['showUpiQr'] == 1 || map['showUpiQr'] == true),
      logoUrl: map['logoUrl'],
      signatureUrl: map['signatureUrl'],
    );
  }

  Map<String, dynamic> toJson() => toDb();

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) => BusinessProfileModel.fromDb(json);
}
