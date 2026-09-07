import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import 'package:joyn/features/barcode/presentation/newlable_screen.dart';

class _Premium {
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 4, offset: const Offset(0, 1)),
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

enum LabelElementType { text, qrCode, barcode, time, line, rectangle, circle, image, serial, sticker, logo, database }
enum BarcodeStyle { normal, isometric }
enum QrShape { square, circle, roundedRect }
enum TextAlignMode { left, center, right, justify }

const _kSwatches = <Color>[
  Colors.black, Color(0xFFE53935), Color(0xFF1E88E5),
  Color(0xFF14B85C), Color(0xFFFF8F00), Color(0xFF7C3AED),
  Color(0xFF795548), Color(0xFF607D8B), Color(0xFF9E9E9E),
  Colors.white,
];

const _kBarcodeTypes = <String>[
  'code128', 'ean13', 'ean8', 'code39', 'upcA', 'upcE',
  'itf', 'codabar', 'isbn', 'code93', 'gs1_128',
];

const _kFontFamilies = <String>[
  'Default', 'Arial', 'Courier', 'Times New Roman',
  'Verdana', 'Georgia', 'Helvetica', 'Impact',
];

const _kEncodings = <String>['UTF-8', 'ASCII', 'ISO-8859-1', 'UTF-16', 'Shift-JIS'];

class StickerDef {
  final String key;
  final IconData? icon;
  final String? textLabel;
  const StickerDef(this.key, {this.icon, this.textLabel});
}

const kStickerLibrary = <String, StickerDef>{
  'star': StickerDef('star', icon: Icons.star_rounded),
  'heart': StickerDef('heart', icon: Icons.favorite_rounded),
  'check': StickerDef('check', icon: Icons.check_circle_rounded),
  'warning': StickerDef('warning', icon: Icons.warning_rounded),
  'info': StickerDef('info', icon: Icons.info_rounded),
  'smile': StickerDef('smile', icon: Icons.emoji_emotions_rounded),
  'fire': StickerDef('fire', icon: Icons.local_fire_department_rounded),
  'gem': StickerDef('gem', icon: Icons.diamond_rounded),
  'crown': StickerDef('crown', icon: Icons.workspace_premium_rounded),
  'bolt': StickerDef('bolt', icon: Icons.bolt_rounded),
  'new': StickerDef('new', textLabel: 'NEW'),
  'hot': StickerDef('hot', textLabel: 'HOT'),
  'sale': StickerDef('sale', textLabel: 'SALE'),
  'free': StickerDef('free', textLabel: 'FREE'),
};


class LabelElement {
  final String id;
  LabelElementType type;
  Offset position;
  Size size;
  double rotation;
  String content;
  String? imagePath;
  double fontSize;
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
  int colorValue;
  double strokeWidth;
  String barcodeType;
  bool liveTime;
  double opacity;
  int zIndex;
  String fontFamily;
  String encoding;
  String prefix;
  String suffix;
  int startValue;
  int interval;
  bool serialEnabled;
  int timeOffsetMinutes;
  String dateFormat;
  String timeFormat;
  TextAlign textAlign;
  double letterSpacing;
  double lineHeightMultiplier;
  bool coloredCode;
  double codeScale;
  TextAlign codeAlign;
  BarcodeStyle barcodeStyle;
  bool autoFit;
  double cornerRadius;
  bool shadowEnabled;
  double shadowBlur;
  Offset shadowOffset;
  Color shadowColor;
  QrShape qrShape;
  bool qrShowLogo;
  String? qrLogoPath;

  LabelElement({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0,
    required this.content,
    this.imagePath,
    this.fontSize = 20,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.colorValue = 0xFF000000,
    this.strokeWidth = 1.5,
    this.barcodeType = 'code128',
    this.liveTime = true,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.fontFamily = 'Default',
    this.encoding = 'UTF-8',
    this.prefix = '',
    this.suffix = '',
    this.startValue = 1,
    this.interval = 1,
    this.serialEnabled = false,
    this.timeOffsetMinutes = 0,
    this.dateFormat = 'yyyy/MM/dd',
    this.timeFormat = 'HH:mm:ss',
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0,
    this.lineHeightMultiplier = 1.2,
    this.coloredCode = false,
    this.codeScale = 4.5,
    this.codeAlign = TextAlign.center,
    this.barcodeStyle = BarcodeStyle.normal,
    this.autoFit = false,
    this.cornerRadius = 0,
    this.shadowEnabled = false,
    this.shadowBlur = 8,
    this.shadowOffset = const Offset(2, 2),
    this.shadowColor = const Color(0x33000000),
    this.qrShape = QrShape.square,
    this.qrShowLogo = false,
    this.qrLogoPath,
  });

