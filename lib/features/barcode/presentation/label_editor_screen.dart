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

// ═══════════════════════════════════════════════════════════════
//  PREMIUM HELPERS
// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
//  ENUMS + CONSTANTS
// ═══════════════════════════════════════════════════════════════
enum LabelElementType { text, qrCode, barcode, time, line, rectangle, circle, image, serial, sticker, logo, database }
enum BarcodeStyle { normal, isometric }
enum QrShape { square, circle, roundedRect }
enum LineStyle { solid, dashed, dotted }
enum BorderStyleMode { solid, dashed, dotted, none }
enum GridStyle { off, dots, lines }
enum QuickPalette { classic, warm, cool, nature, pastel, mono, neon, ocean, sunset, forest, royalty, minimal }

// ─── Border Enums ───
enum LabelBorderCategory { mine, diagonal, parallel, line, circle, ratio46 }

enum LabelBorderStyle {
  none,
  diagonalOrnament1, diagonalOrnament2, diagonalOrnament3, diagonalOrnament4,
  diagonalOrnament5, diagonalOrnament6, diagonalOrnament7, diagonalOrnament8,
  parallelDouble, parallelTriple, parallelDashed, parallelDotted,
  lineTopBottom, lineAllSides, lineLeft, lineRight,
  circleDots, circleLine, circleDouble,
  ratio46Simple, ratio46Double, ratio46Ornate,
}

enum ShapeKind { line, circle, ellipse, square }
enum ShapeStrokeStyle { solid, dashed, dotted, longDash, dashDot }

