

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import 'package:joyn/features/orders/presentation/widgets/order_list_widgets.dart';

// =====================================================================
// MODEL
// =====================================================================
enum OrderFilterType { text, choice, dateRange, amountRange }

class OrderFilterDef {
  final String key;
  final String label;
  final String? shortLabel; // pill mein prefix
  final IconData icon;
  final OrderFilterType type;
  final String hint;
  final List<String> choices; // choice type ke liye
  final String allLabel; // choice type: "All ..." option
  final TextInputType keyboard;

  const OrderFilterDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.type,
    this.shortLabel,
    this.hint = '',
    this.choices = const [],
    this.allLabel = 'All',
    this.keyboard = TextInputType.text,
  });

  String get pillPrefix => shortLabel ?? label;
}

// =====================================================================
// STATE (ChangeNotifier) — saare filter values yahan rehte hain
// =====================================================================
class OrderFilters extends ChangeNotifier {
  OrderFilters(this.defs, {Set<String>? initialActive})
      : _initial = {...?initialActive},
        _active = {...?initialActive};

  final List<OrderFilterDef> defs;
  final Set<String> _initial;
  final Set<String> _active;
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String?> _choices = {};
  final Map<String, DateTimeRange?> _ranges = {};

  // ---------- active toggles ----------
  bool isActive(String key) => _active.contains(key);
  int get activeCount => _active.length;

  OrderFilterDef _def(String key) => defs.firstWhere((d) => d.key == key);

  void toggle(String key) {
    if (_active.contains(key)) {
      _active.remove(key);
      _clearValue(_def(key));
    } else {
      _active.add(key);
    }
    notifyListeners();
  }

  // ---------- controllers / values ----------
  TextEditingController controller(String id) =>
      _ctrls.putIfAbsent(id, () => TextEditingController());

  /// Text filter ki query (lowercase, trimmed). Filter off ho to ''.
  String textQuery(String key) =>
      isActive(key) ? controller(key).text.trim().toLowerCase() : '';

  double? minOf(String key) => isActive(key)
      ? double.tryParse(controller('$key.min').text.trim())
      : null;

  double? maxOf(String key) => isActive(key)
      ? double.tryParse(controller('$key.max').text.trim())
      : null;

  String? choiceOf(String key) => isActive(key) ? _choices[key] : null;

  DateTimeRange? rangeOf(String key) => isActive(key) ? _ranges[key] : null;

  static bool inDateRange(DateTime d, DateTimeRange r) {
    final day = DateUtils.dateOnly(d);
    return !day.isBefore(DateUtils.dateOnly(r.start)) &&
        !day.isAfter(DateUtils.dateOnly(r.end));
  }

  void setChoice(String key, String? value) {
    _choices[key] = value;
    notifyListeners();
  }

  void setRange(String key, DateTimeRange? range) {
    _ranges[key] = range;
    notifyListeners();
  }

  /// TextField onChanged se call karo
  void changed() => notifyListeners();

  // ---------- has values / pills ----------
  bool _hasValue(OrderFilterDef d) {
    switch (d.type) {
      case OrderFilterType.text:
        return controller(d.key).text.trim().isNotEmpty;
      case OrderFilterType.choice:
        return _choices[d.key] != null;
      case OrderFilterType.dateRange:
        return _ranges[d.key] != null;
      case OrderFilterType.amountRange:
        return controller('${d.key}.min').text.trim().isNotEmpty ||
            controller('${d.key}.max').text.trim().isNotEmpty;
    }
  }

  bool get hasValues => defs.any(_hasValue);

  String _pillLabel(OrderFilterDef d) {
    switch (d.type) {
      case OrderFilterType.text:
        return '${d.pillPrefix}: ${controller(d.key).text.trim()}';
      case OrderFilterType.choice:
        return '${d.pillPrefix}: ${_choices[d.key]}';
      case OrderFilterType.dateRange:
        final r = _ranges[d.key]!;
        return '${d.pillPrefix}: ${formatOrderDateTime(r.start)} - '
            '${formatOrderDateTime(r.end)}';
      case OrderFilterType.amountRange:
        final min = controller('${d.key}.min').text.trim();
        final max = controller('${d.key}.max').text.trim();
        return '₹${min.isEmpty ? '0' : min} - ${max.isEmpty ? '∞' : max}';
    }
  }