  Color get color => Color(colorValue).withValues(alpha: opacity);

  String displayContentForIndex(int index) {
    if (serialEnabled) {
      final val = startValue + (index * interval);
      return '$prefix$val$suffix';
    }
    return content;
  }

  LabelElement deepClone({String? newId}) {
    return LabelElement(
      id: newId ?? id, type: type, position: position, size: size,
      rotation: rotation, content: content, imagePath: imagePath,
      fontSize: fontSize, bold: bold, italic: italic, underline: underline,
      strikethrough: strikethrough, colorValue: colorValue, strokeWidth: strokeWidth,
      barcodeType: barcodeType, liveTime: liveTime, opacity: opacity, zIndex: zIndex,
      fontFamily: fontFamily, encoding: encoding, prefix: prefix,
      suffix: suffix, startValue: startValue, interval: interval,
      serialEnabled: serialEnabled, timeOffsetMinutes: timeOffsetMinutes,
      dateFormat: dateFormat, timeFormat: timeFormat, textAlign: textAlign,
      letterSpacing: letterSpacing, lineHeightMultiplier: lineHeightMultiplier,
      coloredCode: coloredCode, codeScale: codeScale, codeAlign: codeAlign,
      barcodeStyle: barcodeStyle, autoFit: autoFit, cornerRadius: cornerRadius,
      shadowEnabled: shadowEnabled, shadowBlur: shadowBlur, shadowOffset: shadowOffset,
      shadowColor: shadowColor, qrShape: qrShape, qrShowLogo: qrShowLogo, qrLogoPath: qrLogoPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'x': position.dx, 'y': position.dy,
    'w': size.width, 'h': size.height, 'rotation': rotation, 'content': content,
    'imagePath': imagePath, 'fontSize': fontSize, 'bold': bold, 'italic': italic,
    'underline': underline, 'strikethrough': strikethrough, 'colorValue': colorValue,
    'strokeWidth': strokeWidth, 'barcodeType': barcodeType, 'liveTime': liveTime,
    'opacity': opacity, 'zIndex': zIndex, 'fontFamily': fontFamily,
    'encoding': encoding, 'prefix': prefix, 'suffix': suffix,
    'startValue': startValue, 'interval': interval, 'serialEnabled': serialEnabled,
    'timeOffsetMinutes': timeOffsetMinutes, 'dateFormat': dateFormat,
    'timeFormat': timeFormat, 'textAlign': textAlign.name,
    'letterSpacing': letterSpacing, 'lineHeightMultiplier': lineHeightMultiplier,
    'coloredCode': coloredCode, 'codeScale': codeScale,
    'codeAlign': codeAlign.name, 'barcodeStyle': barcodeStyle.name,
    'autoFit': autoFit, 'cornerRadius': cornerRadius,
    'shadowEnabled': shadowEnabled, 'shadowBlur': shadowBlur,
    'shadowOffsetX': shadowOffset.dx, 'shadowOffsetY': shadowOffset.dy,
    'shadowColor': shadowColor.value, 'qrShape': qrShape.name,
    'qrShowLogo': qrShowLogo, 'qrLogoPath': qrLogoPath,
  };

  static LabelElement fromJson(Map<String, dynamic> json) {
    return LabelElement(
      id: json['id'] as String,
      type: LabelElementType.values.byName(json['type'] as String),
      position: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
      size: Size((json['w'] as num).toDouble(), (json['h'] as num).toDouble()),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      content: json['content'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.5,
      barcodeType: json['barcodeType'] as String? ?? 'code128',
      liveTime: json['liveTime'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] as int? ?? 0,
      fontFamily: json['fontFamily'] as String? ?? 'Default',
      encoding: json['encoding'] as String? ?? 'UTF-8',
      prefix: json['prefix'] as String? ?? '',
      suffix: json['suffix'] as String? ?? '',
      startValue: json['startValue'] as int? ?? 1,
      interval: json['interval'] as int? ?? 1,
      serialEnabled: json['serialEnabled'] as bool? ?? false,
      timeOffsetMinutes: json['timeOffsetMinutes'] as int? ?? 0,
      dateFormat: json['dateFormat'] as String? ?? 'yyyy/MM/dd',
      timeFormat: json['timeFormat'] as String? ?? 'HH:mm:ss',
      textAlign: TextAlign.values.byName(json['textAlign'] as String? ?? 'left'),
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
      lineHeightMultiplier: (json['lineHeightMultiplier'] as num?)?.toDouble() ?? 1.2,
      coloredCode: json['coloredCode'] as bool? ?? false,
      codeScale: (json['codeScale'] as num?)?.toDouble() ?? 4.5,
      codeAlign: TextAlign.values.byName(json['codeAlign'] as String? ?? 'center'),
      barcodeStyle: BarcodeStyle.values.byName(json['barcodeStyle'] as String? ?? 'normal'),
      autoFit: json['autoFit'] as bool? ?? false,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
      shadowEnabled: json['shadowEnabled'] as bool? ?? false,
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 8,
      shadowOffset: Offset((json['shadowOffsetX'] as num?)?.toDouble() ?? 2, (json['shadowOffsetY'] as num?)?.toDouble() ?? 2),
      shadowColor: Color(json['shadowColor'] as int? ?? 0x33000000),
      qrShape: QrShape.values.byName(json['qrShape'] as String? ?? 'square'),
      qrShowLogo: json['qrShowLogo'] as bool? ?? false,
      qrLogoPath: json['qrLogoPath'] as String?,
    );
  }
}

class LabelEditorScreen extends StatefulWidget {
  final LabelSizeResult? labelSize;
  final String? initialBarcodeValue;
  const LabelEditorScreen({super.key, this.labelSize, this.initialBarcodeValue});

  @override
  State<LabelEditorScreen> createState() => _LabelEditorScreenState();
}

class _LabelEditorScreenState extends State<LabelEditorScreen> {
  static const double _mmToPx = 3.6;
  static const String _prefsKey = 'joyn_label_layout_v1';
  static const double _snapThreshold = 6;

  late Size _labelSizeMm;
  Size get _canvasSize => Size(_labelSizeMm.width * _mmToPx, _labelSizeMm.height * _mmToPx);

  final GlobalKey _canvasKey = GlobalKey();
  final List<LabelElement> _elements = [];
  final List<List<LabelElement>> _undoStack = [];
  final List<List<LabelElement>> _redoStack = [];
  final PageController _toolPageController = PageController();

  String? _selectedId;
  int _idCounter = 0;
  int _serialCounter = 1;
  int _toolPageIndex = 0;
  bool _snapCenterX = false;
  bool _snapCenterY = false;
  bool _isBusy = false;
  bool _showGrid = true;
  Timer? _liveTimer;
  List<Map<String, dynamic>> _importedRows = [];
  int _batchRowIndex = 0;

  LabelElement? get _selected => _selectedId == null ? null : _elements.firstWhere((e) => e.id == _selectedId);

  @override
  void initState() {
    super.initState();
    _labelSizeMm = Size(widget.labelSize?.widthMm ?? 100, widget.labelSize?.heightMm ?? 150);

    if (widget.initialBarcodeValue != null && widget.initialBarcodeValue!.isNotEmpty) {
      _elements.add(LabelElement(id: _nextId(), type: LabelElementType.barcode, position: const Offset(16, 16), size: const Size(280, 110), content: widget.initialBarcodeValue!));
    } else {
      _loadSavedLayout();
    }

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;
      for (final e in _elements) {
        if (e.type == LabelElementType.time && e.liveTime) {
          final dt = DateTime.now().add(Duration(minutes: e.timeOffsetMinutes));
          final formatted = formatLabelDateTime(dt, datePattern: e.dateFormat, timePattern: e.timeFormat);
          if (e.content != formatted) { e.content = formatted; changed = true; }
        }
      }
      if (changed && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _toolPageController.dispose();
    super.dispose();
  }

  String _nextId() => 'el_${_idCounter++}';

  Future<void> _loadSavedLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).map((m) => LabelElement.fromJson(m as Map<String, dynamic>)).toList();
      int maxIndex = -1;
      for (final e in list) {
        final match = RegExp(r'el_(\d+)').firstMatch(e.id);
        if (match != null) { final n = int.tryParse(match.group(1)!) ?? -1; if (n > maxIndex) maxIndex = n; }
      }
      if (!mounted) return;
      setState(() { _elements..clear()..addAll(list); _idCounter = maxIndex + 1; });
    } catch (e) { debugPrint('Load failed: $e'); }
  }

