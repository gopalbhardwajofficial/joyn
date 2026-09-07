import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> fieldShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 3)),
  ];
  static List<BoxShadow> floatingShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static LinearGradient gradient(Color color) => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.18) ?? color],
  );
  static LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Colors.white, JoynColors.background],
  );
}

class LabelSizeResult {
  final double widthMm;
  final double heightMm;
  final bool isCircle;
  final String name;
  final String? backgroundImagePath;
  const LabelSizeResult({
    required this.widthMm,
    required this.heightMm,
    required this.isCircle,
    required this.name,
    this.backgroundImagePath,
  });
}

class _SizePreset {
  final String label;
  final double w;
  final double h;
  final bool isCircle;
  const _SizePreset(this.label, this.w, this.h, this.isCircle);
}

const _kPresets = <_SizePreset>[
  _SizePreset('100×150\nmm', 100, 150, false),
  _SizePreset('100×100\nmm', 100, 100, true),
  _SizePreset('30×55\nmm', 30, 55, false),
  _SizePreset('50×50\nmm', 50, 50, true),
  _SizePreset('40×40\nmm', 40, 40, false),
  _SizePreset('40×30\nmm', 40, 30, false),
];

class NewLabelSizeScreen extends StatefulWidget {
  final double initialWidthMm;
  final double initialHeightMm;
  const NewLabelSizeScreen({super.key, this.initialWidthMm = 100, this.initialHeightMm = 150});

  @override
  State<NewLabelSizeScreen> createState() => _NewLabelSizeScreenState();
}

class _NewLabelSizeScreenState extends State<NewLabelSizeScreen> {
  late double _widthMm;
  late double _heightMm;
  late bool _isCircle;
  late TextEditingController _nameController;
  int _selectedPresetIndex = -1;
  List<_SizePreset> _presets = List.of(_kPresets);

  @override
  void initState() {
    super.initState();
    _widthMm = widget.initialWidthMm;
    _heightMm = widget.initialHeightMm;
    _isCircle = false;
    _nameController = TextEditingController(text: '${_widthMm.toInt()}x${_heightMm.toInt()}');
    _syncSelectedPreset();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _defaultName() => '${_widthMm.toInt()}x${_heightMm.toInt()}';

  void _syncSelectedPreset() {
    _selectedPresetIndex = _presets.indexWhere((p) => p.w == _widthMm && p.h == _heightMm && p.isCircle == _isCircle);
  }

  void _applyPreset(_SizePreset preset, int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _widthMm = preset.w;
      _heightMm = preset.h;
      _isCircle = preset.isCircle;
      _selectedPresetIndex = index;
      _nameController.text = _defaultName();
    });
  }

  void _setShape(bool circle) {
    HapticFeedback.selectionClick();
    setState(() {
      _isCircle = circle;
      if (circle && _widthMm != _heightMm) {
        final d = _widthMm > _heightMm ? _widthMm : _heightMm;
        _widthMm = d;
        _heightMm = d;
      }
      _syncSelectedPreset();
    });
  }

  void _adjustWidth(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _widthMm = (_widthMm + delta).clamp(5, 300);
      if (_isCircle) _heightMm = _widthMm;
      _selectedPresetIndex = -1;
    });
  }

  void _adjustHeight(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _heightMm = (_heightMm + delta).clamp(5, 300);
      if (_isCircle) _widthMm = _heightMm;
      _selectedPresetIndex = -1;
    });
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    final result = LabelSizeResult(
      widthMm: _widthMm,
      heightMm: _heightMm,
      isCircle: _isCircle,
      name: _nameController.text.trim().isEmpty ? _defaultName() : _nameController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: JoynColors.background,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('New Label', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildPreview(),
            const SizedBox(height: 20),
            _buildCard(
              child: Row(
                children: [
                  Text('Name', style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      style: JoynTypography.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: JoynColors.primary),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final p = _presets[i];
                        final selected = i == _selectedPresetIndex;
                        return InkWell(
                          onTap: () => _applyPreset(p, i),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 74,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? JoynColors.primary.withValues(alpha: 0.08) : JoynColors.chipBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: selected ? Border.all(color: JoynColors.primary, width: 1.4) : null,
                            ),
                            child: Text(
                              p.label,
                              textAlign: TextAlign.center,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                color: selected ? JoynColors.primary : JoynColors.secondaryText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Shape', style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                      const Spacer(),
                      _pill('Rectangle', !_isCircle, () => _setShape(false)),
                      const SizedBox(width: 8),
                      _pill('Circle', _isCircle, () => _setShape(true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isCircle)
                    _stepperRow('Diameter (mm)', _widthMm, () => _adjustWidth(-1), () => _adjustWidth(1))
                  else ...[
                    _stepperRow('Width (mm)', _widthMm, () => _adjustWidth(-1), () => _adjustWidth(1)),
                    _stepperRow('Height (mm)', _heightMm, () => _adjustHeight(-1), () => _adjustHeight(1)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: _Premium.floatingShadow(JoynColors.primary),
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoynColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text('Confirm', style: JoynTypography.buttonText.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    const maxDim = 220.0;
    final longest = _widthMm > _heightMm ? _widthMm : _heightMm;
    final scale = longest == 0 ? 1.0 : maxDim / longest;
    final w = _widthMm * scale;
    final h = _heightMm * scale;
    return Center(
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: _isCircle ? null : BorderRadius.circular(10),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: _Premium.fieldShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          '${_widthMm.toInt()}×${_heightMm.toInt()} mm',
          style: JoynTypography.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _Premium.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JoynColors.border, width: 1.2),
        boxShadow: _Premium.cardShadow,
      ),
      child: child,
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
          color: selected ? null : JoynColors.chipBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : JoynColors.secondaryText),
        ),
      ),
    );
  }

  Widget _stepperRow(String label, double value, VoidCallback onMinus, VoidCallback onPlus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: JoynColors.primary)),
          const Spacer(),
          _stepButton(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 46,
            child: Text(value.toInt().toString(), textAlign: TextAlign.center, style: JoynTypography.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: JoynColors.primary)),
          ),
          _stepButton(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JoynColors.border, width: 1.2),
          boxShadow: _Premium.fieldShadow,
        ),
        child: Icon(icon, size: 16, color: JoynColors.primary),
      ),
    );
  }
}