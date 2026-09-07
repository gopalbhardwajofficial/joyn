import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';
import '../models/sales_models.dart';

class SaleOrderDetailScreen extends StatelessWidget {
  final SaleOrderModel order;

  const SaleOrderDetailScreen({super.key, required this.order});

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More Options',
                    style: JoynTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: JoynColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Duplicate
              _buildMenuItem(
                icon: Icons.copy_rounded,
                label: 'Duplicate',
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Duplicate');
                },
              ),

              // Receive Payment
              _buildMenuItem(
                icon: Icons.payments_outlined,
                label: 'Receive Payment',
                color: const Color(0xFF16A34A),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Receive Payment');
                },
              ),

              // Return
              _buildMenuItem(
                icon: Icons.keyboard_return_rounded,
                label: 'Return',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Return');
                },
              ),

              // Delivery Challan
              _buildMenuItem(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery Challan',
                color: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Delivery Challan');
                },
              ),

              // Share as PDF
              _buildMenuItem(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Share as PDF',
                color: const Color(0xFFC0202B),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Share as PDF');
                },
              ),

              // Generate E-Invoice
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                label: 'Generate E-Invoice',
                color: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showComingSoon(context, 'Generate E-Invoice');
                },
              ),

              const SizedBox(height: 8),

              // Cancel Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: JoynColors.chipBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: JoynTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: JoynColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: JoynTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: JoynColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: JoynColors.primary,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = order.paymentMode.toLowerCase() == 'credit';

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Sale Details',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // Three-Dot Menu
          IconButton(
            onPressed: () => _showMoreOptions(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JoynColors.chipBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded, size: 18, color: JoynColors.secondaryText),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Invoice Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, JoynColors.background],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JoynColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice #${order.invoiceNo}',
                              style: JoynTypography.titleMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: JoynColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.date,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 13,
                                color: JoynColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? JoynColors.error.withValues(alpha: 0.08)
                              : JoynColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCredit
                                ? JoynColors.error.withValues(alpha: 0.2)
                                : JoynColors.success.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.paymentMode,
                          style: JoynTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCredit ? JoynColors.error : JoynColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: JoynColors.border),
                  const SizedBox(height: 16),
                  _buildInfoRow('Customer', order.customerName),
                  const SizedBox(height: 12),
                  _buildInfoRow('Phone', order.customerPhone.isEmpty ? 'N/A' : order.customerPhone),
                  const SizedBox(height: 12),
                  _buildInfoRow('Type', order.isOneTimeCustomer ? 'One Time Customer' : 'Regular Customer'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Items Section
            Text(
              'Items',
              style: JoynTypography.bodyLarge.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: JoynColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, JoynColors.background],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JoynColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('Item', style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                      ),
                      Expanded(
                        child: Text('Qty', textAlign: TextAlign.center, style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                      ),
                      Expanded(
                        child: Text('Amount', textAlign: TextAlign.right, style: JoynTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: JoynColors.secondaryText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: JoynColors.border),
                  const SizedBox(height: 10),
                  ...order.items.map((item) {
                    final name = item['name'] ?? '';
                    final qty = item['qty'] ?? 0;
                    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                    final price = (item['price'] as num?)?.toDouble() ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.toString(), style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: JoynColors.primary)),
                                const SizedBox(height: 2),
                                Text('₹${price.toStringAsFixed(2)} / unit', style: JoynTypography.caption.copyWith(fontSize: 10.5, color: JoynColors.secondaryText)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(qty.toString(), textAlign: TextAlign.center, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Text('₹${amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: JoynColors.primary)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Divider(color: JoynColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: JoynTypography.bodyLarge.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800, color: JoynColors.primary)),
                      Text('₹${order.totalAmount.toStringAsFixed(2)}', style: JoynTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: JoynColors.primary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.payments_outlined,
                    label: 'Receive Payment',
                    color: const Color(0xFF16A34A),
                    onTap: () => _showComingSoon(context, 'Receive Payment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Share as PDF',
                    color: const Color(0xFFC0202B),
                    onTap: () => _showComingSoon(context, 'Share as PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: JoynTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: JoynTypography.bodyMedium.copyWith(fontSize: 13, color: JoynColors.secondaryText)),
        Text(value, style: JoynTypography.bodyMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: JoynColors.primary)),
      ],
    );
  }
}