import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../services/canvas_rasterizer_service.dart';
import '../services/printer_service.dart';
import '../services/template_service.dart';
import '../theme/app_colors.dart';
import '../widgets/label_canvas_view.dart';
import '../widgets/printer_connect_modal.dart';
import '../widgets/thermal_preview_dialog.dart';
import 'excel_batch_screen.dart';
import 'freestyle_editor_screen.dart';
import 'new_label_screen.dart';
import 'pdf_print_screen.dart';
import 'templates_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrinterService _printerService = PrinterService();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _printerService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connected = _printerService.connectedDevice;
    final isConnected = _printerService.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Top Bar: FlashLabel Pro Logo + Disconnected/Connected Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'FlashLabel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => PrinterConnectModal.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isConnected ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.print_outlined,
                            size: 15,
                            color: isConnected ? AppColors.primary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? connected!.name : 'Disconnected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isConnected ? AppColors.primary : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Hero Banner: "PDF PRINT ADDS AI CROP!!!"
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PdfPrintScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE8F2FF),
                        Color(0xFFF3EBFF),
                        Color(0xFFE9FBF0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Sparkles
                      Positioned(
                        top: 20,
                        right: 140,
                        child: Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade300),
                      ),
                      Positioned(
                        bottom: 25,
                        right: 120,
                        child: Icon(Icons.auto_awesome, size: 14, color: Colors.purple.shade300),
                      ),

                      // Text Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'PDF PRINT ADDS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E2229),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                              ).createShader(bounds),
                              child: const Text(
                                'AI CROP!!!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Auto crop margins • 1-Click Print',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Illustration: Shipping label being cut by modern lavender scissors
                      Positioned(
                        right: 14,
                        top: 18,
                        bottom: 18,
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 24, height: 4, color: Colors.grey.shade400),
                                  const Spacer(),
                                  Container(width: 14, height: 4, color: Colors.grey.shade300),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(width: 45, height: 3, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              // Barcode preview
                              Center(
                                child: Container(
                                  height: 22,
                                  color: Colors.grey.shade100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      14,
                                      (i) => Container(
                                        width: i % 2 == 0 ? 2 : 1,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Scissors icon cutting
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.content_cut, size: 16, color: Colors.purple.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. Quick Action Buttons: PDF Print | Image Print | Scan Print
              Row(
                children: [
                  // PDF Print
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PdfPrintScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'PDF',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Print',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Image Print
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PdfPrintScreen(isImageMode: true),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Image Print',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Stickers',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Scan Print
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExcelBatchScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.table_chart_outlined, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Excel Data',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Batch Print',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Printer Quick Connect Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.print,
                      size: 22,
                      color: isConnected ? AppColors.primary : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? connected!.name : 'Device not connected',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            isConnected ? 'Ready • TSPL/ESC-POS' : 'Connect Seznik / thermal printer',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => PrinterConnectModal.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? AppColors.primaryLight : Colors.white,
                        foregroundColor: isConnected ? AppColors.primary : AppColors.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      ),
                      child: Text(
                        isConnected ? 'Switch' : 'Connect',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Section: "My Files"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.folder, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Files',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                      );
                    },
                    child: const Text(
                      'More >',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Horizontal cards for My Files (Screenshot 1 cards)
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Card 1: 40*30mm-Pink (Thank you)
                    _buildMyFileCard(
                      context,
                      template: TemplateService.templates[0],
                      title: '40*30mm-Pink',
                      subtitle: '40×30mm',
                    ),
                    const SizedBox(width: 14),

                    // Card 2: RETURN ADDRESS
                    _buildMyFileCard(
                      context,
                      template: TemplateService.templates[1],
                      title: 'RETURN ADDRESS',
                      subtitle: '150×100mm',
                    ),
                    const SizedBox(width: 14),

                    // Card 3: Express Logistics
                    _buildMyFileCard(
                      context,
                      template: TemplateService.templates[7],
                      title: 'Express Label',
                      subtitle: '100×150mm',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Section: "Template"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.grid_view_rounded, size: 16, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Template',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                      );
                    },
                    child: const Text(
                      'More >',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Horizontal cards for Templates (Screenshot 2 cards)
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTemplateQuickCard(
                      context,
                      template: TemplateService.templates[2], // Homemade with love
                    ),
                    const SizedBox(width: 14),
                    _buildTemplateQuickCard(
                      context,
                      template: TemplateService.templates[5], // SCAN TO TAKE 20% OFF
                    ),
                    const SizedBox(width: 14),
                    _buildTemplateQuickCard(
                      context,
                      template: TemplateService.templates[6], // PRETTY THINGS INSIDE
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // Custom Curved Notch Bottom Navigation Bar with floating '+' button
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab
            IconButton(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    color: _currentNavIndex == 0 ? AppColors.primary : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentNavIndex == 0 ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              onPressed: () => setState(() => _currentNavIndex = 0),
            ),

            // Center Floating Add Button with green background
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewLabelScreen()),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x5500C261),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),

            // Profile / My Tab
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: _currentNavIndex == 1 ? AppColors.primary : Colors.grey.shade400,
              ),
              onPressed: () {
                PrinterConnectModal.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyFileCard(
    BuildContext context, {
    required LabelTemplate template,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview thumbnail
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FreestyleEditorScreen(initialTemplate: template),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: LabelCanvasView(
                  size: template.size,
                  elements: template.elements,
                  backgroundColor: template.backgroundColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            ThermalPrintProgressDialog.show(
                              context: context,
                              previewWidget: Container(
                                height: 180,
                                padding: const EdgeInsets.all(8),
                                color: template.backgroundColor,
                                child: LabelCanvasView(size: template.size, elements: template.elements),
                              ),
                              labelTitle: template.title,
                              labelSizeStr: template.sizeSubtitle,
                              onPrintConfirmed: (copies) async {
                                final renderedImg = await CanvasRasterizerService.rasterizeLabel(
                                  size: template.size,
                                  elements: template.elements,
                                  shape: template.shape,
                                );
                                await _printerService.printImage(
                                  image: renderedImg,
                                  labelWidthMm: template.size.widthMm,
                                  labelHeightMm: template.size.heightMm,
                                  copies: copies,
                                );
                              },
                            );
                          },
                          child: const Icon(Icons.print_outlined, size: 16, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateQuickCard(BuildContext context, {required LabelTemplate template}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FreestyleEditorScreen(initialTemplate: template),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: template.backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: LabelCanvasView(
                  size: template.size,
                  elements: template.elements,
                  backgroundColor: template.backgroundColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    template.sizeSubtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

