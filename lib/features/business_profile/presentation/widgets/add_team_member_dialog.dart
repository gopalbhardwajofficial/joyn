import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../team_management/models/team_member_model.dart';
import 'create_role_dialog.dart';
import 'image_crop_dialog.dart';

// =====================================================================
// PREMIUM DESIGN SYSTEM — reused everywhere
// =====================================================================
class _P {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.020), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 8, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 40, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> hairlineShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 7)),
    BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 14)),
  ];

  static List<BoxShadow> softGlow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 4)),
    BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 26, offset: const Offset(0, 10)),
  ];

  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(color, Colors.white, 0.08) ?? color,
      color,
      Color.lerp(color, Colors.black, 0.22) ?? color,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static LinearGradient softGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.04)],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color.lerp(Colors.white, JoynColors.background, 0.6) ?? Colors.white],
  );

  static LinearGradient topHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
  );

  static LinearGradient shineSweep = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(0.5, 0.5),
    colors: [
      Colors.white.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: 0.32),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.35, 0.5, 0.65],
  );

  static Border hairline({double w = 1.0, double a = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: a), width: w);
}

class _PresetAvatar {
  final IconData? icon;
  final String? emoji;
  final Color color;
  final Color? gradientEnd;

  const _PresetAvatar.icon(this.icon, this.color)
      : emoji = null,
        gradientEnd = null;

  const _PresetAvatar.emoji(this.emoji, this.color, this.gradientEnd) : icon = null;
}

