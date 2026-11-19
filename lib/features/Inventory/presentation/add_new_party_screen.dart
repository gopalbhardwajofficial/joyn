import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../../core/widgets/joyn_button.dart';
import '../../../core/widgets/custom_crop_dialog.dart';
import '../../orders/models/sales_models.dart';
import '../../orders/data/sales_repository.dart';
import 'package:joyn/features/Inventory/widgets/avatar.dart';

enum PartySaveMode { mainParty, oneTimeCustomer }
enum PartyType { customer, supplier, both }
enum BalanceType { toReceive, toPay }
enum PriorityLevel { high, medium, low }

const List<String> _kGstTypes = [
  'Unregistered/Consumer',
  'Registered - Regular',
  'Registered - Composite',
  'Consumer',
  'Overseas',
  'Special Economic Zone (SEZ)',
  'Deemed Export',
  'Tax Deductor',
  'Tax Collector (E-Commerce)',
  'Input Service Distributor (ISD)',
  'SEZ Developer',
];

const List<String> _kIndianStates = [
  'Andaman & Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra & Nagar Haveli & Daman & Diu',
  'Daman & Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu & Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

/// ---------------------------------------------------------------------
/// THEME ENHANCEMENT LAYER
/// ---------------------------------------------------------------------
class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 24, offset: const Offset(0, 10)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 3, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> fieldShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> fieldShadowFocused(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 7)),
  ];

  static List<BoxShadow> softGlow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 8)),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.2) ?? color],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, JoynColors.background],
  );

  static Border hairline({double width = 1.1, double alpha = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: alpha), width: width);
}

const String kSavedPartiesPrefsKey = 'joyn_saved_parties';

class AddNewPartyScreen extends StatefulWidget {
  const AddNewPartyScreen({
    super.key,
    this.initialSaveMode = PartySaveMode.mainParty,
    this.existingParty,
  });

  final PartySaveMode initialSaveMode;
  final dynamic existingParty;

  @override
  State<AddNewPartyScreen> createState() => _AddNewPartyScreenState();
}

