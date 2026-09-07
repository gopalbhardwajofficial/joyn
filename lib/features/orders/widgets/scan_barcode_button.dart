import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../Inventory/presentation/scan_code_screen.dart';

class ScanBarcodeButton extends StatelessWidget {
  final Function(String barcode) onBarcodeScanned;
  final double? size;
  final Color? color;

  const ScanBarcodeButton({
    super.key,
    required this.onBarcodeScanned,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();

        final barcode = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => const ScanCodeScreen(),
          ),
        );

        if (barcode != null && barcode.isNotEmpty) {
          onBarcodeScanned(barcode);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (color ?? JoynColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (color ?? JoynColors.primary).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: (size ?? 40) * 0.5,
          color: color ?? JoynColors.primary,
        ),
      ),
    );
  }
}