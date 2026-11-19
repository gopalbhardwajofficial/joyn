import 'package:flutter/material.dart';

enum LabelShape {
  rectangle,
  circle,
}

class LabelSize {
  final String name;
  final double widthMm;
  final double heightMm;
  final bool isRound;

  const LabelSize({
    required this.name,
    required this.widthMm,
    required this.heightMm,
    this.isRound = false,
  });

  // Calculate pixel aspect ratio or size in logical pixels (1mm ≈ 3.78px for screen display)
  double get widthPx => widthMm * 3.78;
  double get heightPx => heightMm * 3.78;
  double get aspectRatio => widthMm / heightMm;

  static const List<LabelSize> standardSizes = [
    LabelSize(name: '50×30 mm', widthMm: 50, heightMm: 30),
    LabelSize(name: '50×50 mm', widthMm: 50, heightMm: 50, isRound: true),
    LabelSize(name: '50×50 mm', widthMm: 50, heightMm: 50, isRound: false),
    LabelSize(name: '99×150 mm', widthMm: 99, heightMm: 150), // 4x6" shipping label
    LabelSize(name: '100×100 mm', widthMm: 100, heightMm: 100, isRound: true),
    LabelSize(name: '100×150 mm', widthMm: 100, heightMm: 150),
    LabelSize(name: '80×40 mm', widthMm: 80, heightMm: 40),
    LabelSize(name: '50×70 mm', widthMm: 50, heightMm: 70),
    LabelSize(name: '50×80 mm', widthMm: 50, heightMm: 80),
    LabelSize(name: '40×30 mm', widthMm: 40, heightMm: 30),
    LabelSize(name: '40×41 mm', widthMm: 40, heightMm: 41),
    LabelSize(name: '76×130 mm', widthMm: 76, heightMm: 130),
  ];
}

enum ElementType {
  text,
  barcode,
  qrcode,
  clipart,
  dateTime,
  shape,
  image,
  serial,
  border,
  excelField,
}

enum ShapeType {
  rectangle,
  roundedRectangle,
  circle,
  horizontalLine,
  verticalLine,
}

enum BorderStyleType {
  singleLine,
  doubleLine,
  roundedFrame,
  dashedFrame,
  decorativeCorner,
}

class LabelElement {
  String id;
  ElementType type;
  double x;
  double y;
  double width;
  double height;
  double rotation; // In degrees
  String text;
  double fontSize;
  bool isBold;
  bool isItalic;
  TextAlign textAlign;
  String barcodeData;
  String qrData;
  String clipartKey;
  ShapeType shapeType;
  BorderStyleType borderStyle;
  double strokeWidth;
  int serialStart;
  String serialPrefix;
  int serialDigits;
  String serialSuffix;
  int serialInterval;
  bool isSerial;
  String? imagePath;
  bool isLocked;
  bool isUnderline;
  double letterSpacing;
  double lineSpacing;
  bool isUppercase;
  String barcodeEncoding; // 'CODE39', 'CODE128', 'CODE93', 'EAN13'
  String qrEncoding; // 'QR_CODE', 'PDF417', 'DATA_MATRIX', 'AZTEC'
  bool showBarcodeText;
  bool isIsometric;
  String dateTimeFormat;
  String fontFamily;

  LabelElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.text = '',
    this.fontSize = 14.0,
    this.isBold = false,
    this.isItalic = false,
    this.textAlign = TextAlign.left,
    this.barcodeData = '123456',
    this.qrData = '123456',
    this.clipartKey = 'star',
    this.shapeType = ShapeType.rectangle,
    this.borderStyle = BorderStyleType.singleLine,
    this.strokeWidth = 2.0,
    this.serialStart = 1,
    this.serialPrefix = 'SN',
    this.serialDigits = 4,
    this.serialSuffix = '',
    this.serialInterval = 1,
    this.isSerial = false,
    this.imagePath,
    this.isLocked = false,
    this.isUnderline = false,
    this.letterSpacing = 0.0,
    this.lineSpacing = 1.0,
    this.isUppercase = false,
    this.barcodeEncoding = 'CODE39',
    this.qrEncoding = 'QR_CODE',
    this.showBarcodeText = true,
    this.isIsometric = false,
    this.dateTimeFormat = 'yyyy/MM/dd HH:mm:ss',
    this.fontFamily = 'Roboto',
  });

  String get effectiveBarcodeData {
    if (isSerial) {
      return '$serialPrefix${serialStart.toString().padLeft(serialDigits, '0')}$serialSuffix';
    }
    return barcodeData.isEmpty ? '123456' : barcodeData;
  }

  String get effectiveQrData {
    if (isSerial) {
      return '$serialPrefix${serialStart.toString().padLeft(serialDigits, '0')}$serialSuffix';
    }
    return qrData.isEmpty ? '123456' : qrData;
  }

  String get effectiveText {
    if (type == ElementType.dateTime) {
      return text;
    }
    if (isUppercase) {
      return text.toUpperCase();
    }
    return text;
  }

  LabelElement copyWith({
    String? id,
    ElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? text,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    TextAlign? textAlign,
    String? barcodeData,
    String? qrData,
    String? clipartKey,
    ShapeType? shapeType,
    BorderStyleType? borderStyle,
    double? strokeWidth,
    int? serialStart,
    String? serialPrefix,
    int? serialDigits,
    String? serialSuffix,
    int? serialInterval,
    bool? isSerial,
    String? imagePath,
    bool? isLocked,
    bool? isUnderline,
    double? letterSpacing,
    double? lineSpacing,
    bool? isUppercase,
    String? barcodeEncoding,
    String? qrEncoding,
    bool? showBarcodeText,
    bool? isIsometric,
    String? dateTimeFormat,
    String? fontFamily,
  }) {
    return LabelElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      textAlign: textAlign ?? this.textAlign,
      barcodeData: barcodeData ?? this.barcodeData,
      qrData: qrData ?? this.qrData,
      clipartKey: clipartKey ?? this.clipartKey,
      shapeType: shapeType ?? this.shapeType,
      borderStyle: borderStyle ?? this.borderStyle,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      serialStart: serialStart ?? this.serialStart,
      serialPrefix: serialPrefix ?? this.serialPrefix,
      serialDigits: serialDigits ?? this.serialDigits,
      serialSuffix: serialSuffix ?? this.serialSuffix,
      serialInterval: serialInterval ?? this.serialInterval,
      isSerial: isSerial ?? this.isSerial,
      imagePath: imagePath ?? this.imagePath,
      isLocked: isLocked ?? this.isLocked,
      isUnderline: isUnderline ?? this.isUnderline,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      isUppercase: isUppercase ?? this.isUppercase,
      barcodeEncoding: barcodeEncoding ?? this.barcodeEncoding,
      qrEncoding: qrEncoding ?? this.qrEncoding,
      showBarcodeText: showBarcodeText ?? this.showBarcodeText,
      isIsometric: isIsometric ?? this.isIsometric,
      dateTimeFormat: dateTimeFormat ?? this.dateTimeFormat,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class LabelTemplate {
  final String id;
  final String title;
  final String sizeSubtitle;
  final LabelSize size;
  final String category;
  final String subcategory;
  final Color backgroundColor;
  final LabelShape shape;
  final List<LabelElement> elements;

  const LabelTemplate({
    required this.id,
    required this.title,
    required this.sizeSubtitle,
    required this.size,
    required this.category,
    required this.subcategory,
    this.backgroundColor = Colors.white,
    this.shape = LabelShape.rectangle,
    required this.elements,
  });
}
