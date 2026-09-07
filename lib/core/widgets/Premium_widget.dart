import 'package:flutter/material.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

/// Reusable premium screen scaffold pieces shared by every report screen so
/// the whole "Reports" section of the app feels like one cohesive product
/// instead of six separately-styled pages.

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: JoynColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: JoynColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Pill-shaped Pdf / Xls export actions — monochrome + a tasteful color dot
/// instead of loud red/green blocks, so it reads as premium rather than busy.
class ExportActions extends StatelessWidget {
  final VoidCallback? onPdf;
  final VoidCallback? onXls;

  const ExportActions({super.key, this.onPdf, this.onXls});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JoynColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ExportPill(label: 'PDF', icon: Icons.picture_as_pdf_outlined, onTap: onPdf),
          Container(width: 1, height: 18, color: JoynColors.border),
          _ExportPill(label: 'XLS', icon: Icons.grid_on_rounded, onTap: onXls),
        ],
      ),
    );
  }
}

class _ExportPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ExportPill({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 15, color: JoynColors.primary),
              const SizedBox(width: 5),
              Text(label,
                  style: JoynTypography.caption.copyWith(
                    color: JoynColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "This Month · 01/09/2026 to 30/09/2026" selector row used on every
/// report screen.
class PeriodDateBar extends StatelessWidget {
  final String period;
  final String dateRangeText;
  final VoidCallback onPeriodTap;
  final VoidCallback onDateTap;

  const PeriodDateBar({
    super.key,
    required this.period,
    required this.dateRangeText,
    required this.onPeriodTap,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onDateTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: JoynColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: JoynColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: JoynColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateRangeText,
                        overflow: TextOverflow.ellipsis,
                        style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onPeriodTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: JoynColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(period,
                      style: JoynTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A KPI stat block used inside summary cards (Gross Profit, Net Profit,
/// Total Sale Amount, Closing Cash, etc).
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = JoynColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: JoynColors.secondaryText),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(label,
                  style: JoynTypography.statLabel, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: JoynTypography.statValue.copyWith(color: valueColor)),
      ],
    );
  }
}

/// Generic centered empty state with a soft illustrative icon badge.
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: JoynColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: JoynColors.border),
                boxShadow: [
                  BoxShadow(
                    color: JoynColors.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: JoynColors.secondaryText),
            ),
            const SizedBox(height: 24),
            Text(title, style: JoynTypography.bodyLarge.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: JoynTypography.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section label used above lists ("Particulars / Amount", "Name & Date...").
class ColumnHeaderRow extends StatelessWidget {
  final List<Widget> children;
  const ColumnHeaderRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(children: children),
    );
  }
}

/// Small neutral filter/status chip.
class PremiumChip extends StatelessWidget {
  final String text;
  final bool selected;
  const PremiumChip({super.key, required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? JoynColors.primary : JoynColors.chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: JoynTypography.caption.copyWith(
          color: selected ? Colors.white : JoynColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A tappable row with a leading label, trailing value + chevron — used for
/// the Transaction Type / Party Name selector rows.
class SelectorRow extends StatelessWidget {
  final String? prefixLabel;
  final String value;
  final VoidCallback onTap;

  const SelectorRow({super.key, this.prefixLabel, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: JoynColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JoynColors.border),
          ),
          child: Row(
            children: [
              if (prefixLabel != null) ...[
                Text(prefixLabel!,
                    style: JoynTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: JoynColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}