import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../../team_management/data/team_member_repository.dart';
import '../../team_management/models/team_member_model.dart';
import 'widgets/add_team_member_dialog.dart'
    show kAvatarPrefix, kPresetAvatars, buildPresetAvatarWidget;

// =====================================================================
// PREMIUM DESIGN SYSTEM — Diamond Edition
// =====================================================================
class _P {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.020), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.030), blurRadius: 8, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 40, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> heroShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 44, offset: const Offset(0, 20)),
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

  static LinearGradient deepGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.32) ?? color],
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

// =====================================================================
// PRESSABLE
// =====================================================================
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback onTap;
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
// STAGGERED ENTRANCE
// =====================================================================
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  late final Animation<double> _fade =
  CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 600));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// =====================================================================
// PULSING DOT
// =====================================================================
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.6,
      height: widget.size * 2.6,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + (widget.size * 1.6 * t),
                height: widget.size + (widget.size * 1.6 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.35),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// FLOATING AVATAR
// =====================================================================
class _FloatingAvatar extends StatefulWidget {
  const _FloatingAvatar({required this.child});
  final Widget child;

  @override
  State<_FloatingAvatar> createState() => _FloatingAvatarState();
}

class _FloatingAvatarState extends State<_FloatingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final offset = Curves.easeInOut.transform(_ctrl.value) * 2.0 - 1.0;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: widget.child,
    );
  }
}

// =====================================================================
// MAIN SCREEN
// =====================================================================
class TeamMemberDetailScreen extends StatefulWidget {
  final TeamMemberModel member;

  const TeamMemberDetailScreen({super.key, required this.member});

  @override
  State<TeamMemberDetailScreen> createState() => _TeamMemberDetailScreenState();
}

