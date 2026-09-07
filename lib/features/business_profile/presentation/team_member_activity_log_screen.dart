import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/activity_log_model.dart';
import '../../team_management/models/team_member_model.dart';

class TeamMemberActivityLogScreen extends StatefulWidget {
  final TeamMemberModel member;

  const TeamMemberActivityLogScreen({super.key, required this.member});

  @override
  State<TeamMemberActivityLogScreen> createState() => _TeamMemberActivityLogScreenState();
}

class _TeamMemberActivityLogScreenState extends State<TeamMemberActivityLogScreen> {
  ActivityTimePeriod _selectedPeriod = ActivityTimePeriod.day1;
  DateTimeRange? _customRange;

  List<ActivityLogEntry> get _dummyEntries => [
    ActivityLogEntry(
      id: '1',
      type: ActivityType.itemPurchased,
      title: 'Item Purchased',
      subtitle: 'Purchase Order #PO-1234',
      amount: 5000,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityLogEntry(
      id: '2',
      type: ActivityType.itemSold,
      title: 'Item Sold',
      subtitle: 'Sale Invoice #2',
      amount: 10020,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityLogEntry(
      id: '3',
      type: ActivityType.itemAddedModified,
      title: 'Item Added / Modified',
      subtitle: 'Sugar 1kg — stock updated',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityLogEntry(
      id: '4',
      type: ActivityType.custAddedModified,
      title: 'Customer Added / Modified',
      subtitle: 'Ramesh Traders — details updated',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<void> _selectPeriod() async {
    final result = await showModalBottomSheet<ActivityTimePeriod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              decoration: BoxDecoration(
                color: JoynColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Time Period',
                  style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 6),
            for (final period in ActivityTimePeriod.values.where((p) => p != ActivityTimePeriod.custom))
              InkWell(
                onTap: () => Navigator.pop(context, period),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          period.label,
                          style: JoynTypography.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: _selectedPeriod == period ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedPeriod == period ? JoynColors.primary : JoynColors.primary.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      if (_selectedPeriod == period)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: JoynColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedPeriod = result);
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = ActivityTimePeriod.custom;
      });
    }
  }

  String get _rangeLabel {
    if (_selectedPeriod == ActivityTimePeriod.custom && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
    return _selectedPeriod.label;
  }

  IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.itemPurchased:
        return Icons.shopping_bag_outlined;
      case ActivityType.itemSold:
        return Icons.shopping_cart_outlined;
      case ActivityType.itemAddedModified:
        return Icons.inventory_2_outlined;
      case ActivityType.custAddedModified:
        return Icons.people_outline_rounded;
    }
  }

  Color _colorFor(ActivityType type) {
    switch (type) {
      case ActivityType.itemPurchased:
        return const Color(0xFF0284C7);
      case ActivityType.itemSold:
        return JoynColors.success;
      case ActivityType.itemAddedModified:
        return const Color(0xFFB45309);
      case ActivityType.custAddedModified:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _dummyEntries;
    final totalPurchased = entries
        .where((e) => e.type == ActivityType.itemPurchased)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final totalSold = entries
        .where((e) => e.type == ActivityType.itemSold)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Activity Log',
          style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildMemberHeader(),
            const SizedBox(height: 24),

            _buildSectionLabel('Time Period'),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            _buildSectionLabel('Summary'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Item Purchased',
                    value: '₹${totalPurchased.toStringAsFixed(0)}',
                    color: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Item Sold',
                    value: '₹${totalSold.toStringAsFixed(0)}',
                    color: JoynColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('Items / Customer / Order'),
            const SizedBox(height: 12),

            if (entries.isEmpty)
              _buildEmptyState()
            else
              _buildActivityCard(entries),
          ],
        ),
      ),
    );
  }


  Widget _buildMemberHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
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
            child: Center(
              child: Text(
                widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : '?',
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: JoynColors.primary,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.name,
                  style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: JoynColors.chipBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.member.roleName,
                    style: JoynTypography.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _selectPeriod,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 17, color: JoynColors.primary),
                        const SizedBox(width: 10),
                        Text(_rangeLabel, style: JoynTypography.bodyLarge.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: JoynColors.secondaryText),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: JoynColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _selectCustomDateRange,
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: JoynColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.date_range_outlined, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: JoynTypography.caption.copyWith(fontSize: 11.5, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: JoynTypography.bodyLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<ActivityLogEntry> entries) {
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
          for (int i = 0; i < entries.length; i++) ...[
            _buildActivityRow(entries[i]),
            if (i != entries.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: JoynColors.border, height: 1, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityRow(ActivityLogEntry entry) {
    final color = _colorFor(entry.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(entry.type), size: 18, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: JoynTypography.caption.copyWith(fontSize: 12, color: JoynColors.secondaryText),
                ),
                const SizedBox(height: 5),
                Text(
                  '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} • ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                  style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
          if (entry.amount != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '₹${entry.amount!.toStringAsFixed(0)}',
                style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 14, color: JoynColors.primary),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: JoynColors.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 30, color: JoynColors.secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            'No Activity Found',
            style: JoynTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'No transactions recorded for this period.',
            style: JoynTypography.subtitle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}