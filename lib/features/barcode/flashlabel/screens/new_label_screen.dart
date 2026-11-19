import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/label_model.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/printer_connect_modal.dart';
import 'freestyle_editor_screen.dart';

class NewLabelScreen extends StatefulWidget {
  const NewLabelScreen({super.key});

  @override
  State<NewLabelScreen> createState() => _NewLabelScreenState();
}

class _NewLabelScreenState extends State<NewLabelScreen> {
  // Label metadata
  late String _labelName;
  LabelShape _shape = LabelShape.rectangle;
  double _widthMm = 50;
  double _heightMm = 30;
  double _diameterMm = 50;
  String? _backgroundImagePath;

  // Selected preset index
  int _selectedPresetIndex = 0;

  final List<LabelSize> _presets = [
    const LabelSize(name: '50×30 mm', widthMm: 50, heightMm: 30),
    const LabelSize(name: '50×50 mm', widthMm: 50, heightMm: 50, isRound: true),
    const LabelSize(name: '50×50 mm', widthMm: 50, heightMm: 50, isRound: false),
    const LabelSize(name: '99×150 mm', widthMm: 99, heightMm: 150),
    const LabelSize(name: '100×100 mm', widthMm: 100, heightMm: 100, isRound: true),
    const LabelSize(name: '100×150 mm', widthMm: 100, heightMm: 150),
    const LabelSize(name: '80×40 mm', widthMm: 80, heightMm: 40),
  ];

  @override
  void initState() {
    super.initState();
    // Default name matches Screenshot: e.g. 20261102 (yyyyMMdd)
    _labelName = DateFormat('yyyyMMdd').format(DateTime.now());
  }

