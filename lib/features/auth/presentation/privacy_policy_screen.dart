import 'package:flutter/material.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: JoynTypography.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: JoynColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy & Data Security',
                          style: JoynTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Strict Zero-Data-Selling Commitment',
                          style: JoynTypography.caption.copyWith(color: JoynColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              number: '1',
              title: 'Information We Collect',
              content:
                  'To provide ERP and billing services, JOYN collects:\n• Account Credentials: Phone number, user email, and business name.\n• Enterprise Profile: GSTIN, business trade name, billing address, state of supply, and business logo.\n• Operational Records: Product catalog, SKU barcodes, party contact details, invoices, purchase orders, expenses, and transaction logs.',
            ),

            _buildSection(
              number: '2',
              title: 'How We Use Your Information',
              content:
                  'Your data is utilized strictly to:\n• Generate professional GST invoices, bills, and payment receipts.\n• Compute statutory tax statements (GSTR-1, GSTR-2, GSTR-3B, GSTR-9).\n• Reconcile cashflow, accounts receivable/payable, and inventory stock levels.\n• Provide secure automated cloud backup and cross-device synchronization.',
            ),

            _buildSection(
              number: '3',
              title: 'Camera & Storage Permissions',
              content:
                  '• Camera: Required only when you use the built-in barcode scanner to scan item codes or capture invoice attachments.\n• Storage / Files: Used to export and save PDF and Excel spreadsheets to your device or select business logos.',
            ),

            _buildSection(
              number: '4',
              title: 'Data Storage & Encryption',
              content:
                  'All data in transit is protected using industry-grade TLS 1.3 encryption. Your records are stored in secure PostgreSQL databases behind firewall-protected infrastructure. Offline records are safely kept in your local SQLite sandbox.',
            ),

            _buildSection(
              number: '5',
              title: 'Third-Party Sharing Policy',
              content:
                  'JOYN NEVER sells, rents, or shares your financial, sales, or customer data with advertisers, third-party data brokers, or competitors. We only share minimal essential data with verified infrastructure providers (such as SMS gateways for OTP verification).',
            ),

            _buildSection(
              number: '6',
              title: 'Your Rights & Data Control',
              content:
                  'You have complete control over your data. You may review, modify, export, or delete your business records directly through the application at any time.',
            ),

            _buildSection(
              number: '7',
              title: 'Policy Updates & Contact',
              content:
                  'Any updates to this privacy policy will be posted within the application. If you have any privacy concerns, contact our Data Protection Officer at privacy@joynonline.in.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: JoynTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: JoynColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              content,
              style: JoynTypography.bodyMedium.copyWith(
                color: Colors.black87,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
