import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joyn/core/theme/joyn_typography.dart';
import 'package:joyn/core/theme/joyn_colors.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/Alltransaction_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/Balancesheet_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/Bill_wise_profite_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/Cashflow_report_screen.dart';
import 'package:joyn/features/reports/Presentation/Party%20Report%20Screens/Party_salepurchase_screen.dart';
import 'package:joyn/features/reports/Presentation/Party%20Report%20Screens/allparties_report_screen.dart';
import 'package:joyn/features/reports/Presentation/Party%20Report%20Screens/party_reportby_item.dart';
import 'package:joyn/features/reports/Presentation/Party%20Report%20Screens/party_statement_screen.dart';
import 'package:joyn/features/reports/Presentation/Party%20Report%20Screens/partywise_profit&loss_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/Profit&loss_report_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/daybook_screen.dart';
import 'package:joyn/features/reports/Presentation/Transaction%20reports/purchase_report_screen.dart';

import 'Transaction reports/sale_report_screen.dart';

const Color _crownBg = Color(0xFFB39DDB);

void _openReport(BuildContext context, String title) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Open: $title'),
      duration: const Duration(milliseconds: 700),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: JoynColors.primary,
    ),
  );
}

class ReportItem {
  final String title;
  final bool isPremium;
  final VoidCallback? onTap;
  const ReportItem(this.title, {this.isPremium = false, this.onTap});
}

