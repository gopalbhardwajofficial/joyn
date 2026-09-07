import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../team_management/models/team_member_model.dart';
import 'widgets/add_team_member_dialog.dart' show kAvatarPrefix, kPresetAvatars, buildPresetAvatarWidget;

class TeamMemberDetailScreen extends StatelessWidget {
  final TeamMemberModel member;

  const TeamMemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Member Details',
          style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 28),

            _buildSectionLabel('Contact Information'),
            const SizedBox(height: 12),

            _buildInfoCard([
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: member.phone.isEmpty ? 'Not added' : member.phone,
              ),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: member.email.isEmpty ? 'Not added' : member.email,
              ),
              _InfoRow(
                icon: Icons.login_rounded,
                label: 'Last Login',
                value: member.lastLoginTime != null
                    ? '${member.lastLoginTime!.day}/${member.lastLoginTime!.month}/${member.lastLoginTime!.year}'
                    : 'Never logged in',
                isLast: true,
              ),
            ]),

            const SizedBox(height: 28),

            _buildSectionLabel('Activity'),
            const SizedBox(height: 12),

            _buildActivityLogButton(context),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  JoynColors.primary.withValues(alpha: 0.9),
                  JoynColors.primary.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: JoynColors.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: _buildAvatarContent()),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            member.name,
            style: JoynTypography.titleMedium.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: JoynColors.chipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.roleName,
                  style: JoynTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: JoynColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: (member.isActive ? JoynColors.success : JoynColors.secondaryText)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: member.isActive ? JoynColors.success : JoynColors.secondaryText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      member.isActive ? 'Active' : 'Not Active',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: member.isActive ? JoynColors.success : JoynColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    final path = member.photoPath;

    if (path != null && path.startsWith(kAvatarPrefix)) {
      final index = int.tryParse(path.substring(kAvatarPrefix.length)) ?? 0;
      final preset = kPresetAvatars[index % kPresetAvatars.length];
      return buildPresetAvatarWidget(preset, iconSize: 40, emojiSize: 46);
    }

    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    return Center(
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: JoynTypography.titleLarge.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: JoynColors.primary,
        ),
      ),
    );
  }


  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: JoynTypography.caption.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: JoynColors.secondaryText,
        letterSpacing: 0.8,
      ),
    );
  }


  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: JoynColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(row.icon, size: 18, color: JoynColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: JoynTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: JoynColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          row.value,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!row.isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(color: JoynColors.border, height: 1, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }


  Widget _buildActivityLogButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('/team-member-activity-log', extra: member);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: JoynColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 18, color: JoynColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'View Full Activity Log',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: JoynColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
}