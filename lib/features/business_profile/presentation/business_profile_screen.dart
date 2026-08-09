import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/image_crop_dialog.dart';
import 'widgets/signature_drawing_dialog.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  int _selectedTab = 0; // 0: Business Details, 1: Team Members
  int _selectedCardThemeIndex = 0;
  final PageController _cardPageController = PageController(viewportFraction: 0.92);
  final GlobalKey _cardRepaintKey = GlobalKey();

  String? _logoImagePath;
  String? _signatureImagePath;

  // Field Toggles for Digital Visiting Card
  bool _showGstOnCard = false;
  bool _showBusinessTypeOnCard = false;
  bool _showCategoryOnCard = false;

  // Form Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _gstController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _descriptionController;

  String _selectedBusinessType = 'Retail Business';
  String _selectedCategory = 'Kirana/ General Merchant';
  String _selectedState = 'Delhi';
  String _selectedCountry = 'India';
  String _booksStartDate = '28/07/2026';

  final List<String> _businessTypes = [
    'Retail Business',
    'Wholesale Business',
    'Service',
    'Manufacturing',
    'Distributor',
    'Other',
  ];

  // Complete List of All 39 Specified Business Categories + Other
  final List<String> _categories = [
    'Accounting & CA',
    'Interior Designer',
    'Automobiles/ Auto parts',
    'Salon & Spa',
    'Liquor Store',
    'Book / Stationary store',
    'Construction Materials & Equipment',
    'Repairing/ Plumbing/ Electrician',
    'Chemicals & Fertilizers',
    'Computer Equipments & Softwares',
    'Electrical & Electronics Equipments',
    'Fashion Accessory/ Cosmetics',
    'Tailoring/ Boutique',
    'Fruit And Vegetable',
    'Kirana/ General Merchant',
    'FMCG Products',
    'Dairy Farm Products/ Poultry',
    'Furniture',
    'Garment/Fashion & Hosiery',
    'Jewellery & Gems',
    'Pharmacy/ Medical',
    'Hardware Store',
    'Industrial Machinery & Equipment',
    'Mobile & Accessories',
    'Nursery/ Plants',
    'Petroleum Bulk Stations & Terminals/ Petrol',
    'Restaurant/ Hotel',
    'Footwear',
    'Paper & Paper Products',
    'Sweet Shop/ Bakery',
    'Gifts & Toys',
    'Laundry/ Washing/ Dry clean',
    'Coaching & Training',
    'Renting & Leasing',
    'Fitness Center',
    'Oil & Gas',
    'Real Estate',
    'NGO & Charitable trust',
    'Tours & Travels',
    'Other',
  ];

  // Complete List of All 28 Indian States & 8 Union Territories
  final List<String> _indianStatesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttarakhand',
    'Uttar Pradesh',
    'West Bengal',
    'Delhi',
    'Jammu & Kashmir',
    'Ladakh',
    'Chandigarh',
    'Puducherry',
    'Andaman & Nicobar',
    'Dadra & Nagar Haveli',
    'Lakshadweep',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(authProvider);

    _businessNameController = TextEditingController(
      text: state.businessName.isNotEmpty
          ? state.businessName
          : (state.selectedCompany ?? ''),
    );
    _ownerNameController = TextEditingController(text: state.userName);
    _gstController = TextEditingController(text: state.gstNumber);
    _phone1Controller = TextEditingController(text: state.phoneNumber);
    _phone2Controller = TextEditingController(text: state.phone2);
    _emailController = TextEditingController(text: state.email);
    _websiteController = TextEditingController(text: state.website);
    _addressController = TextEditingController(text: state.address);
    _cityController = TextEditingController(text: state.city);
    _pincodeController = TextEditingController(text: state.pincode);
    _descriptionController = TextEditingController(text: state.description);

    _selectedBusinessType = state.businessType.isNotEmpty
        ? state.businessType
        : 'Retail Business';

    _selectedCategory = _categories.contains(state.businessCategory)
        ? state.businessCategory
        : 'Kirana/ General Merchant';

    _selectedState = _indianStatesAndUTs.contains(state.state)
        ? state.state
        : 'Delhi';
    _selectedCountry = state.country.isNotEmpty ? state.country : 'India';
    _booksStartDate = state.booksStartDate.isNotEmpty
        ? state.booksStartDate
        : '28/07/2026';

    _logoImagePath = state.logoImagePath;
    _signatureImagePath = state.signatureImagePath;
    _showGstOnCard = state.showGstOnCard;
    _showBusinessTypeOnCard = state.showBusinessTypeOnCard;
    _showCategoryOnCard = state.showCategoryOnCard;
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _gstController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick Logo Image from Device Gallery with Cropping Modal
  Future<void> _pickLogoFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final croppedPath = await showDialog<String>(
          context: context,
          builder: (context) => ImageCropDialog(
            imagePath: image.path,
            title: 'Crop & Adjust Logo',
          ),
        );

        if (croppedPath != null) {
          setState(() {
            _logoImagePath = croppedPath;
          });
          ref.read(authProvider.notifier).toggleLogo(true);
        }
      }
    } catch (_) {}
  }

  // Pick Signature Image from Gallery with Cropping Modal
  Future<void> _uploadSignatureFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final croppedPath = await showDialog<String>(
          context: context,
          builder: (context) => ImageCropDialog(
            imagePath: image.path,
            title: 'Crop & Adjust Signature',
          ),
        );

        if (croppedPath != null) {
          setState(() {
            _signatureImagePath = croppedPath;
          });
          ref.read(authProvider.notifier).toggleSignature(true);
        }
      }
    } catch (_) {}
  }

  // Capture Clean Active Visiting Card & Open Native Share Sheet (NO share button inside image!)
  Future<void> _shareCardAsImage() async {
    try {
      final boundary = _cardRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/business_card.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Here is my Digital Business Card for ${_businessNameController.text}!',
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Digital Business Card ready to share!'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Open Interactive Hand Signature Drawing Canvas Dialog
  void _openSignatureDrawingDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDrawingDialog(),
    );

    if (result != null) {
      if (result is String) {
        setState(() {
          _signatureImagePath = result;
        });
      }
      ref.read(authProvider.notifier).toggleSignature(true);
    }
  }

  Future<void> _saveProfile() async {
    await ref.read(authProvider.notifier).saveFullBusinessProfile(
          businessName: _businessNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          gstNumber: _gstController.text.trim(),
          businessType: _selectedBusinessType,
          businessCategory: _selectedCategory,
          phone1: _phone1Controller.text.trim(),
          phone2: _phone2Controller.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateName: _selectedState,
          pincode: _pincodeController.text.trim(),
          country: _selectedCountry,
          description: _descriptionController.text.trim(),
          booksStartDate: _booksStartDate,
          hasLogo: _logoImagePath != null || ref.read(authProvider).hasLogo,
          hasSignature:
              _signatureImagePath != null || ref.read(authProvider).hasSignature,
          logoImagePath: _logoImagePath,
          signatureImagePath: _signatureImagePath,
          showGstOnCard: _showGstOnCard,
          showBusinessTypeOnCard: _showBusinessTypeOnCard,
          showCategoryOnCard: _showCategoryOnCard,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Business Profile saved successfully!'),
          backgroundColor: JoynColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Business Profile',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: JoynColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                children: [
                  // 1. Swipable 3-Card Carousel (Clean digital visiting cards)
                  _build3CardCarouselSection(authState),

                  const SizedBox(height: 14),

                  // Share Button OUTSIDE card so image capture is 100% clean!
                  Center(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _shareCardAsImage,
                        icon: const Icon(Icons.share_rounded,
                            size: 16, color: Colors.white),
                        label: Text(
                          'Share Card',
                          style: JoynTypography.buttonText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // Red Share Button
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Info Banner Card (Light Blue Accent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildInfoBannerCard(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Profile Completion Card (Black Progress Bar in JOYN theme)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildProfileCompletionCard(authState),
                  ),

                  const SizedBox(height: 24),

                  // 4. Tabs Header (Business Details | Team Members Coming Soon)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTabsHeader(),
                  ),

                  const SizedBox(height: 24),

                  // 5. Tab Content Body
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _selectedTab == 0
                        ? _buildMergedFormSection(authState)
                        : _buildTeamMembersComingSoonView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Swipable 3-Card Carousel (Clean Digital Visiting Cards)
  Widget _build3CardCarouselSection(AuthState authState) {
    return Column(
      children: [
        SizedBox(
          height: 225, // Height adjusted to comfortably fit all 7 potential lines with zero overflow
          child: PageView.builder(
            controller: _cardPageController,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _selectedCardThemeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final isCurrent = index == _selectedCardThemeIndex;
              return RepaintBoundary(
                key: isCurrent ? _cardRepaintKey : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildIndividualVisitingCard(index, authState),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Page Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isSelected = index == _selectedCardThemeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? JoynColors.primary : JoynColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Helper widget to render clean Visiting Cards (NO overflow!)
  Widget _buildIndividualVisitingCard(int themeIndex, AuthState authState) {
    final displayName = _businessNameController.text.isNotEmpty
        ? _businessNameController.text
        : (authState.businessName.isNotEmpty
            ? authState.businessName
            : 'Gopal Bhardwaj');

    final displayPhone = _phone1Controller.text.isNotEmpty
        ? _phone1Controller.text
        : authState.phoneNumber;

    final displayEmail = _emailController.text.isNotEmpty
        ? _emailController.text
        : (authState.email.isNotEmpty
            ? authState.email
            : 'gbdevelopmentservices@gmail.com');

    final displayAddress = _addressController.text.isNotEmpty
        ? _addressController.text
        : 'Business Address';

    Decoration cardDecoration;
    Color textColor;
    Color iconColor;

    if (themeIndex == 0) {
      // Theme 0: Minimal White
      cardDecoration = BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
      textColor = const Color(0xFF0F172A);
      iconColor = const Color(0xFF0284C7);
    } else if (themeIndex == 1) {
      // Theme 1: Warm Pastel Sunset Gradient
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFBAE6FD),
            Color(0xFFFED7AA),
            Color(0xFFFECDD3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
      textColor = const Color(0xFF1E293B);
      iconColor = const Color(0xFF0284C7);
    } else {
      // Theme 2: Royal Indigo Pattern Accent
      cardDecoration = BoxDecoration(
        color: const Color(0xFF1E1B4B),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
      textColor = Colors.white;
      iconColor = const Color(0xFF38BDF8);
    }

    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header Row with Name & Logo Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // + Logo Button (Picker & Cropper from Gallery)
              InkWell(
                onTap: _pickLogoFromGallery,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF0284C7), width: 1.2),
                  ),
                  child: _logoImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_logoImagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 13, color: Color(0xFF0284C7)),
                            Text(
                              'Logo',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Phone Line
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Text(
                displayPhone,
                style: JoynTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Email Line
          Row(
            children: [
              Icon(Icons.email_outlined, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  displayEmail,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Address Line
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  displayAddress,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // GSTIN Line (Only if toggle ON & not empty)
          if (_showGstOnCard && _gstController.text.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 13, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  'GSTIN: ${_gstController.text}',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],

          // Business Type Line (Only if toggle ON & NOT "Other/Others")
          if (_showBusinessTypeOnCard &&
              !_selectedBusinessType.toLowerCase().contains('other')) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.business_center_outlined, size: 13, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  _selectedBusinessType,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],

          // Category Line (Only if toggle ON & NOT "Other/Others")
          if (_showCategoryOnCard &&
              !_selectedCategory.toLowerCase().contains('other')) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 13, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedCategory,
                    style: JoynTypography.bodyMedium.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. Info Banner Card (Light Blue Accent)
  Widget _buildInfoBannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '67% businessmen saw their business increase after sharing their visiting card',
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFF0369A1),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Profile Completion Card (Black Progress Bar - JOYN theme)
  Widget _buildProfileCompletionCard(AuthState authState) {
    final int completion = authState.profileCompletionPercentage;

    return Container(
      decoration: BoxDecoration(
        color: JoynColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile $completion% complete.',
            style: JoynTypography.bodyLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion / 100.0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(JoynColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Tabs Header (Black underline for selected tab)
  Widget _buildTabsHeader() {
    return Column(
      children: [
        Row(
          children: [
            // Tab 1: Business Details
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Business Details',
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 0
                              ? JoynColors.primary
                              : JoynColors.secondaryText,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      height: 2.5,
                      color: _selectedTab == 0
                          ? JoynColors.primary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),

            // Tab 2: Team Members (Disabled + Coming Soon)
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Team Members',
                            style: JoynTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _selectedTab == 1
                                  ? JoynColors.primary
                                  : JoynColors.secondaryText,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: JoynColors.chipBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: JoynTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: JoynColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 2.5,
                      color: _selectedTab == 1
                          ? JoynColors.primary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Divider(color: JoynColors.border, height: 1, thickness: 1),
      ],
    );
  }

  // 5. Merged Form Section
  Widget _buildMergedFormSection(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Business Identity
        _buildSectionHeader('Business Identity'),
        const SizedBox(height: 16),

        _buildFormField(
          label: 'Business Name *',
          hintText: 'Enter business name',
          controller: _businessNameController,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Owner Name',
          hintText: 'Enter owner name',
          controller: _ownerNameController,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'GST Number',
          hintText: 'Enter GSTIN number',
          controller: _gstController,
        ),
        const SizedBox(height: 6),

        // Toggle: Show GSTIN on Card
        _buildShowOnCardToggle(
          title: 'Show GSTIN on Card',
          value: _showGstOnCard,
          onChanged: (val) => setState(() => _showGstOnCard = val),
        ),

        const SizedBox(height: 14),

        _buildDropdownField(
          label: 'Business Type',
          value: _selectedBusinessType,
          items: _businessTypes,
          onChanged: (val) {
            if (val != null) setState(() => _selectedBusinessType = val);
          },
        ),
        const SizedBox(height: 6),

        // Toggle: Show Business Type on Card
        _buildShowOnCardToggle(
          title: 'Show Business Type on Card',
          value: _showBusinessTypeOnCard,
          onChanged: (val) => setState(() => _showBusinessTypeOnCard = val),
        ),

        const SizedBox(height: 14),

        _buildDropdownField(
          label: 'Business Category',
          value: _selectedCategory,
          items: _categories,
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
        const SizedBox(height: 6),

        // Toggle: Show Business Category on Card
        _buildShowOnCardToggle(
          title: 'Show Category on Card',
          value: _showCategoryOnCard,
          onChanged: (val) => setState(() => _showCategoryOnCard = val),
        ),

        const SizedBox(height: 28),

        // Section 2: Contact
        _buildSectionHeader('Contact'),
        const SizedBox(height: 16),

        _buildFormField(
          label: 'Phone Number 1 *',
          hintText: 'Enter phone number',
          controller: _phone1Controller,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Phone Number 2',
          hintText: 'Enter secondary number',
          controller: _phone2Controller,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Email ID',
          hintText: 'Enter email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Website',
          hintText: 'https://',
          controller: _websiteController,
          keyboardType: TextInputType.url,
        ),

        const SizedBox(height: 28),

        // Section 3: Address
        _buildSectionHeader('Address'),
        const SizedBox(height: 16),

        _buildFormField(
          label: 'Business Address',
          hintText: 'Enter shop / office address',
          controller: _addressController,
          maxLines: 2,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'City',
          hintText: 'Enter city',
          controller: _cityController,
        ),
        const SizedBox(height: 14),

        // Complete Indian States & UTs Dropdown List
        _buildDropdownField(
          label: 'State',
          value: _selectedState,
          items: _indianStatesAndUTs,
          onChanged: (val) {
            if (val != null) setState(() => _selectedState = val);
          },
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Pincode',
          hintText: 'Enter pincode',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),

        _buildFormField(
          label: 'Country',
          hintText: 'India',
          controller: TextEditingController(text: _selectedCountry),
          readOnly: true,
        ),

        const SizedBox(height: 28),

        // Section 4: Business Details
        _buildSectionHeader('Business'),
        const SizedBox(height: 16),

        _buildFormField(
          label: 'Business Description',
          hintText: 'Brief description of your business',
          controller: _descriptionController,
          maxLines: 3,
        ),
        const SizedBox(height: 14),

        // Books Beginning Date Picker Box
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Books Beginning Date',
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: JoynColors.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _booksStartDate =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: JoynColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JoynColors.border, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _booksStartDate,
                      style: JoynTypography.bodyLarge.copyWith(fontSize: 15),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: JoynColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Section 5: Signature
        _buildSectionHeader('Signature'),
        const SizedBox(height: 16),

        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: JoynColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: JoynColors.border, width: 1.2),
          ),
          child: Center(
            child: _signatureImagePath != null
                ? Image.file(
                    File(_signatureImagePath!),
                    fit: BoxFit.contain,
                  )
                : (authState.hasSignature
                    ? Text(
                        'Signature Saved',
                        style: JoynTypography.bodyLarge.copyWith(
                          color: JoynColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Text(
                        'No Signature Added',
                        style: JoynTypography.caption.copyWith(
                          color: JoynColors.secondaryText,
                          fontSize: 14,
                        ),
                      )),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: JoynButton(
                text: 'Create Signature',
                variant: JoynButtonVariant.outlined,
                leadingIcon: const Icon(Icons.edit_outlined, size: 16),
                height: 48,
                borderRadius: 14,
                textStyle: JoynTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                  fontSize: 13.5,
                ),
                onPressed: _openSignatureDrawingDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: JoynButton(
                text: 'Upload Signature',
                variant: JoynButtonVariant.outlined,
                leadingIcon: const Icon(Icons.upload_outlined, size: 16),
                height: 48,
                borderRadius: 14,
                textStyle: JoynTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                  fontSize: 13.5,
                ),
                onPressed: _uploadSignatureFromGallery,
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Bottom Action Buttons: Cancel (Outlined) & Save (Black Filled)
        Row(
          children: [
            Expanded(
              child: JoynButton(
                text: 'Cancel',
                variant: JoynButtonVariant.outlined,
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: JoynButton(
                text: 'Save',
                variant: JoynButtonVariant.filled,
                onPressed: _saveProfile,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Toggle switch helper for "Show on Card"
  Widget _buildShowOnCardToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: JoynTypography.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: JoynColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  // Section Header helper
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: JoynTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: JoynColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: JoynColors.border, thickness: 1),
      ],
    );
  }

  // Text Form Field Helper
  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: JoynColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            style: JoynTypography.bodyLarge.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: JoynTypography.bodyLarge.copyWith(
                color: JoynColors.secondaryText.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown Form Field Helper
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: JoynColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: JoynColors.primary,
                size: 20,
              ),
              style: JoynTypography.bodyLarge.copyWith(
                fontSize: 15,
                color: JoynColors.primary,
              ),
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Team Members Coming Soon View
  Widget _buildTeamMembersComingSoonView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: JoynColors.iconBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 32,
                color: JoynColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Team Members Coming Soon',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage staff roles and multi-user access for your store.',
              style: JoynTypography.subtitle.copyWith(
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