class ReportSection {
  final String title;
  final List<ReportItem> items;
  const ReportSection(this.title, this.items);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportSection> _sections(BuildContext context) => [
    ReportSection('Transaction', [
      ReportItem('Sale Report', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SaleReportScreen()));
      }),
      ReportItem('Purchase Report', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseReportScreen()));
      }),
      ReportItem('Day Book', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DayBookScreen()));
      }),
      ReportItem('All Transactions', onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllTransactionsScreen(transactions: sampleTransactions),
          ),
        );
      }),
      ReportItem('Bill Wise Profit', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BillWiseProfitScreen()));
      }),
      ReportItem('Profit & loss', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfitAndLossReportScreen()));
      }),
      ReportItem('Cash Flow', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CashflowReportScreen()));
      }),
      ReportItem('Balance Sheet', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BalanceSheetScreen()));
      }),
    ]),
    ReportSection('Party reports', [
      ReportItem('Party Statement', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyStatementScreen()));
      }),
      ReportItem('Party Wise Profit & Loss', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyWiseProfitLossScreen()));
      }),
      ReportItem('All Parties Report', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AllPartyReportScreen()));
      }),
      ReportItem('Party Report by Items', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyReportByItemScreen()));
      }),
      ReportItem('Sale/Purchase by Party', onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SalePurchaseByPartyScreen()));
      }),
    ]),
    ReportSection('GST reports', [
      ReportItem('GSTR-1', onTap: () => _openReport(context, 'GSTR-1')),
      ReportItem('GSTR-2', onTap: () => _openReport(context, 'GSTR-2')),
      ReportItem('GSTR-3B', onTap: () => _openReport(context, 'GSTR-3B')),
      ReportItem('GST Transaction report', onTap: () => _openReport(context, 'GST Transaction report')),
      ReportItem('GSTR-9', onTap: () => _openReport(context, 'GSTR-9')),
      ReportItem('Sale Summary by HSN', onTap: () => _openReport(context, 'Sale Summary by HSN')),
      ReportItem('SAC Report', onTap: () => _openReport(context, 'SAC Report')),
    ]),
    ReportSection('Item/Stock reports', [
      ReportItem('Stock Summary Report', onTap: () => _openReport(context, 'Stock Summary Report')),
      ReportItem('Item Report by Party', onTap: () => _openReport(context, 'Item Report by Party')),
      ReportItem('Item Wise Profit & Loss', onTap: () => _openReport(context, 'Item Wise Profit & Loss')),
      ReportItem('Low Stock Summary Report', onTap: () => _openReport(context, 'Low Stock Summary Report')),
      ReportItem('Item Detail Report', onTap: () => _openReport(context, 'Item Detail Report')),
      ReportItem('Stock Detail Report', onTap: () => _openReport(context, 'Stock Detail Report')),
      ReportItem('Sale/Purchase By Item Category', onTap: () => _openReport(context, 'Sale/Purchase By Item Category')),
      ReportItem('Stock summary By Item Category', onTap: () => _openReport(context, 'Stock summary By Item Category')),
  ReportItem('Item Batch Report'  ),
      ReportItem('Item Serial Report'),
      ReportItem('Item Wise Discount', onTap: () => _openReport(context, 'Item Wise Discount')),
    ]),
    ReportSection('Business status', [
      ReportItem('Bank Statement', onTap: () => _openReport(context, 'Bank Statement')),
      ReportItem('Discount Report', onTap: () => _openReport(context, 'Discount Report')),
    ]),
    ReportSection('Taxes', [
      ReportItem('GST Report', onTap: () => _openReport(context, 'GST Report')),
      ReportItem('GST Rate Report', onTap: () => _openReport(context, 'GST Rate Report')),
      ReportItem('Form No. 27EQ', onTap: () => _openReport(context, 'Form No. 27EQ')),
      ReportItem('TCS Receivable', onTap: () => _openReport(context, 'TCS Receivable')),
      ReportItem('TDS Payable', onTap: () => _openReport(context, 'TDS Payable')),
      ReportItem('TDS Receivable', onTap: () => _openReport(context, 'TDS Receivable')),
    ]),
    ReportSection('Expense reports', [
      ReportItem('Expense Transaction Report', onTap: () => _openReport(context, 'Expense Transaction Report')),
      ReportItem('Expense Category Report', onTap: () => _openReport(context, 'Expense Category Report')),
      ReportItem('Expense Item Report', onTap: () => _openReport(context, 'Expense Item Report')),
    ]),
    ReportSection('Sale/Purchase Order reports', [
      ReportItem('Sale/Purchase Order Transaction Report',
          onTap: () => _openReport(context, 'Sale/Purchase Order Transaction Report')),
      ReportItem('Sale/Purchase Order Item Report',
          onTap: () => _openReport(context, 'Sale/Purchase Order Item Report')),
    ]),
    ReportSection('Loan Reports', [
      ReportItem('Loan Statement', onTap: () => _openReport(context, 'Loan Statement')),
    ]),
  ];

  List<ReportSection> _filteredSections(List<ReportSection> sections) {
    if (_searchQuery.isEmpty) return sections;

    final query = _searchQuery.toLowerCase();
    return sections
        .map((section) => ReportSection(
      section.title,
      section.items
          .where((item) => item.title.toLowerCase().contains(query) || section.title.toLowerCase().contains(query))
          .toList(),
    ))
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _filteredSections(_sections(context));

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: JoynColors.primary,
        titleSpacing: 0,
        title: _isSearching
            ? _buildSearchField()
            : Text(
          'Reports',
          style: JoynTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: JoynColors.primary,
          ),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: JoynColors.primary),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded, color: JoynColors.primary),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: sections.isEmpty
          ? _buildNoResults()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: sections.length,
        itemBuilder: (context, index) => _SectionCard(
          section: sections[index],
          sectionNumber: index + 1,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: JoynColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search reports...',
          hintStyle: JoynTypography.bodyMedium.copyWith(
            color: JoynColors.secondaryText,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        style: JoynTypography.bodyMedium.copyWith(
          color: JoynColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: JoynColors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: JoynColors.secondaryText.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: JoynTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: JoynColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching with a different keyword',
            style: JoynTypography.caption.copyWith(
              fontSize: 12,
              color: JoynColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ReportSection section;
  final int sectionNumber;
  const _SectionCard({required this.section, required this.sectionNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: JoynColors.iconBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [

                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        JoynColors.primary,
                        JoynColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$sectionNumber',
                    style: JoynTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  section.title,
                  style: JoynTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: JoynColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ...section.items.map((item) => _ReportRow(item: item)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final ReportItem item;
  const _ReportRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isPremium
          ? () => _openReport(context, '${item.title} (Premium)')
          : item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 14.5,
                  color: JoynColors.primary,
                ),
              ),
            ),
            if (item.isPremium)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: _crownBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
              ),
            if (!item.isPremium)
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
}