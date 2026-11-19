import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../models/printer_device.dart';
import '../models/label_model.dart';
import 'canvas_rasterizer_service.dart';
import 'image_processing_service.dart';

enum PaperType {
  gap,        // Die-cut sticker labels
  continuous, // Receipt roll
  blackMark,  // Black mark labels
}

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal() {
    _initBluetoothListeners();
  }

  // Active connected printer
  ThermalPrinterDevice? _connectedDevice;
  ThermalPrinterDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  // Connection in-progress state
  bool _isConnecting = false;
  String? _connectingDeviceId;
  bool get isConnecting => _isConnecting;
  String? get connectingDeviceId => _connectingDeviceId;

  // Scanning state
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // Discovered real available devices list (Zero dummy / simulated devices!)
  final List<ThermalPrinterDevice> _devices = [];
  List<ThermalPrinterDevice> get devices => List.unmodifiable(_devices);

  // Printing state & progress
  double _printProgress = 0.0;
  double get printProgress => _printProgress;
  bool _isPrinting = false;
  bool get isPrinting => _isPrinting;
  String _printStatusMessage = '';
  String get printStatusMessage => _printStatusMessage;

  // Hardware Printer Settings
  PaperType _paperType = PaperType.gap;
  PaperType get paperType => _paperType;

  int _density = 8; // 1 to 15 (Darkness)
  int get density => _density;

  int _speed = 3; // 2 to 5 inches per second
  int get speed => _speed;

  // Physical Bluetooth BLE objects
  BluetoothDevice? _bleDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // Stream subscriptions
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  void _initBluetoothListeners() {
    try {
      FlutterBluePlus.isSupported.then((supported) {
        if (!supported) return;
        FlutterBluePlus.adapterState.listen((state) {
          if (state != BluetoothAdapterState.on && isConnected) {
            disconnect();
          }
        });
      }).catchError((_) {});
    } catch (_) {
      // Ignored if platform does not support bluetooth or during headless tests
    }
  }

  /// Request all required Bluetooth permissions on Android
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true;
      final connGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;

      if (!scanGranted || !connGranted) {
        _printStatusMessage = 'Please grant Bluetooth permissions in phone settings';
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  /// Start scanning for physical available Bluetooth printers
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _printStatusMessage = 'Scanning for nearby Bluetooth devices...';
    // Clear offline devices; only keep currently connected device if any
    _devices.removeWhere((d) => d.id != _connectedDevice?.id);
    notifyListeners();

    try {
      // 1. Check permissions
      final hasPerms = await requestPermissions();
      if (!hasPerms) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      // 2. Check if Bluetooth is supported & turned on
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        _printStatusMessage = 'Bluetooth not supported on this device';
        _isScanning = false;
        notifyListeners();
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {
          _printStatusMessage = 'Please turn ON Bluetooth in phone settings';
          _isScanning = false;
          notifyListeners();
          return;
        }
      }

      // 3. Stop any existing scan before starting fresh
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      // 4. Start active BLE scan for nearby advertising devices
      // NOTE: We DO NOT dump all bondedDevices to ensure only available devices are shown.
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final advName = r.advertisementData.advName.trim();
          final platformName = r.device.platformName.trim();
          String name = advName.isNotEmpty ? advName : platformName;
          final deviceId = r.device.remoteId.str;

          // Filter out nameless random BLE beacons unless they advertise thermal printer services
          if (name.isEmpty) {
            final hasPrinterService = r.advertisementData.serviceUuids.any((u) {
              final s = u.toString().toLowerCase();
              return s.contains('ffe0') || s.contains('fee7') || s.contains('ff00') || s.contains('ae30');
            });
            if (hasPrinterService) {
              name = 'Thermal Printer (${deviceId.length > 5 ? deviceId.substring(deviceId.length - 5) : deviceId})';
            } else {
              continue; // Skip nameless random beacons
            }
          }

          final lower = name.toLowerCase();
          // Portable thermal printers (Seznik Mini/Josh/Dev/Veer/B-41, FlashLabel, POS-58/80, MPT, PT) use ESC/POS!
          // Only large industrial 4x6 desktop printers use TSPL.
          final isTsplIndustrial = lower.contains('4x6') || lower.contains('tsc') || lower.contains('zebra');
          final proto = isTsplIndustrial ? PrinterProtocol.tspl : PrinterProtocol.escPos;

          final printer = ThermalPrinterDevice(
            id: deviceId,
            name: name,
            address: deviceId,
            rssi: r.rssi,
            isSimulated: false,
            protocol: proto,
          );

          final index = _devices.indexWhere((d) => d.id == deviceId);
          if (index >= 0) {
            _devices[index] = printer;
          } else {
            _devices.add(printer);
          }
        }

        // Sort: Likely printers first, then descending by signal strength (RSSI)
        _devices.sort((a, b) {
          final aIsPrinter = _isLikelyPrinter(a.name);
          final bIsPrinter = _isLikelyPrinter(b.name);
          if (aIsPrinter && !bIsPrinter) return -1;
          if (!aIsPrinter && bIsPrinter) return 1;
          return b.rssi.compareTo(a.rssi);
        });

        notifyListeners();
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: true,
      );

      // Wait until scan completes
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
    } catch (e) {
      debugPrint("Scan error: $e");
      _printStatusMessage = 'Scan error: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  bool _isLikelyPrinter(String name) {
    final n = name.toLowerCase();
    return n.contains('printer') ||
        n.contains('seznik') ||
        n.contains('flashlabel') ||
        n.contains('pos') ||
        n.contains('mpt') ||
        n.contains('rp') ||
        n.contains('xp') ||
        n.contains('label') ||
        n.contains('thermal') ||
        n.contains('dev') ||
        n.contains('print') ||
        n.contains('mini');
  }

  /// Stop ongoing scan
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to physical Bluetooth printer
  Future<bool> connect(ThermalPrinterDevice printer) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    _connectingDeviceId = printer.id;
    _printStatusMessage = 'Connecting to ${printer.name}...';
    notifyListeners();

    try {
      // 1. Stop active scanning to prevent Android GATT error 133
      if (_isScanning) {
        await stopScan();
      }
      await Future.delayed(const Duration(milliseconds: 300));

      final device = BluetoothDevice.fromId(printer.id);

      // Cleanly disconnect previous connection if any
      try {
        await device.disconnect();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}

      _printStatusMessage = 'Opening BLE connection to ${printer.name}...';
      notifyListeners();

      // 2. Direct BLE connect (autoConnect: false connects immediately)
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      _bleDevice = device;

      // Small delay for Android GATT stack to settle
      await Future.delayed(const Duration(milliseconds: 400));

      _printStatusMessage = 'Discovering printer services...';
      notifyListeners();

      // 3. Discover GATT services
      final services = await device.discoverServices();
      BluetoothCharacteristic? candidateWrite;

      // Search for thermal printer write characteristic:
      // Priority 1: Known thermal printer UUIDs
      for (final service in services) {
        for (final char in service.characteristics) {
          final u = char.uuid.toString().toLowerCase();
          final isKnownThermal = u.contains('ffe1') ||
              u.contains('fee7') ||
              u.contains('fee8') ||
              u.contains('ff02') ||
              u.contains('ff01') ||
              u.contains('ae01') ||
              u.contains('ae02') ||
              u.contains('ae30') ||
              u.contains('49535343') ||
              u.contains('6e400002') ||
              u.contains('e7810a71') ||
              u.contains('fff1') ||
              u.contains('fff2') ||
              u.contains('ab01') ||
              u.contains('ab02');
          if (isKnownThermal && (char.properties.write || char.properties.writeWithoutResponse)) {
            candidateWrite = char;
            break;
          }
        }
        if (candidateWrite != null) break;
      }

      // Priority 2: Any characteristic in any service that has write capability
      if (candidateWrite == null) {
        for (final service in services) {
          for (final char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              candidateWrite = char;
              break;
            }
          }
          if (candidateWrite != null) break;
        }
      }

      if (candidateWrite == null) {
        _printStatusMessage = 'Connected, but no writable characteristic found on this device';
        await disconnect();
        return false;
      }

      _writeCharacteristic = candidateWrite;
      _connectedDevice = printer.copyWith(isConnected: true);
      _printStatusMessage = 'Connected to ${printer.name}';

      // 4. Set up safe disconnect listener ONLY AFTER successful connection is confirmed
      _connSub?.cancel();
      bool wasConnected = true;
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          wasConnected = true;
        } else if (state == BluetoothConnectionState.disconnected && wasConnected) {
          wasConnected = false;
          _onDeviceDisconnected();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("BLE Connection failed: $e");
      final errStr = e.toString().replaceAll('Exception:', '').trim();
      _printStatusMessage = 'Failed to connect: $errStr';
      try {
        await _bleDevice?.disconnect();
      } catch (_) {}
      _bleDevice = null;
      _writeCharacteristic = null;
      _connectedDevice = null;
      notifyListeners();
      return false;
    } finally {
      _isConnecting = false;
      _connectingDeviceId = null;
      notifyListeners();
    }
  }

  void _onDeviceDisconnected() {
    _connSub?.cancel();
    _connSub = null;
    _writeCharacteristic = null;
    _connectedDevice = null;
    _printStatusMessage = 'Disconnected';
    notifyListeners();
  }

  /// Disconnect printer
  Future<void> disconnect() async {
    try {
      _connSub?.cancel();
      _connSub = null;
      if (_bleDevice != null) {
        await _bleDevice!.disconnect();
        _bleDevice = null;
      }
    } catch (_) {}
    _writeCharacteristic = null;
    _connectedDevice = null;
    _printStatusMessage = 'Disconnected';
    notifyListeners();
  }

  /// Change printer protocol manually (TSPL / ESC-POS / CPCL)
  void setProtocol(PrinterProtocol protocol) {
    if (_connectedDevice != null) {
      _connectedDevice = _connectedDevice!.copyWith(protocol: protocol);
      notifyListeners();
    }
  }

  /// Update hardware settings
  void updateSettings({PaperType? paperType, int? density, int? speed}) {
    if (paperType != null) _paperType = paperType;
    if (density != null) _density = density.clamp(1, 15);
    if (speed != null) _speed = speed.clamp(2, 5);
    notifyListeners();

    if (isConnected && _connectedDevice!.protocol == PrinterProtocol.tspl) {
      final configCmd = 'DENSITY $_density\r\nSPEED $_speed\r\n';
      sendRawCommand(Uint8List.fromList(ascii.encode(configCmd)));
    }
  }

  /// Send raw bytes directly to Bluetooth characteristic
  Future<void> sendRawCommand(Uint8List bytes) async {
    if (_writeCharacteristic != null) {
      if (_writeCharacteristic!.properties.writeWithoutResponse) {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      }
    }
  }

  /// Calibrate Label Gap Sensor (TSPL GAPDETECT)
  Future<bool> calibrateSensor() async {
    if (_connectedDevice == null) return false;
    _printStatusMessage = 'Calibrating label gap sensor...';
    notifyListeners();

    if (_connectedDevice!.protocol == PrinterProtocol.tspl) {
      await sendRawCommand(Uint8List.fromList(ascii.encode('GAPDETECT\r\n')));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _printStatusMessage = 'Sensor calibrated!';
    notifyListeners();
    return true;
  }

  /// Feed label / form feed
  Future<bool> feedPaper() async {
    if (_connectedDevice == null) return false;
    _printStatusMessage = 'Feeding paper...';
    notifyListeners();

    if (_connectedDevice!.protocol == PrinterProtocol.tspl) {
      await sendRawCommand(Uint8List.fromList(ascii.encode('FORMFEED\r\n')));
    } else {
      await sendRawCommand(Uint8List.fromList([0x1B, 0x64, 0x03])); // ESC d 3
    }
    await Future.delayed(const Duration(milliseconds: 400));
    _printStatusMessage = 'Feed completed';
    notifyListeners();
    return true;
  }

  /// Immediately sends abort/reset commands to halt runaway/infinite printing on physical hardware
  Future<void> emergencyStop() async {
    _isPrinting = false;
    _printProgress = 0.0;
    _printStatusMessage = 'Emergency stop sent. Print halted.';
    notifyListeners();

    if (_writeCharacteristic != null) {
      try {
        final resetCmd = BytesBuilder();
        resetCmd.add([0x1B, 0x40]); // ESC @ (Reset ESC/POS)
        resetCmd.add(ascii.encode('\r\nCLS\r\n')); // Clear TSPL buffer
        await _writeCharacteristic!.write(resetCmd.toBytes(), withoutResponse: false);
      } catch (_) {}
    }
  }

  /// Print an img.Image on the physical connected printer
  Future<bool> printImage({
    required img.Image image,
    required double labelWidthMm,
    required double labelHeightMm,
    FilterMode filterMode = FilterMode.bwThreshold,
    int threshold = 200,
    int copies = 1,
  }) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      _printStatusMessage = 'No printer connected!';
      notifyListeners();
      return false;
    }

    _isPrinting = true;
    _printProgress = 0.0;
    _printStatusMessage = 'Processing image for printhead...';
    notifyListeners();

    try {
      // 1. Process image for 1-bit thermal printhead
      final monoImage = ImageProcessingService.processForThermal(
        src: image,
        filterMode: filterMode,
        threshold: threshold,
      );

      // 2. Generate raw command bytes according to printer protocol
      final Uint8List printPayload;
      if (_connectedDevice!.protocol == PrinterProtocol.tspl) {
        printPayload = _generateTSPLBytes(
          monoImage: monoImage,
          widthMm: labelWidthMm,
          heightMm: labelHeightMm,
          copies: copies,
        );
      } else if (_connectedDevice!.protocol == PrinterProtocol.escPos) {
        printPayload = _generateEscPosBytes(
          monoImage: monoImage,
          copies: copies,
        );
      } else {
        printPayload = _generateCPCLBytes(
          monoImage: monoImage,
          widthMm: labelWidthMm,
          heightMm: labelHeightMm,
          copies: copies,
        );
      }

      // 3. Send payload over Bluetooth in safe 48-byte packets with 25ms pacing
      await _sendPayloadChunked(printPayload);

      if (_isPrinting) {
        _printProgress = 1.0;
        _printStatusMessage = 'Print completed successfully!';
        _isPrinting = false;
        notifyListeners();
        return true;
      } else {
        // Was aborted
        return false;
      }
    } catch (e) {
      debugPrint("Print error: $e");
      _printStatusMessage = 'Print failed: $e';
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate TSPL (TSC) command buffer for Seznik Josh / Tejas / FlashLabel
  Uint8List _generateTSPLBytes({
    required img.Image monoImage,
    required double widthMm,
    required double heightMm,
    int copies = 1,
  }) {
    final builder = BytesBuilder();

    // 1. Initial reset to clear any dangling commands in printer buffer
    builder.add(ascii.encode('\r\nCLS\r\n'));

    // If continuous paper (receipt roll without gap): GAP 0 mm, 0 mm
    // If die-cut sticker label: GAP 2 mm, 0 mm
    final gapCmd = (_paperType == PaperType.continuous)
        ? 'GAP 0 mm,0 mm\r\n'
        : 'GAP 2 mm,0 mm\r\n';

    final setupCmd = 'SIZE ${widthMm.toInt()} mm,${heightMm.toInt()} mm\r\n'
        '$gapCmd'
        'DIRECTION 1\r\n'
        'REFERENCE 0,0\r\n'
        'CLS\r\n';
    builder.add(ascii.encode(setupCmd));

    final widthBytes = (monoImage.width + 7) ~/ 8;
    final heightDots = monoImage.height;

    // TSPL BITMAP X, Y, width_in_bytes, height_in_dots, mode, bitmap_data
    final bitmapHeader = 'BITMAP 0,0,$widthBytes,$heightDots,0,';
    builder.add(ascii.encode(bitmapHeader));

    // TSPL mode 0: 0 = Black (burn), 1 = White (no burn) -> invert: false
    final rawBytes = ImageProcessingService.encodeTo1BitBitmap(monoImage, invert: false);
    builder.add(rawBytes);

    final printCmd = '\r\nPRINT $copies,1\r\n';
    builder.add(ascii.encode(printCmd));

    return builder.toBytes();
  }

  /// Generate ESC/POS command buffer for receipt & sticker printers (Seznik Mini/Josh/Dev/Veer/B-41, POS-58/80)
  Uint8List _generateEscPosBytes({
    required img.Image monoImage,
    int copies = 1,
  }) {
    final builder = BytesBuilder();

    // Standard 58mm thermal printhead has 384 printable dots (48 bytes per line at 203 DPI)
    // 50mm sticker width fits exactly into 384 dots.
    const int printHeadDots = 384;
    const int widthBytes = 48; // 384 / 8 = 48 bytes

    // Resize proportionally if larger than printhead
    final img.Image resized = (monoImage.width > printHeadDots)
        ? img.copyResize(monoImage, width: printHeadDots, interpolation: img.Interpolation.nearest)
        : monoImage;

    // Create an exact 384-dot wide canvas with white background and center the image horizontally
    final int canvasHeight = resized.height;
    final canvas = img.Image(width: printHeadDots, height: canvasHeight);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    final int startX = ((printHeadDots - resized.width) ~/ 2).clamp(0, printHeadDots);
    img.compositeImage(canvas, resized, dstX: startX, dstY: 0);

    final heightDots = canvas.height;

    // 1-bit packed monochrome pixels: INVERT = TRUE because ESC/POS 1 is Black (burn), 0 is White (no burn)
    final rawBytes = ImageProcessingService.encodeTo1BitBitmap(canvas, invert: true);

    for (int c = 0; c < copies; c++) {
      // 1. ESC @ (0x1B, 0x40): Initialize printer & cancel any dangling modes
      builder.add([0x1B, 0x40]);

      // 2. ESC 2 (0x1B, 0x32): Default line spacing
      builder.add([0x1B, 0x32]);

      // 3. GS v 0 0 xL xH yL yH: Print raster bit image
      // 0x1D, 0x76, 0x30, 0x00
      final xL = widthBytes & 0xFF; // 48
      final xH = (widthBytes >> 8) & 0xFF; // 0
      final yL = heightDots & 0xFF;
      final yH = (heightDots >> 8) & 0xFF;

      builder.add([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);
      builder.add(rawBytes);

      // 4. Feed 2 lines (ESC d 2) to advance past tear cutter
      builder.add([0x1B, 0x64, 0x02]);
    }

    return builder.toBytes();
  }

  /// Generate CPCL command buffer for portable receipt printers
  Uint8List _generateCPCLBytes({
    required img.Image monoImage,
    required double widthMm,
    required double heightMm,
    int copies = 1,
  }) {
    final builder = BytesBuilder();
    final width = monoImage.width;
    final height = monoImage.height;
    final widthBytes = (width + 7) ~/ 8;

    final header = '! 0 200 200 $height $copies\r\n'
        'PAGE-WIDTH $width\r\n'
        'EG $widthBytes $height 0 0 ';
    builder.add(ascii.encode(header));

    final rawBytes = ImageProcessingService.encodeTo1BitBitmap(monoImage, invert: true);
    final hexString = rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
    builder.add(ascii.encode(hexString));
    builder.add(ascii.encode('\r\nPRINT\r\n'));

    return builder.toBytes();
  }

  /// Sends raw payload bytes over Bluetooth with MTU-aligned packet sizing
  Future<void> _sendPayloadChunked(Uint8List payload) async {
    if (_writeCharacteristic == null || _bleDevice == null) {
      throw Exception('Printer not connected or write characteristic not available');
    }

    int mtu = 23;
    try {
      mtu = _bleDevice!.mtuNow;
    } catch (_) {}

    // Safe chunk size: if MTU is 23 (default BLE), packet is 20 bytes. If larger, clamp to 64 bytes.
    final int safeChunkSize = (mtu > 23) ? (mtu - 3).clamp(20, 64) : 20;

    final totalBytes = payload.length;
    int sent = 0;

    final canWithoutResp = _writeCharacteristic!.properties.writeWithoutResponse;

    while (sent < totalBytes) {
      if (!_isPrinting) {
        // Aborted via emergency stop
        break;
      }

      final end = (sent + safeChunkSize < totalBytes) ? sent + safeChunkSize : totalBytes;
      final chunk = payload.sublist(sent, end);

      try {
        await _writeCharacteristic!.write(chunk, withoutResponse: canWithoutResp);
      } catch (e) {
        // Fallback to write with response
        await _writeCharacteristic!.write(chunk, withoutResponse: !canWithoutResp);
      }

      sent = end;
      _printProgress = sent / totalBytes;
      _printStatusMessage = 'Printing: ${(_printProgress * 100).toInt()}%';
      notifyListeners();

      // Micro delay allows printer MCU UART buffer to process without dropping bytes
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  /// High quality test diagnostic label print for Seznik & FlashLabel
  Future<bool> printTestDiagnostic() async {
    if (_connectedDevice == null) return false;

    final now = DateTime.now();
    final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final elements = [
      LabelElement(
        id: 't1',
        type: ElementType.text,
        x: 4,
        y: 3,
        width: 42,
        height: 6,
        text: 'FlashLabel Pro',
        fontSize: 16,
        isBold: true,
      ),
      LabelElement(
        id: 't2',
        type: ElementType.text,
        x: 4,
        y: 10,
        width: 42,
        height: 4,
        text: 'Printer: ${_connectedDevice!.name}',
        fontSize: 10,
      ),
      LabelElement(
        id: 't3',
        type: ElementType.text,
        x: 4,
        y: 15,
        width: 42,
        height: 4,
        text: 'Protocol: ${_connectedDevice!.protocol.name.toUpperCase()} • $timeStr',
        fontSize: 9,
      ),
      LabelElement(
        id: 'qr1',
        type: ElementType.qrcode,
        x: 32,
        y: 20,
        width: 14,
        height: 14,
        qrData: 'https://flashlabel.pro',
      ),
      LabelElement(
        id: 'bc1',
        type: ElementType.barcode,
        x: 4,
        y: 21,
        width: 26,
        height: 12,
        barcodeData: 'SEZNIK-TEST',
      ),
      LabelElement(
        id: 'bd1',
        type: ElementType.border,
        x: 1,
        y: 1,
        width: 48,
        height: 36,
        strokeWidth: 2,
      ),
    ];

    const testLabelSize = LabelSize(name: '50x38mm', widthMm: 50, heightMm: 38);
    final testImg = await CanvasRasterizerService.rasterizeLabel(
      size: testLabelSize,
      elements: elements,
    );

    return printImage(
      image: testImg,
      labelWidthMm: 50,
      labelHeightMm: 38,
    );
  }
}
