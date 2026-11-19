import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/user_business_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../business_profile/data/business_profile_repository.dart';
import '../../business_profile/models/business_profile_model.dart';

class AuthState {
  final bool isLoggedIn;
  final String phoneNumber;
  final String userName;
  final String businessName;
  final String email;
  final int resendCountdown;
  final bool isTimerRunning;
  final String? selectedCompany;
  final List<String> createdBusinesses;
  final List<UserBusinessModel> userBusinesses;
  final UserBusinessModel? activeBusiness;

  final String ownerName;
  final String gstNumber;
  final String businessType;
  final String businessCategory;
  final String phone2;
  final String website;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String description;
  final String booksStartDate;
  final bool hasLogo;
  final bool hasSignature;

  final String? logoImagePath;
  final String? signatureImagePath;
  final bool showGstOnCard;
  final bool showBusinessTypeOnCard;
  final bool showCategoryOnCard;

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

  const AuthState({
    this.isLoggedIn = false,
    this.phoneNumber = '',
    this.userName = '',
    this.businessName = '',
    this.email = '',
    this.resendCountdown = 28,
    this.isTimerRunning = false,
    this.selectedCompany,
    this.createdBusinesses = const [],
    this.userBusinesses = const [],
    this.activeBusiness,
    this.ownerName = '',
    this.gstNumber = '',
    this.businessType = 'Retail Business',
    this.businessCategory = 'Kirana/ General Merchant',
    this.phone2 = '',
    this.website = '',
    this.address = '',
    this.city = '',
    this.state = 'Delhi',
    this.pincode = '',
    this.country = 'India',
    this.description = '',
    this.booksStartDate = '',
    this.hasLogo = false,
    this.hasSignature = false,
    this.logoImagePath,
    this.signatureImagePath,
    this.showGstOnCard = false,
    this.showBusinessTypeOnCard = false,
    this.showCategoryOnCard = false,
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

  BusinessPermissions get permissions =>
      activeBusiness?.permissions ??
      (isLoggedIn && (activeBusiness?.isOwner ?? true)
          ? BusinessPermissions.allGranted
          : const BusinessPermissions());

  bool get isOwner => activeBusiness?.isOwner ?? true;
  String get userRole => activeBusiness?.userRole ?? 'Owner';

  int get profileCompletionPercentage {
    int score = 0;
    if (businessName.isNotEmpty) score += 20;
    if (phoneNumber.isNotEmpty) score += 10;
    if (email.isNotEmpty) score += 10;
    if (address.isNotEmpty) score += 10;
    if (gstNumber.isNotEmpty) score += 10;
    if (businessType.isNotEmpty) score += 10;
    if (businessCategory.isNotEmpty) score += 10;
    if (hasLogo || (logoImagePath != null && logoImagePath!.isNotEmpty)) score += 10;
    if (hasSignature || (signatureImagePath != null && signatureImagePath!.isNotEmpty)) score += 10;
    return score;
  }

  AuthState copyWith({
    bool? isLoggedIn,
    String? phoneNumber,
    String? userName,
    String? businessName,
    String? email,
    int? resendCountdown,
    bool? isTimerRunning,
    String? selectedCompany,
    List<String>? createdBusinesses,
    List<UserBusinessModel>? userBusinesses,
    UserBusinessModel? activeBusiness,
    String? ownerName,
    String? gstNumber,
    String? businessType,
    String? businessCategory,
    String? phone2,
    String? website,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? description,
    String? booksStartDate,
    bool? hasLogo,
    bool? hasSignature,
    String? logoImagePath,
    String? signatureImagePath,
    bool? showGstOnCard,
    bool? showBusinessTypeOnCard,
    bool? showCategoryOnCard,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? upiId,
    String? invoiceTheme,
    String? invoiceColorHex,
    String? invoiceTerms,
    bool? showUpiQr,
    String? logoUrl,
    String? signatureUrl,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userName: userName ?? this.userName,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      createdBusinesses: createdBusinesses ?? this.createdBusinesses,
      userBusinesses: userBusinesses ?? this.userBusinesses,
      activeBusiness: activeBusiness ?? this.activeBusiness,
      ownerName: ownerName ?? this.ownerName,
      gstNumber: gstNumber ?? this.gstNumber,
      businessType: businessType ?? this.businessType,
      businessCategory: businessCategory ?? this.businessCategory,
      phone2: phone2 ?? this.phone2,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      description: description ?? this.description,
      booksStartDate: booksStartDate ?? this.booksStartDate,
      hasLogo: hasLogo ?? this.hasLogo,
      hasSignature: hasSignature ?? this.hasSignature,
      logoImagePath: logoImagePath ?? this.logoImagePath,
      signatureImagePath: signatureImagePath ?? this.signatureImagePath,
      showGstOnCard: showGstOnCard ?? this.showGstOnCard,
      showBusinessTypeOnCard: showBusinessTypeOnCard ?? this.showBusinessTypeOnCard,
      showCategoryOnCard: showCategoryOnCard ?? this.showCategoryOnCard,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
      invoiceTheme: invoiceTheme ?? this.invoiceTheme,
      invoiceColorHex: invoiceColorHex ?? this.invoiceColorHex,
      invoiceTerms: invoiceTerms ?? this.invoiceTerms,
      showUpiQr: showUpiQr ?? this.showUpiQr,
      logoUrl: logoUrl ?? this.logoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  Timer? _timer;
  LocalStorageService? _storage;
  final BusinessProfileRepository _businessProfileRepository = BusinessProfileRepository();

  AuthNotifier() : super(const AuthState()) {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await LocalStorageService.getInstance();

    state = state.copyWith(
      isLoggedIn: _storage!.isLoggedIn,
      phoneNumber: _storage!.phoneNumber,
      userName: _storage!.userName,
      businessName: _storage!.businessName,
      email: _storage!.email,
      selectedCompany: _storage!.businessName.isNotEmpty
          ? _storage!.businessName
          : null,
      createdBusinesses: _storage!.businessesList,
      ownerName: _storage!.ownerName,
      gstNumber: _storage!.gstNumber,
      businessType: _storage!.businessType,
      businessCategory: _storage!.businessCategory,
      phone2: _storage!.phone2,
      website: _storage!.website,
      address: _storage!.address,
      city: _storage!.city,
      state: _storage!.state,
      pincode: _storage!.pincode,
      country: _storage!.country,
      description: _storage!.description,
      booksStartDate: _storage!.booksStartDate,
      hasLogo: _storage!.hasLogo,
      hasSignature: _storage!.hasSignature,
      logoImagePath: _storage!.logoImagePath,
      signatureImagePath: _storage!.signatureImagePath,
      showGstOnCard: _storage!.showGstOnCard,
      showBusinessTypeOnCard: _storage!.showBusinessTypeOnCard,
      showCategoryOnCard: _storage!.showCategoryOnCard,
    );

    await _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final dbProfile = await _businessProfileRepository.getBusinessProfile();
      if (dbProfile != null) {
        state = state.copyWith(
          businessName: dbProfile.businessName.isNotEmpty ? dbProfile.businessName : state.businessName,
          ownerName: dbProfile.ownerName.isNotEmpty ? dbProfile.ownerName : state.ownerName,
          gstNumber: dbProfile.gstNumber,
          businessType: dbProfile.businessType,
          businessCategory: dbProfile.businessCategory,
          phoneNumber: dbProfile.phone1.isNotEmpty ? dbProfile.phone1 : state.phoneNumber,
          phone2: dbProfile.phone2,
          email: dbProfile.email.isNotEmpty ? dbProfile.email : state.email,
          website: dbProfile.website,
          address: dbProfile.address,
          city: dbProfile.city,
          state: dbProfile.state,
          pincode: dbProfile.pincode,
          country: dbProfile.country,
          description: dbProfile.description,
          booksStartDate: dbProfile.booksStartDate,
          logoImagePath: dbProfile.logoPath ?? state.logoImagePath,
          signatureImagePath: dbProfile.signaturePath ?? state.signatureImagePath,
          showGstOnCard: dbProfile.showGstOnCard,
          showBusinessTypeOnCard: dbProfile.showBusinessTypeOnCard,
          showCategoryOnCard: dbProfile.showCategoryOnCard,
          bankName: dbProfile.bankName,
          accountNumber: dbProfile.accountNumber,
          ifscCode: dbProfile.ifscCode,
          branchName: dbProfile.branchName,
          upiId: dbProfile.upiId,
          invoiceTheme: dbProfile.invoiceTheme,
          invoiceColorHex: dbProfile.invoiceColorHex,
          invoiceTerms: dbProfile.invoiceTerms,
          showUpiQr: dbProfile.showUpiQr,
          logoUrl: dbProfile.logoUrl,
          signatureUrl: dbProfile.signatureUrl,
        );
      }
    } catch (e) {
      debugPrint('Error loading from database: $e');
    }
  }

  Future<void> setPhoneNumber(String phone) async {
    state = state.copyWith(phoneNumber: phone);
    await _storage?.setPhoneNumber(phone);
  }

  Future<void> completeLogin() async {
    state = state.copyWith(isLoggedIn: true);
    await _storage?.setLoggedIn(true);
  }

  /// Phase 1 API Integration: Dispatch SMS OTP via 2Factor.in Gateway
  Future<Map<String, dynamic>> sendOtpApi(String phone) async {
    await setPhoneNumber(phone);
    startOtpTimer();
    return await ApiService.sendOtp(phone);
  }

  /// Phase 1 API Integration: Verify OTP & Sync JWT Session
  Future<Map<String, dynamic>> verifyOtpApi(String otp) async {
    final result = await ApiService.verifyOtp(state.phoneNumber, otp);
    if (result['success'] == true) {
      await completeLogin();

      // Clear any cached session businesses and SQLite tables from a previous user
      await _storage?.clearUserSession();
      await DatabaseHelper().clearUserData();

      final List<dynamic> rawBusinesses = result['businesses'] ?? [];
      final List<UserBusinessModel> parsedBusinesses = rawBusinesses
          .map((b) => UserBusinessModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();

      final List<String> userBizNames = parsedBusinesses
          .map((b) => b.businessName)
          .where((n) => n.isNotEmpty)
          .toList();

      // Set ONLY the authenticated user's business list
      await _storage?.setBusinessesList(userBizNames);

      UserBusinessModel? firstBiz = parsedBusinesses.isNotEmpty ? parsedBusinesses.first : null;
      if (firstBiz != null) {
        await ApiService.saveActiveBusinessId(firstBiz.id);
        await _storage?.setBusinessName(firstBiz.businessName);
      } else {
        await _storage?.setBusinessName('');
      }

      state = state.copyWith(
        createdBusinesses: userBizNames,
        userBusinesses: parsedBusinesses,
        activeBusiness: firstBiz,
        businessName: firstBiz?.businessName ?? '',
        selectedCompany: firstBiz?.businessName,
      );

      // Phase 9: Sync FCM Push Token with authenticated user
      NotificationService.syncTokenWithBackend();
    }
    return result;
  }

  /// Phase 1 API Integration: Google Login & Sync JWT Session
  Future<Map<String, dynamic>> googleLoginApi({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final result = await ApiService.googleAuth(
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    if (result['success'] == true) {
      await completeLogin();

      await _storage?.clearUserSession();
      await DatabaseHelper().clearUserData();
      await _storage?.setEmail(email);

      final List<dynamic> rawBusinesses = result['businesses'] ?? [];
      final List<UserBusinessModel> parsedBusinesses = rawBusinesses
          .map((b) => UserBusinessModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();

      final List<String> userBizNames = parsedBusinesses
          .map((b) => b.businessName)
          .where((n) => n.isNotEmpty)
          .toList();

      await _storage?.setBusinessesList(userBizNames);

      UserBusinessModel? firstBiz = parsedBusinesses.isNotEmpty ? parsedBusinesses.first : null;
      if (firstBiz != null) {
        await ApiService.saveActiveBusinessId(firstBiz.id);
        await _storage?.setBusinessName(firstBiz.businessName);
      } else {
        await _storage?.setBusinessName('');
      }

      state = state.copyWith(
        email: email,
        userName: displayName ?? state.userName,
        createdBusinesses: userBizNames,
        userBusinesses: parsedBusinesses,
        activeBusiness: firstBiz,
        businessName: firstBiz?.businessName ?? '',
        selectedCompany: firstBiz?.businessName,
      );

      NotificationService.syncTokenWithBackend();
    }
    return result;
  }

  /// Phase 1 API Integration: Fetch User Businesses from Backend
  Future<void> fetchUserBusinessesApi() async {
    final result = await ApiService.fetchMyBusinesses();
    if (result['success'] == true && result['businesses'] != null) {
      final List<dynamic> rawBusinesses = result['businesses'];
      final List<UserBusinessModel> parsedBusinesses = rawBusinesses
          .map((b) => UserBusinessModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();

      final List<String> userBizNames = parsedBusinesses
          .map((b) => b.businessName)
          .where((n) => n.isNotEmpty)
          .toList();

      UserBusinessModel? activeBiz = state.activeBusiness;
      if (parsedBusinesses.isNotEmpty) {
        if (activeBiz != null) {
          final matched = parsedBusinesses.where((b) => b.id == activeBiz!.id);
          if (matched.isNotEmpty) {
            activeBiz = matched.first;
          } else {
            activeBiz = parsedBusinesses.first;
          }
        } else {
          activeBiz = parsedBusinesses.first;
        }
        await ApiService.saveActiveBusinessId(activeBiz.id);
        await _storage?.setBusinessName(activeBiz.businessName);
      } else {
        await _storage?.setBusinessName('');
        activeBiz = null;
      }

      await _storage?.setBusinessesList(userBizNames);
      state = state.copyWith(
        createdBusinesses: userBizNames,
        userBusinesses: parsedBusinesses,
        activeBusiness: activeBiz,
        businessName: activeBiz?.businessName ?? '',
        selectedCompany: activeBiz?.businessName,
      );
    }
  }

  Future<void> updateBusinessInfo({
    String? name,
    String? businessName,
    String? email,
  }) async {
    final newName = name != null && name.isNotEmpty ? name : state.userName;
    final newBusiness = businessName != null && businessName.isNotEmpty
        ? businessName
        : state.businessName;
    final newEmail = email ?? state.email;

    if (newName.isNotEmpty) await _storage?.setUserName(newName);
    if (newBusiness.isNotEmpty) await _storage?.setBusinessName(newBusiness);
    if (newEmail.isNotEmpty) await _storage?.setEmail(newEmail);

    final updatedBusinesses = _storage?.businessesList ?? state.createdBusinesses;

    state = state.copyWith(
      userName: newName,
      businessName: newBusiness,
      email: newEmail,
      selectedCompany: newBusiness.isNotEmpty ? newBusiness : null,
      createdBusinesses: updatedBusinesses,
      isLoggedIn: true,
    );
    await _storage?.setLoggedIn(true);
  }

  Future<void> saveFullBusinessProfile({
    required String businessName,
    required String ownerName,
    required String gstNumber,
    required String businessType,
    required String businessCategory,
    required String phone1,
    required String phone2,
    required String email,
    required String website,
    required String address,
    required String city,
    required String stateName,
    required String pincode,
    required String country,
    required String description,
    required String booksStartDate,
    bool? hasLogo,
    bool? hasSignature,
    String? logoImagePath,
    String? signatureImagePath,
    bool? showGstOnCard,
    bool? showBusinessTypeOnCard,
    bool? showCategoryOnCard,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? upiId,
    String? invoiceTheme,
    String? invoiceColorHex,
    String? invoiceTerms,
    bool? showUpiQr,
    String? logoUrl,
    String? signatureUrl,
  }) async {
    await _storage?.setBusinessName(businessName);
    await _storage?.setOwnerName(ownerName);
    await _storage?.setGstNumber(gstNumber);
    await _storage?.setBusinessType(businessType);
    await _storage?.setBusinessCategory(businessCategory);
    await _storage?.setPhoneNumber(phone1);
    await _storage?.setPhone2(phone2);
    await _storage?.setEmail(email);
    await _storage?.setWebsite(website);
    await _storage?.setAddress(address);
    await _storage?.setCity(city);
    await _storage?.setState(stateName);
    await _storage?.setPincode(pincode);
    await _storage?.setCountry(country);
    await _storage?.setDescription(description);
    await _storage?.setBooksStartDate(booksStartDate);
    if (hasLogo != null) await _storage?.setHasLogo(hasLogo);
    if (hasSignature != null) await _storage?.setHasSignature(hasSignature);

    if (logoImagePath != null) await _storage?.setLogoImagePath(logoImagePath);
    if (signatureImagePath != null) await _storage?.setSignatureImagePath(signatureImagePath);
    if (showGstOnCard != null) await _storage?.setShowGstOnCard(showGstOnCard);
    if (showBusinessTypeOnCard != null) await _storage?.setShowBusinessTypeOnCard(showBusinessTypeOnCard);
    if (showCategoryOnCard != null) await _storage?.setShowCategoryOnCard(showCategoryOnCard);

    final profile = BusinessProfileModel(
      businessName: businessName,
      ownerName: ownerName,
      gstNumber: gstNumber,
      businessType: businessType,
      businessCategory: businessCategory,
      phone1: phone1,
      phone2: phone2,
      email: email,
      website: website,
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
      country: country,
      description: description,
      booksStartDate: booksStartDate,
      logoPath: logoImagePath,
      signaturePath: signatureImagePath,
      showGstOnCard: showGstOnCard ?? state.showGstOnCard,
      showBusinessTypeOnCard: showBusinessTypeOnCard ?? state.showBusinessTypeOnCard,
      showCategoryOnCard: showCategoryOnCard ?? state.showCategoryOnCard,
      updatedAt: DateTime.now(),
      bankName: bankName ?? state.bankName,
      accountNumber: accountNumber ?? state.accountNumber,
      ifscCode: ifscCode ?? state.ifscCode,
      branchName: branchName ?? state.branchName,
      upiId: upiId ?? state.upiId,
      invoiceTheme: invoiceTheme ?? state.invoiceTheme,
      invoiceColorHex: invoiceColorHex ?? state.invoiceColorHex,
      invoiceTerms: invoiceTerms ?? state.invoiceTerms,
      showUpiQr: showUpiQr ?? state.showUpiQr,
      logoUrl: logoUrl ?? state.logoUrl,
      signatureUrl: signatureUrl ?? state.signatureUrl,
    );

    await _businessProfileRepository.saveBusinessProfile(profile);

    // Sync Business Profile & Branding with Cloud Backend API (Phase 1 & Phase 8)
    ApiService.createBusiness({
      'businessName': businessName,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'phone1': phone1,
      'email': email,
      'address': address,
      'state': stateName,
    }).catchError((_) => <String, dynamic>{'success': false});

    ApiService.updateBusinessBranding(brandingData: {
      'businessName': businessName,
      'ownerName': ownerName,
      'gstNumber': gstNumber,
      'phone1': phone1,
      'email': email,
      'address': address,
      'state': stateName,
      'bankName': bankName ?? state.bankName,
      'accountNumber': accountNumber ?? state.accountNumber,
      'ifscCode': ifscCode ?? state.ifscCode,
      'branchName': branchName ?? state.branchName,
      'upiId': upiId ?? state.upiId,
      'invoiceTheme': invoiceTheme ?? state.invoiceTheme,
      'invoiceColorHex': invoiceColorHex ?? state.invoiceColorHex,
      'invoiceTerms': invoiceTerms ?? state.invoiceTerms,
      'showUpiQr': showUpiQr ?? state.showUpiQr,
    }).catchError((_) => <String, dynamic>{'success': false});

    final updatedBusinesses = _storage?.businessesList ?? state.createdBusinesses;

    state = state.copyWith(
      businessName: businessName,
      ownerName: ownerName,
      gstNumber: gstNumber,
      businessType: businessType,
      businessCategory: businessCategory,
      phoneNumber: phone1,
      phone2: phone2,
      email: email,
      website: website,
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
      country: country,
      description: description,
      booksStartDate: booksStartDate,
      hasLogo: hasLogo ?? state.hasLogo,
      hasSignature: hasSignature ?? state.hasSignature,
      logoImagePath: logoImagePath ?? state.logoImagePath,
      signatureImagePath: signatureImagePath ?? state.signatureImagePath,
      showGstOnCard: showGstOnCard ?? state.showGstOnCard,
      showBusinessTypeOnCard: showBusinessTypeOnCard ?? state.showBusinessTypeOnCard,
      showCategoryOnCard: showCategoryOnCard ?? state.showCategoryOnCard,
      selectedCompany: businessName.isNotEmpty ? businessName : state.selectedCompany,
      createdBusinesses: updatedBusinesses,
      bankName: bankName ?? state.bankName,
      accountNumber: accountNumber ?? state.accountNumber,
      ifscCode: ifscCode ?? state.ifscCode,
      branchName: branchName ?? state.branchName,
      upiId: upiId ?? state.upiId,
      invoiceTheme: invoiceTheme ?? state.invoiceTheme,
      invoiceColorHex: invoiceColorHex ?? state.invoiceColorHex,
      invoiceTerms: invoiceTerms ?? state.invoiceTerms,
      showUpiQr: showUpiQr ?? state.showUpiQr,
      logoUrl: logoUrl ?? state.logoUrl,
      signatureUrl: signatureUrl ?? state.signatureUrl,
    );
  }

  void toggleLogo(bool value) async {
    await _storage?.setHasLogo(value);
    state = state.copyWith(hasLogo: value);
  }

  void toggleSignature(bool value) async {
    await _storage?.setHasSignature(value);
    state = state.copyWith(hasSignature: value);
  }

  void startOtpTimer() {
    _timer?.cancel();
    state = state.copyWith(resendCountdown: 28, isTimerRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown > 0) {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(isTimerRunning: false);
      }
    });
  }

  Future<void> selectCompany(String companyName, [UserBusinessModel? business]) async {
    UserBusinessModel? target = business;
    if (target == null && state.userBusinesses.isNotEmpty) {
      try {
        target = state.userBusinesses.firstWhere((b) => b.businessName == companyName);
      } catch (_) {
        target = null;
      }
    }

    if (target != null) {
      await ApiService.saveActiveBusinessId(target.id);
    }

    await _storage?.setBusinessName(companyName);
    state = state.copyWith(
      selectedCompany: companyName,
      businessName: companyName,
      activeBusiness: target ?? state.activeBusiness,
      isLoggedIn: true,
    );
    await _storage?.setLoggedIn(true);
  }

  Future<void> logout() async {
    await _storage?.setLoggedIn(false);
    state = state.copyWith(
      isLoggedIn: false,
      selectedCompany: null,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});