class _AddNewPartyScreenState extends State<AddNewPartyScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  final _partyNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _placeOfSupplyController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  late PartySaveMode _saveMode = widget.initialSaveMode;
  PartyType _partyType = PartyType.customer;
  PriorityLevel _priorityLevel = PriorityLevel.medium;
  BalanceType _balanceType = BalanceType.toReceive;

  DateTime _asOfDate = DateTime.now();
  int _selectedDetailTab = 0;

  File? _photoFile;
  int? _selectedAvatarIndex;

  final List<String> _categories = ['Retail', 'Wholesale', 'Distributor'];
  String? _selectedCategory;

  String _selectedGstType = _kGstTypes.first;
  String? _selectedState;

  bool get _isOneTimeCustomer => _saveMode == PartySaveMode.oneTimeCustomer;
  bool get _isEditMode => widget.existingParty != null;

  String? get _existingPartyId {
    final party = widget.existingParty;
    if (party == null) return null;
    if (party is PartyModel) return party.id;
    if (party is Map) return party['id']?.toString();
    try {
      return party.id?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _prefillFromExistingParty();
  }

  void _prefillFromExistingParty() {
    final party = widget.existingParty;
    if (party == null) return;
    try {
      final name = (party is Map) ? party['name'] : party.name;
      final category = (party is Map) ? party['category'] : party.category;
      final contact = (party is Map) ? party['contactNumber'] : party.contactNumber;
      final email = (party is Map) ? party['email'] : party.email;
      final address = (party is Map) ? party['address'] : party.address;

      if (name != null) _partyNameController.text = name.toString();
      if (category != null && category.toString().isNotEmpty) {
        _selectedCategory = category.toString();
        if (!_categories.contains(_selectedCategory)) _categories.add(_selectedCategory!);
      }
      if (contact != null) _contactNumberController.text = contact.toString();
      if (email != null) _emailController.text = email.toString();
      if (address != null) _billingAddressController.text = address.toString();

      if (party is PartyModel) {
        if (party.openingBalance != 0) {
          _openingBalanceController.text = party.openingBalance.toString();
        }
        _balanceType = party.balanceType == 'toPay' ? BalanceType.toPay : BalanceType.toReceive;
        if (party.creditLimit != null) {
          _creditLimitController.text = party.creditLimit!.toStringAsFixed(0);
        }

        _partyType = PartyType.values.firstWhere(
              (t) => t.name == party.partyType,
          orElse: () => PartyType.customer,
        );
        _priorityLevel = PriorityLevel.values.firstWhere(
              (p) => p.name == party.priorityLevel,
          orElse: () => PriorityLevel.medium,
        );
        if (party.photoPath.isNotEmpty && File(party.photoPath).existsSync()) {
          _photoFile = File(party.photoPath);
          _selectedAvatarIndex = null;
        } else if (party.avatarIndex != null) {
          _selectedAvatarIndex = party.avatarIndex;
          _photoFile = null;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _contactNumberController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    _billingAddressController.dispose();
    _emailController.dispose();
    _gstNumberController.dispose();
    _placeOfSupplyController.dispose();
    super.dispose();
  }

  // ---- Actions -------------------------------------------------------

  void _createCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Category', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter category name',
            filled: true,
            fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: JoynColors.secondaryText, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Add', style: TextStyle(color: JoynColors.primary, fontWeight: FontWeight.w800))),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _categories.add(result);
        _selectedCategory = result;
      });
    }
  }

  Future<void> _confirmDeleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category?'),
        content: Text('Remove "$category" from your category list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: JoynColors.secondaryText, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w800))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _categories.remove(category);
        if (_selectedCategory == category) _selectedCategory = null;
      });
    }
  }

  void _addPartyThroughContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contacts picker not wired up yet'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickAsOfDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: JoynColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _asOfDate = picked);
  }

  Future<void> _setCreditLimit() async {
    final controller = TextEditingController(text: _creditLimitController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Credit Limit', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter credit limit amount',
            filled: true,
            fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: JoynColors.secondaryText, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Save', style: TextStyle(color: JoynColors.primary, fontWeight: FontWeight.w800))),
        ],
      ),
    );

    if (result != null) setState(() => _creditLimitController.text = result);
  }

  Future<File?> _cropImage(String sourcePath) async {
    return showDialog<File>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CustomCropDialog(imageFile: File(sourcePath), title: 'Crop & Adjust Photo', aspectRatio: 1),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 90, maxWidth: 1600);
      if (image == null) return;
      final cropped = await _cropImage(image.path);
      if (cropped != null && mounted) {
        setState(() {
          _photoFile = cropped;
          _selectedAvatarIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open camera: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1600);
      if (image == null) return;
      final cropped = await _cropImage(image.path);
      if (cropped != null && mounted) {
        setState(() {
          _photoFile = cropped;
          _selectedAvatarIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open gallery: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4.5, margin: const EdgeInsets.only(top: 14, bottom: 14), decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3))),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add Photo', style: JoynTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              _buildPhotoSourceTile(Icons.photo_camera_rounded, 'Camera', () {
                Navigator.pop(context);
                _pickImageFromCamera();
              }),
              _buildPhotoSourceTile(Icons.photo_library_rounded, 'Gallery', () {
                Navigator.pop(context);
                _pickImageFromGallery();
              }),
              _buildPhotoSourceTile(Icons.face_retouching_natural_rounded, 'Avatar', () {
                Navigator.pop(context);
                _showAvatarPicker();
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSourceTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, size: 19, color: JoynColors.primary),
            ),
            const SizedBox(width: 14),
            Text(label, style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: JoynColors.secondaryText.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final avatar = _selectedAvatarIndex != null ? kPartyAvatarOptions[_selectedAvatarIndex!] : null;
    final hasContent = avatar != null || _photoFile != null;

    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasContent
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [JoynColors.primary, JoynColors.primary.withValues(alpha: 0.35)],
              )
                  : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  JoynColors.primary.withValues(alpha: 0.16),
                  JoynColors.primary.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: hasContent
                  ? _Premium.softGlow(JoynColors.primary)
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !hasContent ? Colors.white : null,
                gradient: avatar != null
                    ? LinearGradient(colors: avatar.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                image: _photoFile != null ? DecorationImage(image: FileImage(_photoFile!), fit: BoxFit.cover) : null,
                border: Border.all(color: Colors.white, width: 3),
              ),
              alignment: Alignment.center,
              child: (_photoFile == null && avatar == null)
                  ? Icon(Icons.add_a_photo_outlined, color: JoynColors.primary.withValues(alpha: 0.55), size: 28)
                  : (_photoFile == null ? Text(avatar!.emoji, style: const TextStyle(fontSize: 38)) : null),
            ),
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: _Premium.gradient(JoynColors.primary),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: _Premium.chipShadow(JoynColors.primary),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4.5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)))),
              Text('Choose an Avatar', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(kPartyAvatarOptions.length, (index) {
                  final option = kPartyAvatarOptions[index];
                  final selected = _selectedAvatarIndex == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedAvatarIndex = index;
                        _photoFile = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: option.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            border: selected ? Border.all(color: JoynColors.primary, width: 2.5) : Border.all(color: Colors.transparent, width: 2.5),
                            boxShadow: [BoxShadow(color: option.gradient.last.withValues(alpha: 0.32), blurRadius: 12, offset: const Offset(0, 5))],
                          ),
                          alignment: Alignment.center,
                          child: Text(option.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        if (selected)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: JoynColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGstTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4.5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)))),
              Text('GST Type', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _kGstTypes.length,
                  itemBuilder: (context, index) {
                    final type = _kGstTypes[index];
                    final selected = _selectedGstType == type;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGstType = type);
                        Navigator.pop(context);
                      },
                      title: Text(type, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? JoynColors.primary : Colors.black87)),
                      trailing: selected
                          ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: JoynColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _kIndianStates.where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4.5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(3)))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('State', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(backgroundColor: JoynColors.chipBackground, shape: const CircleBorder()),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setModalState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search state',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: JoynColors.chipBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final state = filtered[index];
                          final selected = _selectedState == state;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedState = state);
                              Navigator.pop(context);
                            },
                            title: Text(state, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? JoynColors.primary : Colors.black87)),
                            trailing: selected
                                ? Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: JoynColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- Party Type / Priority --------------------------

  String _partyTypeLabel(PartyType type) {
    switch (type) {
      case PartyType.customer:
        return 'Customer';
      case PartyType.supplier:
        return 'Supplier';
      case PartyType.both:
        return 'Both';
    }
  }

  String _priorityLabel(PriorityLevel level) {
    switch (level) {
      case PriorityLevel.high:
        return 'High Priority';
      case PriorityLevel.medium:
        return 'Medium Priority';
      case PriorityLevel.low:
        return 'Low Priority';
    }
  }

  Color _priorityColor(PriorityLevel level) {
    switch (level) {
      case PriorityLevel.high:
        return JoynColors.error;
      case PriorityLevel.medium:
        return const Color(0xFFF59E0B);
      case PriorityLevel.low:
        return JoynColors.success;
    }
  }

  Widget _buildPartyTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Party Type',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: _Premium.hairline(),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: JoynColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.groups_outlined,
                    size: 15, color: JoynColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PartyType>(
                    value: _partyType,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: JoynColors.primary, size: 20),
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    borderRadius: BorderRadius.circular(14),
                    // ← Prevents dropdown menu items from wrapping
                    itemHeight: null,
                    selectedItemBuilder: (context) => PartyType.values
                        .map((type) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _partyTypeLabel(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      HapticFeedback.selectionClick();
                      setState(() => _partyType = val);
                    },
                    items: PartyType.values
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        _partyTypeLabel(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority Level',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: _Premium.hairline(),
            boxShadow: _Premium.fieldShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _priorityColor(_priorityLevel).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.flag_rounded,
                    size: 15, color: _priorityColor(_priorityLevel)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PriorityLevel>(
                    value: _priorityLevel,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: JoynColors.primary, size: 20),
                    style: JoynTypography.bodyLarge.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    borderRadius: BorderRadius.circular(14),
                    itemHeight: null,
                    selectedItemBuilder: (context) => PriorityLevel.values
                        .map((level) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _priorityLabel(level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      HapticFeedback.selectionClick();
                      setState(() => _priorityLevel = val);
                    },
                    items: PriorityLevel.values
                        .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(
                        _priorityLabel(level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Persistence -----------------------------------------------------

  Future<void> _persistParty(Map<String, dynamic> partyData) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kSavedPartiesPrefsKey);

    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {}
    }

    list.add({
      'name': partyData['name'],
      'category': partyData['category'],
      'contactNumber': partyData['contactNumber'],
      'photoPath': partyData['photoPath'],
      'avatarIndex': partyData['avatarIndex'],
      'partyType': partyData['partyType'],
      'priorityLevel': partyData['priorityLevel'],
    });

    await prefs.setString(kSavedPartiesPrefsKey, jsonEncode(list));
  }

  Future<void> _saveToDatabase({bool andNew = false}) async {
    if (_partyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party Name is required')));
      return;
    }

    final partyData = {
      'name': _partyNameController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'saveMode': _saveMode == PartySaveMode.mainParty ? 'mainParty' : 'oneTimeCustomer',
      'type': _partyType.name,
      'partyType': _partyType.name,
      'priorityLevel': _priorityLevel.name,
      'category': _selectedCategory,
      'photoPath': _photoFile?.path,
      'avatarIndex': _selectedAvatarIndex,
      'openingBalance': _openingBalanceController.text.trim(),
      'asOfDate': _asOfDate.toIso8601String(),
      'balanceType': _balanceType.name,
      'creditLimit': _creditLimitController.text.trim(),
      'billingAddress': _billingAddressController.text.trim(),
      'state': _selectedState,
      'email': _emailController.text.trim(),
      'gstType': _selectedGstType,
      'gstNumber': _gstNumberController.text.trim(),
      'placeOfSupply': _placeOfSupplyController.text.trim(),
    };

    if (!_isOneTimeCustomer) {
      await _persistParty(partyData);

      final creditLimitValue = double.tryParse(_creditLimitController.text.trim());
      final openingBalanceValue = double.tryParse(_openingBalanceController.text.trim()) ?? 0;

      if (_isEditMode) {
        final existing = widget.existingParty;
        final createdAt = (existing is PartyModel) ? existing.createdAt : DateTime.now();

        final party = PartyModel(
          id: _existingPartyId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _partyNameController.text.trim(),
          category: _selectedCategory ?? '',
          contactNumber: _contactNumberController.text.trim(),
          email: _emailController.text.trim(),
          address: _billingAddressController.text.trim(),
          partyType: _partyType.name,
          priorityLevel: _priorityLevel.name,
          photoPath: _photoFile?.path ?? '',
          avatarIndex: _selectedAvatarIndex,
          createdAt: createdAt,
          openingBalance: openingBalanceValue,
          balanceType: _balanceType.name,
          creditLimit: creditLimitValue,
          partyNumber: (existing is PartyModel) ? existing.partyNumber : null,
          partyCode: (existing is PartyModel) ? existing.partyCode : null,
        );

        await _salesRepository.updateParty(party);
      } else {
        final party = PartyModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _partyNameController.text.trim(),
          category: _selectedCategory ?? '',
          contactNumber: _contactNumberController.text.trim(),
          email: _emailController.text.trim(),
          address: _billingAddressController.text.trim(),
          partyType: _partyType.name,
          priorityLevel: _priorityLevel.name,
          photoPath: _photoFile?.path ?? '',
          avatarIndex: _selectedAvatarIndex,
          createdAt: DateTime.now(),
          openingBalance: openingBalanceValue,
          balanceType: _balanceType.name,
          creditLimit: creditLimitValue,
        );

        await _salesRepository.insertParty(party);
      }
    }

    debugPrint(partyData.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? 'Party updated successfully!' : (_isOneTimeCustomer ? 'Customer added for this bill!' : 'Party saved successfully!')),
        backgroundColor: JoynColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (andNew) {
      setState(() {
        _partyNameController.clear();
        _contactNumberController.clear();
        _openingBalanceController.clear();
        _creditLimitController.clear();
        _billingAddressController.clear();
        _emailController.clear();
        _gstNumberController.clear();
        _placeOfSupplyController.clear();
        _photoFile = null;
        _selectedAvatarIndex = null;
        _selectedCategory = null;
        _partyType = PartyType.customer;
        _priorityLevel = PriorityLevel.medium;
        _balanceType = BalanceType.toReceive;
        _asOfDate = DateTime.now();
        _selectedGstType = _kGstTypes.first;
        _selectedState = null;
      });
      return;
    }

    context.pop(partyData);
  }

  // ---- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 18),
            ),
            onPressed: () => context.pop(), // ← FIXED: just go back
          ),
        ),
        centerTitle: false,
        title: Text(
          _isEditMode ? 'Edit Party' : 'Add New Party',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                children: [
                  _buildSectionHeader(1, 'Party Details', Icons.badge_outlined),
                  const SizedBox(height: 14),
                  _buildPartyDetailsCard(),
                  const SizedBox(height: 26),

                  if (!_isOneTimeCustomer) ...[
                    _buildSectionHeader(2, 'Balance Details', Icons.account_balance_wallet_outlined),
                    const SizedBox(height: 14),
                    _buildBalanceDetailsCard(),
                    const SizedBox(height: 26),
                  ],

                  if (!_isOneTimeCustomer) ...[
                    _buildSectionHeader(3, 'Category', Icons.sell_outlined),
                    const SizedBox(height: 14),
                    _buildCategoryCard(),
                    const SizedBox(height: 26),
                  ],

                  _buildSectionHeader(_isOneTimeCustomer ? 2 : 4, 'Address & GST', Icons.location_on_outlined),
                  const SizedBox(height: 14),
                  _buildDetailTabsCard(),
                  const SizedBox(height: 16),
                  _buildInfoBanner(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int number, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _Premium.gradient(JoynColors.primary),
            shape: BoxShape.circle,
            boxShadow: _Premium.chipShadow(JoynColors.primary),
          ),
          child: Text('$number', style: JoynTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: JoynColors.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16.5, letterSpacing: -0.2, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPartyDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: _Premium.hairline(),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Center(child: _buildPhotoPicker()),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPartyTypeDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityDropdown()),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: JoynColors.border.withValues(alpha: 0.7)),
          const SizedBox(height: 18),
          _buildFormField(label: 'Party Name *', hintText: 'Enter party name', controller: _partyNameController, icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _addPartyThroughContacts,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                      child: const Icon(Icons.contacts_rounded, size: 12, color: JoynColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text('Add party through contacts', style: JoynTypography.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFormField(label: 'Contact Number', hintText: 'Enter contact number', controller: _contactNumberController, keyboardType: TextInputType.phone, icon: Icons.call_outlined),
          const SizedBox(height: 16),
          _buildFormField(label: 'Email Address', hintText: 'Enter email address', controller: _emailController, keyboardType: TextInputType.emailAddress, icon: Icons.email_outlined),
        ],
      ),
    );
  }

  Widget _buildBalanceDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: _Premium.hairline(),
        boxShadow: _Premium.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFormField(label: 'Opening Balance', hintText: '0', controller: _openingBalanceController, keyboardType: TextInputType.number, icon: Icons.currency_rupee_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildAsOfDateField()),
            ],
          ),
          const SizedBox(height: 14),
          _buildBalanceTypeSelector(),
          const SizedBox(height: 16),
          _buildCreditLimitRow(),
        ],
      ),
    );
  }

  Widget _buildAsOfDateField() {
    final formattedDate =
        '${_asOfDate.day.toString().padLeft(2, '0')}/${_asOfDate.month.toString().padLeft(2, '0')}/${_asOfDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('As of Date',
            style: JoynTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickAsOfDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: _Premium.hairline(),
              boxShadow: _Premium.fieldShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.calendar_today_outlined,
                      size: 13, color: JoynColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formattedDate,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: JoynColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _buildBalancePill(label: 'To Receive', icon: Icons.call_received_rounded, color: JoynColors.success, selected: _balanceType == BalanceType.toReceive, onTap: () => setState(() => _balanceType = BalanceType.toReceive))),
          const SizedBox(width: 4),
          Expanded(child: _buildBalancePill(label: 'To Pay', icon: Icons.call_made_rounded, color: JoynColors.error, selected: _balanceType == BalanceType.toPay, onTap: () => setState(() => _balanceType = BalanceType.toPay))),
        ],
      ),
    );
  }

  Widget _buildBalancePill({required String label, required IconData icon, required Color color, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? color : JoynColors.secondaryText),
            const SizedBox(width: 6),
            Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? color : JoynColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditLimitRow() {
    final hasLimit = _creditLimitController.text.trim().isNotEmpty;
    return InkWell(
      onTap: _setCreditLimit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: hasLimit ? JoynColors.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasLimit ? JoynColors.primary.withValues(alpha: 0.4) : JoynColors.border, width: 1.2),
          boxShadow: _Premium.fieldShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(hasLimit ? Icons.verified_rounded : Icons.add_card_rounded, size: 16, color: JoynColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasLimit ? 'Credit Limit: ₹${_creditLimitController.text}' : 'Set Credit Limit',
                style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: JoynColors.primary),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: JoynColors.secondaryText.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: _Premium.surfaceGradient, borderRadius: BorderRadius.circular(20), border: _Premium.hairline(), boxShadow: _Premium.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._categories.map((category) {
                final selected = _selectedCategory == category;
                return GestureDetector(
                  onLongPress: () => _confirmDeleteCategory(category),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = category);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
                      color: selected ? null : JoynColors.chipBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selected ? _Premium.chipShadow(JoynColors.primary) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(category, style: JoynTypography.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : JoynColors.secondaryText)),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: _createCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: JoynColors.primary.withValues(alpha: 0.3), width: 1.2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: JoynColors.primary),
                      const SizedBox(width: 3),
                      Text('Add New', style: JoynTypography.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 12, color: JoynColors.secondaryText.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text('Long press a category to delete it', style: JoynTypography.caption.copyWith(fontSize: 11, color: JoynColors.secondaryText.withValues(alpha: 0.65))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTabsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: _Premium.surfaceGradient, borderRadius: BorderRadius.circular(20), border: _Premium.hairline(), boxShadow: _Premium.cardShadow),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [Expanded(child: _buildDetailTabButton('Addresses', 0)), Expanded(child: _buildDetailTabButton('GST Details', 1))]),
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: _selectedDetailTab == 0 ? _buildAddressesTab() : _buildGstDetailsTab()),
        ],
      ),
    );
  }

  Widget _buildDetailTabButton(String label, int index) {
    final selected = _selectedDetailTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDetailTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(gradient: selected ? _Premium.gradient(JoynColors.primary) : null, color: selected ? null : Colors.transparent, borderRadius: BorderRadius.circular(13), boxShadow: selected ? _Premium.chipShadow(JoynColors.primary) : null),
        alignment: Alignment.center,
        child: Text(label, style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? Colors.white : JoynColors.secondaryText)),
      ),
    );
  }

  Widget _buildAddressesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(label: 'Billing Address', hintText: 'Enter billing address', controller: _billingAddressController, maxLines: 2, icon: Icons.location_on_outlined),
        const SizedBox(height: 14),
        _buildDropdownField(label: 'State', value: _selectedState ?? 'Select State', icon: Icons.map_outlined, onTap: _showStatePicker, isPlaceholder: _selectedState == null),
      ],
    );
  }

  Widget _buildGstDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(label: 'GST Type', value: _selectedGstType, icon: Icons.rule_folder_outlined, onTap: _showGstTypePicker),
        const SizedBox(height: 14),
        _buildFormField(label: 'GSTIN', hintText: 'Enter GST number', controller: _gstNumberController, icon: Icons.receipt_long_outlined),
        const SizedBox(height: 14),
        _buildFormField(label: 'Place of Supply', hintText: 'Enter place of supply', controller: _placeOfSupplyController, icon: Icons.map_outlined),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JoynColors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.primary.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: const Icon(Icons.info_outline_rounded, size: 14, color: JoynColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Parties are people you do business with. Use them for invoices and to keep track of your payables & receivables.',
              style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -8))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_isEditMode) ...[
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _saveToDatabase(andNew: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: JoynColors.border.withValues(alpha: 0.9), width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Save & New', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 4,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _Premium.chipShadow(JoynColors.primary),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _saveToDatabase(),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _Premium.gradient(JoynColors.primary),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditMode ? Icons.check_circle_outline_rounded : Icons.save_outlined, size: 17, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Update Party' : (_isOneTimeCustomer ? 'Add Customer' : 'Save Party'),
                              style: JoynTypography.buttonText.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required String hintText, required TextEditingController controller, TextInputType keyboardType = TextInputType.text, int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: JoynColors.secondaryText, letterSpacing: 0.1)),
        const SizedBox(height: 6),
        Container(
          constraints: BoxConstraints(minHeight: maxLines > 1 ? 84 : 54),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: _Premium.hairline(), boxShadow: _Premium.fieldShadow),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, size: 15, color: JoynColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  cursorColor: JoynColors.primary,
                  style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 12 : 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value, required VoidCallback onTap, IconData? icon, bool isPlaceholder = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: JoynColors.secondaryText, letterSpacing: 0.1)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: _Premium.hairline(), boxShadow: _Premium.fieldShadow),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, size: 15, color: JoynColors.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontSize: 14.5,
                      fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.w700,
                      color: isPlaceholder ? JoynColors.secondaryText.withValues(alpha: 0.6) : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
              ],
            ),
          ),
        ),

      ],
    );
  }
}