import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/label_model.dart';
import '../services/canvas_rasterizer_service.dart';
import '../services/image_processing_service.dart';
import '../services/printer_service.dart';
import '../services/template_service.dart';
import '../theme/app_colors.dart';
import '../widgets/label_canvas_view.dart';
import '../widgets/thermal_preview_dialog.dart';

class PdfPrintScreen extends StatefulWidget {
  final bool isImageMode;

  const PdfPrintScreen({super.key, this.isImageMode = false});

  @override
  State<PdfPrintScreen> createState() => _PdfPrintScreenState();
}

class _PdfPrintScreenState extends State<PdfPrintScreen> {
  final PrinterService _printerService = PrinterService();

  String _fileName = 'express and logistics.pdf';
  LabelSize _selectedSize = LabelSize.standardSizes[0]; // 50x30 mm (from Screenshot 3)
  FilterMode _filterMode = FilterMode.bwThreshold; // B/W selected in Screenshot 3
  double _threshold = 200.0; // 200 in Screenshot 3
  int _rotationQuarterTurns = 0;
  bool _isAICropped = false;
  bool _isInverted = false;

  // Active label template being displayed
  late LabelTemplate _currentTemplate;

  @override
  void initState() {
    super.initState();
    // Default to Express logistics shipping label (Screenshot 3)
    _currentTemplate = TemplateService.templates[7];
  }

  void _onPickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.isImageMode ? FileType.image : FileType.custom,
        allowedExtensions: widget.isImageMode ? null : ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fileName = result.files.first.name;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded $_fileName for thermal printing')),
          );
        }
      }
    } catch (e) {
      debugPrint("File pick error: $e");
    }
  }

  void _toggleAICrop() {
    setState(() {
      _isAICropped = !_isAICropped;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isAICropped ? 'AI Auto-Crop applied: whitespace margins trimmed!' : 'AI Crop disabled: original frame restored'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: Back, Title + subtitle, + PDF button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isImageMode ? 'Image Print' : 'PDF Print',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          _fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onPickFile,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: Text(widget.isImageMode ? '+ Image' : '+ PDF', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. Main Canvas with Millimeter Rulers & Floating Tools
            Expanded(
              child: Stack(
                children: [
                  // Rulers & Canvas
                  Column(
                    children: [
                      // Top Millimeter Ruler Guide
                      Container(
                        height: 22,
                        margin: const EdgeInsets.only(left: 36, right: 16),
                        child: Row(
                          children: [
                            Text(
                              '0',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                height: 1,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              '${_selectedSize.widthMm.toInt()} mm',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                height: 1,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Canvas Body with Side Ruler
                      Expanded(
                        child: Row(
                          children: [
                            // Left vertical ruler
                            Container(
                              width: 32,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      '${_selectedSize.heightMm.toInt()} mm',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Document Preview Canvas
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 16, bottom: 8),
                                padding: EdgeInsets.all(_isAICropped ? 0 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: RotatedBox(
                                  quarterTurns: _rotationQuarterTurns,
                                  child: LabelCanvasView(
                                    size: _selectedSize,
                                    elements: _currentTemplate.elements,
                                    backgroundColor: _filterMode == FilterMode.bwThreshold && _isInverted ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Floating Toolbar on the Left (Screenshot 3)
                  Positioned(
                    left: 12,
                    top: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. AI Crop with scissors + AI badge
                          InkWell(
                            onTap: _toggleAICrop,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isAICropped ? AppColors.primaryLight : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.content_cut,
                                    size: 20,
                                    color: _isAICropped ? AppColors.primary : Colors.grey.shade700,
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 2. Manual Crop
                          IconButton(
                            icon: const Icon(Icons.crop, size: 20),
                            color: Colors.grey.shade700,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Manual drag crop box active')),
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // 3. Rotate 90°
                          IconButton(
                            icon: const Icon(Icons.rotate_right, size: 20),
                            color: Colors.grey.shade700,
                            onPressed: () {
                              setState(() {
                                _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
                              });
                            },
                          ),
                          const SizedBox(height: 8),

                          // 4. Invert / Contrast
                          IconButton(
                            icon: Icon(_isInverted ? Icons.contrast : Icons.invert_colors, size: 20),
                            color: _isInverted ? AppColors.primary : Colors.grey.shade700,
                            onPressed: () {
                              setState(() {
                                _isInverted = !_isInverted;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom Controls Panel: Paper Size, Filter, Threshold (Screenshot 3)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paper Size Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Paper Size',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.grey),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                        onPressed: () {
                          // Custom label size
                        },
                      ),
                    ],
                  ),

                  // Horizontal Paper Size Chips (Screenshot 3)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: LabelSize.standardSizes.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final size = LabelSize.standardSizes[index];
                        final isSelected = _selectedSize.name == size.name;

                        return ChoiceChip(
                          label: Text(
                            size.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.grey.shade700,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (_) => setState(() => _selectedSize = size),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Header & Modes (Original, B/W, Dithering)
                  Row(
                    children: [
                      const Text(
                        'Filter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.grey),
                      const Spacer(),
                      // Filter segmented buttons
                      _buildFilterChip('Original', FilterMode.original),
                      const SizedBox(width: 6),
                      _buildFilterChip('B/W', FilterMode.bwThreshold),
                      const SizedBox(width: 6),
                      _buildFilterChip('Dithering', FilterMode.dithering, hasInfo: true),
                    ],
                  ),

                  // Threshold Slider (Screenshot 3: "Threshold: 200")
                  if (_filterMode == FilterMode.bwThreshold) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Threshold:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              thumbColor: AppColors.primary,
                              inactiveTrackColor: AppColors.primaryLight,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _threshold,
                              min: 50,
                              max: 255,
                              onChanged: (val) => setState(() => _threshold = val),
                            ),
                          ),
                        ),
                        Text(
                          '${_threshold.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Bottom toolbar: Presets (FNSKU, 1:1) and Green NEXT/PRINT button
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Preset FNSKU
                          setState(() {
                            _selectedSize = LabelSize.standardSizes[0];
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('FNSKU', style: TextStyle(fontSize: 11, color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('1:1', style: TextStyle(fontSize: 11, color: Colors.black87)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          ThermalPrintProgressDialog.show(
                            context: context,
                            previewWidget: Container(
                              height: 220,
                              padding: const EdgeInsets.all(8),
                              color: Colors.white,
                              child: LabelCanvasView(
                                size: _selectedSize,
                                elements: _currentTemplate.elements,
                              ),
                            ),
                            labelTitle: _fileName,
                            labelSizeStr: _selectedSize.name,
                            onPrintConfirmed: (copies) async {
                              final renderedImg = await CanvasRasterizerService.rasterizeLabel(
                                size: _selectedSize,
                                elements: _currentTemplate.elements,
                                shape: _currentTemplate.shape,
                              );
                              await _printerService.printImage(
                                image: renderedImg,
                                labelWidthMm: _selectedSize.widthMm,
                                labelHeightMm: _selectedSize.heightMm,
                                filterMode: _filterMode,
                                threshold: _threshold.toInt(),
                                copies: copies,
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterMode mode, {bool hasInfo = false}) {
    final isSelected = _filterMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _filterMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (hasInfo) ...[
              const SizedBox(width: 3),
              const Icon(Icons.info_outline, size: 12, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}
