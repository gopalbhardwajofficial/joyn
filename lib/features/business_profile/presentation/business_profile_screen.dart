import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team_management/data/role_repository.dart';
import '../../team_management/data/team_member_repository.dart';
import 'package:joyn/features/team_management/models/team_member_model.dart';
import 'widgets/add_team_member_dialog.dart';
import 'widgets/image_crop_dialog.dart';
import 'widgets/signature_drawing_dialog.dart';


class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      JoynColors.background,
    ],
  );
}

class _CardTheme {
  final Decoration decoration;
  final Color textColor;
  final Color iconColor;
  final bool isDark;

  const _CardTheme({
    required this.decoration,
    required this.textColor,
    required this.iconColor,
    this.isDark = false,
  });
}

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  int _selectedTab = 0;
  int _selectedCardThemeIndex = 0;

  final PageController _cardPageController =
  PageController(viewportFraction: 0.92);

  final GlobalKey _cardRepaintKey = GlobalKey();
  final RoleRepository _roleRepository = RoleRepository();
  final TeamMemberRepository _teamMemberRepository = TeamMemberRepository();

  String? _logoImagePath;
  String? _signatureImagePath;

  bool _showGstOnCard = false;
  bool _showBusinessTypeOnCard = false;
  bool _showCategoryOnCard = false;

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

  // Phase 8: Branding, Bank Details & Invoice Customization
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _branchNameController;
  late TextEditingController _upiIdController;
  late TextEditingController _invoiceTermsController;

  String _selectedInvoiceTheme = 'classic_blue';
  String _selectedInvoiceColor = '#4338CA';
  bool _showUpiQr = true;

  String _selectedBusinessType = 'Retail Business';
  String _selectedCategory = 'Kirana/ General Merchant';
  String _selectedState = 'Delhi';
  String _selectedCountry = 'India';
  String _booksStartDate = '28/07/2026';

  final List<TeamMemberModel> _teamMembers = [];
  final List<RoleModel> _roles = List.of(kDefaultRoles);

  final List<String> _businessTypes = [
    'Retail Business',
    'Wholesale Business',
    'Service',
    'Manufacturing',
    'Distributor',
    'Other',
  ];

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

  List<_CardTheme> get _cardThemes => [

    _CardTheme(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: const Color(0xFF0F172A),
      iconColor: const Color(0xFF0284C7),
    ),


    _CardTheme(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFBAE6FD),
            Color(0xFFFED7AA),
            Color(0xFFFECDD3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: const Color(0xFF1E293B),
      iconColor: const Color(0xFF0284C7),
    ),


    _CardTheme(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: Colors.white,
      iconColor: const Color(0xFF38BDF8),
      isDark: true,
    ),

    _CardTheme(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF065F46),
            Color(0xFF022C22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: Colors.white,
      iconColor: const Color(0xFF6EE7B7),
      isDark: true,
    ),

    _CardTheme(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF4D9C6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: const Color(0xFF7C2D12),
      iconColor: const Color(0xFFB45309),
    ),

    _CardTheme(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF97316),
            Color(0xFFDB2777),
            Color(0xFF7E22CE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textColor: Colors.white,
      iconColor: Colors.white,
      isDark: true,
    ),
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

    _selectedBusinessType =
    state.businessType.isNotEmpty ? state.businessType : 'Retail Business';

    _selectedCategory = _categories.contains(state.businessCategory)
        ? state.businessCategory
        : 'Kirana/ General Merchant';

    _selectedState =
    _indianStatesAndUTs.contains(state.state) ? state.state : 'Delhi';

    _selectedCountry = state.country.isNotEmpty ? state.country : 'India';

    _booksStartDate =
    state.booksStartDate.isNotEmpty ? state.booksStartDate : '28/07/2026';

    _logoImagePath = state.logoImagePath;
    _signatureImagePath = state.signatureImagePath;

    _showGstOnCard = state.showGstOnCard;
    _showBusinessTypeOnCard = state.showBusinessTypeOnCard;
    _showCategoryOnCard = state.showCategoryOnCard;

    // Phase 8: Branding & Banking Init
    _bankNameController = TextEditingController(text: state.bankName);
    _accountNumberController = TextEditingController(text: state.accountNumber);
    _ifscCodeController = TextEditingController(text: state.ifscCode);
    _branchNameController = TextEditingController(text: state.branchName);
    _upiIdController = TextEditingController(text: state.upiId);
    _invoiceTermsController = TextEditingController(
      text: state.invoiceTerms.isNotEmpty
          ? state.invoiceTerms
          : '1. Goods once sold will not be taken back or exchanged.\n2. Payment due within 15 days of invoice date.\n3. Subject to local jurisdiction.',
    );
    _selectedInvoiceTheme = state.invoiceTheme.isNotEmpty ? state.invoiceTheme : 'classic_blue';
    _selectedInvoiceColor = state.invoiceColorHex.isNotEmpty ? state.invoiceColorHex : '#4338CA';
    _showUpiQr = state.showUpiQr;

    _loadTeamData();
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
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _branchNameController.dispose();
    _upiIdController.dispose();
    _invoiceTermsController.dispose();
    super.dispose();
  }



  Future<void> _loadTeamData() async {
    try {

      final loadedRoles = await _roleRepository.getRoles();
      final loadedMembers = await _teamMemberRepository.getTeamMembers();

      if (!mounted) return;

      setState(() {
        if (loadedRoles.isNotEmpty) {
          _roles
            ..clear()
            ..addAll(loadedRoles);
        }
        if (loadedMembers.isNotEmpty) {
          _teamMembers
            ..clear()
            ..addAll(loadedMembers);
        }
      });
    } catch (e) {
      debugPrint('Error loading team data: $e');
    }
  }

  Future<void> _persistRoles() async {
    try {
      await _roleRepository.deleteAllRoles();
      for (var role in _roles) {
        await _roleRepository.insertRole(role);
      }
    } catch (e) {
      debugPrint('Error persisting roles: $e');
    }
  }

  Future<void> _showLogoPicker() async {
    if (!mounted) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Business Logo',
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose where you want to get your logo from',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: JoynColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _buildLogoSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        color: const Color(0xFF0284C7),
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildLogoSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Choose photo',
                        color: const Color(0xFFC0202B),
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null && mounted) {
      await _pickLogo(source);
    }
  }

  Widget _buildLogoSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                color: JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image == null || !mounted) return;

      final String? croppedPath = await showDialog<String>(
        context: context,
        builder: (context) => ImageCropDialog(
          imagePath: image.path,
          title: 'Crop & Adjust Logo',
        ),
      );

      if (croppedPath != null && mounted) {
        setState(() => _logoImagePath = croppedPath);
        ref.read(authProvider.notifier).toggleLogo(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Unable to open camera.'
                : 'Unable to open gallery.',
          ),
          backgroundColor: JoynColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadSignatureFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null && mounted) {
        final croppedPath = await showDialog<String>(
          context: context,
          builder: (context) => ImageCropDialog(
            imagePath: image.path,
            title: 'Crop & Adjust Signature',
          ),
        );

        if (croppedPath != null) {
          setState(() => _signatureImagePath = croppedPath);
          ref.read(authProvider.notifier).toggleSignature(true);
        }
      }
    } catch (_) {}
  }

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
          text:
          'Here is my Digital Business Card for ${_businessNameController.text}!',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openSignatureDrawingDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDrawingDialog(),
    );

    if (result != null) {
      if (result is String) {
        setState(() => _signatureImagePath = result);
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
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscCodeController.text.trim(),
      branchName: _branchNameController.text.trim(),
      upiId: _upiIdController.text.trim(),
      invoiceTheme: _selectedInvoiceTheme,
      invoiceColorHex: _selectedInvoiceColor,
      invoiceTerms: _invoiceTermsController.text.trim(),
      showUpiQr: _showUpiQr,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Business Profile saved successfully!'),
        backgroundColor: JoynColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.pop();
  }


  Future<void> _addOrEditTeamMember({TeamMemberModel? existing}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AddTeamMemberDialog(roles: _roles, existingMember: existing),
    );

    if (result != null) {
      final member = result['member'] as TeamMemberModel;
      final updatedRoles = result['roles'] as List<RoleModel>;

      setState(() {
        _roles
          ..clear()
          ..addAll(updatedRoles);

        if (existing != null) {
          final index = _teamMembers.indexWhere((m) => m.id == existing.id);
          if (index != -1) {
            _teamMembers[index] = member;
          }
        } else {
          _teamMembers.add(member);
        }
      });

      await _persistRoles();
      if (existing != null) {
        await _teamMemberRepository.updateTeamMember(member);
      } else {
        await _teamMemberRepository.insertTeamMember(member);
      }

      if (existing != null && mounted) {
        context.push('/team-member-activity-log', extra: member);
      }
    }
  }

  void _toggleMemberActive(TeamMemberModel member) {
    final newStatus = !member.isActive;
    setState(() {
      final index = _teamMembers.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _teamMembers[index] = member.copyWith(isActive: newStatus);
      }
    });
    _teamMemberRepository.toggleMemberActive(member.id, newStatus);
  }

  void _deleteMember(String id) {
    setState(() {
      _teamMembers.removeWhere((m) => m.id == id);
    });
    _teamMemberRepository.deleteTeamMember(id);
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Business Profile',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _Premium.gradient(JoynColors.primary),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _Premium.chipShadow(JoynColors.primary),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _saveProfile();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      child: Text(
                        'Save',
                        style: JoynTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _buildTabsHeader(),
            const SizedBox(height: 22),

            if (_selectedTab == 0) ...[

              _buildSectionHeader(1, 'Digital Business Card', Icons.badge_outlined),
              const SizedBox(height: 16),
              _build3CardCarouselSection(authState),
              const SizedBox(height: 16),
              _buildShareCardButton(),
              const SizedBox(height: 14),
              _buildProfileCompletionCard(authState),

              const SizedBox(height: 30),

              _buildSectionHeader(2, 'Business Identity', Icons.storefront_outlined),
              const SizedBox(height: 16),
              _buildBusinessIdentityCard(),

              const SizedBox(height: 30),

              _buildSectionHeader(3, 'Contact', Icons.contact_phone_outlined),
              const SizedBox(height: 16),
              _buildContactCard(),

              const SizedBox(height: 30),

              _buildSectionHeader(4, 'Address', Icons.location_city_outlined),
              const SizedBox(height: 16),
              _buildAddressCard(),

              const SizedBox(height: 30),

              _buildSectionHeader(5, 'Business Details', Icons.description_outlined),
              const SizedBox(height: 16),
              _buildBusinessDetailsCard(),

              const SizedBox(height: 30),

              _buildSectionHeader(6, 'Signature', Icons.draw_outlined),
              const SizedBox(height: 16),
              _buildSignatureCard(authState),

              const SizedBox(height: 28),

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
            ] else if (_selectedTab == 1) ...[
              _buildSectionHeader(1, 'Team Members', Icons.groups_outlined),
              const SizedBox(height: 16),
              _buildTeamMembersSection(),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(int number, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _Premium.gradient(Colors.black87),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: JoynTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 17, color: JoynColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
                color: JoynColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JoynColors.border,
                JoynColors.border.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildShareCardButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: _Premium.gradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _Premium.floatingShadow(JoynColors.primary),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.lightImpact();
              _shareCardAsImage();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ios_share_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Share Card',
                    style: JoynTypography.buttonText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3CardCarouselSection(AuthState authState) {
    final themeCount = _cardThemes.length;

    return Column(
      children: [
        SizedBox(
          height: 225,
          child: PageView.builder(
            controller: _cardPageController,
            itemCount: themeCount,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCardThemeIndex = index);
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(themeCount, (index) {
            final isSelected = index == _selectedCardThemeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: isSelected ? _Premium.gradient(JoynColors.primary) : null,
                color: isSelected ? null : JoynColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

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

    final theme = _cardThemes[themeIndex % _cardThemes.length];
    final Decoration cardDecoration = theme.decoration;
    final Color textColor = theme.textColor;
    final Color iconColor = theme.iconColor;

    final Color logoChipBackground =
    theme.isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.92);
    final Color logoChipTextColor = theme.isDark ? Colors.white : const Color(0xFF0284C7);

    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _showLogoPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: logoChipBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _logoImagePath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_logoImagePath!), fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: logoChipTextColor),
                      Text(
                        'Logo',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: logoChipTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCardInfoRow(Icons.phone_outlined, displayPhone, iconColor, textColor),
          const SizedBox(height: 4),
          _buildCardInfoRow(Icons.email_outlined, displayEmail, iconColor, textColor),
          const SizedBox(height: 4),
          _buildCardInfoRow(Icons.location_on_outlined, displayAddress, iconColor, textColor),
          if (_showGstOnCard && _gstController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCardInfoRow(
              Icons.receipt_long_outlined,
              'GSTIN: ${_gstController.text}',
              iconColor,
              textColor,
            ),
          ],
          if (_showBusinessTypeOnCard &&
              !_selectedBusinessType.toLowerCase().contains('other')) ...[
            const SizedBox(height: 4),
            _buildCardInfoRow(
              Icons.business_center_outlined,
              _selectedBusinessType,
              iconColor,
              textColor,
            ),
          ],
          if (_showCategoryOnCard &&
              !_selectedCategory.toLowerCase().contains('other')) ...[
            const SizedBox(height: 4),
            _buildCardInfoRow(
              Icons.category_outlined,
              _selectedCategory,
              iconColor,
              textColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String text, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: JoynTypography.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionCard(AuthState authState) {
    final int completion = authState.profileCompletionPercentage;

    return Container(
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: completion / 100.0,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(JoynColors.primary),
                  ),
                ),
                Text(
                  '$completion%',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: JoynColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Completion',
                  style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  completion >= 100
                      ? 'Your profile is fully set up.'
                      : 'Fill remaining details to complete your profile.',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 12,
                    color: JoynColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsHeader() {
    final canManageTeam = ref.watch(authProvider).isOwner || ref.watch(authProvider).permissions.accessAdmin;
    if (!canManageTeam) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Details', 0)),
          Expanded(child: _buildTabButton('Team', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? _Premium.gradient(JoynColors.primary) : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected ? _Premium.chipShadow(JoynColors.primary) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: JoynTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: isSelected ? Colors.white : JoynColors.secondaryText,
          ),
        ),
      ),
    );
  }


  Widget _buildBusinessIdentityCard() {
    return _buildFormCard(
      children: [
        _buildFormField(
          label: 'Business Name *',
          hintText: 'Enter business name',
          controller: _businessNameController,
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'Owner Name',
          hintText: 'Enter owner name',
          controller: _ownerNameController,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'GST Number',
          hintText: 'Enter GSTIN number',
          controller: _gstController,
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 8),
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
          icon: Icons.business_center_outlined,
          onChanged: (val) {
            if (val != null) setState(() => _selectedBusinessType = val);
          },
        ),
        const SizedBox(height: 8),
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
          icon: Icons.category_outlined,
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
        const SizedBox(height: 8),
        _buildShowOnCardToggle(
          title: 'Show Category on Card',
          value: _showCategoryOnCard,
          onChanged: (val) => setState(() => _showCategoryOnCard = val),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildFormCard(
      children: [
        _buildFormField(
          label: 'Phone Number 1 *',
          hintText: 'Enter phone number',
          controller: _phone1Controller,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'Phone Number 2',
          hintText: 'Enter secondary number',
          controller: _phone2Controller,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'Email ID',
          hintText: 'Enter email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'Website',
          hintText: 'https://',
          controller: _websiteController,
          keyboardType: TextInputType.url,
          icon: Icons.language_rounded,
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return _buildFormCard(
      children: [
        _buildFormField(
          label: 'Business Address',
          hintText: 'Enter shop / office address',
          controller: _addressController,
          maxLines: 2,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'City',
          hintText: 'Enter city',
          controller: _cityController,
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'State',
          value: _selectedState,
          items: _indianStatesAndUTs,
          icon: Icons.map_outlined,
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
          icon: Icons.pin_drop_outlined,
        ),
        const SizedBox(height: 14),
        _buildFormField(
          label: 'Country',
          hintText: 'India',
          controller: TextEditingController(text: _selectedCountry),
          readOnly: true,
          icon: Icons.public_rounded,
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsCard() {
    return _buildFormCard(
      children: [
        _buildFormField(
          label: 'Business Description',
          hintText: 'Brief description of your business',
          controller: _descriptionController,
          maxLines: 3,
          icon: Icons.notes_rounded,
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Books Beginning Date',
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
                    '${picked.day.toString().padLeft(2, '0')}/'
                        '${picked.month.toString().padLeft(2, '0')}/'
                        '${picked.year}';
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JoynColors.border, width: 1.2),
                  boxShadow: _Premium.fieldShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: JoynColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: JoynColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _booksStartDate,
                        style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureCard(AuthState authState) {
    return _buildFormCard(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Center(
            child: _signatureImagePath != null
                ? Image.file(File(_signatureImagePath!), fit: BoxFit.contain)
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
                  fontSize: 11.5,
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
                  fontSize: 11.5,
                ),
                onPressed: _uploadSignatureFromGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTeamMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: _Premium.gradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _Premium.chipShadow(JoynColors.primary),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.lightImpact();
                _addOrEditTeamMember();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      'Add Team Member',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_teamMembers.isEmpty)
          _buildEmptyTeamState()
        else
          ..._teamMembers.map(_buildTeamMemberTile),
      ],
    );
  }

  Widget _buildEmptyTeamState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: JoynColors.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.groups_outlined, size: 32, color: JoynColors.secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            'No Team Members Yet',
            style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Add staff and assign roles to manage access.',
            style: JoynTypography.subtitle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberTile(TeamMemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.fieldShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/team-member-detail', extra: member),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JoynColors.primary.withValues(alpha: 0.08),
                            JoynColors.primary.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                      child: ClipOval(child: _buildTileAvatarContent(member)),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: member.isActive ? JoynColors.success : JoynColors.secondaryText,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: JoynTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: JoynColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: JoynColors.chipBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                member.roleName,
                                style: JoynTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: JoynColors.primary,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.isActive ? 'Active' : 'Not Active',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: member.isActive ? JoynColors.success : JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _buildTileActionButton(
                  icon: member.isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                  color: member.isActive ? JoynColors.success : JoynColors.secondaryText,
                  onTap: () => _toggleMemberActive(member),
                ),
                const SizedBox(width: 6),
                _buildTileActionButton(
                  icon: Icons.edit_outlined,
                  color: JoynColors.secondaryText,
                  onTap: () => _addOrEditTeamMember(existing: member),
                ),
                const SizedBox(width: 6),
                _buildTileActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: JoynColors.error,
                  onTap: () => _deleteMember(member.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileAvatarContent(TeamMemberModel member) {
    final path = member.photoPath;

    if (path != null && path.startsWith(kAvatarPrefix)) {
      final index = int.tryParse(path.substring(kAvatarPrefix.length)) ?? 0;
      final preset = kPresetAvatars[index % kPresetAvatars.length];
      return buildPresetAvatarWidget(preset, iconSize: 20, emojiSize: 24);
    }

    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    return Center(
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: JoynTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          color: JoynColors.primary,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _buildTileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }


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
          onChanged: (val) {
            HapticFeedback.selectionClick();
            onChanged(val);
          },
          activeTrackColor: JoynColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }


  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: JoynColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  readOnly: readOnly,
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(
                      color: JoynColors.secondaryText.withValues(alpha: 0.5),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: JoynColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border, width: 1.2),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(value) ? value : items.first,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                    style: JoynTypography.bodyLarge.copyWith(fontSize: 15, color: JoynColors.primary, fontWeight: FontWeight.w600),
                    borderRadius: BorderRadius.circular(16),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      onChanged(val);
                    },
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(value: item, child: Text(item));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // PHASE 8: INVOICE BRANDING & THEMES SECTION WIDGETS
  // ============================================================================

  // ignore: unused_element
  Widget _buildInvoiceBrandingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(1, 'Invoice Theme & Color', Icons.palette_outlined),
        const SizedBox(height: 16),
        _buildInvoiceThemesCard(),

        const SizedBox(height: 30),

        _buildSectionHeader(2, 'Instant UPI Payment QR', Icons.qr_code_2_rounded),
        const SizedBox(height: 16),
        _buildUpiPaymentCard(),

        const SizedBox(height: 30),

        _buildSectionHeader(3, 'Bank Account Details', Icons.account_balance_outlined),
        const SizedBox(height: 16),
        _buildBankDetailsCard(),

        const SizedBox(height: 30),

        _buildSectionHeader(4, 'Terms & Conditions', Icons.gavel_outlined),
        const SizedBox(height: 16),
        _buildInvoiceTermsCard(),

        const SizedBox(height: 30),

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
                text: 'Save Branding',
                variant: JoynButtonVariant.filled,
                onPressed: _saveProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceThemesCard() {
    final themes = [
      {
        'id': 'classic_blue',
        'name': 'Classic Corporate',
        'desc': 'Standard GST tax invoice with full tax grids & clean totals.',
      },
      {
        'id': 'modern_minimal',
        'name': 'Modern Minimal',
        'desc': 'Clean typography, border accents, and compact metadata.',
      },
      {
        'id': 'emerald_elegance',
        'name': 'Emerald Elegance',
        'desc': 'Sophisticated green styling with prominent bank & payment cards.',
      },
      {
        'id': 'thermal_pos',
        'name': 'Thermal POS 80mm',
        'desc': 'Compact receipt slip for thermal roll counter printers.',
      },
    ];

    final colorPresets = [
      {'name': 'Indigo', 'hex': '#4338CA', 'color': const Color(0xFF4338CA)},
      {'name': 'Sky Blue', 'hex': '#0284C7', 'color': const Color(0xFF0284C7)},
      {'name': 'Emerald', 'hex': '#059669', 'color': const Color(0xFF059669)},
      {'name': 'Crimson', 'hex': '#E11D48', 'color': const Color(0xFFE11D48)},
      {'name': 'Amber', 'hex': '#D97706', 'color': const Color(0xFFD97706)},
      {'name': 'Slate', 'hex': '#1E293B', 'color': const Color(0xFF1E293B)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Invoice Template',
            style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 12),
          ...themes.map((t) {
            final isSelected = _selectedInvoiceTheme == t['id'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedInvoiceTheme = t['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? JoynColors.primary.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? JoynColors.primary : JoynColors.border,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? JoynColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? JoynColors.primary : JoynColors.secondaryText.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['name'] as String,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                              color: isSelected ? JoynColors.primary : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t['desc'] as String,
                            style: JoynTypography.caption.copyWith(
                              fontSize: 12,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Text(
            'Primary Brand Color',
            style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Used for invoice banners, headers, and total summary accents.',
            style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colorPresets.map((cp) {
              final isChosen = _selectedInvoiceColor.toUpperCase() == (cp['hex'] as String).toUpperCase();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedInvoiceColor = cp['hex'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cp['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isChosen
                        ? [
                            BoxShadow(
                              color: (cp['color'] as Color).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isChosen
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Dynamic UPI QR on Invoices',
                      style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Allows customers to scan & pay exact amount in 1 tap',
                      style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _showUpiQr,
                activeTrackColor: JoynColors.primary,
                onChanged: (val) {
                  setState(() => _showUpiQr = val);
                },
              ),
            ],
          ),
          if (_showUpiQr) ...[
            const SizedBox(height: 16),
            _buildFormField(
              label: 'Merchant UPI ID (VPA)',
              hintText: 'e.g. 8130820030@upi or store@hdfcbank',
              controller: _upiIdController,
              icon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'When customer scans with PhonePe, GPay, or Paytm, your store name and exact invoice amount will be filled automatically.',
                      style: JoynTypography.caption.copyWith(fontSize: 12, color: const Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Direct Bank Transfer Details',
            style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 3),
          Text(
            'Printed on invoice footer for NEFT, IMPS, and RTGS payments.',
            style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Bank Name',
            hintText: 'e.g. HDFC Bank, SBI, ICICI Bank',
            controller: _bankNameController,
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            label: 'Account Number',
            hintText: 'Enter bank account number',
            controller: _accountNumberController,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'IFSC Code',
                  hintText: 'e.g. HDFC0001234',
                  controller: _ifscCodeController,
                  icon: Icons.password_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Branch Name',
                  hintText: 'e.g. Noida Sec 62',
                  controller: _branchNameController,
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTermsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Default Invoice Terms & Conditions',
            hintText: 'Enter payment due terms, warranty notes, exchange policy...',
            controller: _invoiceTermsController,
            icon: Icons.gavel_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
