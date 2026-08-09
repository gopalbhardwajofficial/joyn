import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_storage_service.dart';

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

  // Additional Profile Details
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

  // Persistent Image Paths & Card Field Toggles
  final String? logoImagePath;
  final String? signatureImagePath;
  final bool showGstOnCard;
  final bool showBusinessTypeOnCard;
  final bool showCategoryOnCard;

  const AuthState({
    this.isLoggedIn = false,
    this.phoneNumber = '+91 81308 20030',
    this.userName = '',
    this.businessName = '',
    this.email = '',
    this.resendCountdown = 28,
    this.isTimerRunning = false,
    this.selectedCompany,
    this.createdBusinesses = const [],
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
    this.booksStartDate = '28/07/2026',
    this.hasLogo = false,
    this.hasSignature = false,
    this.logoImagePath,
    this.signatureImagePath,
    this.showGstOnCard = false,
    this.showBusinessTypeOnCard = false,
    this.showCategoryOnCard = false,
  });

  // Calculate Profile Completion Percentage
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
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  Timer? _timer;
  LocalStorageService? _storage;

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
  }

  Future<void> setPhoneNumber(String phone) async {
    state = state.copyWith(phoneNumber: phone);
    await _storage?.setPhoneNumber(phone);
  }

  Future<void> completeLogin() async {
    state = state.copyWith(isLoggedIn: true);
    await _storage?.setLoggedIn(true);
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

  Future<void> selectCompany(String companyName) async {
    await _storage?.setBusinessName(companyName);
    state = state.copyWith(
      selectedCompany: companyName,
      businessName: companyName,
      isLoggedIn: true,
    );
    await _storage?.setLoggedIn(true);
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
