import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyUserName = 'user_name';
  static const String _keyBusinessName = 'business_name';
  static const String _keyEmail = 'email';
  static const String _keyBusinessesList = 'businesses_list';

  // Profile keys
  static const String _keyOwnerName = 'owner_name';
  static const String _keyGstNumber = 'gst_number';
  static const String _keyBusinessType = 'business_type';
  static const String _keyBusinessCategory = 'business_category';
  static const String _keyPhone2 = 'phone_2';
  static const String _keyWebsite = 'website';
  static const String _keyAddress = 'address';
  static const String _keyCity = 'city';
  static const String _keyState = 'state';
  static const String _keyPincode = 'pincode';
  static const String _keyCountry = 'country';
  static const String _keyDescription = 'description';
  static const String _keyBooksStartDate = 'books_start_date';
  static const String _keyHasLogo = 'has_logo';
  static const String _keyHasSignature = 'has_signature';

  // Image Paths & Toggles Persistence
  static const String _keyLogoImagePath = 'logo_image_path';
  static const String _keySignatureImagePath = 'signature_image_path';
  static const String _keyShowGstOnCard = 'show_gst_on_card';
  static const String _keyShowBusinessTypeOnCard = 'show_business_type_on_card';
  static const String _keyShowCategoryOnCard = 'show_category_on_card';

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(_keyIsLoggedIn, value);
  }

  String get phoneNumber =>
      _prefs?.getString(_keyPhoneNumber) ?? '+91 81308 20030';
  Future<void> setPhoneNumber(String value) async {
    await _prefs?.setString(_keyPhoneNumber, value);
  }

  String get userName => _prefs?.getString(_keyUserName) ?? '';
  Future<void> setUserName(String value) async {
    await _prefs?.setString(_keyUserName, value);
  }

  String get businessName => _prefs?.getString(_keyBusinessName) ?? '';
  Future<void> setBusinessName(String value) async {
    await _prefs?.setString(_keyBusinessName, value);
    if (value.isNotEmpty) {
      await addBusiness(value);
    }
  }

  String get email => _prefs?.getString(_keyEmail) ?? '';
  Future<void> setEmail(String value) async {
    await _prefs?.setString(_keyEmail, value);
  }

  List<String> get businessesList =>
      _prefs?.getStringList(_keyBusinessesList) ?? [];

  Future<void> addBusiness(String name) async {
    if (name.isEmpty) return;
    final current = businessesList;
    if (!current.contains(name)) {
      current.add(name);
      await _prefs?.setStringList(_keyBusinessesList, current);
    }
  }

  // Business Profile Properties
  String get ownerName => _prefs?.getString(_keyOwnerName) ?? '';
  Future<void> setOwnerName(String v) => _prefs?.setString(_keyOwnerName, v) ?? Future.value();

  String get gstNumber => _prefs?.getString(_keyGstNumber) ?? '';
  Future<void> setGstNumber(String v) => _prefs?.setString(_keyGstNumber, v) ?? Future.value();

  String get businessType => _prefs?.getString(_keyBusinessType) ?? 'Retail Business';
  Future<void> setBusinessType(String v) => _prefs?.setString(_keyBusinessType, v) ?? Future.value();

  String get businessCategory => _prefs?.getString(_keyBusinessCategory) ?? 'Kirana/ General Merchant';
  Future<void> setBusinessCategory(String v) => _prefs?.setString(_keyBusinessCategory, v) ?? Future.value();

  String get phone2 => _prefs?.getString(_keyPhone2) ?? '';
  Future<void> setPhone2(String v) => _prefs?.setString(_keyPhone2, v) ?? Future.value();

  String get website => _prefs?.getString(_keyWebsite) ?? '';
  Future<void> setWebsite(String v) => _prefs?.setString(_keyWebsite, v) ?? Future.value();

  String get address => _prefs?.getString(_keyAddress) ?? '';
  Future<void> setAddress(String v) => _prefs?.setString(_keyAddress, v) ?? Future.value();

  String get city => _prefs?.getString(_keyCity) ?? '';
  Future<void> setCity(String v) => _prefs?.setString(_keyCity, v) ?? Future.value();

  String get state => _prefs?.getString(_keyState) ?? 'Delhi';
  Future<void> setState(String v) => _prefs?.setString(_keyState, v) ?? Future.value();

  String get pincode => _prefs?.getString(_keyPincode) ?? '';
  Future<void> setPincode(String v) => _prefs?.setString(_keyPincode, v) ?? Future.value();

  String get country => _prefs?.getString(_keyCountry) ?? 'India';
  Future<void> setCountry(String v) => _prefs?.setString(_keyCountry, v) ?? Future.value();

  String get description => _prefs?.getString(_keyDescription) ?? '';
  Future<void> setDescription(String v) => _prefs?.setString(_keyDescription, v) ?? Future.value();

  String get booksStartDate => _prefs?.getString(_keyBooksStartDate) ?? '28/07/2026';
  Future<void> setBooksStartDate(String v) => _prefs?.setString(_keyBooksStartDate, v) ?? Future.value();

  bool get hasLogo => _prefs?.getBool(_keyHasLogo) ?? false;
  Future<void> setHasLogo(bool v) => _prefs?.setBool(_keyHasLogo, v) ?? Future.value();

  bool get hasSignature => _prefs?.getBool(_keyHasSignature) ?? false;
  Future<void> setHasSignature(bool v) => _prefs?.setBool(_keyHasSignature, v) ?? Future.value();

  // Logo & Signature Paths & Card Toggles Persistence
  String? get logoImagePath => _prefs?.getString(_keyLogoImagePath);
  Future<void> setLogoImagePath(String? v) => v != null ? _prefs?.setString(_keyLogoImagePath, v) ?? Future.value() : _prefs?.remove(_keyLogoImagePath) ?? Future.value();

  String? get signatureImagePath => _prefs?.getString(_keySignatureImagePath);
  Future<void> setSignatureImagePath(String? v) => v != null ? _prefs?.setString(_keySignatureImagePath, v) ?? Future.value() : _prefs?.remove(_keySignatureImagePath) ?? Future.value();

  bool get showGstOnCard => _prefs?.getBool(_keyShowGstOnCard) ?? false;
  Future<void> setShowGstOnCard(bool v) => _prefs?.setBool(_keyShowGstOnCard, v) ?? Future.value();

  bool get showBusinessTypeOnCard => _prefs?.getBool(_keyShowBusinessTypeOnCard) ?? false;
  Future<void> setShowBusinessTypeOnCard(bool v) => _prefs?.setBool(_keyShowBusinessTypeOnCard, v) ?? Future.value();

  bool get showCategoryOnCard => _prefs?.getBool(_keyShowCategoryOnCard) ?? false;
  Future<void> setShowCategoryOnCard(bool v) => _prefs?.setBool(_keyShowCategoryOnCard, v) ?? Future.value();

  Future<void> clearSession() async {
    await _prefs?.clear();
  }
}
