import 'package:flutter/material.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../../../core/widgets/joyn_button.dart';
import '../../../team_management/models/team_member_model.dart';

class CreateRoleDialog extends StatefulWidget {
  const CreateRoleDialog({super.key});

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _nameController = TextEditingController();

  bool _sales = false;
  bool _purchase = false;
  bool _inventory = false;
  bool _reports = false;
  bool _admin = false;
  bool _partyDetails = false;


  static final List<BoxShadow> _fieldShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> _chipShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAdmin() {
    setState(() {
      _admin = !_admin;

      if (_admin) {
        _sales = true;
        _purchase = true;
        _inventory = true;
        _reports = true;
        _partyDetails = true;
      } else {
        _sales = false;
        _purchase = false;
        _inventory = false;
        _reports = false;
        _partyDetails = false;
      }
    });
  }

  void _toggleAccess(String access, bool value) {
    setState(() {
      switch (access) {
        case 'sales':
          _sales = value;
          break;
        case 'purchase':
          _purchase = value;
          break;
        case 'inventory':
          _inventory = value;
          break;
        case 'reports':
          _reports = value;
          break;
        case 'partyDetails':
          _partyDetails = value;
          break;
      }
      _admin = false;
    });
  }

  void _submit() {
    final roleName = _nameController.text.trim();

    if (roleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role name is required')),
      );
      return;
    }

    final role = RoleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: roleName,
      accessSales: _sales,
      accessPurchase: _purchase,
      accessInventory: _inventory,
      accessReports: _reports,
      accessAdmin: _admin,
      accessPartyDetails: _partyDetails,
    );

    Navigator.of(context).pop(role);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: keyboardOpen ? 24 : 60,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                JoynColors.background,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create New Role',
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

                Text(
                  'Name of Role',
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
                    border: Border.all(
                      color: JoynColors.border,
                      width: 1.2,
                    ),
                    boxShadow: _fieldShadow,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Cashier, Supervisor',
                            hintStyle: JoynTypography.bodyLarge.copyWith(
                              color: JoynColors.secondaryText.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
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

                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: JoynColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: JoynColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Access',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: JoynColors.border,
                      width: 1.2,
                    ),
                    boxShadow: _fieldShadow,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _adminChip(),
                      _accessChip(
                        'Sales',
                        _sales,
                            (value) => _toggleAccess('sales', value),
                      ),
                      _accessChip(
                        'Purchase',
                        _purchase,
                            (value) => _toggleAccess('purchase', value),
                      ),
                      _accessChip(
                        'Inventory',
                        _inventory,
                            (value) => _toggleAccess('inventory', value),
                      ),
                      _accessChip(
                        'Reports',
                        _reports,
                            (value) => _toggleAccess('reports', value),
                      ),
                      _accessChip(
                        'Party Details',
                        _partyDetails,
                            (value) => _toggleAccess('partyDetails', value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        JoynColors.primary,
                        Color.lerp(JoynColors.primary, Colors.black, 0.18) ?? JoynColors.primary,
                      ],
                    ),
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
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Create Role',
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

  Widget _adminChip() {
    return InkWell(
      onTap: _toggleAdmin,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          gradient: _admin
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF4F46E5),
            ],
          )
              : null,
          color: _admin ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _admin ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: _admin
              ? [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : _chipShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _admin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.admin_panel_settings_outlined,
              size: 16,
              color: _admin ? Colors.white : const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 6),
            Text(
              'Admin',
              style: JoynTypography.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _admin ? Colors.white : const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessChip(
      String label,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: value ? JoynColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? JoynColors.primary : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: value
              ? [
            BoxShadow(
              color: JoynColors.primary.withValues(alpha: 0.20),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : _chipShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: value ? Colors.white : JoynColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: JoynTypography.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: value ? Colors.white : JoynColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}