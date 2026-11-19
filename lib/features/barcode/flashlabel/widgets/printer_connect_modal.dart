import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import 'printer_settings_modal.dart';

class PrinterConnectModal extends StatefulWidget {
  const PrinterConnectModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrinterConnectModal(),
    );
  }

  @override
  State<PrinterConnectModal> createState() => _PrinterConnectModalState();
}

class _PrinterConnectModalState extends State<PrinterConnectModal> {
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onServiceUpdate);
    // Auto-start scanning for real available Bluetooth printers when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_printerService.isConnected && !_printerService.isScanning) {
        _printerService.startScan();
      }
    });
  }

  @override
  void dispose() {
    _printerService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  bool _isPrinterName(String name) {
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

  @override
  Widget build(BuildContext context) {
    final connected = _printerService.connectedDevice;
    final isConnected = _printerService.isConnected;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
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
                      'Bluetooth Printer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Seznik / FlashLabel / ESC-POS / TSPL',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _printerService.isConnecting
                      ? null
                      : () {
                          if (_printerService.isScanning) {
                            _printerService.stopScan();
                          } else {
                            _printerService.startScan();
                          }
                        },
                  icon: _printerService.isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(_printerService.isScanning ? 'Stop' : 'Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Live Status banner
          if (_printerService.printStatusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _printerService.isConnected
                    ? AppColors.primaryLight
                    : (_printerService.printStatusMessage.contains('fail') ||
                            _printerService.printStatusMessage.contains('error') ||
                            _printerService.printStatusMessage.contains('Please grant')
                        ? Colors.red.shade50
                        : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _printerService.isConnected
                        ? Icons.check_circle_outline
                        : (_printerService.isConnecting
                            ? Icons.hourglass_top
                            : (_printerService.isScanning ? Icons.radar : Icons.info_outline)),
                    size: 14,
                    color: _printerService.isConnected
                        ? AppColors.primary
                        : (_printerService.printStatusMessage.contains('fail') ||
                                _printerService.printStatusMessage.contains('error')
                            ? Colors.red.shade700
                            : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _printerService.printStatusMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _printerService.isConnected
                            ? AppColors.primary
                            : (_printerService.printStatusMessage.contains('fail') ||
                                    _printerService.printStatusMessage.contains('error')
                                ? Colors.red.shade700
                                : Colors.blue.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Connected device card (if currently connected)
          if (isConnected && connected != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.print, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    connected.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ONLINE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              connected.address,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _printerService.disconnect(),
                        child: const Text('Disconnect', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Protocol switcher
                  Row(
                    children: [
                      const Text(
                        'Protocol: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('ESC/POS (Seznik / 58mm)', style: TextStyle(fontSize: 11)),
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
                        label: const Text('TSPL (4x6 Desktop)', style: TextStyle(fontSize: 11)),
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
                  const SizedBox(height: 8),
                  // Send Test Diagnostic Label
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _printerService.isPrinting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await _printerService.printTestDiagnostic();
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    backgroundColor: ok ? AppColors.primary : Colors.red,
                                    content: Text(ok
                                        ? '✓ Test diagnostic label sent to ${connected.name}!'
                                        : 'Print failed: check printer power & paper'),
                                  ),
                                );
                              }
                            },
                      icon: _printerService.isPrinting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt, size: 16),
                      label: Text(
                        _printerService.isPrinting ? 'Printing...' : 'Send Test Diagnostic Label to Printer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Hardware Settings Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            PrinterSettingsModal.show(context);
                          },
                          icon: const Icon(Icons.tune, size: 14, color: AppColors.primary),
                          label: const Text('Printer Settings & Gap', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await _printerService.feedPaper();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Paper feed executed')),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_downward, size: 14, color: AppColors.textPrimary),
                          label: const Text('Feed Paper', style: TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _printerService.isScanning
                      ? 'SEARCHING FOR AVAILABLE BLUETOOTH PRINTERS...'
                      : 'AVAILABLE BLUETOOTH DEVICES (${_printerService.devices.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Real Discovered Devices List (Live nearby only)
          Expanded(
            child: _printerService.devices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _printerService.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                            size: 52,
                            color: _printerService.isScanning ? AppColors.primary : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _printerService.isScanning
                                ? 'Scanning for nearby Bluetooth devices...'
                                : 'No Bluetooth devices found nearby',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _printerService.isScanning
                                ? 'Ensure your Seznik / FlashLabel / thermal printer is turned ON and within 5 meters.'
                                : 'Only actively powered-on devices are shown. Turn ON your printer and tap "Scan Again".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (!_printerService.isScanning) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _printerService.startScan(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Scan Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _printerService.devices.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = _printerService.devices[index];
                      final isCurrConnected = connected?.id == device.id && isConnected;
                      final isConnectingThis = _printerService.isConnecting && _printerService.connectingDeviceId == device.id;
                      final isPrinter = _isPrinterName(device.name);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isCurrConnected
                                ? AppColors.primaryLight
                                : (isPrinter ? Colors.green.shade50 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPrinter ? Icons.print : Icons.bluetooth,
                            color: isCurrConnected
                                ? AppColors.primary
                                : (isPrinter ? Colors.green.shade700 : Colors.grey.shade700),
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                device.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            if (isPrinter) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PRINTER',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              device.protocol.name.toUpperCase(),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${device.rssi} dBm',
                              style: TextStyle(
                                color: device.rssi > -70 ? Colors.green.shade700 : Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              device.rssi > -70 ? Icons.signal_cellular_alt : Icons.signal_cellular_alt_2_bar,
                              size: 12,
                              color: device.rssi > -70 ? Colors.green.shade700 : Colors.grey.shade500,
                            ),
                          ],
                        ),
                        trailing: isCurrConnected
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text('Connected', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _printerService.isConnecting
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final ok = await _printerService.connect(device);
                                        if (mounted) {
                                          if (ok) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                backgroundColor: AppColors.primary,
                                                content: Text('✓ Connected to ${device.name}! Ready to print.'),
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          } else {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                backgroundColor: Colors.red.shade700,
                                                content: Text(_printerService.printStatusMessage.isNotEmpty
                                                    ? _printerService.printStatusMessage
                                                    : 'Connection failed. Please ensure printer is ON and in range.'),
                                                duration: const Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 0,
                                ),
                                child: isConnectingThis
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                      );
                    },
                  ),
          ),

          // Bottom tip notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Only nearby active Bluetooth devices are listed. Keep your printer ON and nearby.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