  Future<void> _saveLayout() async {
    setState(() => _isBusy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_elements.map((e) => e.toJson()).toList()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Layout saved'), behavior: SnackBarBehavior.floating, backgroundColor: JoynColors.primary));
    } finally { if (mounted) setState(() => _isBusy = false); }
  }

  List<LabelElement> _snapshot() => _elements.map((e) => e.deepClone()).toList();
  void _pushHistory() { _undoStack.add(_snapshot()); _redoStack.clear(); if (_undoStack.length > 50) _undoStack.removeAt(0); }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() { _redoStack.add(_snapshot()); final prev = _undoStack.removeLast(); _elements..clear()..addAll(prev); _selectedId = null; });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() { _undoStack.add(_snapshot()); final next = _redoStack.removeLast(); _elements..clear()..addAll(next); _selectedId = null; });
  }

  Future<void> _addElement(LabelElementType type) async {
    if (type == LabelElementType.image) {
      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      _pushHistory();
      final el = LabelElement(id: _nextId(), type: type, position: const Offset(40, 40), size: const Size(140, 140), content: '', imagePath: picked.path, zIndex: _elements.length);
      setState(() { _elements.add(el); _selectedId = el.id; });
      return;
    }

    _pushHistory();
    final now = DateTime.now();
    late LabelElement el;
    switch (type) {
      case LabelElementType.text: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 140), size: const Size(170, 40), content: 'Sample text', zIndex: _elements.length); break;
      case LabelElementType.qrCode: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 190), size: const Size(100, 100), content: 'QR-DATA', zIndex: _elements.length); break;
      case LabelElementType.barcode: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 300), size: const Size(280, 110), content: '0000000000000', zIndex: _elements.length); break;
      case LabelElementType.time: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 420), size: const Size(190, 30), content: formatLabelDateTime(now), zIndex: _elements.length); break;
      case LabelElementType.line: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 460), size: const Size(200, 4), content: '', zIndex: _elements.length); break;
      case LabelElementType.rectangle: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 480), size: const Size(120, 80), content: '', zIndex: _elements.length); break;
      case LabelElementType.circle: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 480), size: const Size(80, 80), content: '', zIndex: _elements.length); break;
      case LabelElementType.serial: el = LabelElement(id: _nextId(), type: type, position: const Offset(20, 500), size: const Size(140, 34), content: (_serialCounter++).toString().padLeft(4, '0'), zIndex: _elements.length); break;
      case LabelElementType.sticker:
      case LabelElementType.logo:
      case LabelElementType.database:
      case LabelElementType.image:
        return;
    }
    setState(() { _elements.add(el); _selectedId = el.id; });
  }

  void _deleteElement(String id) { _pushHistory(); setState(() { _elements.removeWhere((e) => e.id == id); if (_selectedId == id) _selectedId = null; }); }

  void _duplicateElement(String id) {
    _pushHistory();
    final original = _elements.firstWhere((e) => e.id == id);
    final clone = original.deepClone(newId: _nextId());
    clone.position = original.position + const Offset(14, 14);
    clone.zIndex = _elements.length;
    setState(() { _elements.add(clone); _selectedId = clone.id; });
  }

  void _rotateSelected() { if (_selectedId == null) return; _pushHistory(); setState(() => _selected!.rotation += 1.5708); }
  void _bringToFront() { if (_selectedId == null) return; _pushHistory(); setState(() { final el = _selected!; _elements.remove(el); el.zIndex = _elements.length; _elements.add(el); }); }
  void _sendToBack() { if (_selectedId == null) return; _pushHistory(); setState(() { final el = _selected!; _elements.remove(el); el.zIndex = -1; _elements.insert(0, el); }); }

  void _clearCanvas() {
    if (_elements.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(4))),
            Padding(padding: const EdgeInsets.all(16), child: Text('Clear label?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: JoynColors.error), title: const Text('Clear All Elements'), onTap: () { _pushHistory(); setState(() { _elements.clear(); _selectedId = null; }); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.close_rounded, color: JoynColors.secondaryText), title: const Text('Cancel'), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickQrLogo(LabelElement el) async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      el.qrLogoPath = picked.path;
      el.qrShowLogo = true;
    });
  }

  void _showElementSettings(LabelElement el) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Element Settings', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: TextEditingController(text: el.content),
                    onChanged: (val) => setSheetState(() => el.content = val),
                    decoration: InputDecoration(labelText: 'Content', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 12),

                  if (el.type == LabelElementType.qrCode || el.type == LabelElementType.barcode) ...[
                    SwitchListTile(
                      title: const Text('Serial Number'),
                      value: el.serialEnabled,
                      onChanged: (v) => setSheetState(() => el.serialEnabled = v),
                      activeColor: JoynColors.primary,
                    ),
                    if (el.serialEnabled) ...[
                      _propertyField('Prefix', el.prefix, (val) => setSheetState(() => el.prefix = val)),
                      _propertyField('Suffix', el.suffix, (val) => setSheetState(() => el.suffix = val)),
                      _propertyField('Start Value', el.startValue.toString(), (val) => setSheetState(() => el.startValue = int.tryParse(val) ?? 1)),
                      _propertyField('Interval', el.interval.toString(), (val) => setSheetState(() => el.interval = int.tryParse(val) ?? 1)),
                      _propertyDropdown('Encoding', el.encoding, _kEncodings, (val) => setSheetState(() => el.encoding = val)),
                    ],
                  ],

                  if (el.type == LabelElementType.qrCode) ...[
                    _propertyDropdown('QR Shape', el.qrShape.name, ['square', 'circle', 'roundedRect'], (val) => setSheetState(() => el.qrShape = QrShape.values.byName(val))),
                    SwitchListTile(
                      title: const Text('Show Logo'),
                      value: el.qrShowLogo,
                      onChanged: (v) => setSheetState(() => el.qrShowLogo = v),
                      activeColor: JoynColors.primary,
                    ),
                    if (el.qrShowLogo)
                      ElevatedButton.icon(
                        onPressed: () => _pickQrLogo(el),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Pick Logo'),
                      ),
                  ],

                  if (el.type == LabelElementType.barcode) ...[
                    _propertyDropdown('Barcode Type', el.barcodeType, _kBarcodeTypes, (val) => setSheetState(() => el.barcodeType = val)),
                    _propertyDropdown('Style', el.barcodeStyle.name, ['normal', 'isometric'], (val) => setSheetState(() => el.barcodeStyle = BarcodeStyle.values.byName(val))),
                  ],

                  if (el.type == LabelElementType.text || el.type == LabelElementType.serial) ...[
                    _propertyField('Font Size', el.fontSize.toString(), (val) => setSheetState(() => el.fontSize = double.tryParse(val) ?? 20)),
                    _propertyDropdown('Font Family', el.fontFamily, _kFontFamilies, (val) => setSheetState(() => el.fontFamily = val)),
                    _propertyDropdown('Align', el.textAlign.name, ['left', 'center', 'right', 'justify'], (val) => setSheetState(() => el.textAlign = TextAlign.values.byName(val))),
                  ],

                  SwitchListTile(
                    title: const Text('Shadow'),
                    value: el.shadowEnabled,
                    onChanged: (v) => setSheetState(() => el.shadowEnabled = v),
                    activeColor: JoynColors.primary,
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () { _pushHistory(); setState(() {}); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _propertyField(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      ),
    );
  }

  Widget _propertyDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: JoynColors.border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (val) { if (val != null) onChanged(val); },
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _captureCanvasAsPng() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) { return null; }
  }

  Future<void> _printViaSystem() async {
    setState(() { _selectedId = null; _isBusy = true; });
    await Future.delayed(const Duration(milliseconds: 80));
    final bytes = await _captureCanvasAsPng();
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (bytes == null) return;
    final pdf = pw.Document();
    final image = pw.MemoryImage(bytes);
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat(_labelSizeMm.width * PdfPageFormat.mm, _labelSizeMm.height * PdfPageFormat.mm), build: (context) => pw.Center(child: pw.Image(image))));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'label_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  void _showPrintOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(4))),
            Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text('Print label', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
            ListTile(leading: const Icon(Icons.print_outlined, color: JoynColors.primary), title: const Text('System print / PDF'), onTap: () { Navigator.pop(context); _printViaSystem(); }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openExcelImport() {
    final demoRows = [
      {'Name': 'Item 1', 'Price': '₹100', 'Qty': '5'},
      {'Name': 'Item 2', 'Price': '₹200', 'Qty': '3'},
      {'Name': 'Item 3', 'Price': '₹150', 'Qty': '2'},
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import from Excel', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Use sample data to test batch printing.', style: JoynTypography.subtitle.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF7C3AED)), title: const Text('Use Sample Data'), subtitle: Text('Import ${demoRows.length} demo rows'), onTap: () { Navigator.pop(context); setState(() => _importedRows = demoRows); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaterialLibrary() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Material Library', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kStickerLibrary.entries.map((entry) {
                  final def = entry.value;
                  return InkWell(
                    onTap: () => Navigator.pop(context, entry.key),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border)),
                      child: def.icon != null ? Icon(def.icon, size: 28, color: JoynColors.primary) : Center(child: Text(def.textLabel ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.add_photo_alternate_outlined, color: JoynColors.primary), title: const Text('Add from Gallery'), onTap: () { Navigator.pop(context); _addElement(LabelElementType.image); }),
            ],
          ),
        ),
      ),
    ).then((key) {
      if (key != null && mounted) {
        _pushHistory();
        final el = LabelElement(id: _nextId(), type: LabelElementType.sticker, position: const Offset(40, 40), size: const Size(90, 90), content: key, zIndex: _elements.length);
        setState(() { _elements.add(el); _selectedId = el.id; });
      }
    });
  }

  Offset _applyCenterSnap(Offset position, Size size) {
    final elCenter = position + Offset(size.width / 2, size.height / 2);
    final canvasCenter = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    double dx = position.dx, dy = position.dy;
    _snapCenterX = (elCenter.dx - canvasCenter.dx).abs() < _snapThreshold;
    _snapCenterY = (elCenter.dy - canvasCenter.dy).abs() < _snapThreshold;
    if (_snapCenterX) dx = canvasCenter.dx - size.width / 2;
    if (_snapCenterY) dy = canvasCenter.dy - size.height / 2;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: Text('Label Editor', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.undo_rounded), onPressed: _undoStack.isEmpty ? null : _undo),
          IconButton(icon: const Icon(Icons.redo_rounded), onPressed: _redoStack.isEmpty ? null : _redo),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _isBusy ? null : _saveLayout),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : _showPrintOptions,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            height: 52,
            decoration: BoxDecoration(color: JoynColors.background, border: Border(bottom: BorderSide(color: JoynColors.border))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _toolbarChip('${_labelSizeMm.width.toInt()}x${_labelSizeMm.height.toInt()}mm', Icons.straighten_rounded),
                  const SizedBox(width: 4),
                  _toolbarIcon(Icons.grid_on_rounded, _showGrid, () => setState(() => _showGrid = !_showGrid)),
                  _toolbarIcon(Icons.cleaning_services_outlined, false, _clearCanvas),
                  if (_selectedId != null) ...[
                    _toolbarIcon(Icons.rotate_right_rounded, false, _rotateSelected),
                    _toolbarIcon(Icons.flip_to_front_rounded, false, _bringToFront),
                    _toolbarIcon(Icons.flip_to_back_rounded, false, _sendToBack),
                    _toolbarIcon(Icons.settings_rounded, false, () => _showElementSettings(_selected!)),
                  ],
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: JoynColors.background,
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5, maxScale: 3,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedId = null),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        width: _canvasSize.width,
                        height: _canvasSize.height,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: _Premium.cardShadow),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ..._elements.map((el) => _buildElementView(el)),
                            if (_snapCenterX) Positioned(left: _canvasSize.width / 2, top: 0, bottom: 0, child: Container(width: 1, color: JoynColors.primary)),
                            if (_snapCenterY) Positioned(top: _canvasSize.height / 2, left: 0, right: 0, child: Container(height: 1, color: JoynColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Container(height: 1, color: JoynColors.border),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(gradient: _Premium.surfaceGradient),
            child: SizedBox(
              height: 80,
              child: PageView(
                controller: _toolPageController,
                onPageChanged: (i) => setState(() => _toolPageIndex = i),
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _toolButton(Icons.title_rounded, 'Text', () => _addElement(LabelElementType.text)),
                    _toolButton(Icons.qr_code_2_rounded, 'QR Code', () => _addElement(LabelElementType.qrCode)),
                    _toolButton(Icons.view_week_outlined, 'Barcode', () => _addElement(LabelElementType.barcode)),
                    _toolButton(Icons.access_time_rounded, 'Time', () => _addElement(LabelElementType.time)),
                    _toolButton(Icons.emoji_emotions_outlined, 'Material', _showMaterialLibrary),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _toolButton(Icons.horizontal_rule_rounded, 'Line', () => _addElement(LabelElementType.line)),
                    _toolButton(Icons.crop_square_rounded, 'Shape', () => _addElement(LabelElementType.rectangle)),
                    _toolButton(Icons.circle_outlined, 'Circle', () => _addElement(LabelElementType.circle)),
                    _toolButton(Icons.image_outlined, 'Image', () => _addElement(LabelElementType.image)),
                    _toolButton(Icons.tag_rounded, 'Serial No.', () => _addElement(LabelElementType.serial)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _toolButton(Icons.table_chart_outlined, 'Excel', _openExcelImport),
                  ]),
                ],
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) {
            final active = i == _toolPageIndex;
            return AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 3), width: active ? 16 : 6, height: 6, decoration: BoxDecoration(color: active ? JoynColors.primary : JoynColors.border, borderRadius: BorderRadius.circular(3)));
          })),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _toolbarChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: JoynColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: JoynColors.secondaryText), const SizedBox(width: 4), Text(label, style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.primary))]),
    );
  }

  Widget _toolbarIcon(IconData icon, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: active ? JoynColors.primary.withValues(alpha: 0.1) : JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: active ? JoynColors.primary : JoynColors.secondaryText)),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: JoynColors.border), boxShadow: _Premium.fieldShadow), child: Icon(icon, color: JoynColors.primary, size: 21)),
          const SizedBox(height: 6),
          Text(label, style: JoynTypography.caption.copyWith(fontSize: 10, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildElementView(LabelElement el) {
    final isSelected = el.id == _selectedId;
    return Positioned(
      left: el.position.dx,
      top: el.position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = el.id),
        onDoubleTap: () => _showElementSettings(el),
        onPanStart: (_) => _pushHistory(),
        onPanUpdate: (details) => setState(() { el.position = _applyCenterSnap(el.position + details.delta, el.size); }),
        onPanEnd: (_) => setState(() { _snapCenterX = false; _snapCenterY = false; }),
        child: Transform.rotate(
          angle: el.rotation,
          child: Opacity(
            opacity: el.opacity,
            child: Container(
              width: el.size.width,
              height: el.size.height,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? JoynColors.primary : Colors.transparent, width: 1.4),
                boxShadow: el.shadowEnabled ? [BoxShadow(color: el.shadowColor, blurRadius: el.shadowBlur, offset: el.shadowOffset)] : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _buildElementContent(el)),
                  if (isSelected) ...[
                    Positioned(left: -14, top: -14, child: _handleButton(Icons.delete_outline_rounded, () => _deleteElement(el.id))),
                    Positioned(right: -14, top: -14, child: _handleButton(Icons.copy_rounded, () => _duplicateElement(el.id))),
                    Positioned(right: -14, bottom: -14, child: GestureDetector(onPanStart: (_) => _pushHistory(), onPanUpdate: (details) => setState(() { el.size = Size((el.size.width + details.delta.dx).clamp(24, _canvasSize.width), (el.size.height + details.delta.dy).clamp(24, _canvasSize.height)); }), child: _handleButton(Icons.open_in_full_rounded, null))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _handleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 28, height: 28, decoration: BoxDecoration(gradient: _Premium.gradient(JoynColors.primary), shape: BoxShape.circle, boxShadow: _Premium.floatingShadow(JoynColors.primary)), child: Icon(icon, size: 15, color: Colors.white)),
    );
  }

  Widget _buildElementContent(LabelElement el) {
    final displayContent = el.displayContentForIndex(_batchRowIndex);
    switch (el.type) {
      case LabelElementType.text:
        return FittedBox(fit: BoxFit.scaleDown, child: Text(displayContent, textAlign: el.textAlign, style: TextStyle(fontSize: el.fontSize, color: el.color, fontWeight: el.bold ? FontWeight.w700 : FontWeight.w400, fontStyle: el.italic ? FontStyle.italic : FontStyle.normal, decoration: el.underline ? TextDecoration.underline : el.strikethrough ? TextDecoration.lineThrough : TextDecoration.none, letterSpacing: el.letterSpacing, height: el.lineHeightMultiplier, fontFamily: el.fontFamily == 'Default' ? null : el.fontFamily)));
      case LabelElementType.time:
        return FittedBox(fit: BoxFit.scaleDown, child: Text(el.content, style: TextStyle(fontSize: el.fontSize, color: el.color, fontWeight: el.bold ? FontWeight.w700 : FontWeight.w400)));
      case LabelElementType.serial:
        return FittedBox(fit: BoxFit.scaleDown, child: Text('#${displayContent}', style: TextStyle(fontSize: el.fontSize, color: el.color, fontWeight: FontWeight.w600)));
      case LabelElementType.qrCode:
        return QrImageView(data: displayContent.isEmpty ? ' ' : displayContent, backgroundColor: Colors.white, eyeStyle: QrEyeStyle(color: el.coloredCode ? el.color : Colors.black), dataModuleStyle: QrDataModuleStyle(color: el.coloredCode ? el.color : Colors.black));
      case LabelElementType.barcode:
        final valid = isValidBarcodeData(el.barcodeType, displayContent);
        if (!valid) return Container(alignment: Alignment.center, child: const Text('Invalid data', style: TextStyle(color: Colors.red, fontSize: 10)));
        final barcodeWidget = BarcodeWidget(barcode: barcodeFor(el.barcodeType), data: displayContent, drawText: true, color: el.coloredCode ? el.color : Colors.black);
        if (el.barcodeStyle == BarcodeStyle.isometric) {
          return Transform(alignment: FractionalOffset.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateX(0.35)..rotateZ(-0.08), child: barcodeWidget);
        }
        return barcodeWidget;
      case LabelElementType.line:
        return Container(color: el.color);
      case LabelElementType.rectangle:
        return Container(decoration: BoxDecoration(border: Border.all(color: el.color, width: el.strokeWidth), borderRadius: BorderRadius.circular(el.cornerRadius)));
      case LabelElementType.circle:
        return Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: el.color, width: el.strokeWidth)));
      case LabelElementType.image:
        return el.imagePath == null ? Container(color: JoynColors.chipBackground) : Image.file(File(el.imagePath!), fit: BoxFit.contain);
      case LabelElementType.sticker:
        final def = kStickerLibrary[el.content];
        if (def == null) return const SizedBox();
        if (def.icon != null) return FittedBox(child: Icon(def.icon, color: el.color));
        return FittedBox(child: Text(def.textLabel!, textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: el.color)));
      case LabelElementType.logo:
        return el.imagePath == null ? const Icon(Icons.business_center_rounded, size: 40) : Image.file(File(el.imagePath!), fit: BoxFit.contain);
      case LabelElementType.database:
        return Container(alignment: Alignment.center, child: Text('DB', style: TextStyle(fontSize: el.fontSize, color: el.color, fontWeight: FontWeight.bold)));
    }
  }
}