const _kSwatches = <Color>[
  Colors.black, Color(0xFFE53935), Color(0xFF1E88E5),
  Color(0xFF14B85C), Color(0xFFFF8F00), Color(0xFF7C3AED),
  Color(0xFF795548), Color(0xFF607D8B), Color(0xFF9E9E9E),
  Colors.white, Color(0xFFFFEB3B), Color(0xFF00BCD4),
  Color(0xFFE91E63), Color(0xFF8BC34A), Color(0xFFFF5722),
  Color(0xFF673AB7), Color(0xFF009688),
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

const _kDateFormats = <String>[
  'yyyy/MM/dd', 'dd/MM/yyyy', 'MM/dd/yyyy',
  'dd-MM-yyyy', 'yyyy-MM-dd', 'dd MMM yyyy',
  'EEE, dd MMM', 'MMMM dd, yyyy',
];

const _kTimeFormats = <String>[
  'HH:mm:ss', 'HH:mm', 'hh:mm a', 'HH:mm:ss.SSS',
];

const _kFontWeights = <int>[100, 200, 300, 400, 500, 600, 700, 800, 900];

// ─── Material Library ───
class MaterialItem {
  final String key;
  final IconData? icon;
  final String? emoji;
  final String? text;
  const MaterialItem(this.key, {this.icon, this.emoji, this.text});
}

class MaterialCategory {
  final String name;
  final List<MaterialItem> items;
  const MaterialCategory(this.name, this.items);
}

const kMaterialCategories = <MaterialCategory>[
  MaterialCategory("Mine", [
    MaterialItem('m_star', icon: Icons.star_rounded),
    MaterialItem('m_heart', icon: Icons.favorite_rounded),
    MaterialItem('m_check', icon: Icons.check_circle_rounded),
    MaterialItem('m_fire', icon: Icons.local_fire_department_rounded),
    MaterialItem('m_gem', icon: Icons.diamond_rounded),
    MaterialItem('m_crown', icon: Icons.workspace_premium_rounded),
  ]),
  MaterialCategory("Valentine's", [
    MaterialItem('v_heart1', emoji: '❤️'),
    MaterialItem('v_heart2', emoji: '💕'),
    MaterialItem('v_heart3', emoji: '💖'),
    MaterialItem('v_heart4', emoji: '💝'),
    MaterialItem('v_cupid', emoji: '💘'),
    MaterialItem('v_kiss', emoji: '💋'),
    MaterialItem('v_rose', emoji: '🌹'),
    MaterialItem('v_lock', emoji: '🔐'),
    MaterialItem('v_key', emoji: '🔑'),
    MaterialItem('v_ring', emoji: '💍'),
  ]),
  MaterialCategory("Shoes", [
    MaterialItem('s_shoe1', emoji: '👟'),
    MaterialItem('s_shoe2', emoji: '👞'),
    MaterialItem('s_shoe3', emoji: '👠'),
    MaterialItem('s_shoe4', emoji: '🥾'),
    MaterialItem('s_shoe5', emoji: '👢'),
    MaterialItem('s_sandal', emoji: '🩴'),
  ]),
  MaterialCategory("Logistics", [
    MaterialItem('l_box', emoji: '📦'),
    MaterialItem('l_truck', emoji: '🚚'),
    MaterialItem('l_ship', emoji: '🚢'),
    MaterialItem('l_plane', emoji: '✈️'),
    MaterialItem('l_pin', emoji: '📍'),
    MaterialItem('l_hand', emoji: '🤝'),
    MaterialItem('l_warehouse', icon: Icons.warehouse_rounded),
    MaterialItem('l_local', icon: Icons.local_shipping_rounded),
    MaterialItem('l_qr', icon: Icons.qr_code_scanner_rounded),
    MaterialItem('l_barcode', icon: Icons.qr_code_rounded),
  ]),
  MaterialCategory("Washing", [
    MaterialItem('w_hand', emoji: '🤲'),
    MaterialItem('w_bleach', icon: Icons.water_drop_rounded),
    MaterialItem('w_iron', icon: Icons.iron_rounded),
    MaterialItem('w_dry', icon: Icons.dry_cleaning_rounded),
    MaterialItem('w_sun', emoji: '☀️'),
    MaterialItem('w_temp', icon: Icons.thermostat_rounded),
  ]),
  MaterialCategory("Food", [
    MaterialItem('f_pizza', emoji: '🍕'),
    MaterialItem('f_burger', emoji: '🍔'),
    MaterialItem('f_coffee', emoji: '☕'),
    MaterialItem('f_cake', emoji: '🎂'),
    MaterialItem('f_ice', emoji: '🍦'),
    MaterialItem('f_veg', emoji: '🥦'),
    MaterialItem('f_fruit', emoji: '🍎'),
  ]),
  MaterialCategory("Characters", [
    MaterialItem('c_smile', emoji: '😀'),
    MaterialItem('c_love', emoji: '😍'),
    MaterialItem('c_wink', emoji: '😉'),
    MaterialItem('c_cool', emoji: '😎'),
    MaterialItem('c_party', emoji: '🥳'),
    MaterialItem('c_think', emoji: '🤔'),
    MaterialItem('c_star', emoji: '🌟'),
  ]),
  MaterialCategory("Symbols", [
    MaterialItem('sy_check', emoji: '✅'),
    MaterialItem('sy_cross', emoji: '❌'),
    MaterialItem('sy_warn', emoji: '⚠️'),
    MaterialItem('sy_info', emoji: 'ℹ️'),
    MaterialItem('sy_star', emoji: '⭐'),
    MaterialItem('sy_arrow', emoji: '➡️'),
    MaterialItem('sy_recycle', emoji: '♻️'),
    MaterialItem('sy_bio', emoji: '☣️'),
  ]),
  MaterialCategory("Vegetable", [
    MaterialItem('vg_carrot', emoji: '🥕'),
    MaterialItem('vg_tomato', emoji: '🍅'),
    MaterialItem('vg_corn', emoji: '🌽'),
    MaterialItem('vg_pepper', emoji: '🌶️'),
    MaterialItem('vg_onion', emoji: '🧅'),
    MaterialItem('vg_potato', emoji: '🥔'),
  ]),
  MaterialCategory("Beverage", [
    MaterialItem('b_soda', emoji: '🥤'),
    MaterialItem('b_beer', emoji: '🍺'),
    MaterialItem('b_wine', emoji: '🍷'),
    MaterialItem('b_juice', emoji: '🧃'),
    MaterialItem('b_tea', emoji: '🍵'),
    MaterialItem('b_milk', emoji: '🥛'),
  ]),
];

// ═══════════════════════════════════════════════════════════════
//  SAVED LABEL MODEL
// ═══════════════════════════════════════════════════════════════
class SavedLabel {
  final String id;
  String name;
  final double widthMm;
  final double heightMm;
  final bool isCircle;
  final List<Map<String, dynamic>> elements;
  final int canvasBgValue;
  final String gridStyle;
  final String? canvasBgImagePath;
  final String borderStyle;
  final double borderThickness;
  final int borderColorValue;
  DateTime createdAt;
  DateTime updatedAt;
  final String? thumbnailPath;

  SavedLabel({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    required this.isCircle,
    required this.elements,
    required this.canvasBgValue,
    required this.gridStyle,
    this.canvasBgImagePath,
    this.borderStyle = 'none',
    this.borderThickness = 1.5,
    this.borderColorValue = 0xFF000000,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  String get sizeLabel => '${widthMm.toInt()}×${heightMm.toInt()} mm';
  int get elementCount => elements.length;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'widthMm': widthMm, 'heightMm': heightMm,
    'isCircle': isCircle, 'elements': elements,
    'canvasBgValue': canvasBgValue, 'gridStyle': gridStyle,
    'canvasBgImagePath': canvasBgImagePath,
    'borderStyle': borderStyle,
    'borderThickness': borderThickness,
    'borderColorValue': borderColorValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'thumbnailPath': thumbnailPath,
  };

  static SavedLabel fromJson(Map<String, dynamic> j) => SavedLabel(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'Untitled',
    widthMm: (j['widthMm'] as num?)?.toDouble() ?? 50,
    heightMm: (j['heightMm'] as num?)?.toDouble() ?? 30,
    isCircle: j['isCircle'] as bool? ?? false,
    elements: ((j['elements'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    canvasBgValue: j['canvasBgValue'] as int? ?? 0xFFFFFFFF,
    gridStyle: j['gridStyle'] as String? ?? 'lines',
    canvasBgImagePath: j['canvasBgImagePath'] as String?,
    borderStyle: j['borderStyle'] as String? ?? 'none',
    borderThickness: (j['borderThickness'] as num?)?.toDouble() ?? 1.5,
    borderColorValue: j['borderColorValue'] as int? ?? 0xFF000000,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
    thumbnailPath: j['thumbnailPath'] as String?,
  );
}

// ═══════════════════════════════════════════════════════════════
//  LABEL STORAGE SERVICE
// ═══════════════════════════════════════════════════════════════
class LabelStorageService {
  static const String _prefsMultiKey = 'joyn_saved_labels_v2';
  static const String _prefsActiveIdKey = 'joyn_active_label_id_v2';
  static const String legacyLayoutKey = 'joyn_label_layout_v1';
  static const String legacyBgKey = 'joyn_label_bg_v1';
  static const String legacyGridKey = 'joyn_label_grid_v1';

  static Future<List<SavedLabel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsMultiKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((m) => SavedLabel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) { return []; }
  }

  static Future<String> save({
    String? id,
    required String name,
    required double widthMm,
    required double heightMm,
    required bool isCircle,
    required List<Map<String, dynamic>> elements,
    required int canvasBgValue,
    required String gridStyle,
    String? canvasBgImagePath,
    String borderStyle = 'none',
    double borderThickness = 1.5,
    int borderColorValue = 0xFF000000,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    final now = DateTime.now();
    final newId = id ?? 'label_${now.millisecondsSinceEpoch}';
    final idx = all.indexWhere((x) => x.id == newId);

    final newLabel = SavedLabel(
      id: newId, name: name, widthMm: widthMm, heightMm: heightMm,
      isCircle: isCircle, elements: elements,
      canvasBgValue: canvasBgValue, gridStyle: gridStyle,
      canvasBgImagePath: canvasBgImagePath,
      borderStyle: borderStyle,
      borderThickness: borderThickness,
      borderColorValue: borderColorValue,
      createdAt: idx >= 0 ? all[idx].createdAt : now, updatedAt: now,
    );

    if (idx >= 0) { all[idx] = newLabel; } else { all.insert(0, newLabel); }

    await prefs.setString(_prefsMultiKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    await prefs.setString(_prefsActiveIdKey, newId);
    return newId;
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    all.removeWhere((x) => x.id == id);
    await prefs.setString(_prefsMultiKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    final activeId = prefs.getString(_prefsActiveIdKey);
    if (activeId == id) await prefs.remove(_prefsActiveIdKey);
  }

  static Future<void> rename(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    final idx = all.indexWhere((x) => x.id == id);
    if (idx >= 0) {
      all[idx].name = newName;
      all[idx].updatedAt = DateTime.now();
      await prefs.setString(_prefsMultiKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    }
  }

  static Future<String> duplicate(String id) async {
    final all = await getAll();
    final src = all.firstWhere((x) => x.id == id);
    final now = DateTime.now();
    final newId = 'label_${now.millisecondsSinceEpoch}';
    final copy = SavedLabel(
      id: newId, name: '${src.name} (Copy)',
      widthMm: src.widthMm, heightMm: src.heightMm, isCircle: src.isCircle,
      elements: src.elements, canvasBgValue: src.canvasBgValue, gridStyle: src.gridStyle,
      canvasBgImagePath: src.canvasBgImagePath,
      borderStyle: src.borderStyle,
      borderThickness: src.borderThickness,
      borderColorValue: src.borderColorValue,
      createdAt: now, updatedAt: now,
    );
    all.insert(0, copy);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsMultiKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    return newId;
  }

  static Future<SavedLabel?> getById(String id) async {
    final all = await getAll();
    try { return all.firstWhere((x) => x.id == id); } catch (_) { return null; }
  }

  static Future<String?> getActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsActiveIdKey);
  }

  static Future<void> setActiveId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) { await prefs.remove(_prefsActiveIdKey); }
    else { await prefs.setString(_prefsActiveIdKey, id); }
  }

  static Future<List<Map<String, dynamic>>?> loadLegacyElements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(legacyLayoutKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
    } catch (_) { return null; }
  }

  static Future<int?> loadLegacyBg() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(legacyBgKey);
  }

  static Future<String?> loadLegacyGrid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(legacyGridKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsMultiKey);
    await prefs.remove(_prefsActiveIdKey);
    await prefs.remove(legacyLayoutKey);
    await prefs.remove(legacyBgKey);
    await prefs.remove(legacyGridKey);
  }
}

// ═══════════════════════════════════════════════════════════════
//  LABEL ELEMENT MODEL
// ═══════════════════════════════════════════════════════════════
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
  int? backgroundColorValue;
  bool uppercase;
  bool lowercase;
  double padding;
  int qrErrorCorrection;
  int qrBackgroundValue;
  double qrPadding;
  bool barcodeShowText;
  double barcodeFontSize;
  int barcodeBackgroundValue;
  LineStyle lineStyle;
  int? fillColorValue;
  bool filled;
  BorderStyleMode borderStyleMode;
  BoxFit imageFit;
  double imageBorderRadius;
  int? imageBorderColorValue;
  double imageBorderWidth;
  int serialPadding;
  bool locked;
  bool visible;
  int fontWeight;
  bool flipHorizontal;
  bool flipVertical;
  double textShadowBlur;
  int? textShadowColorValue;
  ShapeKind shapeKind;
  ShapeStrokeStyle shapeStrokeStyle;

  LabelElement({
    required this.id, required this.type, required this.position, required this.size,
    this.rotation = 0, required this.content, this.imagePath,
    this.fontSize = 20, this.bold = false, this.italic = false,
    this.underline = false, this.strikethrough = false,
    this.colorValue = 0xFF000000, this.strokeWidth = 1.5,
    this.barcodeType = 'code128', this.liveTime = true, this.opacity = 1.0,
    this.zIndex = 0, this.fontFamily = 'Default', this.encoding = 'UTF-8',
    this.prefix = '', this.suffix = '', this.startValue = 1, this.interval = 1,
    this.serialEnabled = false, this.timeOffsetMinutes = 0,
    this.dateFormat = 'yyyy/MM/dd', this.timeFormat = 'HH:mm:ss',
    this.textAlign = TextAlign.left, this.letterSpacing = 0,
    this.lineHeightMultiplier = 1.2, this.coloredCode = false, this.codeScale = 4.5,
    this.codeAlign = TextAlign.center, this.barcodeStyle = BarcodeStyle.normal,
    this.autoFit = false, this.cornerRadius = 0, this.shadowEnabled = false,
    this.shadowBlur = 8, this.shadowOffset = const Offset(2, 2),
    this.shadowColor = const Color(0x33000000), this.qrShape = QrShape.square,
    this.qrShowLogo = false, this.qrLogoPath, this.backgroundColorValue,
    this.uppercase = false, this.lowercase = false, this.padding = 4,
    this.qrErrorCorrection = 1, this.qrBackgroundValue = 0xFFFFFFFF,
    this.qrPadding = 0, this.barcodeShowText = true, this.barcodeFontSize = 12,
    this.barcodeBackgroundValue = 0xFFFFFFFF, this.lineStyle = LineStyle.solid,
    this.fillColorValue, this.filled = false, this.borderStyleMode = BorderStyleMode.solid,
    this.imageFit = BoxFit.contain, this.imageBorderRadius = 0,
    this.imageBorderColorValue, this.imageBorderWidth = 0, this.serialPadding = 4,
    this.locked = false, this.visible = true, this.fontWeight = 400,
    this.flipHorizontal = false, this.flipVertical = false,
    this.textShadowBlur = 0, this.textShadowColorValue,
    this.shapeKind = ShapeKind.square,
    this.shapeStrokeStyle = ShapeStrokeStyle.solid,
  });

  Color get color => Color(colorValue).withValues(alpha: opacity);
  Color get backgroundColor => backgroundColorValue == null ? Colors.transparent : Color(backgroundColorValue!);
  Color get qrBackgroundColor => Color(qrBackgroundValue);
  Color get barcodeBackgroundColor => Color(barcodeBackgroundValue);
  Color get fillColor => fillColorValue == null ? Colors.transparent : Color(fillColorValue!);
  Color get imageBorderColor => imageBorderColorValue == null ? Colors.transparent : Color(imageBorderColorValue!);
  Color get textShadowColor => textShadowColorValue == null ? Colors.transparent : Color(textShadowColorValue!);

  String displayContentForIndex(int index) {
    if (serialEnabled) {
      final val = startValue + (index * interval);
      return '$prefix${val.toString().padLeft(serialPadding, '0')}$suffix';
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
      backgroundColorValue: backgroundColorValue, uppercase: uppercase, lowercase: lowercase,
      padding: padding, qrErrorCorrection: qrErrorCorrection, qrBackgroundValue: qrBackgroundValue,
      qrPadding: qrPadding, barcodeShowText: barcodeShowText, barcodeFontSize: barcodeFontSize,
      barcodeBackgroundValue: barcodeBackgroundValue, lineStyle: lineStyle,
      fillColorValue: fillColorValue, filled: filled, borderStyleMode: borderStyleMode,
      imageFit: imageFit, imageBorderRadius: imageBorderRadius,
      imageBorderColorValue: imageBorderColorValue, imageBorderWidth: imageBorderWidth,
      serialPadding: serialPadding, locked: locked, visible: visible,
      fontWeight: fontWeight, flipHorizontal: flipHorizontal, flipVertical: flipVertical,
      textShadowBlur: textShadowBlur, textShadowColorValue: textShadowColorValue,
      shapeKind: shapeKind, shapeStrokeStyle: shapeStrokeStyle,
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
    'shadowColor': shadowColor.toARGB32(),
    'qrShape': qrShape.name,
    'qrShowLogo': qrShowLogo, 'qrLogoPath': qrLogoPath,
    'backgroundColorValue': backgroundColorValue, 'uppercase': uppercase,
    'lowercase': lowercase, 'padding': padding,
    'qrErrorCorrection': qrErrorCorrection, 'qrBackgroundValue': qrBackgroundValue,
    'qrPadding': qrPadding, 'barcodeShowText': barcodeShowText,
    'barcodeFontSize': barcodeFontSize, 'barcodeBackgroundValue': barcodeBackgroundValue,
    'lineStyle': lineStyle.name, 'fillColorValue': fillColorValue, 'filled': filled,
    'borderStyleMode': borderStyleMode.name, 'imageFit': imageFit.name,
    'imageBorderRadius': imageBorderRadius, 'imageBorderColorValue': imageBorderColorValue,
    'imageBorderWidth': imageBorderWidth, 'serialPadding': serialPadding,
    'locked': locked, 'visible': visible, 'fontWeight': fontWeight,
    'flipHorizontal': flipHorizontal, 'flipVertical': flipVertical,
    'textShadowBlur': textShadowBlur, 'textShadowColorValue': textShadowColorValue,
    'shapeKind': shapeKind.name, 'shapeStrokeStyle': shapeStrokeStyle.name,
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
      backgroundColorValue: json['backgroundColorValue'] as int?,
      uppercase: json['uppercase'] as bool? ?? false,
      lowercase: json['lowercase'] as bool? ?? false,
      padding: (json['padding'] as num?)?.toDouble() ?? 4,
      qrErrorCorrection: json['qrErrorCorrection'] as int? ?? 1,
      qrBackgroundValue: json['qrBackgroundValue'] as int? ?? 0xFFFFFFFF,
      qrPadding: (json['qrPadding'] as num?)?.toDouble() ?? 0,
      barcodeShowText: json['barcodeShowText'] as bool? ?? true,
      barcodeFontSize: (json['barcodeFontSize'] as num?)?.toDouble() ?? 12,
      barcodeBackgroundValue: json['barcodeBackgroundValue'] as int? ?? 0xFFFFFFFF,
      lineStyle: LineStyle.values.byName(json['lineStyle'] as String? ?? 'solid'),
      fillColorValue: json['fillColorValue'] as int?,
      filled: json['filled'] as bool? ?? false,
      borderStyleMode: BorderStyleMode.values.byName(json['borderStyleMode'] as String? ?? 'solid'),
      imageFit: BoxFit.values.byName(json['imageFit'] as String? ?? 'contain'),
      imageBorderRadius: (json['imageBorderRadius'] as num?)?.toDouble() ?? 0,
      imageBorderColorValue: json['imageBorderColorValue'] as int?,
      imageBorderWidth: (json['imageBorderWidth'] as num?)?.toDouble() ?? 0,
      serialPadding: json['serialPadding'] as int? ?? 4,
      locked: json['locked'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      fontWeight: json['fontWeight'] as int? ?? 400,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      textShadowBlur: (json['textShadowBlur'] as num?)?.toDouble() ?? 0,
      textShadowColorValue: json['textShadowColorValue'] as int?,
      shapeKind: ShapeKind.values.byName(json['shapeKind'] as String? ?? 'square'),
      shapeStrokeStyle: ShapeStrokeStyle.values.byName(json['shapeStrokeStyle'] as String? ?? 'solid'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MY LABELS SCREEN
// ═══════════════════════════════════════════════════════════════
enum _SortMode { recent, nameAZ, nameZA, size }

class MyLabelsScreen extends StatefulWidget {
  const MyLabelsScreen({super.key});

  @override
  State<MyLabelsScreen> createState() => _MyLabelsScreenState();
}

class _MyLabelsScreenState extends State<MyLabelsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<SavedLabel> _all = [];
  bool _isLoading = true;
  String _query = '';
  _SortMode _sortMode = _SortMode.recent;
  bool _gridView = true;
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await LabelStorageService.getAll();
    final active = await LabelStorageService.getActiveId();
    if (!mounted) return;
    setState(() { _all = list; _activeId = active; _isLoading = false; });
  }

  List<SavedLabel> get _filtered {
    var list = List<SavedLabel>.from(_all);
    if (_query.isNotEmpty) {
      list = list.where((l) =>
      l.name.toLowerCase().contains(_query) ||
          l.sizeLabel.toLowerCase().contains(_query)
      ).toList();
    }
    switch (_sortMode) {
      case _SortMode.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); break;
      case _SortMode.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); break;
      case _SortMode.nameZA:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase())); break;
      case _SortMode.size:
        list.sort((a, b) => (b.widthMm * b.heightMm).compareTo(a.widthMm * a.heightMm)); break;
    }
    return list;
  }

  Future<void> _openLabel(SavedLabel label) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabelEditorScreen(
          labelSize: LabelSizeResult(
            widthMm: label.widthMm,
            heightMm: label.heightMm,
            isCircle: label.isCircle,
            name: label.name,
          ),
          existingLabel: label,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _rename(SavedLabel label) async {
    final ctrl = TextEditingController(text: label.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Label', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(
            labelText: 'Label name', filled: true, fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await LabelStorageService.rename(label.id, newName);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renamed'), behavior: SnackBarBehavior.floating, backgroundColor: JoynColors.primary));
      }
    }
  }

  Future<void> _delete(SavedLabel label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Label?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete "${label.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LabelStorageService.delete(label.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _duplicate(SavedLabel label) async {
    await LabelStorageService.duplicate(label.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicated'), behavior: SnackBarBehavior.floating, backgroundColor: JoynColors.primary));
    }
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<LabelSizeResult>(
      context,
      MaterialPageRoute(builder: (_) => const NewLabelSizeScreen()),
    );
    if (result != null && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => LabelEditorScreen(labelSize: result)));
      await _load();
    }
  }

  void _showSortMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(16), child: Text('Sort by', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
            _sortTile('Recent first', _SortMode.recent, Icons.access_time_rounded),
            _sortTile('Name (A → Z)', _SortMode.nameAZ, Icons.sort_by_alpha_rounded),
            _sortTile('Name (Z → A)', _SortMode.nameZA, Icons.sort_by_alpha_rounded),
            _sortTile('Largest size', _SortMode.size, Icons.photo_size_select_large_rounded),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String label, _SortMode mode, IconData icon) {
    final selected = _sortMode == mode;
    return ListTile(
      leading: Icon(icon, color: selected ? JoynColors.primary : JoynColors.secondaryText),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? JoynColors.primary : const Color(0xFF16171D))),
      trailing: selected ? const Icon(Icons.check_rounded, color: JoynColors.primary) : null,
      onTap: () { Navigator.pop(context); setState(() => _sortMode = mode); },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: JoynColors.chipBackground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Labels', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridView = !_gridView),
            tooltip: _gridView ? 'List view' : 'Grid view',
          ),
          IconButton(icon: const Icon(Icons.sort_rounded), onPressed: _showSortMenu, tooltip: 'Sort'),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNew,
        backgroundColor: JoynColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Label', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JoynColors.border),
                boxShadow: _Premium.cardShadow,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search labels...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: JoynColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18), onPressed: () => _searchCtrl.clear())
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (!_isLoading && _all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: JoynColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.folder_special_rounded, size: 13, color: JoynColors.primary),
                      const SizedBox(width: 5),
                      Text('${_all.length} total', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                    ]),
                  ),
                  const Spacer(),
                  Text(_sortLabel(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
                : _all.isEmpty
                ? _emptyState()
                : filtered.isEmpty
                ? _noResultsState()
                : RefreshIndicator(
              color: JoynColors.primary,
              onRefresh: _load,
              child: _gridView ? _buildGrid(filtered) : _buildList(filtered),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel() {
    switch (_sortMode) {
      case _SortMode.recent: return 'Recent';
      case _SortMode.nameAZ: return 'A → Z';
      case _SortMode.nameZA: return 'Z → A';
      case _SortMode.size: return 'Size';
    }
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [JoynColors.primary.withValues(alpha: 0.12), JoynColors.primary.withValues(alpha: 0.03)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.label_off_rounded, size: 48, color: JoynColors.primary.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 20),
            const Text('No saved labels yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF16171D))),
            const SizedBox(height: 8),
            Text('Create your first label and save it here for quick access.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4)),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _createNew,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create New Label', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No matching labels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF16171D))),
          const SizedBox(height: 6),
          Text('Try a different search term', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildGrid(List<SavedLabel> labels) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82,
      ),
      itemCount: labels.length,
      itemBuilder: (context, i) => _gridCard(labels[i]),
    );
  }

  Widget _gridCard(SavedLabel label) {
    final isActive = label.id == _activeId;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? JoynColors.primary : JoynColors.border, width: isActive ? 1.6 : 1),
        boxShadow: _Premium.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLabel(label),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Color(label.canvasBgValue),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Center(child: Icon(Icons.label_rounded, size: 42, color: JoynColors.primary.withValues(alpha: 0.35)))),
                      if (isActive)
                        Positioned(top: 8, left: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: JoynColors.primary, borderRadius: BorderRadius.circular(6)),
                          child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                        )),
                      Positioned(
                        top: 4, right: 4,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]),
                            child: const Icon(Icons.more_vert_rounded, size: 16),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (v) {
                            if (v == 'rename') _rename(label);
                            if (v == 'duplicate') _duplicate(label);
                            if (v == 'delete') _delete(label);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.edit_rounded, size: 18), title: Text('Rename'), dense: true, contentPadding: EdgeInsets.zero)),
                            PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy_rounded, size: 18), title: Text('Duplicate'), dense: true, contentPadding: EdgeInsets.zero)),
                            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16171D))),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.straighten_rounded, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(label.sizeLabel, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${label.elementCount}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatDate(label.updatedAt), style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<SavedLabel> labels) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: labels.length,
      itemBuilder: (context, i) => _listCard(labels[i]),
    );
  }

  Widget _listCard(SavedLabel label) {
    final isActive = label.id == _activeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? JoynColors.primary : JoynColors.border, width: isActive ? 1.5 : 1),
        boxShadow: _Premium.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openLabel(label),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: Color(label.canvasBgValue),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: JoynColors.border),
                  ),
                  child: Center(child: Icon(Icons.label_rounded, size: 26, color: JoynColors.primary.withValues(alpha: 0.4))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(label.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF16171D)))),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: JoynColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.straighten_rounded, size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(label.sizeLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        Icon(Icons.widgets_rounded, size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text('${label.elementCount}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 3),
                      Text(_formatDate(label.updatedAt), style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'rename') _rename(label);
                    if (v == 'duplicate') _duplicate(label);
                    if (v == 'delete') _delete(label);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.edit_rounded, size: 18), title: Text('Rename'), dense: true, contentPadding: EdgeInsets.zero)),
                    PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy_rounded, size: 18), title: Text('Duplicate'), dense: true, contentPadding: EdgeInsets.zero)),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LABEL EDITOR SCREEN
// ═══════════════════════════════════════════════════════════════
class LabelEditorScreen extends StatefulWidget {
  final LabelSizeResult? labelSize;
  final String? initialBarcodeValue;
  final SavedLabel? existingLabel;
  const LabelEditorScreen({super.key, this.labelSize, this.initialBarcodeValue, this.existingLabel});

  @override
  State<LabelEditorScreen> createState() => _LabelEditorScreenState();
}

class _LabelEditorScreenState extends State<LabelEditorScreen> {
  static const double _mmToPx = 3.6;
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
  GridStyle _gridStyle = GridStyle.lines;
  Timer? _liveTimer;
  List<Map<String, dynamic>> _importedRows = [];
  int _batchRowIndex = 0;
  int _canvasBgValue = 0xFFFFFFFF;
  bool _snapToGrid = false;
  double _gridSpacing = 20;
  LabelElement? _clipboard;
  String? _activeLabelId;
  String _activeLabelName = 'Untitled';
  String? _canvasBgImagePath;

