import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/label_model.dart';
import '../services/canvas_rasterizer_service.dart';
import '../services/clipart_service.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/label_canvas_view.dart';
import '../widgets/thermal_preview_dialog.dart';
import '../widgets/printer_settings_modal.dart';
import '../widgets/printer_connect_modal.dart';

class FreestyleEditorScreen extends StatefulWidget {
  final LabelTemplate? initialTemplate;
  final String? customLabelName;
  final LabelSize? customSize;
  final LabelShape? customShape;
  final String? backgroundImagePath;

  const FreestyleEditorScreen({
    super.key,
    this.initialTemplate,
    this.customLabelName,
    this.customSize,
    this.customShape,
    this.backgroundImagePath,
  });

  @override
  State<FreestyleEditorScreen> createState() => _FreestyleEditorScreenState();
}

class _FreestyleEditorScreenState extends State<FreestyleEditorScreen> {
  final PrinterService _printerService = PrinterService();

  late String _labelName;
  late LabelSize _currentSize;
  late LabelShape _shape;
  late List<LabelElement> _elements;
  String? _selectedElementId;
  String _activeClipartCategory = 'Halloween';

  // Bottom toolbar page controller (Page 1 vs Page 2)
  final PageController _bottomBarPageController = PageController();
  int _bottomBarPageIndex = 0;

  // Active sub-tab in contextual property panels
  int _textTabIndex = 0; // 0 = Style, 1 = Font
  int _barcodeTabIndex = 0; // 0 = Barcode, 1 = Style

  // History stack
  final List<List<LabelElement>> _undoStack = [];
  final List<List<LabelElement>> _redoStack = [];

  // Text controller for live editing in bottom bar
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelName = widget.customLabelName ?? DateFormat('yyyyMMdd').format(DateTime.now());
    _shape = widget.customShape ?? (widget.initialTemplate?.shape ?? LabelShape.rectangle);