String formatLabelDateTime(DateTime dt, {String datePattern = 'yyyy/MM/dd', String timePattern = 'HH:mm:ss'}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date = datePattern.replaceAll('yyyy', dt.year.toString()).replaceAll('MM', two(dt.month)).replaceAll('dd', two(dt.day));
  final time = timePattern.replaceAll('HH', two(dt.hour)).replaceAll('mm', two(dt.minute)).replaceAll('ss', two(dt.second));
  return '$date $time';
}

bool isValidBarcodeData(String type, String data) {
  if (data.isEmpty) return false;
  switch (type) {
    case 'ean13': return RegExp(r'^\d{12,13}$').hasMatch(data);
    case 'ean8': return RegExp(r'^\d{7,8}$').hasMatch(data);
    case 'upcA': return RegExp(r'^\d{11,12}$').hasMatch(data);
    case 'upcE': return RegExp(r'^\d{6,8}$').hasMatch(data);
    case 'code39': return RegExp(r'^[A-Za-z0-9\-. $/+%]+$').hasMatch(data);
    case 'itf': return RegExp(r'^\d+$').hasMatch(data);
    case 'codabar': return RegExp(r'^[0-9\-:$/.+]+$').hasMatch(data);
    case 'isbn': return RegExp(r'^[\d\-Xx]+$').hasMatch(data);
    default: return true;
  }
}

Barcode barcodeFor(String type) {
  switch (type) {
    case 'ean13': return Barcode.ean13();
    case 'ean8': return Barcode.ean8();
    case 'upcA': return Barcode.upcA();
    case 'upcE': return Barcode.upcE();
    case 'code39': return Barcode.code39();
    case 'itf': return Barcode.itf();
    case 'codabar': return Barcode.codabar();
    case 'isbn': return Barcode.isbn();
    default: return Barcode.code128();
  }
}