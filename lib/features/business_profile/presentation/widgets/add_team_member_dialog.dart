import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/widgets/joyn_button.dart';
import '../../../team_management/models/team_member_model.dart';
import 'create_role_dialog.dart';
import 'image_crop_dialog.dart';

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


  static final List<BoxShadow> _cardShadow = [
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

  static final List<BoxShadow> _fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static LinearGradient get _surfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      JoynColors.background,
    ],
  );

  static LinearGradient _gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      Color.lerp(color, Colors.black, 0.18) ?? color,
    ],
  );

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Role?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${role.name}" from your roles list? This won\'t affect members already assigned to it.',
          style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, color: JoynColors.secondaryText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: JoynColors.error, fontWeight: FontWeight.w700)),
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
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assign Role',
                            style: JoynTypography.titleMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await _createNewRole();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _gradient(JoynColors.primary),
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
                                  const Icon(Icons.add_rounded, size: 14, color: Colors.white),
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
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Long-press a role to delete it',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 11.5,
                          color: JoynColors.secondaryText,
                        ),
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
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _roles.length,
                          itemBuilder: (context, index) {
                            final role = _roles[index];
                            final isSelected = _selectedRole?.id == role.id;
                            return InkWell(
                              onTap: () {
                                setState(() => _selectedRole = role);
                                Navigator.pop(sheetContext);
                              },
                              onLongPress: () async {
                                await _confirmDeleteRole(role);
                                setSheetState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? _gradient(JoynColors.primary.withValues(alpha: 0.08)) : null,
                                  color: isSelected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? JoynColors.primary : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? JoynColors.primary.withValues(alpha: 0.12)
                                            : JoynColors.chipBackground,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.badge_outlined,
                                        size: 16,
                                        color: JoynColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        role.name,
                                        style: JoynTypography.bodyLarge.copyWith(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: JoynColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, size: 18, color: JoynColors.primary),
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
      id: widget.existingMember?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 24 : 60,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _surfaceGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _cardShadow,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Team Member' : 'Add Team Member',
                      style: JoynTypography.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: JoynColors.chipBackground,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: JoynColors.secondaryText,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Center(child: _buildAvatarPickerButton()),
                const SizedBox(height: 20),

                _buildField(
                  'Name *',
                  'Enter name',
                  _nameController,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                _buildField(
                  'Email ID',
                  'Enter Gmail ID',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

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
                    InkWell(
                      onTap: _createNewRole,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _gradient(JoynColors.primary),
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
                            const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Create New Role',
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
                const SizedBox(height: 6),

                InkWell(
                  onTap: _openRolePicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: JoynColors.border, width: 1.2),
                      boxShadow: _fieldShadow,
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
                            Icons.badge_outlined,
                            size: 16,
                            color: JoynColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedRole?.name ?? (_roles.isEmpty ? 'No roles — create one' : 'Select Role'),
                            style: JoynTypography.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: JoynColors.primary,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: JoynColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: JoynColors.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditing ? Icons.check_rounded : Icons.person_add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'Update Member' : 'Add Member',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPickerButton() {
    return GestureDetector(
      onTap: _showAvatarPicker,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
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
              border: Border.all(color: JoynColors.border, width: 1.2),
            ),
            child: ClipOval(child: _buildAvatarContent(_photoPath, iconSize: 30, fontSize: 26)),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: _gradient(JoynColors.primary),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: JoynColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? path, {required double iconSize, required double fontSize}) {
    if (path != null && path.startsWith(kAvatarPrefix)) {
      final index = int.tryParse(path.substring(kAvatarPrefix.length)) ?? 0;
      final preset = kPresetAvatars[index % kPresetAvatars.length];
      return buildPresetAvatarWidget(preset, iconSize: iconSize + 6, emojiSize: iconSize + 10);
    }

    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    final initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: JoynTypography.titleMedium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: JoynColors.primary,
        ),
      ),
    );
  }

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
            boxShadow: _fieldShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
}

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

            Text(
              'CHOOSE AN AVATAR',
              style: JoynTypography.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: JoynColors.secondaryText,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(kPresetAvatars.length, (index) {
                final preset = kPresetAvatars[index];
                final identifier = '$kAvatarPrefix$index';
                final isSelected = currentPath == identifier;

                return GestureDetector(
                  onTap: () => Navigator.pop(context, identifier),
                  child: Container(
                    width: 56,
                    height: 56,
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
                          color: preset.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                          : null,
                    ),
                    child: buildPresetAvatarWidget(preset, iconSize: 26, emojiSize: 26),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 9),
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