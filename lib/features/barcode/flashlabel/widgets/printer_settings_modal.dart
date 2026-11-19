import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';

class PrinterSettingsModal extends StatefulWidget {
  const PrinterSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrinterSettingsModal(),
    );
  }

  @override
  State<PrinterSettingsModal> createState() => _PrinterSettingsModalState();
}

class _PrinterSettingsModalState extends State<PrinterSettingsModal> {
  final PrinterService _printerService = PrinterService();

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Printer Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Bluetooth Thermal & Seznik Hardware Config',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Status Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.primaryLight : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isConnected ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.primary : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.print, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? connected!.name : 'No Printer Connected',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isConnected ? '${connected!.address} • ${connected.protocol.name.toUpperCase()}' : 'Connect your Seznik / FlashLabel via Bluetooth',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.primary : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isConnected ? 'CONNECTED' : 'OFFLINE',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. Protocol Mode (TSPL / ESC-POS / CPCL)
                  const Text(
                    'PRINTER COMMAND PROTOCOL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildProtocolChip('ESC/POS (Seznik / 58mm)', PrinterProtocol.escPos),
                      const SizedBox(width: 8),
                      _buildProtocolChip('TSPL (4x6 Desktop)', PrinterProtocol.tspl),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Paper Media Type (Gap, Continuous, Black Mark)
                  const Text(
                    'PAPER MEDIA TYPE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaperTypeChip('Gap Label', PaperType.gap),
                      const SizedBox(width: 8),
                      _buildPaperTypeChip('Continuous Roll', PaperType.continuous),
                      const SizedBox(width: 8),
                      _buildPaperTypeChip('Black Mark', PaperType.blackMark),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Print Density / Darkness Slider (1 to 15)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRINT DENSITY (DARKNESS)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                      ),
                      Text(
                        '${_printerService.density} / 15',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primaryLight,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _printerService.density.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      onChanged: (val) {
                        _printerService.updateSettings(density: val.toInt());
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Print Speed (Inches per second)
                  const Text(
                    'PRINT SPEED (INCHES / SEC)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [2, 3, 4, 5].map((s) {
                      final isSelected = _printerService.speed == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$s ips', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          onSelected: (_) => _printerService.updateSettings(speed: s),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 5. Hardware Commands & Calibration
                  const Text(
                    'HARDWARE COMMANDS & SENSOR CALIBRATION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),

                  // Calibrate Gap Sensor
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isConnected
                          ? () async {
                              final ok = await _printerService.calibrateSensor();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ok ? 'Gap sensor calibrated' : 'Calibration failed')),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.tune, size: 18, color: AppColors.primary),
                      label: const Text('Calibrate Label Gap Sensor (GAPDETECT)', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Feed 1 Label
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isConnected
                          ? () async {
                              final ok = await _printerService.feedPaper();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ok ? 'Paper feed executed' : 'Feed failed')),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.blue),
                      label: const Text('Form Feed (Feed 1 Label / Receipt)', style: TextStyle(color: Colors.blue, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Print Self-Test Diagnostic
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isConnected
                          ? () async {
                              final ok = await _printerService.printTestDiagnostic();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ok ? 'Test diagnostic printed' : 'Print failed')),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.bolt, size: 18, color: Colors.white),
                      label: const Text('Print Self-Test Configuration Label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Emergency Stop / Clear Buffer
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isConnected
                          ? () async {
                              await _printerService.emergencyStop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('Emergency stop signal sent! Printer buffer cleared.'),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.stop_circle, size: 18, color: Colors.red),
                      label: const Text('Emergency Stop / Clear Printer Buffer', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolChip(String label, PrinterProtocol proto) {
    final isSelected = _printerService.connectedDevice?.protocol == proto;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => _printerService.setProtocol(proto),
    );
  }

  Widget _buildPaperTypeChip(String label, PaperType type) {
    final isSelected = _printerService.paperType == type;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => _printerService.updateSettings(paperType: type),
    );
  }
}