  void _applyPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      final p = _presets[index];
      if (p.isRound) {
        _shape = LabelShape.circle;
        _diameterMm = p.widthMm;
      } else {
        _shape = LabelShape.rectangle;
        _widthMm = p.widthMm;
        _heightMm = p.heightMm;
      }
    });
  }

  void _swapDimensions() {
    setState(() {
      final temp = _widthMm;
      _widthMm = _heightMm;
      _heightMm = temp;
      _selectedPresetIndex = -1; // Deselect preset
    });
  }

  void _editNameDialog() {
    final controller = TextEditingController(text: _labelName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Label Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _labelName = controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _pickBackgroundImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _backgroundImagePath = result.files.first.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background watermark selected')),
          );
        }
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  void _confirmAndCreateLabel() {
    final finalSize = _shape == LabelShape.circle
        ? LabelSize(name: '${_diameterMm.toInt()}×${_diameterMm.toInt()} mm', widthMm: _diameterMm, heightMm: _diameterMm, isRound: true)
        : LabelSize(name: '${_widthMm.toInt()}×${_heightMm.toInt()} mm', widthMm: _widthMm, heightMm: _heightMm, isRound: false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FreestyleEditorScreen(
          customLabelName: _labelName,
          customSize: finalSize,
          customShape: _shape,
          backgroundImagePath: _backgroundImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = _shape == LabelShape.circle;
    final currentWidth = isCircle ? _diameterMm : _widthMm;
    final currentHeight = isCircle ? _diameterMm : _heightMm;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Label',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ListenableBuilder(
              listenable: PrinterService(),
              builder: (context, _) => Icon(
                PrinterService().isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: PrinterService().isConnected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            tooltip: 'Bluetooth Printer',
            onPressed: () => PrinterConnectModal.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dynamic Top Preview Box with mm Dimension Lines (Images 1, 2, 3)
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          // Top Dimension Line
                          Positioned(
                            top: 4,
                            left: 30,
                            right: 30,
                            child: Row(
                              children: [
                                Container(width: 1, height: 6, color: Colors.grey.shade400),
                                Expanded(
                                  child: Container(height: 1, color: Colors.grey.shade400),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '${currentWidth.toInt()} mm',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  child: Container(height: 1, color: Colors.grey.shade400),
                                ),
                                Container(width: 1, height: 6, color: Colors.grey.shade400),
                              ],
                            ),
                          ),

                          // Right Dimension Line
                          Positioned(
                            top: 25,
                            bottom: 15,
                            right: 4,
                            child: Column(
                              children: [
                                Container(width: 6, height: 1, color: Colors.grey.shade400),
                                Expanded(
                                  child: Container(width: 1, color: Colors.grey.shade400),
                                ),
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      '${currentHeight.toInt()} mm',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(width: 1, color: Colors.grey.shade400),
                                ),
                                Container(width: 6, height: 1, color: Colors.grey.shade400),
                              ],
                            ),
                          ),

                          // Dynamic Center Label Shape Canvas
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 15, right: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double maxW = constraints.maxWidth - 20;
                                  final double maxH = constraints.maxHeight - 20;

                                  final double ratio = currentWidth / currentHeight;
                                  double w, h;
                                  if (ratio > maxW / maxH) {
                                    w = maxW;
                                    h = maxW / ratio;
                                  } else {
                                    h = maxH;
                                    w = maxH * ratio;
                                  }

                                  return Container(
                                    width: w.clamp(60, maxW),
                                    height: h.clamp(60, maxH),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                                      borderRadius: isCircle ? null : BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Name Section (Screenshot 1: Name 20261102 ✏️)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          InkWell(
                            onTap: _editNameDialog,
                            child: Row(
                              children: [
                                Text(
                                  _labelName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Preset Sizes Section (Horizontal Chips from Screenshot 1 & 2)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horizontal Preset Cards
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _presets.length + 1,
                              separatorBuilder: (context, index) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                if (index == _presets.length) {
                                  // More icon •••
                                  return Container(
                                    width: 44,
                                    height: 70,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.more_horiz, color: Colors.grey),
                                  );
                                }

                                final p = _presets[index];
                                final isSelected = _selectedPresetIndex == index;

                                return GestureDetector(
                                  onTap: () => _applyPreset(index),
                                  child: Container(
                                    width: p.widthMm == p.heightMm && p.isRound ? 66 : (p.heightMm > 100 ? 56 : 64),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryLight : const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(p.isRound ? 33 : 12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${p.widthMm.toInt()}×${p.heightMm.toInt()}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'mm',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isSelected ? AppColors.primary : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Shape Selector (Rectangle / Circle)
                          Row(
                            children: [
                              const Text(
                                'Shape',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const Spacer(),
                              // Rectangle Pill
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _shape = LabelShape.rectangle;
                                    _selectedPresetIndex = -1;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isCircle ? AppColors.primaryLight : const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Rectangle',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: !isCircle ? FontWeight.bold : FontWeight.normal,
                                      color: !isCircle ? AppColors.primary : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Circle Pill
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _shape = LabelShape.circle;
                                    _selectedPresetIndex = -1;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCircle ? AppColors.primaryLight : const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Circle',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCircle ? FontWeight.bold : FontWeight.normal,
                                      color: isCircle ? AppColors.primary : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Steppers: Width / Height OR Diameter
                          if (!isCircle) ...[
                            // Width Stepper
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Width (mm)',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                _buildStepper(
                                  value: _widthMm.toInt(),
                                  onMinus: () {
                                    if (_widthMm > 10) {
                                      setState(() {
                                        _widthMm--;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                  onPlus: () {
                                    if (_widthMm < 200) {
                                      setState(() {
                                        _widthMm++;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            // Center Swap Button ⇅
                            Center(
                              child: InkWell(
                                onTap: _swapDimensions,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                                ),
                              ),
                            ),

                            // Height Stepper
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Height (mm)',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                _buildStepper(
                                  value: _heightMm.toInt(),
                                  onMinus: () {
                                    if (_heightMm > 10) {
                                      setState(() {
                                        _heightMm--;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                  onPlus: () {
                                    if (_heightMm < 300) {
                                      setState(() {
                                        _heightMm++;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ] else ...[
                            // Diameter Stepper (Image 2)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Diameter (mm)',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                _buildStepper(
                                  value: _diameterMm.toInt(),
                                  onMinus: () {
                                    if (_diameterMm > 10) {
                                      setState(() {
                                        _diameterMm--;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                  onPlus: () {
                                    if (_diameterMm < 200) {
                                      setState(() {
                                        _diameterMm++;
                                        _selectedPresetIndex = -1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Background Section (Image 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Background image does not print',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _pickBackgroundImage,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 5. Solid Green Confirm Button (Images 1, 2, 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmAndCreateLabel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onMinus,
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.remove, size: 14, color: Colors.black87),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