  bool _isCircle = false;

  // Border state
  LabelBorderStyle _borderStyle = LabelBorderStyle.none;
  double _borderThickness = 1.5;
  int _borderColorValue = 0xFF000000;

  // Shape picker state
  ShapeKind _pendingShapeKind = ShapeKind.square;
  ShapeStrokeStyle _pendingShapeStyle = ShapeStrokeStyle.solid;
  double _pendingShapeThickness = 1.5;

  LabelElement? get _selected => _selectedId == null ? null : _elements.firstWhere((e) => e.id == _selectedId);

  @override
  void initState() {
    super.initState();
    _labelSizeMm = Size(widget.labelSize?.widthMm ?? 100, widget.labelSize?.heightMm ?? 150);

    _isCircle = widget.existingLabel?.isCircle
        ?? widget.labelSize?.isCircle
        ?? false;

    _canvasBgImagePath = widget.existingLabel?.canvasBgImagePath
        ?? widget.labelSize?.backgroundImagePath;

    if (widget.existingLabel != null) {
      final lbl = widget.existingLabel!;
      final list = lbl.elements.map((m) => LabelElement.fromJson(m)).toList();
      int maxIndex = -1;
      for (final e in list) {
        final match = RegExp(r'el_(\d+)').firstMatch(e.id);
        if (match != null) { final n = int.tryParse(match.group(1)!) ?? -1; if (n > maxIndex) maxIndex = n; }
      }
      _labelSizeMm = Size(lbl.widthMm, lbl.heightMm);
      _canvasBgValue = lbl.canvasBgValue;
      _gridStyle = GridStyle.values.byName(lbl.gridStyle);
      _isCircle = lbl.isCircle;
      _borderStyle = LabelBorderStyle.values.byName(lbl.borderStyle);
      _borderThickness = lbl.borderThickness;
      _borderColorValue = lbl.borderColorValue;
      _elements.addAll(list);
      _idCounter = maxIndex + 1;
      _activeLabelId = lbl.id;
      _activeLabelName = lbl.name;
    } else if (widget.initialBarcodeValue != null && widget.initialBarcodeValue!.isNotEmpty) {
      final size = const Size(280, 110);
      _elements.add(LabelElement(id: _nextId(), type: LabelElementType.barcode, position: _safePositionFor(size), size: size, content: widget.initialBarcodeValue!));
    } else {
      _loadLegacyLayout();
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

  Offset _safePositionFor(Size size) {
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final maxX = (w - size.width - 6).clamp(4.0, 10000.0);
    final maxY = (h - size.height - 6).clamp(4.0, 10000.0);
    final x = ((w - size.width) / 2).clamp(4.0, maxX);
    double y = 16;
    for (final el in _elements) {
      final bottom = el.position.dy + el.size.height + 10;
      if (bottom > y) y = bottom;
    }
    if (y > maxY) y = maxY;
    return Offset(x, y);
  }

  Future<void> _loadLegacyLayout() async {
    try {
      final bg = await LabelStorageService.loadLegacyBg();
      final gridStr = await LabelStorageService.loadLegacyGrid();
      if (bg != null) _canvasBgValue = bg;
      if (gridStr != null) _gridStyle = GridStyle.values.byName(gridStr);

      final list = await LabelStorageService.loadLegacyElements();
      if (list == null) return;
      final elements = list.map((m) => LabelElement.fromJson(m)).toList();
      int maxIndex = -1;
      for (final e in elements) {
        final match = RegExp(r'el_(\d+)').firstMatch(e.id);
        if (match != null) { final n = int.tryParse(match.group(1)!) ?? -1; if (n > maxIndex) maxIndex = n; }
      }
      if (!mounted) return;
      setState(() { _elements..clear()..addAll(elements); _idCounter = maxIndex + 1; });
    } catch (e) { debugPrint('Legacy load failed: $e'); }
  }

  Future<void> _saveLayout() async {
    if (_activeLabelId == null) {
      final ctrl = TextEditingController(text: 'Label ${_labelSizeMm.width.toInt()}x${_labelSizeMm.height.toInt()}');
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Save Label', style: TextStyle(fontWeight: FontWeight.w800)),
          content: TextField(
            controller: ctrl, autofocus: true,
            decoration: InputDecoration(
              labelText: 'Label name', hintText: 'e.g., Product Sticker',
              filled: true, fillColor: JoynColors.chipBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (name == null || name.isEmpty) return;
      _activeLabelName = name;
    }

    setState(() => _isBusy = true);
    try {
      final newId = await LabelStorageService.save(
        id: _activeLabelId,
        name: _activeLabelName,
        widthMm: _labelSizeMm.width,
        heightMm: _labelSizeMm.height,
        isCircle: _isCircle,
        elements: _elements.map((e) => e.toJson()).toList(),
        canvasBgValue: _canvasBgValue,
        gridStyle: _gridStyle.name,
        canvasBgImagePath: _canvasBgImagePath,
        borderStyle: _borderStyle.name,
        borderThickness: _borderThickness,
        borderColorValue: _borderColorValue,
      );
      if (mounted) {
        setState(() => _activeLabelId = newId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Label saved'), behavior: SnackBarBehavior.floating,
          backgroundColor: JoynColors.primary,
        ));
      }
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'), behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ));
      }
    } finally { if (mounted) setState(() => _isBusy = false); }
  }

  Future<void> _duplicateLabel() async {
    if (_activeLabelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pehle label save karein'), behavior: SnackBarBehavior.floating));
      return;
    }
    await LabelStorageService.duplicate(_activeLabelId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Label duplicate ho gaya'), behavior: SnackBarBehavior.floating, backgroundColor: JoynColors.primary));
    }
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

  void _alignSelected(String align) {
    if (_selected == null) return;
    _pushHistory();
    setState(() {
      final el = _selected!;
      final cw = _canvasSize.width;
      final ch = _canvasSize.height;
      switch (align) {
        case 'left': el.position = Offset(4, el.position.dy); break;
        case 'right': el.position = Offset(cw - el.size.width - 4, el.position.dy); break;
        case 'top': el.position = Offset(el.position.dx, 4); break;
        case 'bottom': el.position = Offset(el.position.dx, ch - el.size.height - 4); break;
        case 'cx': el.position = Offset((cw - el.size.width) / 2, el.position.dy); break;
        case 'cy': el.position = Offset(el.position.dx, (ch - el.size.height) / 2); break;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _copySelected() {
    if (_selected == null) return;
    _clipboard = _selected!.deepClone(newId: _nextId());
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
  }

  void _pasteElement() {
    if (_clipboard == null) return;
    _pushHistory();
    final clone = _clipboard!.deepClone(newId: _nextId());
    clone.position = clone.position + const Offset(16, 16);
    clone.zIndex = _elements.length;
    setState(() { _elements.add(clone); _selectedId = clone.id; });
    HapticFeedback.selectionClick();
  }

  void _showLayersPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.layers_rounded, color: JoynColors.primary),
                  const SizedBox(width: 10),
                  Text('Layers (${_elements.length})', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: _elements.isEmpty
                    ? const Center(child: Text('No elements yet', style: TextStyle(color: Colors.grey)))
                    : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _elements.length,
                  onReorder: (oldIdx, newIdx) {
                    _pushHistory();
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = _elements.removeAt(oldIdx);
                      _elements.insert(newIdx, item);
                      for (int i = 0; i < _elements.length; i++) { _elements[i].zIndex = i; }
                    });
                    setSheetState(() {});
                  },
                  itemBuilder: (context, idx) {
                    final el = _elements[idx];
                    return Container(
                      key: ValueKey(el.id),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _selectedId == el.id ? JoynColors.primary.withValues(alpha: 0.08) : JoynColors.chipBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedId == el.id ? JoynColors.primary : Colors.transparent, width: 1.4),
                      ),
                      child: ListTile(
                        leading: Icon(_iconForToolType(el.type), color: JoynColors.primary, size: 20),
                        title: Text(_titleForToolType(el.type).replaceFirst('Add ', ''), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        subtitle: Text(el.content.length > 20 ? '${el.content.substring(0, 20)}...' : el.content, style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(el.visible ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18, color: el.visible ? JoynColors.primary : Colors.grey), onPressed: () { setState(() => el.visible = !el.visible); setSheetState(() {}); }),
                            IconButton(icon: Icon(el.locked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18, color: el.locked ? Colors.orange : Colors.grey), onPressed: () { setState(() => el.locked = !el.locked); setSheetState(() {}); }),
                            Icon(Icons.drag_handle_rounded, color: Colors.grey.shade400),
                          ],
                        ),
                        onTap: () { setState(() => _selectedId = el.id); setSheetState(() {}); },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCanvasSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: _Premium.gradient(JoynColors.primary), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Text('Canvas Settings', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 20),
                _sectionDivider('Background'),
                _sheetLabel('Background image'),
                const SizedBox(height: 8),
                Row(children: [
                  if (_canvasBgImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_canvasBgImagePath!), width: 44, height: 44, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
                        if (picked == null) return;
                        setState(() => _canvasBgImagePath = picked.path);
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change'),
                    ),
                    TextButton.icon(
                      onPressed: () { setState(() => _canvasBgImagePath = null); setSheetState(() {}); },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
                        if (picked == null) return;
                        setState(() => _canvasBgImagePath = picked.path);
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text('Add background image'),
                    ),
                ]),
                const SizedBox(height: 12),
                _sheetLabel('Label background color'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                  final sel = _canvasBgValue == c.toARGB32();
                  return GestureDetector(
                    onTap: () { setState(() => _canvasBgValue = c.toARGB32()); setSheetState(() {}); },
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                  );
                }).toList()),
                const SizedBox(height: 20),
                _sectionDivider('Grid'),
                _sheetLabel('Grid style'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: GridStyle.values.map((s) {
                  return _choiceChip(label: s.name.toUpperCase(), selected: _gridStyle == s, onTap: () { setState(() => _gridStyle = s); setSheetState(() {}); });
                }).toList()),
                const SizedBox(height: 12),
                _sheetLabel('Grid spacing: ${_gridSpacing.toInt()} px'),
                Slider(value: _gridSpacing, min: 8, max: 60, activeColor: JoynColors.primary, onChanged: (v) { setState(() => _gridSpacing = v); setSheetState(() {}); }),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Snap to grid', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), value: _snapToGrid, activeColor: JoynColors.primary, onChanged: (v) { setState(() => _snapToGrid = v); setSheetState(() {}); }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _saveLayout(); },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save & Close', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(backgroundColor: JoynColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickPalettes() {
    final palettes = <QuickPalette, List<Color>>{
      QuickPalette.classic: [Colors.black, Colors.white, const Color(0xFF2563EB), const Color(0xFFDC2626)],
      QuickPalette.warm: [const Color(0xFFDC2626), const Color(0xFFF59E0B), const Color(0xFFEA580C), const Color(0xFFFBBF24)],
      QuickPalette.cool: [const Color(0xFF2563EB), const Color(0xFF06B6D4), const Color(0xFF7C3AED), const Color(0xFF14B85C)],
      QuickPalette.nature: [const Color(0xFF16A34A), const Color(0xFF84CC16), const Color(0xFF65A30D), const Color(0xFFD97706)],
      QuickPalette.pastel: [const Color(0xFFFBBF24), const Color(0xFF60A5FA), const Color(0xFFF472B6), const Color(0xFF34D399)],
      QuickPalette.mono: [Colors.black, const Color(0xFF525252), const Color(0xFF9E9E9E), Colors.white],
      QuickPalette.neon: [const Color(0xFF00FF88), const Color(0xFFFF00FF), const Color(0xFF00FFFF), const Color(0xFFFFFF00)],
      QuickPalette.ocean: [const Color(0xFF0EA5E9), const Color(0xFF06B6D4), const Color(0xFF0F766E), const Color(0xFF1E40AF)],
      QuickPalette.sunset: [const Color(0xFFEC4899), const Color(0xFFF97316), const Color(0xFFEAB308), const Color(0xFF8B5CF6)],
      QuickPalette.forest: [const Color(0xFF166534), const Color(0xFF16A34A), const Color(0xFF65A30D), const Color(0xFF78350F)],
      QuickPalette.royalty: [const Color(0xFF6D28D9), const Color(0xFF7C3AED), const Color(0xFFA855F7), const Color(0xFFEAB308)],
      QuickPalette.minimal: [Colors.black, const Color(0xFF404040), const Color(0xFFA3A3A3), Colors.white],
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.palette_rounded, color: JoynColors.primary),
                const SizedBox(width: 10),
                Text('Quick Palettes', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: palettes.length,
                itemBuilder: (_, i) {
                  final entry = palettes.entries.elementAt(i);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: JoynColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16171D))),
                        const SizedBox(height: 10),
                        Row(
                          children: entry.value.map((c) {
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedId != null) {
                                    _pushHistory();
                                    setState(() => _selected!.colorValue = c.toARGB32());
                                    HapticFeedback.selectionClick();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied to selected element'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1), backgroundColor: JoynColors.primary));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an element first'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
                                  }
                                },
                                child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 48, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300))),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addElement(LabelElementType type) async {
    if (type == LabelElementType.image) {
      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      _pushHistory();
      final size = const Size(140, 140);
      final el = LabelElement(id: _nextId(), type: type, position: _safePositionFor(size), size: size, content: '', imagePath: picked.path, zIndex: _elements.length);
      setState(() { _elements.add(el); _selectedId = el.id; });
      return;
    }
    _showToolSheet(type);
  }

  IconData _iconForToolType(LabelElementType t) {
    switch (t) {
      case LabelElementType.text:      return Icons.title_rounded;
      case LabelElementType.qrCode:    return Icons.qr_code_2_rounded;
      case LabelElementType.barcode:   return Icons.view_week_outlined;
      case LabelElementType.time:      return Icons.access_time_rounded;
      case LabelElementType.serial:    return Icons.tag_rounded;
      case LabelElementType.line:      return Icons.horizontal_rule_rounded;
      case LabelElementType.rectangle: return Icons.crop_square_rounded;
      case LabelElementType.circle:    return Icons.circle_outlined;
      case LabelElementType.image:     return Icons.image_outlined;
      case LabelElementType.sticker:   return Icons.emoji_emotions_outlined;
      default:                         return Icons.add_rounded;
    }
  }

  String _titleForToolType(LabelElementType t) {
    switch (t) {
      case LabelElementType.text:      return 'Add Text';
      case LabelElementType.qrCode:    return 'Add QR Code';
      case LabelElementType.barcode:   return 'Add Barcode';
      case LabelElementType.time:      return 'Add Time / Date';
      case LabelElementType.serial:    return 'Add Serial Number';
      case LabelElementType.line:      return 'Add Line';
      case LabelElementType.rectangle: return 'Add Rectangle';
      case LabelElementType.circle:    return 'Add Circle';
      case LabelElementType.image:     return 'Add Image';
      case LabelElementType.sticker:   return 'Add Sticker';
      default:                         return 'Add Element';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BORDER SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showBorderSheet() {
    LabelBorderCategory selectedCat = LabelBorderCategory.diagonal;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Column(
                  children: [
                    Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: _Premium.gradient(JoynColors.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.border_style_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Border',
                          style: JoynTypography.titleMedium.copyWith(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                height: 42,
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: LabelBorderCategory.values.map((cat) {
                    final sel = selectedCat == cat;
                    final label = switch (cat) {
                      LabelBorderCategory.mine => 'Mine',
                      LabelBorderCategory.diagonal => 'Diagonal border',
                      LabelBorderCategory.parallel => 'Parallel border',
                      LabelBorderCategory.line => 'Line',
                      LabelBorderCategory.circle => 'Circle border',
                      LabelBorderCategory.ratio46 => '4*6 Border',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setSheetState(() => selectedCat = cat),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: sel ? JoynColors.primary : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                color: sel ? JoynColors.primary : JoynColors.secondaryText,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: _borderStylesForCategory(selectedCat).length,
                    itemBuilder: (_, i) {
                      final bs = _borderStylesForCategory(selectedCat)[i];
                      final sel = _borderStyle == bs;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _borderStyle = bs);
                          setSheetState(() {});
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: JoynColors.chipBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? JoynColors.primary : JoynColors.border,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CustomPaint(
                                    painter: _LabelBorderPainter(
                                      style: bs,
                                      thickness: 1.2,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                ),
                              ),
                              if (sel)
                                Positioned(
                                  top: 4, right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: JoynColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check,
                                        size: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: JoynColors.border)),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.line_weight_rounded,
                          size: 16, color: JoynColors.primary),
                      const SizedBox(width: 8),
                      Text('Thickness: ${_borderThickness.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Slider(
                          value: _borderThickness,
                          min: 0.5, max: 8,
                          activeColor: JoynColors.primary,
                          onChanged: (v) {
                            setState(() => _borderThickness = v);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.palette_outlined,
                          size: 16, color: JoynColors.primary),
                      const SizedBox(width: 8),
                      const Text('Color',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Wrap(spacing: 6, children: _kSwatches.map((c) {
                        final sel = _borderColorValue == c.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            setState(() => _borderColorValue = c.toARGB32());
                            setSheetState(() {});
                          },
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel ? JoynColors.primary : Colors.grey.shade300,
                                width: sel ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList()),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _borderStyle = LabelBorderStyle.none);
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: const Text('Remove Border',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade100,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LabelBorderStyle> _borderStylesForCategory(LabelBorderCategory cat) {
    switch (cat) {
      case LabelBorderCategory.mine:
        return [
          LabelBorderStyle.none,
          LabelBorderStyle.lineAllSides,
          LabelBorderStyle.parallelDouble,
          LabelBorderStyle.circleLine,
        ];
      case LabelBorderCategory.diagonal:
        return [
          LabelBorderStyle.diagonalOrnament1,
          LabelBorderStyle.diagonalOrnament2,
          LabelBorderStyle.diagonalOrnament3,
          LabelBorderStyle.diagonalOrnament4,
          LabelBorderStyle.diagonalOrnament5,
          LabelBorderStyle.diagonalOrnament6,
          LabelBorderStyle.diagonalOrnament7,
          LabelBorderStyle.diagonalOrnament8,
        ];
      case LabelBorderCategory.parallel:
        return [
          LabelBorderStyle.parallelDouble,
          LabelBorderStyle.parallelTriple,
          LabelBorderStyle.parallelDashed,
          LabelBorderStyle.parallelDotted,
        ];
      case LabelBorderCategory.line:
        return [
          LabelBorderStyle.lineTopBottom,
          LabelBorderStyle.lineAllSides,
          LabelBorderStyle.lineLeft,
          LabelBorderStyle.lineRight,
        ];
      case LabelBorderCategory.circle:
        return [
          LabelBorderStyle.circleLine,
          LabelBorderStyle.circleDots,
          LabelBorderStyle.circleDouble,
        ];
      case LabelBorderCategory.ratio46:
        return [
          LabelBorderStyle.ratio46Simple,
          LabelBorderStyle.ratio46Double,
          LabelBorderStyle.ratio46Ornate,
        ];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHAPE PICKER
  // ═══════════════════════════════════════════════════════════════
  void _showShapePicker(ShapeKind initial) {
    _pendingShapeKind = initial;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20,
              MediaQuery.of(ctx).viewPadding.bottom + 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.category_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Shape',
                    style: JoynTypography.titleMedium.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shapeBtn(ShapeKind.line, Icons.horizontal_rule_rounded,
                      'Line', setSheetState),
                  _shapeBtn(ShapeKind.circle, Icons.circle_outlined,
                      'Circle', setSheetState),
                  _shapeBtn(ShapeKind.ellipse, Icons.circle_outlined,
                      'Ellipse', setSheetState, oval: true),
                  _shapeBtn(ShapeKind.square, Icons.crop_square_rounded,
                      'Square', setSheetState),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Text('Style',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const Spacer(),
                ...ShapeStrokeStyle.values.map((s) {
                  final sel = _pendingShapeStyle == s;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => setSheetState(() => _pendingShapeStyle = s),
                      child: Container(
                        width: 40, height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? JoynColors.primary.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomPaint(
                          size: const Size(30, 2),
                          painter: _LineStylePainter(
                            style: s,
                            color: sel ? JoynColors.primary : Colors.grey.shade600,
                            thickness: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.line_weight_rounded,
                    size: 16, color: JoynColors.primary),
                const SizedBox(width: 8),
                Text('Thick  ${_pendingShapeThickness.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                Expanded(
                  child: Slider(
                    value: _pendingShapeThickness,
                    min: 0.5, max: 12,
                    activeColor: JoynColors.primary,
                    onChanged: (v) =>
                        setSheetState(() => _pendingShapeThickness = v),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addShapeElement(_pendingShapeKind,
                        _pendingShapeStyle, _pendingShapeThickness);
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add to Label',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoynColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shapeBtn(ShapeKind kind, IconData icon, String label,
      StateSetter setSheetState, {bool oval = false}) {
    final sel = _pendingShapeKind == kind;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => setSheetState(() => _pendingShapeKind = kind),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? JoynColors.primary.withValues(alpha: 0.10)
                  : JoynColors.chipBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? JoynColors.primary : JoynColors.border,
                width: sel ? 1.8 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: oval ? 22 : 26,
                    color: sel ? JoynColors.primary : JoynColors.secondaryText),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? JoynColors.primary : JoynColors.secondaryText,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addShapeElement(
      ShapeKind kind, ShapeStrokeStyle style, double thickness) {
    _pushHistory();
    Size size = const Size(140, 90);
    if (kind == ShapeKind.circle) size = const Size(100, 100);
    if (kind == ShapeKind.square) size = const Size(120, 120);
    if (kind == ShapeKind.line) size = const Size(180, 4);
    if (kind == ShapeKind.ellipse) size = const Size(140, 90);

    final el = LabelElement(
      id: _nextId(),
      type: kind == ShapeKind.line
          ? LabelElementType.line
          : (kind == ShapeKind.circle || kind == ShapeKind.ellipse
          ? LabelElementType.circle
          : LabelElementType.rectangle),
      position: _safePositionFor(size),
      size: size,
      content: '',
      strokeWidth: thickness,
      shapeKind: kind,
      shapeStrokeStyle: style,
      zIndex: _elements.length,
    );
    setState(() {
      _elements.add(el);
      _selectedId = el.id;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  MATERIAL LIBRARY
  // ═══════════════════════════════════════════════════════════════
  void _showMaterialLibrary() {
    String selectedCat = kMaterialCategories.first.name;
    showModalBottomSheet<MaterialItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final category = kMaterialCategories
              .firstWhere((c) => c.name == selectedCat);
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Column(
                    children: [
                      Container(width: 40, height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: _Premium.gradient(JoynColors.primary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.widgets_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Material',
                            style: JoynTypography.titleMedium.copyWith(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: kMaterialCategories.map((cat) {
                      final sel = selectedCat == cat.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedCat = cat.name),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: sel ? JoynColors.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Text(cat.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                  color: sel ? JoynColors.primary : JoynColors.secondaryText,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: category.items.length,
                    itemBuilder: (_, i) {
                      final item = category.items[i];
                      return InkWell(
                        onTap: () => Navigator.pop(ctx, item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: JoynColors.chipBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: JoynColors.border),
                          ),
                          alignment: Alignment.center,
                          child: item.icon != null
                              ? Icon(item.icon, size: 28,
                              color: JoynColors.primary)
                              : item.emoji != null
                              ? Text(item.emoji!,
                              style: const TextStyle(fontSize: 26))
                              : Text(item.text ?? '',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: JoynColors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity, height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final XFile? picked = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (picked == null) return;
                        _pushHistory();
                        final size = const Size(120, 120);
                        final el = LabelElement(
                          id: _nextId(),
                          type: LabelElementType.image,
                          position: _safePositionFor(size),
                          size: size,
                          content: '',
                          imagePath: picked.path,
                          zIndex: _elements.length,
                        );
                        setState(() {
                          _elements.add(el);
                          _selectedId = el.id;
                        });
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 18),
                      label: const Text('Add from Gallery',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JoynColors.primary,
                        side: const BorderSide(color: Colors.transparent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((item) {
      if (item != null && mounted) {
        _pushHistory();
        final size = const Size(90, 90);
        final el = LabelElement(
          id: _nextId(),
          type: LabelElementType.sticker,
          position: _safePositionFor(size),
          size: size,
          content: item.key,
          zIndex: _elements.length,
        );
        setState(() {
          _elements.add(el);
          _selectedId = el.id;
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOOL SHEET (Text/QR/Barcode/Time/Serial/Line/Shape/Image)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showToolSheet(LabelElementType type, {LabelElement? existing}) async {
    if (type == LabelElementType.sticker) { _showMaterialLibrary(); return; }
    if (type == LabelElementType.image && existing == null) {
      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      if (existing != null) { _pushHistory(); setState(() => existing.imagePath = picked.path); }
      else { await _addElement(LabelElementType.image); }
      return;
    }

    final isEdit = existing != null;

    LabelElement liveEl;
    LabelElement? originalSnapshot;

    if (isEdit) {
      liveEl = existing;
      originalSnapshot = existing.deepClone();
      _pushHistory();
    } else {
      Size initSize = const Size(180, 60);
      double initFontSize = 22;
      String initContent = '';
      switch (type) {
        case LabelElementType.text:      initSize = const Size(180, 40); initFontSize = 22; initContent = 'Sample text'; break;
        case LabelElementType.qrCode:    initSize = const Size(120, 120); initContent = 'https://example.com'; break;
        case LabelElementType.barcode:   initSize = const Size(240, 90); initContent = '123456789012'; break;
        case LabelElementType.time:      initSize = const Size(200, 36); initFontSize = 18; initContent = formatLabelDateTime(DateTime.now()); break;
        case LabelElementType.serial:    initSize = const Size(150, 36); initFontSize = 20; break;
        case LabelElementType.line:      initSize = const Size(180, 4); break;
        case LabelElementType.rectangle: initSize = const Size(140, 90); break;
        case LabelElementType.circle:    initSize = const Size(100, 100); break;
        default: break;
      }
      liveEl = LabelElement(
        id: _nextId(), type: type,
        position: _safePositionFor(initSize), size: initSize,
        content: initContent, fontSize: initFontSize,
        zIndex: _elements.length,
      );
      _pushHistory();
      setState(() { _elements.add(liveEl); _selectedId = liveEl.id; });
    }

    final contentCtrl = TextEditingController(text: liveEl.content);
    double fontSize = liveEl.fontSize;
    int colorValue = liveEl.colorValue;
    int? backgroundColorValue = liveEl.backgroundColorValue;
    int qrBackgroundValue = liveEl.qrBackgroundValue;
    int barcodeBackgroundValue = liveEl.barcodeBackgroundValue;
    int? fillColorValue = liveEl.fillColorValue;
    double widthVal = liveEl.size.width;
    double heightVal = liveEl.size.height;
    bool bold = liveEl.bold;
    bool italic = liveEl.italic;
    bool underline = liveEl.underline;
    bool strikethrough = liveEl.strikethrough;
    String fontFamily = liveEl.fontFamily;
    TextAlign textAlign = liveEl.textAlign;
    double letterSpacing = liveEl.letterSpacing;
    double lineHeight = liveEl.lineHeightMultiplier;
    bool uppercase = liveEl.uppercase;
    bool lowercase = liveEl.lowercase;
    double rotationDeg = liveEl.rotation * 180 / 3.14159;
    bool shadowEnabled = liveEl.shadowEnabled;
    double shadowBlur = liveEl.shadowBlur;
    double strokeWidth = liveEl.strokeWidth;
    double cornerRadius = liveEl.cornerRadius;
    double padding = liveEl.padding;
    int fontWeight = liveEl.fontWeight;
    double opacity = liveEl.opacity;
    bool autoFit = liveEl.autoFit;
    bool flipH = liveEl.flipHorizontal;
    bool flipV = liveEl.flipVertical;
    double textShadowBlur = liveEl.textShadowBlur;
    int? textShadowColorValue = liveEl.textShadowColorValue;
    String barcodeType = liveEl.barcodeType;
    bool barcodeShowText = liveEl.barcodeShowText;
    double barcodeFontSize = liveEl.barcodeFontSize;
    BarcodeStyle barcodeStyle = liveEl.barcodeStyle;
    String qrShape = liveEl.qrShape.name;
    int qrErrorCorrection = liveEl.qrErrorCorrection;
    double qrPadding = liveEl.qrPadding;
    int serialStart = liveEl.startValue;
    int serialInterval = liveEl.interval;
    int serialPadding = liveEl.serialPadding;
    String prefix = liveEl.prefix;
    String suffix = liveEl.suffix;
    bool serialEnabled = liveEl.serialEnabled;
    String dateFormat = liveEl.dateFormat;
    String timeFormat = liveEl.timeFormat;
    int timeOffset = liveEl.timeOffsetMinutes;
    bool liveTime = liveEl.liveTime;
    LineStyle lineStyle = liveEl.lineStyle;
    bool filled = liveEl.filled;
    BoxFit imageFit = liveEl.imageFit;
    double imageBorderRadius = liveEl.imageBorderRadius;
    int? imageBorderColorValue = liveEl.imageBorderColorValue;
    double imageBorderWidth = liveEl.imageBorderWidth;
    ShapeStrokeStyle shapeStrokeStyle = liveEl.shapeStrokeStyle;

    void applyLive() {
      setState(() {
        liveEl.fontSize = fontSize;
        liveEl.colorValue = colorValue;
        liveEl.backgroundColorValue = backgroundColorValue;
        liveEl.qrBackgroundValue = qrBackgroundValue;
        liveEl.barcodeBackgroundValue = barcodeBackgroundValue;
        liveEl.fillColorValue = fillColorValue;
        liveEl.bold = bold;
        liveEl.italic = italic;
        liveEl.underline = underline;
        liveEl.strikethrough = strikethrough;
        liveEl.fontFamily = fontFamily;
        liveEl.textAlign = textAlign;
        liveEl.letterSpacing = letterSpacing;
        liveEl.lineHeightMultiplier = lineHeight;
        liveEl.uppercase = uppercase;
        liveEl.lowercase = lowercase;
        liveEl.rotation = rotationDeg * 3.14159 / 180.0;
        liveEl.shadowEnabled = shadowEnabled;
        liveEl.shadowBlur = shadowBlur;
        liveEl.strokeWidth = strokeWidth;
        liveEl.cornerRadius = cornerRadius;
        liveEl.padding = padding;
        liveEl.fontWeight = fontWeight;
        liveEl.opacity = opacity;
        liveEl.autoFit = autoFit;
        liveEl.flipHorizontal = flipH;
        liveEl.flipVertical = flipV;
        liveEl.textShadowBlur = textShadowBlur;
        liveEl.textShadowColorValue = textShadowColorValue;
        liveEl.barcodeType = barcodeType;
        liveEl.barcodeShowText = barcodeShowText;
        liveEl.barcodeFontSize = barcodeFontSize;
        liveEl.barcodeStyle = barcodeStyle;
        liveEl.qrShape = QrShape.values.byName(qrShape);
        liveEl.qrErrorCorrection = qrErrorCorrection;
        liveEl.qrPadding = qrPadding;
        liveEl.startValue = serialStart;
        liveEl.interval = serialInterval;
        liveEl.serialPadding = serialPadding;
        liveEl.prefix = prefix;
        liveEl.suffix = suffix;
        liveEl.serialEnabled = serialEnabled;
        liveEl.dateFormat = dateFormat;
        liveEl.timeFormat = timeFormat;
        liveEl.timeOffsetMinutes = timeOffset;
        liveEl.liveTime = liveTime;
        liveEl.lineStyle = lineStyle;
        liveEl.filled = filled;
        liveEl.imageFit = imageFit;
        liveEl.imageBorderRadius = imageBorderRadius;
        liveEl.imageBorderColorValue = imageBorderColorValue;
        liveEl.imageBorderWidth = imageBorderWidth;
        liveEl.shapeStrokeStyle = shapeStrokeStyle;
        liveEl.coloredCode = colorValue != 0xFF000000;

        final txt = contentCtrl.text.trim();
        switch (type) {
          case LabelElementType.text:
            liveEl.content = txt.isEmpty ? 'Sample text' : txt;
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.qrCode:
            liveEl.content = txt.isEmpty ? 'QR-DATA' : txt;
            liveEl.size = Size(widthVal, widthVal);
            break;
          case LabelElementType.barcode:
            liveEl.content = txt.isEmpty ? '123456789012' : txt;
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.time:
            liveEl.content = formatLabelDateTime(DateTime.now().add(Duration(minutes: timeOffset)), datePattern: dateFormat, timePattern: timeFormat);
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.serial:
            liveEl.content = serialStart.toString().padLeft(serialPadding, '0');
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.line:
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.rectangle:
            liveEl.size = Size(widthVal, heightVal);
            break;
          case LabelElementType.circle:
            liveEl.size = Size(widthVal, widthVal);
            break;
          default: break;
        }
      });
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void update(VoidCallback fn) {
            setSheetState(fn);
            applyLive();
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.60,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: JoynColors.border))),
                  child: Column(
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: _Premium.gradient(JoynColors.primary),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _Premium.floatingShadow(JoynColors.primary),
                            ),
                            child: Icon(_iconForToolType(type), color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit ${_titleForToolType(type).replaceFirst('Add ', '')}' : _titleForToolType(type),
                              style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (isEdit)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () => Navigator.pop(ctx, 'delete'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx, 'cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 20, right: 20, top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (type == LabelElementType.text || (type == LabelElementType.qrCode && !serialEnabled) || (type == LabelElementType.barcode && !serialEnabled)) ...[
                          _sheetTextField(
                            label: type == LabelElementType.text
                                ? 'Text Content'
                                : (type == LabelElementType.qrCode ? 'QR Data (URL / Text)' : 'Barcode Value'),
                            controller: contentCtrl,
                            maxLines: type == LabelElementType.text ? 3 : 1,
                            onChanged: (_) => update(() {}),
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (type == LabelElementType.qrCode || type == LabelElementType.barcode) ...[
                          _sectionDivider('Serial / Auto Number'),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Serial mode (auto-increment)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Batch print me har label ki value badhegi', style: TextStyle(fontSize: 11.5)),
                            value: serialEnabled,
                            activeColor: JoynColors.primary,
                            onChanged: (v) => update(() => serialEnabled = v),
                          ),
                          if (serialEnabled) ...[
                            Row(children: [
                              Expanded(child: _sheetTextField(label: 'Prefix', controller: TextEditingController(text: prefix), onChanged: (v) => update(() => prefix = v))),
                              const SizedBox(width: 10),
                              Expanded(child: _sheetTextField(label: 'Suffix', controller: TextEditingController(text: suffix), onChanged: (v) => update(() => suffix = v))),
                            ]),
                            Row(children: [
                              Expanded(child: _sheetTextField(label: 'Start', controller: TextEditingController(text: serialStart.toString()), onChanged: (v) => update(() => serialStart = int.tryParse(v) ?? 1))),
                              const SizedBox(width: 10),
                              Expanded(child: _sheetTextField(label: 'Interval', controller: TextEditingController(text: serialInterval.toString()), onChanged: (v) => update(() => serialInterval = int.tryParse(v) ?? 1))),
                              const SizedBox(width: 10),
                              Expanded(child: _sheetTextField(label: 'Pad', controller: TextEditingController(text: serialPadding.toString()), onChanged: (v) => update(() => serialPadding = int.tryParse(v) ?? 4))),
                            ]),
                            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)),
                                child: Text('Preview: $prefix${serialStart.toString().padLeft(serialPadding, '0')}$suffix', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600))),
                          ] else
                            Row(children: [
                              Expanded(child: _sheetTextField(
                                label: type == LabelElementType.qrCode ? 'QR Data (URL / Text)' : 'Barcode Value',
                                controller: contentCtrl,
                                onChanged: (_) => update(() {}),
                              )),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  final rnd = (100000000000 + DateTime.now().millisecondsSinceEpoch % 899999999999).toString();
                                  contentCtrl.text = rnd;
                                  update(() {});
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.shuffle_rounded, size: 18, color: JoynColors.primary),
                                ),
                              ),
                            ]),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.text || type == LabelElementType.serial || type == LabelElementType.time) ...[
                          _sectionDivider('Typography'),
                          _sheetLabel('Font family'),
                          const SizedBox(height: 8),
                          _dropdownContainer(value: fontFamily, items: _kFontFamilies, onChanged: (v) => update(() => fontFamily = v)),
                          const SizedBox(height: 12),
                          _sheetLabel('Font weight'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: _kFontWeights.map((w) => _choiceChip(label: '$w', selected: fontWeight == w, onTap: () => update(() => fontWeight = w))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Font size: ${fontSize.toInt()}'),
                          Slider(value: fontSize, min: 8, max: 96, activeColor: JoynColors.primary, onChanged: (v) => update(() => fontSize = v)),
                          const SizedBox(height: 6),
                          _sheetLabel('Letter spacing: ${letterSpacing.toStringAsFixed(1)}'),
                          Slider(value: letterSpacing, min: -2, max: 10, activeColor: JoynColors.primary, onChanged: (v) => update(() => letterSpacing = v)),
                          const SizedBox(height: 6),
                          _sheetLabel('Line height: ${lineHeight.toStringAsFixed(2)}'),
                          Slider(value: lineHeight, min: 0.8, max: 3, activeColor: JoynColors.primary, onChanged: (v) => update(() => lineHeight = v)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _toggleChip(icon: Icons.format_bold_rounded, label: 'Bold', selected: bold, onTap: () => update(() => bold = !bold)),
                            _toggleChip(icon: Icons.format_italic_rounded, label: 'Italic', selected: italic, onTap: () => update(() => italic = !italic)),
                            _toggleChip(icon: Icons.format_underline_rounded, label: 'Underline', selected: underline, onTap: () => update(() => underline = !underline)),
                            _toggleChip(icon: Icons.format_strikethrough_rounded, label: 'Strike', selected: strikethrough, onTap: () => update(() => strikethrough = !strikethrough)),
                            _toggleChip(icon: Icons.text_fields_rounded, label: 'UPPER', selected: uppercase, onTap: () => update(() { uppercase = !uppercase; if (uppercase) lowercase = false; })),
                            _toggleChip(icon: Icons.text_fields_rounded, label: 'lower', selected: lowercase, onTap: () => update(() { lowercase = !lowercase; if (lowercase) uppercase = false; })),
                          ]),
                          const SizedBox(height: 12),
                          _sheetLabel('Alignment'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: [
                            _alignChip(Icons.format_align_left_rounded, textAlign == TextAlign.left, () => update(() => textAlign = TextAlign.left)),
                            _alignChip(Icons.format_align_center_rounded, textAlign == TextAlign.center, () => update(() => textAlign = TextAlign.center)),
                            _alignChip(Icons.format_align_right_rounded, textAlign == TextAlign.right, () => update(() => textAlign = TextAlign.right)),
                            _alignChip(Icons.format_align_justify_rounded, textAlign == TextAlign.justify, () => update(() => textAlign = TextAlign.justify)),
                          ]),
                          const SizedBox(height: 12),
                          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Auto-fit text', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), value: autoFit, activeColor: JoynColors.primary, onChanged: (v) => update(() => autoFit = v)),
                          const SizedBox(height: 8),
                          _sectionDivider('Text Shadow'),
                          _sheetLabel('Blur: ${textShadowBlur.toInt()}'),
                          Slider(value: textShadowBlur, min: 0, max: 20, activeColor: JoynColors.primary, onChanged: (v) => update(() => textShadowBlur = v)),
                          if (textShadowBlur > 0) ...[
                            const SizedBox(height: 8),
                            _sheetLabel('Shadow color'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                              final sel = textShadowColorValue == c.toARGB32();
                              return GestureDetector(
                                onTap: () => update(() => textShadowColorValue = c.toARGB32()),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                              );
                            }).toList()),
                          ],
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.qrCode) ...[
                          _sectionDivider('QR Appearance'),
                          _sheetLabel('QR Shape'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: ['square', 'circle', 'roundedRect'].map((s) => _choiceChip(label: s == 'roundedRect' ? 'Rounded' : (s == 'square' ? 'Square' : 'Circle'), selected: qrShape == s, onTap: () => update(() => qrShape = s))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Error correction'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: ['L', 'M', 'Q', 'H'].asMap().entries.map((e) => _choiceChip(label: e.value, selected: qrErrorCorrection == e.key, onTap: () => update(() => qrErrorCorrection = e.key))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('QR padding: ${qrPadding.toInt()}'),
                          Slider(value: qrPadding, min: 0, max: 30, activeColor: JoynColors.primary, onChanged: (v) => update(() => qrPadding = v)),
                          const SizedBox(height: 8),
                          _sheetLabel('QR Background'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                            final sel = qrBackgroundValue == c.toARGB32();
                            return GestureDetector(
                              onTap: () => update(() => qrBackgroundValue = c.toARGB32()),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                            );
                          }).toList()),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.barcode) ...[
                          _sectionDivider('Barcode Settings'),
                          _sheetLabel('Barcode Type'),
                          const SizedBox(height: 8),
                          _dropdownContainer(value: barcodeType.toUpperCase(), items: _kBarcodeTypes.map((t) => t.toUpperCase()).toList(), onChanged: (v) => update(() => barcodeType = v.toLowerCase())),
                          const SizedBox(height: 12),
                          _sheetLabel('Style'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: [
                            _choiceChip(label: 'Normal', selected: barcodeStyle == BarcodeStyle.normal, onTap: () => update(() => barcodeStyle = BarcodeStyle.normal)),
                            _choiceChip(label: 'Isometric', selected: barcodeStyle == BarcodeStyle.isometric, onTap: () => update(() => barcodeStyle = BarcodeStyle.isometric)),
                          ]),
                          const SizedBox(height: 12),
                          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show text below barcode', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), value: barcodeShowText, activeColor: JoynColors.primary, onChanged: (v) => update(() => barcodeShowText = v)),
                          if (barcodeShowText) ...[
                            _sheetLabel('Text size: ${barcodeFontSize.toInt()}'),
                            Slider(value: barcodeFontSize, min: 6, max: 24, activeColor: JoynColors.primary, onChanged: (v) => update(() => barcodeFontSize = v)),
                          ],
                          const SizedBox(height: 8),
                          _sheetLabel('Barcode Background'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                            final sel = barcodeBackgroundValue == c.toARGB32();
                            return GestureDetector(
                              onTap: () => update(() => barcodeBackgroundValue = c.toARGB32()),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                            );
                          }).toList()),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.time) ...[
                          _sectionDivider('Date & Time'),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Real-time', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Off karne par time fix ho jayega', style: TextStyle(fontSize: 11.5)),
                            value: liveTime,
                            activeColor: JoynColors.primary,
                            onChanged: (v) => update(() => liveTime = v),
                          ),
                          const SizedBox(height: 8),
                          _sheetLabel('Date format'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: _kDateFormats.map((f) => _choiceChip(label: f, selected: dateFormat == f, onTap: () => update(() => dateFormat = f))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Time format'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: _kTimeFormats.map((f) => _choiceChip(label: f, selected: timeFormat == f, onTap: () => update(() => timeFormat = f))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Time offset: ${timeOffset >= 0 ? '+' : ''}${timeOffset} min'),
                          Slider(value: timeOffset.toDouble(), min: -720, max: 720, divisions: 96, activeColor: JoynColors.primary, onChanged: (v) => update(() => timeOffset = v.toInt())),
                          const SizedBox(height: 10),
                          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)),
                              child: Text('Preview: ${formatLabelDateTime(DateTime.now().add(Duration(minutes: timeOffset)), datePattern: dateFormat, timePattern: timeFormat)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600))),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.serial) ...[
                          _sectionDivider('Serial Number'),
                          Row(children: [
                            Expanded(child: _sheetTextField(label: 'Prefix', controller: TextEditingController(text: prefix), onChanged: (v) => update(() => prefix = v))),
                            const SizedBox(width: 10),
                            Expanded(child: _sheetTextField(label: 'Suffix', controller: TextEditingController(text: suffix), onChanged: (v) => update(() => suffix = v))),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _sheetTextField(label: 'Start', controller: TextEditingController(text: serialStart.toString()), onChanged: (v) => update(() => serialStart = int.tryParse(v) ?? 1))),
                            const SizedBox(width: 10),
                            Expanded(child: _sheetTextField(label: 'Interval', controller: TextEditingController(text: serialInterval.toString()), onChanged: (v) => update(() => serialInterval = int.tryParse(v) ?? 1))),
                            const SizedBox(width: 10),
                            Expanded(child: _sheetTextField(label: 'Pad', controller: TextEditingController(text: serialPadding.toString()), onChanged: (v) => update(() => serialPadding = int.tryParse(v) ?? 4))),
                          ]),
                          const SizedBox(height: 12),
                          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)),
                              child: Text('Preview: $prefix${serialStart.toString().padLeft(serialPadding, '0')}$suffix', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600))),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.line) ...[
                          _sectionDivider('Line Style'),
                          _sheetLabel('Style'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: ShapeStrokeStyle.values.map((s) => _choiceChip(label: s.name.toUpperCase(), selected: shapeStrokeStyle == s, onTap: () => update(() => shapeStrokeStyle = s))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Thickness: ${heightVal.toInt()}'),
                          Slider(value: heightVal.clamp(1, 20).toDouble(), min: 1, max: 20, activeColor: JoynColors.primary, onChanged: (v) => update(() => heightVal = v)),
                          const SizedBox(height: 8),
                          _sheetLabel('Width: ${widthVal.toInt()}'),
                          Slider(value: widthVal.clamp(20, 320).toDouble(), min: 20, max: 320, activeColor: JoynColors.primary, onChanged: (v) => update(() => widthVal = v)),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.rectangle || type == LabelElementType.circle) ...[
                          _sectionDivider('Shape Styling'),
                          _sheetLabel('Stroke style'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: ShapeStrokeStyle.values.map((s) => _choiceChip(label: s.name.toUpperCase(), selected: shapeStrokeStyle == s, onTap: () => update(() => shapeStrokeStyle = s))).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Border width: ${strokeWidth.toStringAsFixed(1)}'),
                          Slider(value: strokeWidth, min: 0.5, max: 10, activeColor: JoynColors.primary, onChanged: (v) => update(() => strokeWidth = v)),
                          const SizedBox(height: 8),
                          if (type == LabelElementType.rectangle) ...[
                            _sheetLabel('Corner radius: ${cornerRadius.toInt()}'),
                            Slider(value: cornerRadius, min: 0, max: 40, activeColor: JoynColors.primary, onChanged: (v) => update(() => cornerRadius = v)),
                            const SizedBox(height: 8),
                          ],
                          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Fill shape', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), value: filled, activeColor: JoynColors.primary, onChanged: (v) => update(() => filled = v)),
                          if (filled) ...[
                            _sheetLabel('Fill color'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                              final sel = fillColorValue == c.toARGB32();
                              return GestureDetector(
                                onTap: () => update(() => fillColorValue = c.toARGB32()),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                              );
                            }).toList()),
                          ],
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.image && isEdit) ...[
                          _sectionDivider('Image Options'),
                          _sheetLabel('Fit mode'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: [
                            _choiceChip(label: 'Contain', selected: imageFit == BoxFit.contain, onTap: () => update(() => imageFit = BoxFit.contain)),
                            _choiceChip(label: 'Cover', selected: imageFit == BoxFit.cover, onTap: () => update(() => imageFit = BoxFit.cover)),
                            _choiceChip(label: 'Fill', selected: imageFit == BoxFit.fill, onTap: () => update(() => imageFit = BoxFit.fill)),
                          ]),
                          const SizedBox(height: 12),
                          _sheetLabel('Corner radius: ${imageBorderRadius.toInt()}'),
                          Slider(value: imageBorderRadius, min: 0, max: 60, activeColor: JoynColors.primary, onChanged: (v) => update(() => imageBorderRadius = v)),
                          const SizedBox(height: 8),
                          _sheetLabel('Border width: ${imageBorderWidth.toStringAsFixed(1)}'),
                          Slider(value: imageBorderWidth, min: 0, max: 8, activeColor: JoynColors.primary, onChanged: (v) => update(() => imageBorderWidth = v)),
                          if (imageBorderWidth > 0) ...[
                            const SizedBox(height: 8),
                            _sheetLabel('Border color'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                              final sel = imageBorderColorValue == c.toARGB32();
                              return GestureDetector(
                                onTap: () => update(() => imageBorderColorValue = c.toARGB32()),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                              );
                            }).toList()),
                          ],
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.text) ...[
                          _sectionDivider('Colors'),
                          _sheetLabel('Text color'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                            final sel = colorValue == c.toARGB32();
                            return GestureDetector(
                              onTap: () => update(() => colorValue = c.toARGB32()),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                            );
                          }).toList()),
                          const SizedBox(height: 12),
                          _sheetLabel('Background color'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            GestureDetector(
                              onTap: () => update(() => backgroundColorValue = null),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: backgroundColorValue == null ? JoynColors.primary : Colors.grey.shade300, width: backgroundColorValue == null ? 3 : 1)), child: const Icon(Icons.close, size: 14, color: Colors.grey)),
                            ),
                            ..._kSwatches.map((c) {
                              final sel = backgroundColorValue == c.toARGB32();
                              return GestureDetector(
                                onTap: () => update(() => backgroundColorValue = c.toARGB32()),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                              );
                            }),
                          ]),
                          const SizedBox(height: 12),
                          _sheetLabel('Padding: ${padding.toInt()}'),
                          Slider(value: padding, min: 0, max: 30, activeColor: JoynColors.primary, onChanged: (v) => update(() => padding = v)),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.qrCode || type == LabelElementType.barcode) ...[
                          _sheetLabel('Foreground color'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                            final sel = colorValue == c.toARGB32();
                            return GestureDetector(
                              onTap: () => update(() => colorValue = c.toARGB32()),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                            );
                          }).toList()),
                          const SizedBox(height: 14),
                        ],

                        if (type == LabelElementType.line || type == LabelElementType.rectangle || type == LabelElementType.circle) ...[
                          _sheetLabel('Stroke color'),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _kSwatches.map((c) {
                            final sel = colorValue == c.toARGB32();
                            return GestureDetector(
                              onTap: () => update(() => colorValue = c.toARGB32()),
                              child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? JoynColors.primary : Colors.grey.shade300, width: sel ? 3 : 1))),
                            );
                          }).toList()),
                          const SizedBox(height: 14),
                        ],

                        if (type != LabelElementType.line) ...[
                          _sectionDivider('Size & Layout'),
                          _sheetLabel('Width: ${widthVal.toInt()}'),
                          Slider(value: widthVal.clamp(20, 320).toDouble(), min: 20, max: 320, activeColor: JoynColors.primary, onChanged: (v) => update(() => widthVal = v)),
                          if (type != LabelElementType.qrCode && type != LabelElementType.circle) ...[
                            const SizedBox(height: 6),
                            _sheetLabel('Height: ${heightVal.toInt()}'),
                            Slider(value: heightVal.clamp(20, 320).toDouble(), min: 20, max: 320, activeColor: JoynColors.primary, onChanged: (v) => update(() => heightVal = v)),
                          ],
                        ],

                        const SizedBox(height: 8),
                        _sheetLabel('Rotation: ${rotationDeg.toStringAsFixed(0)}°'),
                        Slider(value: rotationDeg, min: -180, max: 180, divisions: 36, activeColor: JoynColors.primary, onChanged: (v) => update(() => rotationDeg = v)),

                        const SizedBox(height: 8),
                        _sheetLabel('Opacity: ${(opacity * 100).toInt()}%'),
                        Slider(value: opacity, min: 0.05, max: 1, activeColor: JoynColors.primary, onChanged: (v) => update(() => opacity = v)),

                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _toggleChip(icon: Icons.flip_rounded, label: 'Flip H', selected: flipH, onTap: () => update(() => flipH = !flipH))),
                          const SizedBox(width: 8),
                          Expanded(child: _toggleChip(icon: Icons.flip_rounded, label: 'Flip V', selected: flipV, onTap: () => update(() => flipV = !flipV))),
                        ]),

                        const SizedBox(height: 12),
                        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Drop shadow', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), value: shadowEnabled, activeColor: JoynColors.primary, onChanged: (v) => update(() => shadowEnabled = v)),
                        if (shadowEnabled) ...[
                          _sheetLabel('Shadow blur: ${shadowBlur.toInt()}'),
                          Slider(value: shadowBlur, min: 0, max: 30, activeColor: JoynColors.primary, onChanged: (v) => update(() => shadowBlur = v)),
                        ],

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: JoynColors.border)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, 'cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: JoynColors.secondaryText,
                              side: BorderSide(color: JoynColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, 'save'),
                            icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 20),
                            label: Text(isEdit ? 'Update Element' : 'Add to Label',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JoynColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (action == 'save') {
      HapticFeedback.selectionClick();
    } else if (action == 'delete') {
      setState(() {
        _elements.removeWhere((e) => e.id == liveEl.id);
        if (_selectedId == liveEl.id) _selectedId = null;
      });
    } else {
      if (isEdit && originalSnapshot != null) {
        setState(() {
          final idx = _elements.indexWhere((e) => e.id == originalSnapshot!.id);
          if (idx >= 0) _elements[idx] = originalSnapshot!;
          _selectedId = originalSnapshot!.id;
        });
      } else {
        setState(() {
          _elements.removeWhere((e) => e.id == liveEl.id);
          if (_selectedId == liveEl.id) _selectedId = null;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPER UI METHODS
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionDivider(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: JoynColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF16171D))),
    ]),
  );

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: JoynTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
  );

  Widget _sheetTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: JoynColors.chipBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  Widget _dropdownContainer({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13.5)))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      );

  Widget _choiceChip({required String label, required bool selected, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
            color: selected ? null : JoynColors.chipBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : JoynColors.secondaryText)),
        ),
      );

  Widget _toggleChip({required IconData icon, required String label, required bool selected, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
            color: selected ? null : JoynColors.chipBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.transparent : JoynColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: selected ? Colors.white : JoynColors.secondaryText),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : JoynColors.secondaryText)),
          ]),
        ),
      );

  Widget _alignChip(IconData icon, bool selected, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: selected ? _Premium.gradient(JoynColors.primary) : null,
            color: selected ? null : JoynColors.chipBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: selected ? Colors.white : JoynColors.secondaryText),
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  //  ELEMENT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════
  void _deleteElement(String id) {
    _pushHistory();
    setState(() { _elements.removeWhere((e) => e.id == id); if (_selectedId == id) _selectedId = null; });
  }

  void _duplicateElement(String id) {
    _pushHistory();
    final original = _elements.firstWhere((e) => e.id == id);
    final clone = original.deepClone(newId: _nextId());
    clone.position = original.position + const Offset(14, 14);
    clone.zIndex = _elements.length;
    setState(() { _elements.add(clone); _selectedId = clone.id; });
  }

  void _rotateSelected() { if (_selectedId == null || _selected!.locked) return; _pushHistory(); setState(() => _selected!.rotation += 1.5708); }
  void _bringToFront() { if (_selectedId == null) return; _pushHistory(); setState(() { final el = _selected!; _elements.remove(el); el.zIndex = _elements.length; _elements.add(el); }); }
  void _sendToBack() { if (_selectedId == null) return; _pushHistory(); setState(() { final el = _selected!; _elements.remove(el); el.zIndex = -1; _elements.insert(0, el); }); }
  void _flipH() { if (_selectedId == null) return; _pushHistory(); setState(() => _selected!.flipHorizontal = !_selected!.flipHorizontal); }
  void _flipV() { if (_selectedId == null) return; _pushHistory(); setState(() => _selected!.flipVertical = !_selected!.flipVertical); }
  void _toggleLock() { if (_selectedId == null) return; setState(() => _selected!.locked = !_selected!.locked); }

  void _clearCanvas() {
    if (_elements.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.all(16), child: Text('Clear label?', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
          ListTile(leading: const Icon(Icons.delete_outline_rounded, color: JoynColors.error), title: const Text('Clear All Elements'), onTap: () { _pushHistory(); setState(() { _elements.clear(); _selectedId = null; }); Navigator.pop(context); }),
          ListTile(leading: const Icon(Icons.close_rounded, color: JoynColors.secondaryText), title: const Text('Cancel'), onTap: () => Navigator.pop(context)),
          const SizedBox(height: 12),
        ]),
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

  Future<void> _printViaSystem({bool batch = false}) async {
    setState(() { _selectedId = null; _isBusy = true; });
    await Future.delayed(const Duration(milliseconds: 80));

    final pdf = pw.Document();

    if (batch && _importedRows.isNotEmpty) {
      for (int i = 0; i < _importedRows.length; i++) {
        setState(() => _batchRowIndex = i);
        await Future.delayed(const Duration(milliseconds: 60));
        final bytes = await _captureCanvasAsPng();
        if (bytes == null) continue;
        final image = pw.MemoryImage(bytes);
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat(
            _labelSizeMm.width * PdfPageFormat.mm,
            _labelSizeMm.height * PdfPageFormat.mm,
          ),
          build: (_) => pw.Center(child: pw.Image(image)),
        ));
      }
      setState(() => _batchRowIndex = 0);
    } else {
      final bytes = await _captureCanvasAsPng();
      if (bytes == null) { setState(() => _isBusy = false); return; }
      final image = pw.MemoryImage(bytes);
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(
          _labelSizeMm.width * PdfPageFormat.mm,
          _labelSizeMm.height * PdfPageFormat.mm,
        ),
        build: (_) => pw.Center(child: pw.Image(image)),
      ));
    }

    if (!mounted) return;
    setState(() => _isBusy = false);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'label_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  void _showPrintOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: JoynColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: JoynColors.border, borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text('Print label', style: JoynTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
          ListTile(leading: const Icon(Icons.print_outlined, color: JoynColors.primary), title: const Text('System print / PDF'), onTap: () { Navigator.pop(context); _printViaSystem(); }),
          if (_importedRows.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.print_rounded, color: Color(0xFF7C3AED)),
              title: Text('Batch Print (${_importedRows.length} labels)'),
              subtitle: const Text('Each row = one label'),
              onTap: () { Navigator.pop(context); _printViaSystem(batch: true); },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXCEL / CSV IMPORT
  // ═══════════════════════════════════════════════════════════════
  void _openExcelImport() {
    final textCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: _Premium.gradient(JoynColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Import Data',
                    style: JoynTypography.titleMedium.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JoynColors.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paste CSV / Excel data',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Format: col1,col2,col3\\nrow1a,row1b,row1c',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textCtrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Name,Price,Qty\\nItem1,100,5\\nItem2,200,3',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final parsed = _parseCsv(textCtrl.text);
                    if (parsed.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No valid data found')));
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _importedRows = parsed);
                    Future.delayed(const Duration(milliseconds: 200), _showImportPreview);
                  },
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Import Data',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoynColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _importedRows = [
                      {'Name': 'Item 1', 'Price': '100', 'Qty': '5'},
                      {'Name': 'Item 2', 'Price': '200', 'Qty': '3'},
                      {'Name': 'Item 3', 'Price': '150', 'Qty': '2'},
                    ]);
                    Future.delayed(const Duration(milliseconds: 200), _showImportPreview);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Use Sample Data',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JoynColors.primary,
                    side: const BorderSide(color: Colors.transparent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_importedRows.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showImportPreview();
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: Text('View Current Import (${_importedRows.length} rows)',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseCsv(String raw) {
    final lines = raw.trim().split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return [];

    final first = lines.first;
    String sep = ',';
    if (first.contains('\t')) sep = '\t';
    else if (first.contains(';') && !first.contains(',')) sep = ';';

    final headers = first.split(sep).map((h) => h.trim()).toList();
    final rows = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final cells = _splitCsvLine(lines[i], sep);
      final row = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < cells.length ? cells[j].trim() : '';
      }
      rows.add(row);
    }
    return rows;
  }

  List<String> _splitCsvLine(String line, String sep) {
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') { inQuotes = !inQuotes; }
      else if (c == sep && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else { buf.write(c); }
    }
    result.add(buf.toString());
    return result;
  }

  void _showImportPreview() {
    if (_importedRows.isEmpty) return;
    final headers = _importedRows.first.keys.toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: JoynColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${_importedRows.length} rows imported',
                          style: JoynTypography.titleMedium.copyWith(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        JoynColors.chipBackground),
                    columns: headers.map((h) => DataColumn(
                        label: Text(h,
                            style: const TextStyle(fontWeight: FontWeight.w800,
                                fontSize: 12)))).toList(),
                    rows: _importedRows.take(50).map((row) => DataRow(
                      cells: headers.map((h) => DataCell(
                          Text('${row[h] ?? ''}',
                              style: const TextStyle(fontSize: 12)))).toList(),
                    )).toList(),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: JoynColors.border)),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _importedRows = []);
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Clear',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _printViaSystem(batch: true);
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text('Print ${_importedRows.length} Labels',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JoynColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  Offset _applyCenterSnap(Offset position, Size size) {
    final elCenter = position + Offset(size.width / 2, size.height / 2);
    final canvasCenter = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    double dx = position.dx, dy = position.dy;
    _snapCenterX = (elCenter.dx - canvasCenter.dx).abs() < _snapThreshold;
    _snapCenterY = (elCenter.dy - canvasCenter.dy).abs() < _snapThreshold;
    if (_snapCenterX) dx = canvasCenter.dx - size.width / 2;
    if (_snapCenterY) dy = canvasCenter.dy - size.height / 2;
    if (_snapToGrid) {
      dx = (dx / _gridSpacing).round() * _gridSpacing;
      dy = (dy / _gridSpacing).round() * _gridSpacing;
    }
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final sortedElements = List<LabelElement>.from(_elements)..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: Text('Label Editor', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.undo_rounded), onPressed: _undoStack.isEmpty ? null : _undo, tooltip: 'Undo'),
          IconButton(icon: const Icon(Icons.redo_rounded), onPressed: _redoStack.isEmpty ? null : _redo, tooltip: 'Redo'),
          IconButton(icon: const Icon(Icons.layers_rounded), onPressed: _showLayersPanel, tooltip: 'Layers'),
          IconButton(icon: const Icon(Icons.palette_rounded), onPressed: _showQuickPalettes, tooltip: 'Palettes'),
          _isBusy
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              switch (value) {
                case 'print':
                  _showPrintOptions();
                  break;
                case 'save':
                  _saveLayout();
                  break;
                case 'duplicate_label':
                  _duplicateLabel();
                  break;
                case 'my_labels':
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLabelsScreen()));
                  if (!mounted) return;
                  final activeId = await LabelStorageService.getActiveId();
                  if (activeId != null) {
                    final lbl = await LabelStorageService.getById(activeId);
                    if (lbl != null && mounted) {
                      setState(() { _activeLabelId = lbl.id; _activeLabelName = lbl.name; });
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'print',
                child: Row(children: [
                  Icon(Icons.print_rounded, size: 19, color: JoynColors.primary),
                  SizedBox(width: 12),
                  Text('Print', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(children: [
                  Icon(Icons.save_outlined, size: 19, color: JoynColors.primary),
                  SizedBox(width: 12),
                  Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
              PopupMenuItem(
                value: 'duplicate_label',
                child: Row(children: [
                  Icon(Icons.copy_all_rounded, size: 19, color: JoynColors.primary),
                  SizedBox(width: 12),
                  Text('Duplicate Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
              PopupMenuDivider(height: 8),
              PopupMenuItem(
                value: 'my_labels',
                child: Row(children: [
                  Icon(Icons.folder_special_rounded, size: 19, color: JoynColors.primary),
                  SizedBox(width: 12),
                  Text('My Labels', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _showPrintOptions,
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text('Print', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
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
              child: Row(children: [
                _toolbarChip('${_labelSizeMm.width.toInt()}x${_labelSizeMm.height.toInt()}mm', Icons.straighten_rounded),
                const SizedBox(width: 4),
                _toolbarIcon(Icons.settings_rounded, false, _showCanvasSettings),
                _toolbarIcon(Icons.border_style_rounded,
                    _borderStyle != LabelBorderStyle.none, _showBorderSheet),
                _toolbarIcon(Icons.palette_rounded, false, _showQuickPalettes),
                _toolbarIcon(Icons.layers_rounded, false, _showLayersPanel),
                _toolbarIcon(Icons.cleaning_services_outlined, false, _clearCanvas),
                if (_selectedId != null) ...[
                  _toolbarIcon(Icons.rotate_right_rounded, false, _rotateSelected),
                  _toolbarIcon(Icons.flip_rounded, false, _flipH),
                  _toolbarIcon(_selected!.locked ? Icons.lock_rounded : Icons.lock_open_rounded, _selected!.locked, _toggleLock),
                  _toolbarIcon(Icons.flip_to_front_rounded, false, _bringToFront),
                  _toolbarIcon(Icons.flip_to_back_rounded, false, _sendToBack),
                  _toolbarIcon(Icons.copy_rounded, false, _copySelected),
                ],
                if (_clipboard != null) _toolbarIcon(Icons.paste_rounded, false, _pasteElement),
              ]),
            ),
          ),

          if (_selectedId != null)
            Container(
              height: 40,
              color: JoynColors.background,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Text('Align:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                  const SizedBox(width: 8),
                  _alignBtn(Icons.align_horizontal_left_rounded, () => _alignSelected('left'), 'Left'),
                  _alignBtn(Icons.align_horizontal_center_rounded, () => _alignSelected('cx'), 'Center H'),
                  _alignBtn(Icons.align_horizontal_right_rounded, () => _alignSelected('right'), 'Right'),
                  const SizedBox(width: 8),
                  _alignBtn(Icons.align_vertical_top_rounded, () => _alignSelected('top'), 'Top'),
                  _alignBtn(Icons.align_vertical_center_rounded, () => _alignSelected('cy'), 'Center V'),
                  _alignBtn(Icons.align_vertical_bottom_rounded, () => _alignSelected('bottom'), 'Bottom'),
                ]),
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
                        decoration: BoxDecoration(
                          color: Color(_canvasBgValue),
                          borderRadius: BorderRadius.circular(_isCircle ? _canvasSize.width / 2 : 14),
                          boxShadow: _Premium.cardShadow,
                          image: _canvasBgImagePath != null
                              ? DecorationImage(image: FileImage(File(_canvasBgImagePath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (_gridStyle != GridStyle.off)
                              Positioned.fill(child: CustomPaint(painter: _GridPainter(style: _gridStyle, spacing: _gridSpacing, color: Colors.grey.withValues(alpha: 0.20)))),
                            ...sortedElements.where((e) => e.visible).map((el) => _buildElementView(el)),
                            if (_snapCenterX) Positioned(left: _canvasSize.width / 2, top: 0, bottom: 0, child: Container(width: 1, color: JoynColors.primary)),
                            if (_snapCenterY) Positioned(top: _canvasSize.height / 2, left: 0, right: 0, child: Container(height: 1, color: JoynColors.primary)),
                            if (_borderStyle != LabelBorderStyle.none)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _LabelBorderPainter(
                                      style: _borderStyle,
                                      thickness: _borderThickness,
                                      color: Color(_borderColorValue),
                                    ),
                                  ),
                                ),
                              ),
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

          // ═══════════════════════════════════════════════════════
          //  BOTTOM TOOLBAR — 2 PAGES
          // ═══════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(gradient: _Premium.surfaceGradient),
            child: SizedBox(
              height: 80,
              child: PageView(
                controller: _toolPageController,
                onPageChanged: (i) => setState(() => _toolPageIndex = i),
                children: [
                  // ───── PAGE 1 ─────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _toolButton(Icons.title_rounded, 'Text',
                            () => _showToolSheet(LabelElementType.text)),
                    _toolButton(Icons.qr_code_2_rounded, 'QR Code',
                            () => _showToolSheet(LabelElementType.qrCode)),
                    _toolButton(Icons.view_week_outlined, 'Barcode',
                            () => _showToolSheet(LabelElementType.barcode)),
                    _toolButton(Icons.access_time_rounded, 'Time',
                            () => _showToolSheet(LabelElementType.time)),
                    _toolButton(Icons.emoji_emotions_outlined, 'Material',
                        _showMaterialLibrary),
                  ]),
                  // ───── PAGE 2 ─────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _toolButton(Icons.crop_square_rounded, 'Shape',
                            () => _showShapePicker(ShapeKind.square)),
                    _toolButton(Icons.image_outlined, 'Image',
                            () => _showToolSheet(LabelElementType.image)),
                    _toolButton(Icons.tag_rounded, 'Serial No.',
                            () => _showToolSheet(LabelElementType.serial)),
                    _toolButton(Icons.border_style_rounded, 'Border',
                        _showBorderSheet),
                    _toolButton(Icons.table_chart_outlined, 'Excel',
                        _openExcelImport),
                  ]),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              final active = i == _toolPageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? JoynColors.primary : JoynColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _alignBtn(IconData icon, VoidCallback onTap, String tooltip) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(width: 32, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: JoynColors.border)),
          child: Icon(icon, size: 16, color: JoynColors.primary)),
    ),
  );

  Widget _toolbarChip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: JoynColors.chipBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: JoynColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: JoynColors.secondaryText), const SizedBox(width: 4), Text(label, style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.primary))]),
  );

  Widget _toolbarIcon(IconData icon, bool active, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(width: 34, height: 34, alignment: Alignment.center,
          decoration: BoxDecoration(color: active ? JoynColors.primary.withValues(alpha: 0.1) : JoynColors.chipBackground, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: active ? JoynColors.primary : JoynColors.secondaryText)),
    ),
  );

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: JoynColors.border), boxShadow: _Premium.fieldShadow),
            child: Icon(icon, color: JoynColors.primary, size: 21)),
        const SizedBox(height: 6),
        Text(label, style: JoynTypography.caption.copyWith(fontSize: 10, color: JoynColors.secondaryText, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _buildElementView(LabelElement el) {
    final isSelected = el.id == _selectedId;
    return Positioned(
      left: el.position.dx, top: el.position.dy,
      child: GestureDetector(
        onTap: () {
          if (el.locked) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Element is locked'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
            setState(() => _selectedId = el.id);
            return;
          }
          setState(() => _selectedId = el.id);
          _showToolSheet(el.type, existing: el);
        },
        onDoubleTap: () {
          if (el.locked) return;
          setState(() => _selectedId = el.id);
          _showToolSheet(el.type, existing: el);
        },
        onPanStart: (_) {
          if (el.locked) return;
          setState(() => _selectedId = el.id);
          _pushHistory();
        },
        onPanUpdate: (details) {
          if (el.locked) return;
          setState(() { el.position = _applyCenterSnap(el.position + details.delta, el.size); });
        },
        onPanEnd: (_) => setState(() { _snapCenterX = false; _snapCenterY = false; }),
        child: Transform.rotate(
          angle: el.rotation,
          child: Transform.scale(
            scaleX: el.flipHorizontal ? -1 : 1,
            scaleY: el.flipVertical ? -1 : 1,
            child: Opacity(
              opacity: el.opacity,
              child: Container(
                width: el.size.width, height: el.size.height,
                padding: EdgeInsets.all(el.padding),
                decoration: BoxDecoration(
                  color: el.backgroundColor,
                  border: Border.all(color: isSelected ? JoynColors.primary : Colors.transparent, width: 1.4),
                  boxShadow: el.shadowEnabled ? [BoxShadow(color: el.shadowColor, blurRadius: el.shadowBlur, offset: el.shadowOffset)] : null,
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: _buildElementContent(el)),
                  if (isSelected && !el.locked) ...[
                    Positioned(left: -14, top: -14, child: _handleButton(Icons.delete_outline_rounded, () => _deleteElement(el.id))),
                    Positioned(right: -14, top: -14, child: _handleButton(Icons.copy_rounded, () => _duplicateElement(el.id))),
                    Positioned(right: -14, bottom: -14, child: GestureDetector(
                      onPanStart: (_) => _pushHistory(),
                      onPanUpdate: (details) => setState(() {
                        el.size = Size((el.size.width + details.delta.dx).clamp(24, _canvasSize.width), (el.size.height + details.delta.dy).clamp(24, _canvasSize.height));
                      }),
                      child: _handleButton(Icons.open_in_full_rounded, null),
                    )),
                  ],
                  if (isSelected && el.locked)
                    Positioned(right: -14, top: -14, child: _handleButton(Icons.lock_rounded, _toggleLock)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _handleButton(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 28, height: 28,
        decoration: BoxDecoration(gradient: _Premium.gradient(JoynColors.primary), shape: BoxShape.circle, boxShadow: _Premium.floatingShadow(JoynColors.primary)),
        child: Icon(icon, size: 15, color: Colors.white)),
  );

  Widget _buildElementContent(LabelElement el) {
    final displayContent = el.displayContentForIndex(_batchRowIndex);
    final effContent = el.uppercase ? displayContent.toUpperCase() : (el.lowercase ? displayContent.toLowerCase() : displayContent);

    switch (el.type) {
      case LabelElementType.text:
        final textWidget = Text(
          effContent,
          textAlign: el.textAlign,
          style: TextStyle(
            fontSize: el.fontSize, color: el.color,
            fontWeight: FontWeight.values.firstWhere((w) => w.value == el.fontWeight, orElse: () => FontWeight.w400),
            fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
            decoration: el.underline ? TextDecoration.underline : (el.strikethrough ? TextDecoration.lineThrough : TextDecoration.none),
            letterSpacing: el.letterSpacing,
            height: el.lineHeightMultiplier,
            fontFamily: el.fontFamily == 'Default' ? null : el.fontFamily,
            shadows: el.textShadowBlur > 0 && el.textShadowColorValue != null
                ? [Shadow(color: el.textShadowColor, blurRadius: el.textShadowBlur, offset: const Offset(1, 1))]
                : null,
          ),
        );
        return el.autoFit ? FittedBox(fit: BoxFit.scaleDown, child: textWidget) : textWidget;
      case LabelElementType.time:
        final tWidget = Text(el.content, style: TextStyle(
          fontSize: el.fontSize, color: el.color,
          fontWeight: FontWeight.values.firstWhere((w) => w.value == el.fontWeight, orElse: () => FontWeight.w400),
          fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: el.letterSpacing, height: el.lineHeightMultiplier,
          fontFamily: el.fontFamily == 'Default' ? null : el.fontFamily,
          shadows: el.textShadowBlur > 0 && el.textShadowColorValue != null ? [Shadow(color: el.textShadowColor, blurRadius: el.textShadowBlur)] : null,
        ));
        return el.autoFit ? FittedBox(fit: BoxFit.scaleDown, child: tWidget) : tWidget;
      case LabelElementType.serial:
        final sWidget = Text(displayContent, style: TextStyle(
          fontSize: el.fontSize, color: el.color,
          fontWeight: FontWeight.values.firstWhere((w) => w.value == el.fontWeight, orElse: () => FontWeight.w600),
          fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: el.letterSpacing, height: el.lineHeightMultiplier,
          fontFamily: el.fontFamily == 'Default' ? null : el.fontFamily,
          shadows: el.textShadowBlur > 0 && el.textShadowColorValue != null ? [Shadow(color: el.textShadowColor, blurRadius: el.textShadowBlur)] : null,
        ));
        return el.autoFit ? FittedBox(fit: BoxFit.scaleDown, child: sWidget) : sWidget;
      case LabelElementType.qrCode:
        return Container(
          color: el.qrBackgroundColor, padding: EdgeInsets.all(el.qrPadding),
          child: QrImageView(
            data: effContent.isEmpty ? ' ' : effContent,
            backgroundColor: el.qrBackgroundColor,
            eyeStyle: QrEyeStyle(color: el.coloredCode ? el.color : Colors.black),
            dataModuleStyle: QrDataModuleStyle(color: el.coloredCode ? el.color : Colors.black),
            errorCorrectionLevel: [QrErrorCorrectLevel.L, QrErrorCorrectLevel.M, QrErrorCorrectLevel.Q, QrErrorCorrectLevel.H][el.qrErrorCorrection.clamp(0, 3)],
          ),
        );
      case LabelElementType.barcode:
        final valid = isValidBarcodeData(el.barcodeType, effContent);
        if (!valid) return Container(alignment: Alignment.center, child: const Text('Invalid data', style: TextStyle(color: Colors.red, fontSize: 10)));
        final widget = BarcodeWidget(
          barcode: barcodeFor(el.barcodeType), data: effContent,
          drawText: el.barcodeShowText,
          style: TextStyle(fontSize: el.barcodeFontSize, color: el.color, fontFamily: el.fontFamily == 'Default' ? null : el.fontFamily),
          color: el.color, backgroundColor: el.barcodeBackgroundColor,
        );
        if (el.barcodeStyle == BarcodeStyle.isometric) {
          return Transform(alignment: FractionalOffset.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateX(0.35)..rotateZ(-0.08), child: widget);
        }
        return widget;
      case LabelElementType.line:
        return CustomPaint(
          painter: _ShapeStrokePainter(
            kind: ShapeKind.line,
            strokeStyle: el.shapeStrokeStyle,
            color: el.color,
            thickness: el.strokeWidth,
          ),
        );
      case LabelElementType.rectangle:
        return CustomPaint(
          painter: _ShapeStrokePainter(
            kind: el.shapeKind == ShapeKind.square ? ShapeKind.square : el.shapeKind,
            strokeStyle: el.shapeStrokeStyle,
            color: el.color,
            thickness: el.strokeWidth,
            fillColor: el.filled ? el.fillColor : null,
            cornerRadius: el.cornerRadius,
          ),
        );
      case LabelElementType.circle:
        return CustomPaint(
          painter: _ShapeStrokePainter(
            kind: el.shapeKind == ShapeKind.ellipse ? ShapeKind.ellipse : ShapeKind.circle,
            strokeStyle: el.shapeStrokeStyle,
            color: el.color,
            thickness: el.strokeWidth,
            fillColor: el.filled ? el.fillColor : null,
          ),
        );
      case LabelElementType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(el.imageBorderRadius),
          child: Container(
            decoration: el.imageBorderWidth > 0
                ? BoxDecoration(borderRadius: BorderRadius.circular(el.imageBorderRadius), border: Border.all(color: el.imageBorderColor, width: el.imageBorderWidth))
                : null,
            child: el.imagePath == null ? Container(color: JoynColors.chipBackground) : Image.file(File(el.imagePath!), fit: el.imageFit),
          ),
        );
      case LabelElementType.sticker:
        MaterialItem? found;
        for (final cat in kMaterialCategories) {
          for (final it in cat.items) {
            if (it.key == el.content) { found = it; break; }
          }
          if (found != null) break;
        }
        if (found == null) return const SizedBox();
        if (found.icon != null) {
          return FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(found.icon, color: el.color),
            ),
          );
        }
        if (found.emoji != null) {
          return FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(found.emoji!, style: const TextStyle(fontSize: 48)),
            ),
          );
        }
        return FittedBox(
          child: Text(found.text ?? '', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: el.color)),
        );
      default:
        return const SizedBox();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  GRID PAINTER
// ═══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final GridStyle style;
  final double spacing;
  final Color color;
  _GridPainter({required this.style, required this.spacing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    if (style == GridStyle.lines) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (style == GridStyle.dots) {
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.style != style || old.spacing != spacing || old.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  BORDER PAINTER
// ═══════════════════════════════════════════════════════════════
class _LabelBorderPainter extends CustomPainter {
  final LabelBorderStyle style;
  final double thickness;
  final Color color;

  _LabelBorderPainter({
    required this.style,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (style == LabelBorderStyle.none) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    const double inset = 8.0;

    // Diagonal corners
    if (style.name.startsWith('diagonal')) {
      final double len = (w < h ? w : h) * 0.18;
      final int styleIdx = int.tryParse(style.name.replaceAll(RegExp(r'\D'), '')) ?? 1;

      for (int corner = 0; corner < 4; corner++) {
        final Offset origin = corner == 0
            ? const Offset(inset, inset)
            : corner == 1
            ? Offset(w - inset, inset)
            : corner == 2
            ? Offset(inset, h - inset)
            : Offset(w - inset, h - inset);
        _drawCorner(canvas, paint, origin, len, styleIdx, corner);
      }

      if (styleIdx == 1 || styleIdx == 4 || styleIdx == 7) {
        canvas.drawLine(const Offset(inset, inset), Offset(w - inset, inset), paint);
        canvas.drawLine(Offset(inset, h - inset), Offset(w - inset, h - inset), paint);
      }
      if (styleIdx == 2 || styleIdx == 5 || styleIdx == 8) {
        canvas.drawLine(const Offset(inset, inset), Offset(inset, h - inset), paint);
        canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, h - inset), paint);
      }
      return;
    }

    // Parallel borders
    if (style.name.startsWith('parallel')) {
      if (style == LabelBorderStyle.parallelDashed) {
        _drawDashedRect(canvas, paint, size, inset);
        return;
      }
      if (style == LabelBorderStyle.parallelDotted) {
        _drawDottedRect(canvas, paint, size, inset);
        return;
      }
      int lines = 1;
      if (style == LabelBorderStyle.parallelTriple) lines = 3;
      if (style == LabelBorderStyle.parallelDouble) lines = 2;
      for (int i = 0; i < lines; i++) {
        final double g = inset + i * (thickness * 2.5);
        canvas.drawRect(Rect.fromLTRB(g, g, w - g, h - g), paint);
      }
      return;
    }

    // Line borders
    if (style.name.startsWith('line')) {
      switch (style) {
        case LabelBorderStyle.lineTopBottom:
          canvas.drawLine(const Offset(inset, inset), Offset(w - inset, inset), paint);
          canvas.drawLine(Offset(inset, h - inset), Offset(w - inset, h - inset), paint);
          break;
        case LabelBorderStyle.lineAllSides:
          canvas.drawRect(Rect.fromLTRB(inset, inset, w - inset, h - inset), paint);
          break;
        case LabelBorderStyle.lineLeft:
          canvas.drawLine(const Offset(inset, inset), Offset(inset, h - inset), paint);
          break;
        case LabelBorderStyle.lineRight:
          canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, h - inset), paint);
          break;
        default:
          break;
      }
      return;
    }

    // Circle / round borders
    if (style.name.startsWith('circle')) {
      final double radius = (w < h ? w : h) / 2 - inset;
      final Offset center = Offset(w / 2, h / 2);
      switch (style) {
        case LabelBorderStyle.circleDots:
          const int dots = 48;
          final fillPaint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          for (int i = 0; i < dots; i++) {
            final double a = (i / dots) * 2 * 3.14159265;
            final double dx = radius * _cos(a);
            final double dy = radius * _sin(a);
            canvas.drawCircle(center + Offset(dx, dy), thickness * 1.2, fillPaint);
          }
          break;
        case LabelBorderStyle.circleDouble:
          canvas.drawCircle(center, radius, paint);
          canvas.drawCircle(center, radius - thickness * 3, paint);
          break;
        default:
          canvas.drawCircle(center, radius, paint);
      }
      return;
    }

    // 4*6 borders
    if (style.name.startsWith('ratio46')) {
      canvas.drawRect(Rect.fromLTRB(inset, inset, w - inset, h - inset), paint);
      if (style == LabelBorderStyle.ratio46Double) {
        final double g = inset + thickness * 3;
        canvas.drawRect(Rect.fromLTRB(g, g, w - g, h - g), paint);
      } else if (style == LabelBorderStyle.ratio46Ornate) {
        for (final c in [
          const Offset(inset, inset),
          Offset(w - inset, inset),
          Offset(inset, h - inset),
          Offset(w - inset, h - inset),
        ]) {
          canvas.drawCircle(c, thickness * 3, paint);
        }
      }
      return;
    }
  }

  double _cos(double a) {
    a = a % (2 * 3.14159265);
    if (a > 3.14159265) a -= 2 * 3.14159265;
    if (a > 1.57079632) a = 3.14159265 - a;
    if (a < -1.57079632) a = -3.14159265 - a;
    final double a2 = a * a;
    return 1 - a2 / 2 + a2 * a2 / 24 - a2 * a2 * a2 / 720 + a2 * a2 * a2 * a2 / 40320;
  }

  double _sin(double a) => _cos(a - 1.57079632);

  void _drawCorner(Canvas canvas, Paint p, Offset origin, double len,
      int styleIdx, int corner) {
    final path = Path();
    switch (styleIdx) {
      case 1:
      case 2:
      case 3:
        path.moveTo(origin.dx, origin.dy + len);
        path.lineTo(origin.dx, origin.dy);
        path.lineTo(origin.dx + len, origin.dy);
        break;
      case 4:
      case 5:
      case 6:
        path.moveTo(origin.dx, origin.dy + len * 0.6);
        path.quadraticBezierTo(origin.dx, origin.dy, origin.dx + len * 0.6, origin.dy);
        path.moveTo(origin.dx + len * 0.3, origin.dy + len * 0.3);
        path.lineTo(origin.dx + len * 0.6, origin.dy + len * 0.6);
        break;
      case 7:
      case 8:
        path.moveTo(origin.dx, origin.dy + len);
        path.lineTo(origin.dx, origin.dy);
        path.lineTo(origin.dx + len, origin.dy);
        path.moveTo(origin.dx + len * 0.4, origin.dy + len * 0.4);
        path.lineTo(origin.dx + len * 0.7, origin.dy + len * 0.7);
        break;
      default:
        path.moveTo(origin.dx, origin.dy + len);
        path.lineTo(origin.dx, origin.dy);
        path.lineTo(origin.dx + len, origin.dy);
    }

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(
      corner == 1 || corner == 3 ? -1 : 1,
      corner == 2 || corner == 3 ? -1 : 1,
    );
    canvas.translate(-origin.dx, -origin.dy);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  void _drawDashedRect(Canvas canvas, Paint p, Size s, double inset,
      {double dash = 10, double gap = 6}) {
    void drawDashLine(Offset a, Offset b) {
      final double total = (b - a).distance;
      final Offset dir = (b - a) / total;
      double t = 0.0;
      while (t < total) {
        final double end = ((t + dash) < total) ? (t + dash) : total;
        canvas.drawLine(a + dir * t, a + dir * end, p);
        t = end + gap;
      }
    }
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    drawDashLine(r.topLeft, r.topRight);
    drawDashLine(r.topRight, r.bottomRight);
    drawDashLine(r.bottomRight, r.bottomLeft);
    drawDashLine(r.bottomLeft, r.topLeft);
  }

  void _drawDottedRect(Canvas canvas, Paint p, Size s, double inset,
      {double dotSpacing = 8}) {
    final fillPaint = Paint()..color = p.color..style = PaintingStyle.fill;
    void drawDots(Offset a, Offset b) {
      final double total = (b - a).distance;
      final Offset dir = (b - a) / total;
      double t = 0;
      while (t <= total) {
        canvas.drawCircle(a + dir * t, p.strokeWidth * 1.2, fillPaint);
        t += dotSpacing;
      }
    }
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    drawDots(r.topLeft, r.topRight);
    drawDots(r.topRight, r.bottomRight);
    drawDots(r.bottomRight, r.bottomLeft);
    drawDots(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(covariant _LabelBorderPainter old) =>
      old.style != style || old.thickness != thickness || old.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  SHAPE STROKE PAINTER
// ═══════════════════════════════════════════════════════════════
class _ShapeStrokePainter extends CustomPainter {
  final ShapeKind kind;
  final ShapeStrokeStyle strokeStyle;
  final Color color;
  final double thickness;
  final Color? fillColor;
  final double cornerRadius;
  _ShapeStrokePainter({
    required this.kind,
    required this.strokeStyle,
    required this.color,
    required this.thickness,
    this.fillColor,
    this.cornerRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _pathFor(size);

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!);
    }
    _strokePath(canvas, path, p, strokeStyle);
  }

  Path _pathFor(Size size) {
    final path = Path();
    switch (kind) {
      case ShapeKind.line:
        path.moveTo(0, size.height / 2);
        path.lineTo(size.width, size.height / 2);
        break;
      case ShapeKind.circle:
      case ShapeKind.ellipse:
        path.addOval(Rect.fromLTWH(
            thickness / 2, thickness / 2,
            size.width - thickness, size.height - thickness));
        break;
      case ShapeKind.square:
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(thickness / 2, thickness / 2,
              size.width - thickness, size.height - thickness),
          Radius.circular(cornerRadius),
        ));
        break;
    }
    return path;
  }

  void _strokePath(Canvas canvas, Path path, Paint paint, ShapeStrokeStyle style) {
    if (style == ShapeStrokeStyle.solid) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      final double len = metric.length;
      double distance = 0.0;
      switch (style) {
        case ShapeStrokeStyle.dashed:
          while (distance < len) {
            final double next = (distance + 8) < len ? (distance + 8) : len;
            canvas.drawPath(metric.extractPath(distance, next), paint);
            distance = next + 5;
          }
          break;
        case ShapeStrokeStyle.dotted:
          final fillPaint = Paint()
            ..color = paint.color
            ..style = PaintingStyle.fill;
          while (distance < len) {
            final tangent = metric.getTangentForOffset(distance);
            if (tangent != null) {
              canvas.drawCircle(tangent.position, paint.strokeWidth * 0.8, fillPaint);
            }
            distance += paint.strokeWidth * 2.5 + 3;
          }
          break;
        case ShapeStrokeStyle.longDash:
          while (distance < len) {
            final double next = (distance + 14) < len ? (distance + 14) : len;
            canvas.drawPath(metric.extractPath(distance, next), paint);
            distance = next + 6;
          }
          break;
        case ShapeStrokeStyle.dashDot:
          bool dot = false;
          final fillPaint = Paint()
            ..color = paint.color
            ..style = PaintingStyle.fill;
          while (distance < len) {
            if (dot) {
              final tangent = metric.getTangentForOffset(distance);
              if (tangent != null) {
                canvas.drawCircle(tangent.position, paint.strokeWidth * 0.8, fillPaint);
              }
              distance += 8;
            } else {
              final double next = (distance + 10) < len ? (distance + 10) : len;
              canvas.drawPath(metric.extractPath(distance, next), paint);
              distance = next + 4;
            }
            dot = !dot;
          }
          break;
        case ShapeStrokeStyle.solid:
          canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeStrokePainter old) =>
      old.kind != kind || old.strokeStyle != strokeStyle ||
          old.color != color || old.thickness != thickness ||
          old.fillColor != fillColor || old.cornerRadius != cornerRadius;
}

// ═══════════════════════════════════════════════════════════════
//  LINE STYLE PAINTER (for Shape Picker previews)
// ═══════════════════════════════════════════════════════════════
class _LineStylePainter extends CustomPainter {
  final ShapeStrokeStyle style;
  final Color color;
  final double thickness;
  _LineStylePainter({
    required this.style,
    required this.color,
    required this.thickness,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final double y = size.height / 2;
    switch (style) {
      case ShapeStrokeStyle.solid:
        canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
        break;
      case ShapeStrokeStyle.dashed:
        for (double x = 0; x < size.width; x += 8) {
          final double endX = (x + 4) < size.width ? (x + 4) : size.width;
          canvas.drawLine(Offset(x, y), Offset(endX, y), p);
        }
        break;
      case ShapeStrokeStyle.dotted:
        final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
        for (double x = 0; x < size.width; x += 6) {
          canvas.drawCircle(Offset(x, y), thickness, fillPaint);
        }
        break;
      case ShapeStrokeStyle.longDash:
        for (double x = 0; x < size.width; x += 14) {
          final double endX = (x + 8) < size.width ? (x + 8) : size.width;
          canvas.drawLine(Offset(x, y), Offset(endX, y), p);
        }
        break;
      case ShapeStrokeStyle.dashDot:
        bool dot = false;
        final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
        for (double x = 0; x < size.width; x += 10) {
          if (dot) {
            canvas.drawCircle(Offset(x, y), thickness, fillPaint);
          } else {
            final double endX = (x + 6) < size.width ? (x + 6) : size.width;
            canvas.drawLine(Offset(x, y), Offset(endX, y), p);
          }
          dot = !dot;
        }
        break;
    }
  }
  @override
  bool shouldRepaint(covariant _LineStylePainter old) =>
      old.style != style || old.color != color || old.thickness != thickness;
}

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════
String formatLabelDateTime(DateTime dt, {String datePattern = 'yyyy/MM/dd', String timePattern = 'HH:mm:ss'}) {
  String two(int n) => n.toString().padLeft(2, '0');
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  final dayIdx = dt.weekday - 1;
  final date = datePattern
      .replaceAll('yyyy', dt.year.toString())
      .replaceAll('MMMM', ['January','February','March','April','May','June','July','August','September','October','November','December'][dt.month - 1])
      .replaceAll('MMM', months[dt.month - 1])
      .replaceAll('MM', two(dt.month))
      .replaceAll('EEE', days[dayIdx])
      .replaceAll('dd', two(dt.day));
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final time = timePattern
      .replaceAll('HH', two(dt.hour))
      .replaceAll('hh', two(hour12))
      .replaceAll('mm', two(dt.minute))
      .replaceAll('ss', two(dt.second))
      .replaceAll('SSS', dt.millisecond.toString().padLeft(3, '0'))
      .replaceAll('a', ampm);
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