const List<_PresetAvatar> kPresetAvatars = [
  _PresetAvatar.emoji('👨‍💼', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('👩‍💼', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('🎌', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('💼', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('🦸', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('🧑‍💼', Color(0xFFFFD6E8), Color(0xFFF599C2)),
  _PresetAvatar.emoji('🐯', Color(0xFFFFCB8E), Color(0xFFF57C3C)),
  _PresetAvatar.emoji('🦉', Color(0xFFD9C2FF), Color(0xFF8E6FCE)),
  _PresetAvatar.emoji('🐰', Color(0xFFFFD6E8), Color(0xFFF599C2)),
];

const String kAvatarPrefix = 'avatar://';

Widget buildPresetAvatarWidget(dynamic preset, {required double iconSize, required double emojiSize}) {
  if (preset.emoji != null) {
    final Color start = preset.color as Color;
    final Color end = (preset.gradientEnd as Color?) ?? start;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(preset.emoji as String, style: TextStyle(fontSize: emojiSize)),
    );
  }

  final Color color = preset.color as Color;
  return Container(
    color: color.withValues(alpha: 0.14),
    alignment: Alignment.center,
    child: Icon(preset.icon as IconData, size: iconSize, color: color),
  );
}

// =====================================================================
// PRESSABLE (scale-on-tap)
// =====================================================================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.onLongPress,
  });
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// MAIN DIALOG
// =====================================================================
class AddTeamMemberDialog extends StatefulWidget {
  final List<RoleModel> roles;
  final TeamMemberModel? existingMember;

  const AddTeamMemberDialog({super.key, required this.roles, this.existingMember});

  @override
  State<AddTeamMemberDialog> createState() => _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends State<AddTeamMemberDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  late List<RoleModel> _roles;
  RoleModel? _selectedRole;

  String? _photoPath;

  bool get _isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();
    _roles = List.of(widget.roles);

    final member = widget.existingMember;
    if (member != null) {
      _nameController.text = member.name;
      _phoneController.text = member.phone;
      _emailController.text = member.email;
      _photoPath = member.photoPath;
      _selectedRole = _roles.where((r) => r.id == member.roleId).isNotEmpty
          ? _roles.firstWhere((r) => r.id == member.roleId)
          : (_roles.isNotEmpty ? _roles.first : null);
    } else if (_roles.isNotEmpty) {
      _selectedRole = _roles.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showAvatarPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AvatarPickerSheet(currentPath: _photoPath),
    );

    if (result == null) return;

    if (result == 'camera' || result == 'gallery') {
      await _pickPhoto(result == 'camera' ? ImageSource.camera : ImageSource.gallery);
    } else if (result == 'remove') {
      setState(() => _photoPath = null);
    } else {
      setState(() => _photoPath = result);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      final String? croppedPath = await showDialog<String>(
        context: context,
        builder: (context) => ImageCropDialog(
          imagePath: image.path,
          title: 'Crop & Adjust Photo',
        ),
      );

      if (croppedPath != null && mounted) {
        setState(() => _photoPath = croppedPath);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _createNewRole() async {
    final result = await showDialog<RoleModel>(
      context: context,
      builder: (context) => const CreateRoleDialog(),
    );
    if (result != null) {
      setState(() {
        _roles.add(result);
        _selectedRole = result;
      });
    }
  }

  Future<void> _confirmDeleteRole(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Role?',
            style: JoynTypography.titleMedium
                .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${role.name}" from your roles list? This won\'t affect members already assigned to it.',
          style: JoynTypography.bodyMedium
              .copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(
                    color: JoynColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _roles.removeWhere((r) => r.id == role.id);
        if (_selectedRole?.id == role.id) {
          _selectedRole = _roles.isNotEmpty ? _roles.first : null;
        }
      });
    }
  }

  Future<void> _openRolePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // handle
                      Container(
                        width: 42,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign Role',
                                  style: JoynTypography.titleMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Long-press a role to delete',
                                  style: JoynTypography.caption.copyWith(
                                    fontSize: 11.5,
                                    color: JoynColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            _Pressable(
                              scale: 0.94,
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                await _createNewRole();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: _P.gradient(JoynColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: JoynColors.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Create New',
                                      style: JoynTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_roles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No roles yet',
                            style: JoynTypography.subtitle.copyWith(fontSize: 13.5),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight:
                              MediaQuery.of(context).size.height * 0.5),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _roles.length,
                            itemBuilder: (context, index) {
                              final role = _roles[index];
                              final isSelected = _selectedRole?.id == role.id;
                              return _Pressable(
                                scale: 0.98,
                                onTap: () {
                                  setState(() => _selectedRole = role);
                                  Navigator.pop(sheetContext);
                                },
                                onLongPress: () async {
                                  await _confirmDeleteRole(role);
                                  setSheetState(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? _P.softGradient(JoynColors.primary)
                                        : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? JoynColors.primary
                                          .withValues(alpha: 0.5)
                                          : JoynColors.border
                                          .withValues(alpha: 0.7),
                                      width: 1.2,
                                    ),
                                    boxShadow: isSelected
                                        ? _P.softGlow(JoynColors.primary)
                                        : _P.hairlineShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          gradient: _P.softGradient(
                                              JoynColors.primary),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          border: Border.all(
                                            color: JoynColors.primary
                                                .withValues(alpha: 0.18),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.badge_outlined,
                                          size: 15,
                                          color: JoynColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          role.name,
                                          style: JoynTypography.bodyLarge
                                              .copyWith(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: JoynColors.primary,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: JoynColors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign a role')),
      );
      return;
    }

    final result = TeamMemberModel(
      id: widget.existingMember?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      roleId: _selectedRole!.id,
      roleName: _selectedRole!.name,
      isActive: widget.existingMember?.isActive ?? true,
      photoPath: _photoPath,
      lastLoginTime: widget.existingMember?.lastLoginTime,
      createdAt: widget.existingMember?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop({'member': result, 'roles': _roles});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 50,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _P.surfaceGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: _P.cardShadow,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: 22 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============== HEADER ===============
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: _P.gradient(JoynColors.primary),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _P.softGlow(JoynColors.primary),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_rounded
                            : Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Team Member' : 'Add Team Member',
                            style: JoynTypography.titleMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing
                                ? 'Update member details'
                                : 'Fill in the details to add',
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: JoynColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Pressable(
                      scale: 0.9,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: JoynColors.border.withValues(alpha: 0.7),
                            width: 1,
                          ),
                          boxShadow: _P.hairlineShadow,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // =============== AVATAR ===============
                Center(child: _buildAvatarPickerButton()),
                const SizedBox(height: 22),

                // =============== NAME ===============
                _buildField(
                  'Name *',
                  'Enter name',
                  _nameController,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // =============== PHONE ===============
                _buildField(
                  'Phone Number *',
                  'e.g. 9810230230',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 14),

                // =============== EMAIL ===============
                _buildField(
                  'Email ID',
                  'Enter Gmail ID',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 18),

                // =============== ROLE HEADER ===============
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assign Role',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                    _Pressable(
                      scale: 0.94,
                      onTap: _createNewRole,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _P.gradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: JoynColors.primary.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'New Role',
                              style: JoynTypography.bodyMedium.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // =============== ROLE SELECTOR ===============
                _Pressable(
                  scale: 0.98,
                  onTap: _openRolePicker,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: _P.surfaceGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: JoynColors.primary.withValues(alpha: 0.20),
                        width: 1.2,
                      ),
                      boxShadow: _P.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: _P.softGradient(JoynColors.primary),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: JoynColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: JoynColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedRole?.name ??
                                (_roles.isEmpty
                                    ? 'No roles — create one'
                                    : 'Select Role'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: JoynColors.primary,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: JoynColors.primary, size: 22),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // =============== SUBMIT BUTTON ===============
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =================================================================
  // AVATAR PICKER BUTTON
  // =================================================================
  Widget _buildAvatarPickerButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showAvatarPicker();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _P.softGradient(JoynColors.primary),
              border: Border.all(
                color: JoynColors.primary.withValues(alpha: 0.20),
                width: 1.5,
              ),
              boxShadow: _P.softGlow(JoynColors.primary),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  child: _buildAvatarContent(_photoPath,
                      iconSize: 32, fontSize: 30),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: _P.gradient(JoynColors.primary),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: JoynColors.primary.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? path,
      {required double iconSize, required double fontSize}) {
    if (path != null && path.startsWith(kAvatarPrefix)) {
      final index = int.tryParse(path.substring(kAvatarPrefix.length)) ?? 0;
      final preset = kPresetAvatars[index % kPresetAvatars.length];
      return buildPresetAvatarWidget(preset,
          iconSize: iconSize + 6, emojiSize: iconSize + 10);
    }

    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: JoynTypography.titleMedium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  // =================================================================
  // PREMIUM FIELD
  // =================================================================
  Widget _buildField(
      String label,
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        IconData? icon,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: _P.gradient(JoynColors.primary),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              label,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JoynColors.secondaryText,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: _P.surfaceGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: JoynColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: _P.softShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: _P.softGradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: JoynColors.primary.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 15, color: JoynColors.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: JoynTypography.bodyLarge.copyWith(
                      color: JoynColors.secondaryText.withValues(alpha: 0.5),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
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

  // =================================================================
  // SUBMIT BUTTON — with shine sweep + top highlight
  // =================================================================
  Widget _buildSubmitButton() {
    return _Pressable(
      scale: 0.97,
      onTap: _submit,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _P.gradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _P.chipShadow(JoynColors.primary),
        ),
        child: Stack(
          children: [
            // shine sweep
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _P.shineSweep,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            // top highlight
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _P.topHighlight,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
            ),
            // content
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 0.7,
                      ),
                    ),
                    child: Icon(
                      _isEditing ? Icons.check_rounded : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Update Member' : 'Add Member',
                    style: JoynTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 14.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// AVATAR PICKER SHEET
// =====================================================================
class _AvatarPickerSheet extends StatelessWidget {
  final String? currentPath;

  const _AvatarPickerSheet({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Member Photo',
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a photo, choose from gallery, or pick an avatar',
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: JoynColors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    context,
                    icon: Icons.camera_alt_rounded,
                    title: 'Camera',
                    subtitle: 'Take photo',
                    color: const Color(0xFF0284C7),
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    context,
                    icon: Icons.photo_library_rounded,
                    title: 'Gallery',
                    subtitle: 'Choose photo',
                    color: const Color(0xFFC0202B),
                    onTap: () => Navigator.pop(context, 'gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: _P.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  'CHOOSE AN AVATAR',
                  style: JoynTypography.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: JoynColors.secondaryText,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(kPresetAvatars.length, (index) {
                final preset = kPresetAvatars[index];
                final identifier = '$kAvatarPrefix$index';
                final isSelected = currentPath == identifier;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, identifier);
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? preset.color : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: preset.color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : _P.hairlineShadow,
                    ),
                    child: buildPresetAvatarWidget(preset,
                        iconSize: 26, emojiSize: 26),
                  ),
                );
              }),
            ),

            if (currentPath != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, 'remove'),
                  child: Text(
                    'Remove Photo',
                    style: JoynTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: JoynColors.error,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),
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
  }

  Widget _sourceButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return _Pressable(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: _P.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: JoynTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: JoynTypography.caption.copyWith(
                fontSize: 10.5,
                color: JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}