  /// Sirf un filters ki pills jinme value set hai
  List<MapEntry<String, String>> get pills => [
    for (final d in defs)
      if (isActive(d.key) && _hasValue(d)) MapEntry(d.key, _pillLabel(d)),
  ];

  // ---------- clearing ----------
  void _clearValue(OrderFilterDef d) {
    switch (d.type) {
      case OrderFilterType.text:
        controller(d.key).clear();
        break;
      case OrderFilterType.choice:
        _choices[d.key] = null;
        break;
      case OrderFilterType.dateRange:
        _ranges[d.key] = null;
        break;
      case OrderFilterType.amountRange:
        controller('${d.key}.min').clear();
        controller('${d.key}.max').clear();
        break;
    }
  }

  void clear(String key) {
    _clearValue(_def(key));
    notifyListeners();
  }

  void clearAll() {
    for (final d in defs) {
      _clearValue(d);
    }
    _active
      ..clear()
      ..addAll(_initial);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}

// =====================================================================
// DESIGN TOKENS (Manage Inventory ke _Premium ka subset)
// =====================================================================
class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.020),
        blurRadius: 2,
        offset: const Offset(0, 1)),
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.030),
        blurRadius: 8,
        offset: const Offset(0, 3)),
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 20,
        offset: const Offset(0, 8)),
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 40,
        offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> hairlineShadow = [
    BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chipShadow(Color color) => [
    BoxShadow(
        color: color.withValues(alpha: 0.20),
        blurRadius: 6,
        offset: const Offset(0, 2)),
    BoxShadow(
        color: color.withValues(alpha: 0.28),
        blurRadius: 16,
        offset: const Offset(0, 7)),
    BoxShadow(
        color: color.withValues(alpha: 0.15),
        blurRadius: 30,
        offset: const Offset(0, 14)),
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
    colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
  );

  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color.lerp(Colors.white, JoynColors.background, 0.55) ?? Colors.white
    ],
  );

  static LinearGradient topHighlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
  );

  static Border hairline({double width = 1.0, double alpha = 1}) =>
      Border.all(color: JoynColors.border.withValues(alpha: alpha), width: width);
}

// =====================================================================
// SMALL HELPERS
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

/// Smooth show/hide for filter fields
class _AnimatedReveal extends StatelessWidget {
  const _AnimatedReveal({
    required this.show,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  final bool show;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: show
            ? Container(key: const ValueKey('show'), child: child)
            : const SizedBox.shrink(key: ValueKey('hide')),
      ),
    );
  }
}

