import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import 'printer_connect_modal.dart';

class ThermalPrintProgressDialog extends StatefulWidget {
  final Widget previewWidget;
  final String labelTitle;
  final String labelSizeStr;
  final Function(int copies) onPrintConfirmed;

  const ThermalPrintProgressDialog({
    super.key,
    required this.previewWidget,
    required this.labelTitle,
    required this.labelSizeStr,
    required this.onPrintConfirmed,
  });

  static Future<void> show({
    required BuildContext context,
    required Widget previewWidget,
    required String labelTitle,
    required String labelSizeStr,
    required Function(int copies) onPrintConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ThermalPrintProgressDialog(
        previewWidget: previewWidget,
        labelTitle: labelTitle,
        labelSizeStr: labelSizeStr,
        onPrintConfirmed: onPrintConfirmed,
      ),
    );
  }

  @override
  State<ThermalPrintProgressDialog> createState() => _ThermalPrintProgressDialogState();
}

class _ThermalPrintProgressDialogState extends State<ThermalPrintProgressDialog> with SingleTickerProviderStateMixin {
  final PrinterService _printerService = PrinterService();
  late AnimationController _ejectController;
  late Animation<double> _ejectAnimation;
  int _copies = 1;

  @override
  void initState() {
    super.initState();
    _ejectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ejectAnimation = CurvedAnimation(
      parent: _ejectController,
      curve: Curves.easeOutCubic,
    );
    _printerService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _ejectController.dispose();
    _printerService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (_printerService.isPrinting && !_ejectController.isAnimating && _ejectController.value < 1.0) {
      _ejectController.forward();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connected = _printerService.connectedDevice;
    final isConnected = _printerService.isConnected;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.labelTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.labelSizeStr} • ${isConnected ? connected!.name : "Device not connected"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Printer slot representation
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Animated Label Paper Ejection
            ClipRect(
              child: AnimatedBuilder(
                animation: _ejectAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (_ejectAnimation.value - 1.0) * -10),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        child: widget.previewWidget,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Protocol & Paper Mode Selector (Direct 1-tap switches)
            if (isConnected && connected != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Protocol selector
                    Row(
                      children: [
                        const Text('Mode: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('ESC/POS (Seznik/58mm)', style: TextStyle(fontSize: 10)),
                          selected: connected.protocol == PrinterProtocol.escPos,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: connected.protocol == PrinterProtocol.escPos ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => _printerService.setProtocol(PrinterProtocol.escPos),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('TSPL (4x6 Desktop)', style: TextStyle(fontSize: 10)),
                          selected: connected.protocol == PrinterProtocol.tspl,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: connected.protocol == PrinterProtocol.tspl ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => _printerService.setProtocol(PrinterProtocol.tspl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connected.protocol == PrinterProtocol.escPos
                          ? '✓ ESC/POS active: Designed for Seznik 50x30mm sticker rolls.'
                          : '⚠️ TSPL is only for large 4x6 desktop printers. Use ESC/POS for Seznik.',
                      style: TextStyle(
                        fontSize: 9,
                        color: connected.protocol == PrinterProtocol.escPos ? Colors.green.shade700 : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Paper Type selector
                    Row(
                      children: [
                        const Text('Paper: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('Gap (Sticker)', style: TextStyle(fontSize: 10)),
                          selected: _printerService.paperType == PaperType.gap,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _printerService.paperType == PaperType.gap ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => _printerService.updateSettings(paperType: PaperType.gap),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Continuous (Roll)', style: TextStyle(fontSize: 10)),
                          selected: _printerService.paperType == PaperType.continuous,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _printerService.paperType == PaperType.continuous ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => _printerService.updateSettings(paperType: PaperType.continuous),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Copies selector with Quick Chips (1, 2, 3, etc.) & Stepper
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Copies:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 24),
                            onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            alignment: Alignment.center,
                            child: Text('$_copies', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                            onPressed: () => setState(() => _copies++),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 3, 4, 5, 10].map((c) {
                      final isSel = _copies == c;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _copies = c),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AppColors.primary : Colors.grey.shade300),
                            ),
                            child: Text(
                              '$c',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Progress bar if printing
            if (_printerService.isPrinting) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _printerService.printProgress > 0 ? _printerService.printProgress : null,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
              Text(
                _printerService.printStatusMessage,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // Emergency Stop Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _printerService.emergencyStop(),
                  icon: const Icon(Icons.stop_circle, color: Colors.white, size: 16),
                  label: const Text('Emergency Stop / Halt Print', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _printerService.isPrinting
                    ? null
                    : () {
                        if (!isConnected) {
                          // Open scanner to connect printer first!
                          PrinterConnectModal.show(context);
                        } else {
                          _ejectController.reset();
                          _ejectController.forward();
                          widget.onPrintConfirmed(_copies);
                        }
                      },
                icon: Icon(isConnected ? Icons.print : Icons.bluetooth_searching, color: Colors.white, size: 20),
                label: Text(
                  isConnected ? 'Print via ${connected!.name}' : 'Connect Bluetooth Printer',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