    if (widget.initialTemplate != null) {
      _currentSize = widget.initialTemplate!.size;
      _elements = widget.initialTemplate!.elements.map((e) => e.copyWith()).toList();
    } else if (widget.customSize != null) {
      _currentSize = widget.customSize!;
      // Empty canvas as requested: User will add elements themselves!
      _elements = [];
    } else {
      _currentSize = const LabelSize(name: '80×40 mm', widthMm: 80, heightMm: 40);
      _elements = [];
    }
  }

  @override
  void dispose() {
    _bottomBarPageController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _saveState() {
    _undoStack.add(_elements.map((e) => e.copyWith()).toList());
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_elements.map((e) => e.copyWith()).toList());
      setState(() {
        _elements = _undoStack.removeLast();
        _selectedElementId = null;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_elements.map((e) => e.copyWith()).toList());
      setState(() {
        _elements = _redoStack.removeLast();
        _selectedElementId = null;
      });
    }
  }

  LabelElement? get _selectedElement {
    if (_selectedElementId == null) return null;
    try {
      return _elements.firstWhere((e) => e.id == _selectedElementId);
    } catch (_) {
      return null;
    }
  }

  void _selectElement(LabelElement? el) {
    setState(() {
      _selectedElementId = el?.id;
      if (el != null) {
        if (el.type == ElementType.text) {
          _textEditingController.text = el.text;
        }
      }
    });
  }

  void _deleteSelected() {
    if (_selectedElementId == null) return;
    _saveState();
    setState(() {
      _elements.removeWhere((e) => e.id == _selectedElementId);
      _selectedElementId = null;
    });
  }

  void _duplicateSelected() {
    if (_selectedElementId == null) return;
    _saveState();
    final el = _selectedElement;
    if (el == null) return;
    final copy = el.copyWith(
      id: 'el_${DateTime.now().millisecondsSinceEpoch}',
      x: el.x + 10,
      y: el.y + 10,
    );
    setState(() {
      _elements.add(copy);
      _selectedElementId = copy.id;
      if (copy.type == ElementType.text) {
        _textEditingController.text = copy.text;
      }
    });
  }

  void _rotateSelected() {
    final el = _selectedElement;
    if (el == null) return;
    _saveState();
    setState(() {
      el.rotation = (el.rotation + 90) % 360;
    });
  }

  void _alignCenterSelected() {
    final el = _selectedElement;
    if (el == null) return;
    _saveState();
    setState(() {
      el.x = ((_currentSize.widthPx - el.width) / 2).clamp(0.0, _currentSize.widthPx);
      el.y = ((_currentSize.heightPx - el.height) / 2).clamp(0.0, _currentSize.heightPx);
    });
  }

  void _toggleLockSelected() {
    final el = _selectedElement;
    if (el == null) return;
    setState(() {
      el.isLocked = !el.isLocked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(el.isLocked ? 'Element locked' : 'Element unlocked'),
      ),
    );
  }

  // --- Element Addition Tools ---
  void _addText() {
    _saveState();
    final newEl = LabelElement(
      id: 'txt_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.text,
      text: 'Gopal',
      x: 20,
      y: 20,
      width: 140,
      height: 28,
      fontSize: 14,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
      _textEditingController.text = newEl.text;
      _textTabIndex = 0;
    });
  }

  void _addQRCode() {
    _saveState();
    final newEl = LabelElement(
      id: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.qrcode,
      qrData: '123456',
      x: 30,
      y: 30,
      width: 65,
      height: 65,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _addBarcode() {
    _saveState();
    final newEl = LabelElement(
      id: 'bc_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.barcode,
      barcodeData: '123456',
      x: 20,
      y: 20,
      width: 130,
      height: 48,
      barcodeEncoding: 'CODE39',
      showBarcodeText: true,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
      _barcodeTabIndex = 0;
    });
  }

  void _addTime() {
    _saveState();
    final nowStr = DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
    final newEl = LabelElement(
      id: 'dt_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.dateTime,
      text: nowStr,
      dateTimeFormat: 'yyyy/MM/dd HH:mm:ss',
      x: 15,
      y: 15,
      width: 170,
      height: 24,
      fontSize: 12,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _addMaterialSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final items = ClipartService.cliparts.where((c) => c.category == _activeClipartCategory).toList();
          return Container(
            height: 320,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 10),
                // Categories
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: ClipartService.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final cat = ClipartService.categories[index];
                      final isSelected = cat == _activeClipartCategory;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _activeClipartCategory = cat);
                          setState(() {});
                        },
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // Items Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: () {
                          _saveState();
                          final newEl = LabelElement(
                            id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
                            type: ElementType.clipart,
                            clipartKey: item.key,
                            x: 40,
                            y: 30,
                            width: 44,
                            height: 44,
                          );
                          setState(() {
                            _elements.add(newEl);
                            _selectedElementId = newEl.id;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(item.icon, size: 28, color: Colors.black87),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        _saveState();
        final newEl = LabelElement(
          id: 'img_${DateTime.now().millisecondsSinceEpoch}',
          type: ElementType.image,
          imagePath: result.files.first.path,
          x: 30,
          y: 30,
          width: 80,
          height: 80,
        );
        setState(() {
          _elements.add(newEl);
          _selectedElementId = newEl.id;
        });
      }
    } catch (e) {
      debugPrint("Image add error: $e");
    }
  }

  void _addSerial() {
    _saveState();
    final newEl = LabelElement(
      id: 'ser_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.serial,
      text: 'SN0001',
      x: 30,
      y: 30,
      width: 100,
      height: 25,
      fontSize: 14,
      isBold: true,
      isSerial: true,
      serialPrefix: 'SN',
      serialDigits: 4,
      serialStart: 1,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _addBorder() {
    _saveState();
    final newEl = LabelElement(
      id: 'bdr_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.border,
      shapeType: ShapeType.rectangle,
      borderStyle: BorderStyleType.singleLine,
      x: 6,
      y: 6,
      width: 160,
      height: 90,
      strokeWidth: 2,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _addShape() {
    _saveState();
    final newEl = LabelElement(
      id: 'shp_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.shape,
      shapeType: ShapeType.roundedRectangle,
      x: 30,
      y: 30,
      width: 90,
      height: 50,
      strokeWidth: 2,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _addExcel() {
    _saveState();
    final newEl = LabelElement(
      id: 'xl_${DateTime.now().millisecondsSinceEpoch}',
      type: ElementType.excelField,
      text: '{Name}',
      x: 30,
      y: 30,
      width: 110,
      height: 25,
      fontSize: 14,
      isBold: true,
    );
    setState(() {
      _elements.add(newEl);
      _selectedElementId = newEl.id;
    });
  }

  void _editElementDialog(LabelElement el) {
    final controller = TextEditingController(
      text: el.type == ElementType.barcode
          ? el.barcodeData
          : (el.type == ElementType.qrcode ? el.qrData : el.text),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${el.type.name.toUpperCase()}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              _saveState();
              setState(() {
                if (el.type == ElementType.barcode) {
                  el.barcodeData = controller.text.trim();
                } else if (el.type == ElementType.qrcode) {
                  el.qrData = controller.text.trim();
                } else {
                  el.text = controller.text;
                  _textEditingController.text = controller.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPrintDialog() {
    ThermalPrintProgressDialog.show(
      context: context,
      previewWidget: Container(
        height: 240,
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: LabelCanvasView(
          size: _currentSize,
          elements: _elements,
        ),
      ),
      labelTitle: _labelName,
      labelSizeStr: _currentSize.name,
      onPrintConfirmed: (copies) async {
        final renderedImg = await CanvasRasterizerService.rasterizeLabel(
          size: _currentSize,
          elements: _elements,
          shape: _shape,
        );

        await _printerService.printImage(
          image: renderedImg,
          labelWidthMm: _currentSize.widthMm,
          labelHeightMm: _currentSize.heightMm,
          copies: copies,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEl = _selectedElement;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. TOP HEADER (Row 1): Back, Title & Size, Bluetooth, Settings, Green Print Button ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _labelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary),
                        ),
                        Text(
                          _currentSize.name,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Bluetooth Printer Quick Status Button
                  IconButton(
                    icon: ListenableBuilder(
                      listenable: _printerService,
                      builder: (context, _) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _printerService.isConnected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _printerService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          size: 18,
                          color: _printerService.isConnected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    tooltip: 'Bluetooth Printer',
                    onPressed: () => PrinterConnectModal.show(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 4),
                  // Printer Hardware Settings Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.textSecondary),
                    ),
                    tooltip: 'Printer Settings',
                    onPressed: () => PrinterSettingsModal.show(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 8),
                  // Green Print Button — Always clearly visible on top right!
                  ElevatedButton.icon(
                    onPressed: _openPrintDialog,
                    icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Print',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. ACTION RIBBON (Row 2): Undo, Redo, Copy, Clear, Save, Size Dropdown ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    color: _undoStack.isNotEmpty ? AppColors.textPrimary : Colors.grey.shade400,
                    tooltip: 'Undo',
                    onPressed: _undoStack.isNotEmpty ? _undo : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded, size: 20),
                    color: _redoStack.isNotEmpty ? AppColors.textPrimary : Colors.grey.shade400,
                    tooltip: 'Redo',
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    color: _selectedElementId != null ? AppColors.textPrimary : Colors.grey.shade400,
                    tooltip: 'Duplicate Element',
                    onPressed: _selectedElementId != null ? _duplicateSelected : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                    color: _elements.isNotEmpty ? AppColors.textPrimary : Colors.grey.shade400,
                    tooltip: 'Clear Canvas',
                    onPressed: _elements.isEmpty
                        ? null
                        : () {
                            _saveState();
                            setState(() {
                              _elements.clear();
                              _selectedElementId = null;
                            });
                          },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_outlined, size: 18),
                    color: AppColors.textPrimary,
                    tooltip: 'Save Label',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved label "$_labelName"'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  const Spacer(),
                  // Size Selector Dropdown (e.g. "50×30mm ∨")
                  PopupMenuButton<LabelSize>(
                    initialValue: _currentSize,
                    onSelected: (size) => setState(() => _currentSize = size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentSize.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => LabelSize.standardSizes
                        .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Text(s.name, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            // 3. Main Interactive Label Canvas Area with Top Floating Action Bar
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedElementId = null),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Canvas Renderer
                      LabelCanvasView(
                        size: _currentSize,
                        elements: _elements,
                        isEditable: true,
                        selectedElementId: _selectedElementId,
                        onElementTap: (el) => _selectElement(el),
                        onElementDoubleTap: (el) => _editElementDialog(el),
                        onElementDragged: (el, dx, dy) {
                          setState(() {
                            el.x += dx;
                            el.y += dy;
                          });
                        },
                        onElementResized: (el, newW, newH) {
                          setState(() {
                            el.width = newW;
                            el.height = newH;
                          });
                        },
                        onElementDelete: (el) => _deleteSelected(),
                        onElementDuplicate: (el) => _duplicateSelected(),
                        onElementScaled: (el, factor) {
                          setState(() {
                            el.width = (el.width * factor).clamp(20.0, 600.0);
                            el.height = (el.height * factor).clamp(12.0, 600.0);
                          });
                        },
                      ),

                      // Top Floating Action Bar (Screenshot 1, 3, 4, 5)
                      if (selectedEl != null)
                        Positioned(
                          top: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildFloatingActionBar(selectedEl),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Bottom Contextual Property Panel OR Paginated Creation Toolbar
            _buildBottomPanel(selectedEl),
          ],
        ),
      ),
    );
  }

  // --- Top Floating Action Bar (Black Rounded Pill) ---
  Widget _buildFloatingActionBar(LabelElement el) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Edit
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit_note, color: Colors.white, size: 20),
            tooltip: 'Edit',
            onPressed: () => _editElementDialog(el),
          ),
          const SizedBox(width: 8),

          // 2. Delete
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
            tooltip: 'Delete',
            onPressed: _deleteSelected,
          ),
          const SizedBox(width: 8),

          // 3. Copy
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.content_copy_outlined, color: Colors.white, size: 19),
            tooltip: 'Copy',
            onPressed: _duplicateSelected,
          ),
          const SizedBox(width: 8),

          // 4. Rotate
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
            tooltip: 'Rotate',
            onPressed: _rotateSelected,
          ),
          const SizedBox(width: 8),

          // 5. Align
          InkWell(
            onTap: _alignCenterSelected,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_align_center, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Align', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Lock
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            icon: Icon(
              el.isLocked ? Icons.lock : Icons.lock_outline,
              color: el.isLocked ? AppColors.primary : Colors.white,
              size: 19,
            ),
            tooltip: el.isLocked ? 'Unlock' : 'Lock',
            onPressed: _toggleLockSelected,
          ),
        ],
      ),
    );
  }

  // --- Bottom Panel (Contextual Sheet OR Creation Toolbar) ---
  Widget _buildBottomPanel(LabelElement? selectedEl) {
    if (selectedEl == null) {
      // General Creation Toolbar
      return _buildGeneralCreationToolbar();
    }

    switch (selectedEl.type) {
      case ElementType.text:
        return _buildTextContextualPanel(selectedEl);
      case ElementType.barcode:
        return _buildBarcodeContextualPanel(selectedEl);
      case ElementType.qrcode:
        return _buildQRCodeContextualPanel(selectedEl);
      case ElementType.dateTime:
        return _buildDateTimeContextualPanel(selectedEl);
      default:
        return _buildGenericContextualPanel(selectedEl);
    }
  }

  // --- 1. General Creation Toolbar (Page 1 & Page 2) ---
  Widget _buildGeneralCreationToolbar() {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _bottomBarPageController,
              onPageChanged: (idx) => setState(() => _bottomBarPageIndex = idx),
              children: [
                // Page 1: Text | QR Code | Barcode | Time | Material (Image 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomToolItem(
                      icon: Icons.title,
                      label: 'Text',
                      onTap: _addText,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.qr_code_2,
                      label: 'QR Code',
                      onTap: _addQRCode,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.barcode_reader,
                      label: 'Barcode',
                      onTap: _addBarcode,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.access_time,
                      label: 'Time',
                      onTap: _addTime,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.sentiment_satisfied_alt,
                      label: 'Material',
                      onTap: _addMaterialSheet,
                    ),
                  ],
                ),

                // Page 2: Image | Serial | Border | Shape | Excel (Image 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomToolItem(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      onTap: _addImage,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.format_list_numbered,
                      label: 'Serial',
                      onTap: _addSerial,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.crop_square,
                      label: 'Border',
                      onTap: _addBorder,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.interests_outlined,
                      label: 'Shape',
                      onTap: _addShape,
                    ),
                    _buildBottomToolItem(
                      icon: Icons.table_chart_outlined,
                      label: 'Excel',
                      onTap: _addExcel,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Page Indicator Dots (• ○ / ○ •)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bottomBarPageIndex == 0 ? Colors.black87 : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bottomBarPageIndex == 1 ? Colors.black87 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Text Contextual Property Panel (Screenshot 4) ---
  Widget _buildTextContextualPanel(LabelElement el) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Direct editable text pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              onChanged: (val) {
                setState(() {
                  el.text = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: Header Tabs (Style | Font) and Dismiss Down Arrow
          Row(
            children: [
              _buildPanelTab(
                title: 'Style',
                isSelected: _textTabIndex == 0,
                onTap: () => setState(() => _textTabIndex = 0),
              ),
              const SizedBox(width: 24),
              _buildPanelTab(
                title: 'Font',
                isSelected: _textTabIndex == 1,
                onTap: () => setState(() => _textTabIndex = 1),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black87),
                onPressed: () => setState(() => _selectedElementId = null),
              ),
            ],
          ),
          const Divider(height: 12),

          if (_textTabIndex == 0) ...[
            // Formatting Row: B | U | I | Align Left | Align Center | Align Right | (A)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFormatBtn(
                  child: const Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  isActive: el.isBold,
                  onTap: () => setState(() => el.isBold = !el.isBold),
                ),
                _buildFormatBtn(
                  child: const Text('U', style: TextStyle(decoration: TextDecoration.underline, fontSize: 16)),
                  isActive: el.isUnderline,
                  onTap: () => setState(() => el.isUnderline = !el.isUnderline),
                ),
                _buildFormatBtn(
                  child: const Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                  isActive: el.isItalic,
                  onTap: () => setState(() => el.isItalic = !el.isItalic),
                ),
                _buildFormatBtn(
                  child: const Icon(Icons.format_align_left, size: 20),
                  isActive: el.textAlign == TextAlign.left,
                  onTap: () => setState(() => el.textAlign = TextAlign.left),
                ),
                _buildFormatBtn(
                  child: const Icon(Icons.format_align_center, size: 20),
                  isActive: el.textAlign == TextAlign.center,
                  onTap: () => setState(() => el.textAlign = TextAlign.center),
                ),
                _buildFormatBtn(
                  child: const Icon(Icons.format_align_right, size: 20),
                  isActive: el.textAlign == TextAlign.right,
                  onTap: () => setState(() => el.textAlign = TextAlign.right),
                ),
                _buildFormatBtn(
                  child: const Text('(A)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  isActive: el.isUppercase,
                  onTap: () => setState(() => el.isUppercase = !el.isUppercase),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stepper 1: Font Size (Aa)
            _buildStepperRow(
              iconWidget: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              value: el.fontSize,
              min: 8,
              max: 48,
              displayStr: el.fontSize.round().toString(),
              onChanged: (val) => setState(() => el.fontSize = val),
            ),
            const SizedBox(height: 8),

            // Stepper 2: Line Spacing (≡)
            _buildStepperRow(
              iconWidget: const Icon(Icons.format_line_spacing, size: 20),
              value: el.lineSpacing,
              min: 0,
              max: 20,
              displayStr: el.lineSpacing.round().toString(),
              onChanged: (val) => setState(() => el.lineSpacing = val),
            ),
            const SizedBox(height: 8),

            // Stepper 3: Letter Spacing (|A|)
            _buildStepperRow(
              iconWidget: const Text('|A|', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              value: el.letterSpacing,
              min: 0,
              max: 20,
              displayStr: el.letterSpacing.round().toString(),
              onChanged: (val) => setState(() => el.letterSpacing = val),
            ),
          ] else ...[
            // Font Families list
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFontChoice('Default', 'Roboto', el),
                  _buildFontChoice('Monospace', 'monospace', el),
                  _buildFontChoice('Serif', 'serif', el),
                  _buildFontChoice('Sans-Serif', 'sans-serif', el),
                  _buildFontChoice('Cursive', 'cursive', el),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFontChoice(String name, String family, LabelElement el) {
    final isSelected = el.fontFamily == family;
    return GestureDetector(
      onTap: () => setState(() => el.fontFamily = family),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontFamily: family,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Barcode Contextual Property Panel (Screenshots 1, 2, 5) ---
  Widget _buildBarcodeContextualPanel(LabelElement el) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Tabs: Barcode | Style and Dismiss Down Arrow
          Row(
            children: [
              _buildPanelTab(
                title: 'Barcode',
                isSelected: _barcodeTabIndex == 0,
                onTap: () => setState(() => _barcodeTabIndex = 0),
              ),
              const SizedBox(width: 24),
              _buildPanelTab(
                title: 'Style',
                isSelected: _barcodeTabIndex == 1,
                onTap: () => setState(() => _barcodeTabIndex = 1),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black87),
                onPressed: () => setState(() => _selectedElementId = null),
              ),
            ],
          ),
          const Divider(height: 12),

          if (_barcodeTabIndex == 0) ...[
            // --- Barcode Tab (Screenshot 1) ---
            // 1. Serial toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Serial', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Switch(
                  value: el.isSerial,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => el.isSerial = val),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!el.isSerial) ...[
              // 2. Barcode content pill with scan/edit icon
              InkWell(
                onTap: () => _editElementDialog(el),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          el.barcodeData.isEmpty ? '123456' : el.barcodeData,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.crop_free, size: 20, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Encoding Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Encoding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  PopupMenuButton<String>(
                    initialValue: el.barcodeEncoding,
                    onSelected: (val) => setState(() => el.barcodeEncoding = val),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            el.barcodeEncoding,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      'CODE39',
                      'CODE128',
                      'CODE93',
                      'EAN13',
                    ]
                        .map((enc) => PopupMenuItem(
                              value: enc,
                              child: Text(enc, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ] else ...[
              // Serial Parameters
              _buildSerialConfigView(el),
            ],
          ] else ...[
            // --- Style Tab (Screenshot 2) ---
            // 1. Style option: Barcode with text vs Barcode only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Style', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    // Option 1: Barcode with text
                    GestureDetector(
                      onTap: () => setState(() => el.showBarcodeText = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: el.showBarcodeText ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: el.showBarcodeText ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.view_column,
                              size: 20,
                              color: el.showBarcodeText ? AppColors.primary : Colors.grey,
                            ),
                            Text(
                              '123456',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: el.showBarcodeText ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Option 2: Barcode only
                    GestureDetector(
                      onTap: () => setState(() => el.showBarcodeText = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: !el.showBarcodeText ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !el.showBarcodeText ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          Icons.view_column,
                          size: 26,
                          color: !el.showBarcodeText ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Size Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Size', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    _buildStepperBtn(
                      icon: Icons.remove,
                      onTap: () => setState(() {
                        el.height = (el.height - 4).clamp(18.0, 160.0);
                      }),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        (el.height / 10).toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    _buildStepperBtn(
                      icon: Icons.add,
                      onTap: () => setState(() {
                        el.height = (el.height + 4).clamp(18.0, 160.0);
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Align Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Align', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    _buildFormatBtn(
                      child: const Icon(Icons.format_align_left, size: 20),
                      isActive: el.textAlign == TextAlign.left,
                      onTap: () => setState(() => el.textAlign = TextAlign.left),
                    ),
                    const SizedBox(width: 8),
                    _buildFormatBtn(
                      child: const Icon(Icons.format_align_center, size: 20),
                      isActive: el.textAlign == TextAlign.center,
                      onTap: () => setState(() => el.textAlign = TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    _buildFormatBtn(
                      child: const Icon(Icons.format_align_right, size: 20),
                      isActive: el.textAlign == TextAlign.right,
                      onTap: () => setState(() => el.textAlign = TextAlign.right),
                    ),
                    const SizedBox(width: 8),
                    _buildFormatBtn(
                      child: const Icon(Icons.format_align_justify, size: 20),
                      isActive: el.textAlign == TextAlign.justify,
                      onTap: () => setState(() => el.textAlign = TextAlign.justify),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Isometric drawing Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Isometric drawing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Switch(
                  value: el.isIsometric,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => el.isIsometric = val),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. QR Code Contextual Property Panel (Screenshot 3) ---
  Widget _buildQRCodeContextualPanel(LabelElement el) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Tab: QR Code and Dismiss Down Arrow
          Row(
            children: [
              _buildPanelTab(
                title: 'QR Code',
                isSelected: true,
                onTap: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black87),
                onPressed: () => setState(() => _selectedElementId = null),
              ),
            ],
          ),
          const Divider(height: 12),

          // 1. Serial toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Serial', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Switch(
                value: el.isSerial,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => el.isSerial = val),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!el.isSerial) ...[
            // 2. Content edit pill
            InkWell(
              onTap: () => _editElementDialog(el),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        el.qrData.isEmpty ? '123456' : el.qrData,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.crop_free, size: 20, color: Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Encoding Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Encoding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                PopupMenuButton<String>(
                  initialValue: el.qrEncoding,
                  onSelected: (val) => setState(() => el.qrEncoding = val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          el.qrEncoding,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    'QR_CODE',
                    'PDF417',
                    'DATA_MATRIX',
                    'AZTEC',
                  ]
                      .map((enc) => PopupMenuItem(
                            value: enc,
                            child: Text(enc, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ] else ...[
            // Serial Parameters
            _buildSerialConfigView(el),
          ],
        ],
      ),
    );
  }

  // --- 5. DateTime Contextual Property Panel ---
  Widget _buildDateTimeContextualPanel(LabelElement el) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildPanelTab(title: 'Time', isSelected: true, onTap: () {}),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black87),
                onPressed: () => setState(() => _selectedElementId = null),
              ),
            ],
          ),
          const Divider(height: 12),

          // Date format picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Format', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              PopupMenuButton<String>(
                initialValue: el.dateTimeFormat,
                onSelected: (val) {
                  setState(() {
                    el.dateTimeFormat = val;
                    el.text = DateFormat(val).format(DateTime.now());
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        el.dateTimeFormat,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  'yyyy/MM/dd HH:mm:ss',
                  'yyyy-MM-dd HH:mm',
                  'dd/MM/yyyy',
                  'HH:mm:ss',
                  'yyyy/MM/dd',
                  'MM/dd/yyyy',
                ]
                    .map((fmt) => PopupMenuItem(
                          value: fmt,
                          child: Text(fmt, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Font Size Stepper
          _buildStepperRow(
            iconWidget: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            value: el.fontSize,
            min: 8,
            max: 36,
            displayStr: el.fontSize.round().toString(),
            onChanged: (val) => setState(() => el.fontSize = val),
          ),
          const SizedBox(height: 12),

          // Alignment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Align', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  _buildFormatBtn(
                    child: const Icon(Icons.format_align_left, size: 20),
                    isActive: el.textAlign == TextAlign.left,
                    onTap: () => setState(() => el.textAlign = TextAlign.left),
                  ),
                  const SizedBox(width: 8),
                  _buildFormatBtn(
                    child: const Icon(Icons.format_align_center, size: 20),
                    isActive: el.textAlign == TextAlign.center,
                    onTap: () => setState(() => el.textAlign = TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  _buildFormatBtn(
                    child: const Icon(Icons.format_align_right, size: 20),
                    isActive: el.textAlign == TextAlign.right,
                    onTap: () => setState(() => el.textAlign = TextAlign.right),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. Generic Contextual Property Panel for other elements ---
  Widget _buildGenericContextualPanel(LabelElement el) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildPanelTab(
                title: el.type.name.toUpperCase(),
                isSelected: true,
                onTap: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black87),
                onPressed: () => setState(() => _selectedElementId = null),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text('Edit', style: TextStyle(color: Colors.white)),
                onPressed: () => _editElementDialog(el),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                label: const Text('Delete', style: TextStyle(color: Colors.white)),
                onPressed: _deleteSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Serial Configuration View ---
  Widget _buildSerialConfigView(LabelElement el) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Prefix',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                controller: TextEditingController(text: el.serialPrefix),
                onChanged: (val) => setState(() => el.serialPrefix = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Suffix',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                controller: TextEditingController(text: el.serialSuffix),
                onChanged: (val) => setState(() => el.serialSuffix = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Start:', style: TextStyle(fontSize: 14)),
            Row(
              children: [
                _buildStepperBtn(
                  icon: Icons.remove,
                  onTap: () => setState(() {
                    if (el.serialStart > 0) el.serialStart--;
                  }),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    el.serialStart.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStepperBtn(
                  icon: Icons.add,
                  onTap: () => setState(() => el.serialStart++),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Text('Digits:', style: TextStyle(fontSize: 14)),
            Row(
              children: [
                _buildStepperBtn(
                  icon: Icons.remove,
                  onTap: () => setState(() {
                    if (el.serialDigits > 1) el.serialDigits--;
                  }),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    el.serialDigits.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStepperBtn(
                  icon: Icons.add,
                  onTap: () => setState(() => el.serialDigits++),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Preview: ${el.effectiveBarcodeData}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // --- Sub-Components and Helpers ---
  Widget _buildPanelTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2.5,
              width: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatBtn({
    required Widget child,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(
            color: isActive ? AppColors.primary : Colors.black87,
            size: 20,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: isActive ? AppColors.primary : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildStepperRow({
    required Widget iconWidget,
    required double value,
    required double min,
    required double max,
    required String displayStr,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 28, child: Center(child: iconWidget)),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStepperBtn(
          icon: Icons.remove,
          onTap: () {
            if (value > min) onChanged((value - 1).clamp(min, max));
          },
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            displayStr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        _buildStepperBtn(
          icon: Icons.add,
          onTap: () {
            if (value < max) onChanged((value + 1).clamp(min, max));
          },
        ),
      ],
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