/// Focus hone par soft glow
class _FocusField extends StatefulWidget {
  const _FocusField({required this.child});
  final Widget child;

  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _focused
              ? [
            BoxShadow(
                color: JoynColors.primary.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

BoxDecoration _fieldBox({List<BoxShadow>? shadow}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
      color: JoynColors.border.withValues(alpha: 0.85), width: 1.2),
  boxShadow: shadow,
);

Widget _fieldLabel(String label) => Text(label,
    style: JoynTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
        color: JoynColors.secondaryText,
        letterSpacing: 0.1));

Widget _iconBox(IconData icon, {double size = 13, double pad = 5}) => Container(
  padding: EdgeInsets.all(pad),
  decoration: BoxDecoration(
    gradient: _Premium.softGradient(JoynColors.primary),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(icon, size: size, color: JoynColors.primary),
);

// =====================================================================
// FILTER CARD
// =====================================================================
class OrderFilterCard extends StatelessWidget {
  const OrderFilterCard({super.key, required this.filters});

  final OrderFilters filters;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: filters,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: _Premium.surfaceGradient,
            borderRadius: BorderRadius.circular(18),
            border: _Premium.hairline(width: 1.0, alpha: 0.85),
            boxShadow: _Premium.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              for (final d in filters.defs)
                _AnimatedReveal(
                  show: filters.isActive(d.key),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildField(context, d),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            gradient: _Premium.gradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: _Premium.softGradient(JoynColors.primary),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.filter_alt_outlined,
              size: 14, color: JoynColors.primary),
        ),
        const SizedBox(width: 10),
        Text('Filters',
            style: JoynTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                letterSpacing: -0.2,
                color: Colors.black87)),
        const Spacer(),
        _Pressable(
          onTap: () => showOrderFilterSettings(context, filters),
          scale: 0.9,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: JoynColors.border.withValues(alpha: 0.7), width: 1),
              boxShadow: _Premium.hairlineShadow,
            ),
            child: const Icon(Icons.settings_rounded,
                size: 15, color: JoynColors.primary),
          ),
        ),
        if (filters.hasValues) ...[
          const SizedBox(width: 8),
          _Pressable(
            onTap: filters.clearAll,
            scale: 0.94,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: _Premium.softGradient(JoynColors.error),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: JoynColors.error.withValues(alpha: 0.20), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded,
                      size: 12, color: JoynColors.error),
                  const SizedBox(width: 4),
                  Text('Clear',
                      style: JoynTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: JoynColors.error)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context, OrderFilterDef d) {
    switch (d.type) {
      case OrderFilterType.text:
        return _TextFilterField(
          label: d.label,
          hint: d.hint,
          controller: filters.controller(d.key),
          icon: d.icon,
          keyboardType: d.keyboard,
          onChanged: filters.changed,
        );

      case OrderFilterType.choice:
        return _ChoiceFilterField(
          label: d.label,
          icon: d.icon,
          value: filters.choiceOf(d.key),
          choices: d.choices,
          allLabel: d.allLabel,
          onChanged: (v) => filters.setChoice(d.key, v),
        );

      case OrderFilterType.dateRange:
        return _DateRangeFilterField(
          label: d.label,
          hint: d.hint.isEmpty ? 'Select date range' : d.hint,
          icon: d.icon,
          range: filters.rangeOf(d.key),
          onTap: () => _pickRange(context, d),
          onClear: () => filters.setRange(d.key, null),
        );

      case OrderFilterType.amountRange:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TextFilterField(
                label: 'Min Amount',
                hint: '0',
                controller: filters.controller('${d.key}.min'),
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                onChanged: filters.changed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TextFilterField(
                label: 'Max Amount',
                hint: '∞',
                controller: filters.controller('${d.key}.max'),
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                onChanged: filters.changed,
              ),
            ),
          ],
        );
    }
  }

  Future<void> _pickRange(BuildContext context, OrderFilterDef d) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: filters.rangeOf(d.key),
    );
    if (picked != null) filters.setRange(d.key, picked);
  }
}

// ---------------------------------------------------------------------
// Text field — focus glow + clear button
// ---------------------------------------------------------------------
class _TextFilterField extends StatelessWidget {
  const _TextFilterField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _FocusField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 6),
          Container(
            decoration: _fieldBox(),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: (_) => onChanged(),
              style: JoynTypography.bodyLarge
                  .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: JoynTypography.bodyMedium.copyWith(
                    color: JoynColors.secondaryText.withValues(alpha: 0.5),
                    fontSize: 13),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 9),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _Premium.softGradient(JoynColors.primary),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 12, color: JoynColors.primary),
                  ),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: JoynColors.chipBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.clear_rounded,
                        size: 11, color: JoynColors.secondaryText),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Dropdown (Payment Mode / Due Status ...)
// ---------------------------------------------------------------------
class _ChoiceFilterField extends StatelessWidget {
  const _ChoiceFilterField({
    required this.label,
    required this.icon,
    required this.value,
    required this.choices,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> choices;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  TextStyle get _style => JoynTypography.bodyLarge.copyWith(
      fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87);

  Widget _selected(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: _style),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _fieldBox(shadow: _Premium.hairlineShadow),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    itemHeight: null,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: JoynColors.primary),
                    dropdownColor: Colors.white,
                    style: _style,
                    borderRadius: BorderRadius.circular(14),
                    selectedItemBuilder: (context) =>
                        [allLabel, ...choices].map(_selected).toList(),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(allLabel)),
                      ...choices.map((c) => DropdownMenuItem<String?>(
                          value: c, child: Text(c))),
                    ],
                    onChanged: onChanged,
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