class _TeamMemberDetailScreenState extends State<TeamMemberDetailScreen> {
  late TeamMemberModel _member;
  final TeamMemberRepository _repository = TeamMemberRepository();
  bool _isToggling = false;
  bool _loadingStats = true;
  double _totalSold = 0;
  double _totalPurchased = 0;
  int _activityCount = 0;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadMemberStats();
  }

  Future<void> _loadMemberStats() async {
    try {
      final res = await ApiService.fetchMemberActivityLogs(_member.id, period: '1month');
      if (res['success'] == true && res['logs'] is List) {
        final logs = res['logs'] as List;
        double sold = 0;
        double purchased = 0;
        final realLogs = logs.where((l) {
          final title = (l['title'] ?? '').toString().toLowerCase();
          final subtitle = (l['subtitle'] ?? '').toString().toLowerCase();
          if (title.contains('team member joined') || (title.contains('team member updated'))) return false;
          if (subtitle.contains('assigned as')) return false;
          return true;
        }).toList();

        for (final l in realLogs) {
          final amt = (l['amount'] as num?)?.toDouble() ?? 0;
          final type = l['type']?.toString();
          if (type == 'itemSold') sold += amt;
          else if (type == 'itemPurchased') purchased += amt;
        }
        if (mounted) {
          setState(() {
            _totalSold = sold;
            _totalPurchased = purchased;
            _activityCount = realLogs.length;
            _loadingStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _totalSold = 0;
            _totalPurchased = 0;
            _activityCount = 0;
            _loadingStats = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalSold = 0;
          _totalPurchased = 0;
          _activityCount = 0;
          _loadingStats = false;
        });
      }
    }
  }

  Future<void> _toggleStatus([bool? targetState]) async {
    if (_isToggling) return;
    final nextStatus = targetState ?? !_member.isActive;
    setState(() {
      _isToggling = true;
      _member = _member.copyWith(isActive: nextStatus);
    });

    try {
      await _repository.toggleMemberActive(_member.id, nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextStatus
                  ? '${_member.name} activated successfully'
                  : '${_member.name} deactivated successfully',
            ),
            backgroundColor: nextStatus ? JoynColors.success : const Color(0xFF64748B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _member = _member.copyWith(isActive: !nextStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: JoynColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

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
          child: _Pressable(
            onTap: () => context.pop(),
            scale: 0.9,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: JoynColors.border.withValues(alpha: 0.7), width: 1),
                boxShadow: _P.hairlineShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Colors.black87),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Member Details',
          style: JoynTypography.titleMedium.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _StaggeredItem(index: 0, child: _buildProfileHero()),
            const SizedBox(height: 20),

            _StaggeredItem(index: 1, child: _buildSectionLabel('Access & Status Control')),
            const SizedBox(height: 12),
            _StaggeredItem(index: 2, child: _buildStatusControlCard()),
            const SizedBox(height: 20),

            _StaggeredItem(index: 3, child: _buildSectionLabel('Performance (Last 30 Days)')),
            const SizedBox(height: 12),
            _StaggeredItem(index: 4, child: _buildPerformanceCard()),
            const SizedBox(height: 20),

            _StaggeredItem(
                index: 5, child: _buildSectionLabel('Contact Information')),
            const SizedBox(height: 12),
            _StaggeredItem(index: 6, child: _buildInfoCard()),
            const SizedBox(height: 24),

            _StaggeredItem(index: 7, child: _buildSectionLabel('Activity Log')),
            const SizedBox(height: 12),
            _StaggeredItem(index: 8, child: _buildActivityLogButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusControlCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _member.isActive
              ? JoynColors.success.withValues(alpha: 0.3)
              : JoynColors.border,
          width: 1.2,
        ),
        boxShadow: _P.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _member.isActive
                  ? JoynColors.success.withValues(alpha: 0.12)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _member.isActive ? Icons.verified_user_rounded : Icons.block_rounded,
              color: _member.isActive ? JoynColors.success : JoynColors.secondaryText,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _member.isActive ? 'Active Team Member' : 'Deactivated Member',
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _member.isActive ? JoynColors.success : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _member.isActive
                      ? 'Member has active business access'
                      : 'Member login & business access is disabled',
                  style: JoynTypography.caption.copyWith(
                    color: JoynColors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _member.isActive,
            activeColor: JoynColors.success,
            onChanged: _isToggling ? null : (val) => _toggleStatus(val),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    if (_loadingStats) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _P.cardShadow,
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _P.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: JoynColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, size: 16, color: JoynColors.success),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOTAL SALES',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_totalSold.toStringAsFixed(0)}',
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: JoynColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _P.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVITIES',
                      style: JoynTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: JoynColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$_activityCount Records',
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // PROFILE HERO — gradient card
  // =================================================================
  Widget _buildProfileHero() {
    final statusLabel = _member.isActive ? 'Active' : 'Not Active';

    return Container(
      decoration: BoxDecoration(
        gradient: _P.deepGradient(JoynColors.primary),
        borderRadius: BorderRadius.circular(26),
        boxShadow: _P.heroShadow,
      ),
      child: Stack(
        children: [
          // radial top-right glow
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // bottom-left glow
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // top highlight
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: _P.topHighlight,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                // ---- Floating avatar with ring ----
                _FloatingAvatar(
                  child: Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.45),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.10),
                          blurRadius: 40,
                          offset: const Offset(0, 14),
                        ),
                      ],
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
                ),

                const SizedBox(height: 18),

                // ---- Name ----
                Text(
                  _member.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: JoynTypography.titleMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 14),

                // ---- Role + status pills ----
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 0.9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            _member.roleName,
                            style: JoynTypography.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status pill (interactive tap to toggle)
                    GestureDetector(
                      onTap: () => _toggleStatus(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _member.isActive
                              ? Colors.white.withValues(alpha: 0.22)
                              : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_member.isActive)
                              _PulsingDot(color: Colors.white, size: 5)
                            else
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    final path = _member.photoPath;

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
        _member.name.isNotEmpty ? _member.name[0].toUpperCase() : '?',
        style: JoynTypography.titleLarge.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: JoynColors.primary,
        ),
      ),
    );
  }

  // =================================================================
  // SECTION LABEL — gradient accent bar
  // =================================================================
  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 9),
          decoration: BoxDecoration(
            gradient: _P.gradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(
          title.toUpperCase(),
          style: JoynTypography.caption.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: JoynColors.secondaryText,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // =================================================================
  // INFO CARD — premium row items
  // =================================================================
  Widget _buildInfoCard() {
    final rows = <_InfoRow>[
      _InfoRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: _member.phone.isEmpty ? 'Not added' : _member.phone,
        color: const Color(0xFF0284C7),
      ),
      _InfoRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: _member.email.isEmpty ? 'Not added' : _member.email,
        color: const Color(0xFFB45309),
      ),
      _InfoRow(
        icon: Icons.login_rounded,
        label: 'Last Login',
        value: _member.lastLoginTime != null
            ? '${_member.lastLoginTime!.day}/${_member.lastLoginTime!.month}/${_member.lastLoginTime!.year}'
            : 'Never logged in',
        color: const Color(0xFF7C3AED),
        isLast: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: _P.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        // border: _P.hairline(width: 1.0, alpha: 0.85),
        boxShadow: _P.cardShadow,
      ),
      child: Column(
        children: [
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: _P.softGradient(row.color),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: row.color.withValues(alpha: 0.18),
                          width: 1),
                    ),
                    child: Icon(row.icon, size: 18, color: row.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label.toUpperCase(),
                          style: JoynTypography.caption.copyWith(
                            fontSize: 10,
                            color: JoynColors.secondaryText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.value,
                          style: JoynTypography.bodyMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18,
                      color:
                      JoynColors.secondaryText.withValues(alpha: 0.35)),
                ],
              ),
            ),
            if (!row.isLast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: JoynColors.border.withValues(alpha: 0.5),
                  height: 1,
                  thickness: 1,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // =================================================================
  // ACTIVITY LOG BUTTON — premium gradient CTA
  // =================================================================
  Widget _buildActivityLogButton(BuildContext context) {
    return _Pressable(
      scale: 0.98,
      onTap: () => context.push('/team-member-activity-log', extra: _member),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: _P.gradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _P.chipShadow(JoynColors.primary),
        ),
        child: Stack(
          children: [
            // shine sweep
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _P.shineSweep,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // top highlight
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _P.topHighlight,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 19, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View Full Activity Log',
                          style: JoynTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All transactions & actions',
                          style: JoynTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 15, color: Colors.white),
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

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });
}