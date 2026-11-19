import 'package:flutter/material.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                color: JoynColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JoynColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: JoynColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JOYN ERP & Billing Platform',
                          style: JoynTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: JoynColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last Updated: November 2026',
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
              title: 'Acceptance of Terms',
              content:
                  'By registering, accessing, downloading, or using JOYN ERP & Billing ("Service", "Application"), you agree to be bound by these Terms of Service. If you are using this Application on behalf of a company, partnership, or business enterprise, you represent and warrant that you possess full authority to bind that entity to these Terms.',
            ),

            _buildSection(
              number: '2',
              title: 'Business & Accounting Services',
              content:
                  'JOYN provides point-of-sale (POS) billing, invoicing, GST computation, inventory control, party ledger management, and financial reporting. All calculations (including GST, discounts, and margins) are computed based on inputs provided by the user. While JOYN implements compliant Indian GST and accounting algorithms, the user remains solely responsible for the legal validity and compliance of filed tax returns and published invoices.',
            ),

            _buildSection(
              number: '3',
              title: 'Account & Security',
              content:
                  'You are responsible for safeguarding your registered phone number, OTP authentication, and device access credentials. JOYN utilizes encrypted communication protocols (TLS/SSL) and deterministic security tokens. You agree to notify JOYN immediately of any unauthorized access or security breach involving your enterprise account.',
            ),

            _buildSection(
              number: '4',
              title: 'Data Ownership & Confidentiality',
              content:
                  'You retain 100% full legal ownership of your business data, inventory records, customer lists, invoices, and accounting ledgers. JOYN does not sell, lease, or monetize your trade or transaction data to any third party. Your data is stored locally on your device with synchronized cloud backup capabilities to protect your continuity.',
            ),

            _buildSection(
              number: '5',
              title: 'Compliance with Indian Laws',
              content:
                  'Users agree to operate in accordance with the Information Technology Act, 2000, Central Goods and Services Tax Act, 2017, and applicable state commercial statutes. You shall not generate fraudulent, duplicate, or fictitious tax invoices through the application.',
            ),

            _buildSection(
              number: '6',
              title: 'Availability & Offline Functionality',
              content:
                  'JOYN is engineered to work reliably offline using local SQLite storage. When network connectivity is re-established, records are reconciled with our cloud servers. JOYN strives for 99.9% cloud availability but is not liable for temporary carrier outages, hardware failures, or force majeure events.',
            ),

            _buildSection(
              number: '7',
              title: 'Termination & Data Portability',
              content:
                  'You may terminate your account at any time. Upon request, you are entitled to export all your invoices, parties, items, and day records in standard spreadsheet (Excel/CSV) and PDF formats before closing your account.',
            ),

            _buildSection(
              number: '8',
              title: 'Contact & Support',
              content:
                  'For legal, technical, or billing queries, contact our enterprise support team at support@joynonline.in or through the in-app Help section.',
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
                  color: JoynColors.primary,
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