// ---------------------------------------------------------------------
// Date range picker field
// ---------------------------------------------------------------------
class _DateRangeFilterField extends StatelessWidget {
  const _DateRangeFilterField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.range,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String hint;
  final IconData icon;
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasRange = range != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: _fieldBox(shadow: _Premium.hairlineShadow),
            child: Row(
              children: [
                _iconBox(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasRange
                        ? '${formatOrderDateTime(range!.start)}  -  ${formatOrderDateTime(range!.end)}'
                        : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasRange
                        ? JoynTypography.bodyLarge.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)
                        : JoynTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: JoynColors.secondaryText
                            .withValues(alpha: 0.5)),
                  ),
                ),
                if (hasRange)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: JoynColors.chipBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.clear_rounded,
                          size: 12, color: JoynColors.secondaryText),
                    ),
                  )
                else
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: JoynColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// ACTIVE FILTER PILLS
// =====================================================================
class OrderActiveFilterPills extends StatelessWidget {
  const OrderActiveFilterPills({super.key, required this.filters});

  final OrderFilters filters;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: filters,
      builder: (context, _) {
        final pills = filters.pills;
        if (pills.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills
                .map((e) => _ActiveFilterPill(
              label: e.value,
              onClear: () => filters.clear(e.key),
            ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onClear,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 6, 6, 6),
        decoration: BoxDecoration(
          gradient: _Premium.softGradient(JoynColors.primary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: JoynColors.primary.withValues(alpha: 0.22), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JoynTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: JoynColors.primary),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: JoynColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: JoynColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// FILTER SETTINGS SHEET — kaunse filters dikhane hain, toggle karo
// =====================================================================
Future<void> showOrderFilterSettings(
    BuildContext context, OrderFilters filters) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return ListenableBuilder(
        listenable: filters,
        builder: (_, __) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: JoynColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient:
                              _Premium.softGradient(JoynColors.primary),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: JoynColors.primary
                                      .withValues(alpha: 0.12),
                                  width: 1),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                size: 15, color: JoynColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text('Filter Settings',
                              style: JoynTypography.titleMedium.copyWith(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: JoynColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                '${filters.activeCount}/${filters.defs.length}',
                                style: JoynTypography.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: JoynColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Toggle filters to show/hide them on the main screen',
                        style: JoynTypography.caption.copyWith(
                          fontSize: 13,
                          color: JoynColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filters.defs.map((d) => _settingTile(filters, d)),
                      const SizedBox(height: 20),
                      _Pressable(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(JoynColors.primary),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _Premium.chipShadow(JoynColors.primary),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _Premium.topHighlight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Done',
                                        style: JoynTypography.bodyMedium
                                            .copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _settingTile(OrderFilters filters, OrderFilterDef d) {
  final isActive = filters.isActive(d.key);
  return _Pressable(
    onTap: () => filters.toggle(d.key),
    scale: 0.98,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive ? _Premium.softGradient(JoynColors.primary) : null,
        color: isActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? JoynColors.primary.withValues(alpha: 0.25)
              : JoynColors.border.withValues(alpha: 0.6),
          width: isActive ? 1.3 : 1.1,
        ),
        boxShadow: isActive
            ? [
          BoxShadow(
              color: JoynColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isActive
                  ? _Premium.gradient(JoynColors.primary)
                  : _Premium.softGradient(JoynColors.primary),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                BoxShadow(
                    color: JoynColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ]
                  : null,
            ),
            child: Icon(d.icon,
                size: 16, color: isActive ? Colors.white : JoynColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              d.label,
              style: JoynTypography.bodyLarge.copyWith(
                fontSize: 14.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? JoynColors.primary : Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.72,
            child: Switch.adaptive(
              value: isActive,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                filters.toggle(d.key);
              },
              activeTrackColor: JoynColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    ),
  );
}