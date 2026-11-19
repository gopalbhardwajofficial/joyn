import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
import 'gst/gstr1_report_screen.dart';
import 'gst/gstr2_report_screen.dart';
import 'gst/gstr3b_report_screen.dart';
import 'gst/gstr9_report_screen.dart';
import 'gst/hsn_summary_screen.dart';
import 'expenses/manage_expenses_screen.dart';
import 'overview_screen.dart';

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

// ═══════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════
class ReportItem {
  final String title;
  final String? subtitle;
  final bool isPremium;
  final VoidCallback? onTap;
  const ReportItem(this.title, {this.subtitle, this.isPremium = false, this.onTap});
}

class ReportSection {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<ReportItem> items;
  const ReportSection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.items,
  });
}

// ═══════════════════════════════════════════════════════════════
//  REPORTS SCREEN
// ═══════════════════════════════════════════════════════════════
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
    ReportSection(
      title: 'Transaction',
      subtitle: 'Sales, purchases & financial entries',
      icon: Icons.receipt_long_rounded,
      items: [
        ReportItem('Sale Report', subtitle: 'All sales transactions',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleReportScreen()))),
        ReportItem('Purchase Report', subtitle: 'All purchase entries',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseReportScreen()))),
        ReportItem('Day Book', subtitle: 'Daily transaction summary',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DayBookScreen()))),
        ReportItem('All Transactions', subtitle: 'Complete ledger view',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen()))),
        ReportItem('Bill Wise Profit', subtitle: 'Profit per invoice',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillWiseProfitScreen()))),
        ReportItem('Profit & Loss', subtitle: 'Income vs expenses',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfitAndLossReportScreen()))),
        ReportItem('Cash Flow', subtitle: 'Cash movement tracking',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashflowReportScreen()))),
        ReportItem('Balance Sheet', subtitle: 'Assets & liabilities',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceSheetScreen()))),
      ],
    ),
    ReportSection(
      title: 'Party Reports',
      subtitle: 'Customer & supplier insights',
      icon: Icons.groups_rounded,
      items: [
        ReportItem('Party Statement', subtitle: 'Full party ledger',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyStatementScreen()))),
        ReportItem('Party Wise Profit & Loss', subtitle: 'Per-party profitability',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyWiseProfitLossScreen()))),
        ReportItem('All Parties Report', subtitle: 'Complete party list',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPartyReportScreen()))),
        ReportItem('Party Report by Items', subtitle: 'Item-wise party analysis',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyReportByItemScreen()))),
        ReportItem('Sale/Purchase by Party', subtitle: 'Party-wise volumes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalePurchaseByPartyScreen()))),
      ],
    ),
    ReportSection(
      title: 'GST Reports',
      subtitle: 'Tax filings & compliance',
      icon: Icons.account_balance_rounded,
      items: [
        ReportItem('GSTR-1', subtitle: 'Outward supplies',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Gstr1ReportScreen()))),
        ReportItem('GSTR-2', subtitle: 'Inward supplies',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Gstr2ReportScreen()))),
        ReportItem('GSTR-3B', subtitle: 'Monthly summary return',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Gstr3bReportScreen()))),
        ReportItem('GST Transaction Report', subtitle: 'All GST transactions', onTap: () => _openReport(context, 'GST Transaction report')),
        ReportItem('GSTR-9', subtitle: 'Annual return',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Gstr9ReportScreen()))),
        ReportItem('Sale Summary by HSN', subtitle: 'HSN-wise sale breakup',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HsnSummaryScreen()))),
        ReportItem('SAC Report', subtitle: 'Service accounting codes', onTap: () => _openReport(context, 'SAC Report')),
      ],
    ),
    ReportSection(
      title: 'Item / Stock Reports',
      subtitle: 'Inventory intelligence',
      icon: Icons.inventory_2_rounded,
      items: [
        ReportItem('Stock Summary Report', subtitle: 'Current stock levels', onTap: () => _openReport(context, 'Stock Summary Report')),
        ReportItem('Item Report by Party', subtitle: 'Item movement per party', onTap: () => _openReport(context, 'Item Report by Party')),
        ReportItem('Item Wise Profit & Loss', subtitle: 'Item-level margins', onTap: () => _openReport(context, 'Item Wise Profit & Loss')),
        ReportItem('Low Stock Summary Report', subtitle: 'Reorder alerts', onTap: () => _openReport(context, 'Low Stock Summary Report')),
        ReportItem('Item Detail Report', subtitle: 'Detailed item info', onTap: () => _openReport(context, 'Item Detail Report')),
        ReportItem('Stock Detail Report', subtitle: 'Detailed stock history', onTap: () => _openReport(context, 'Stock Detail Report')),
        ReportItem('Sale/Purchase By Item Category', subtitle: 'Category performance', onTap: () => _openReport(context, 'Sale/Purchase By Item Category')),
        ReportItem('Stock Summary By Item Category', subtitle: 'Category stock levels', onTap: () => _openReport(context, 'Stock summary By Item Category')),
        ReportItem('Item Batch Report', subtitle: 'Batch-wise inventory'),
        ReportItem('Item Serial Report', subtitle: 'Serial number tracking'),
        ReportItem('Item Wise Discount', subtitle: 'Discount by item', onTap: () => _openReport(context, 'Item Wise Discount')),
      ],
    ),
    ReportSection(
      title: 'Business Status',
      subtitle: 'Banking & discount overview',
      icon: Icons.trending_up_rounded,
      items: [
        ReportItem('Bank Statement', subtitle: 'Account transactions', onTap: () => _openReport(context, 'Bank Statement')),
        ReportItem('Discount Report', subtitle: 'All discounts given', onTap: () => _openReport(context, 'Discount Report')),
      ],
    ),
    ReportSection(
      title: 'Taxes',
      subtitle: 'TDS, TCS & tax summaries',
      icon: Icons.gavel_rounded,
      items: [
        ReportItem('GST Report', subtitle: 'Consolidated GST view', onTap: () => _openReport(context, 'GST Report')),
        ReportItem('GST Rate Report', subtitle: 'Rate-wise breakup', onTap: () => _openReport(context, 'GST Rate Report')),
        ReportItem('Form No. 27EQ', subtitle: 'TCS quarterly statement', onTap: () => _openReport(context, 'Form No. 27EQ')),
        ReportItem('TCS Receivable', subtitle: 'Tax collected at source', onTap: () => _openReport(context, 'TCS Receivable')),
        ReportItem('TDS Payable', subtitle: 'Tax payable at source', onTap: () => _openReport(context, 'TDS Payable')),
        ReportItem('TDS Receivable', subtitle: 'TDS to be received', onTap: () => _openReport(context, 'TDS Receivable')),
      ],
    ),
    ReportSection(
      title: 'Expense Reports',
      subtitle: 'Track your spending',
      icon: Icons.account_balance_wallet_rounded,
      items: [
        ReportItem('Expense Transaction Report', subtitle: 'All expense entries',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageExpensesScreen()))),
        ReportItem('Expense Category Report', subtitle: 'Category-wise summary',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageExpensesScreen()))),
        ReportItem('Expense Item Report', subtitle: 'Item-wise expenses',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageExpensesScreen()))),
      ],
    ),
    ReportSection(
      title: 'Sale / Purchase Orders',
      subtitle: 'Order lifecycle tracking',
      icon: Icons.shopping_cart_rounded,
      items: [
        ReportItem('Order Transaction Report', subtitle: 'All order transactions', onTap: () => _openReport(context, 'Sale/Purchase Order Transaction Report')),
        ReportItem('Order Item Report', subtitle: 'Item-wise orders', onTap: () => _openReport(context, 'Sale/Purchase Order Item Report')),
      ],
    ),
    ReportSection(
      title: 'Estimates & Returns',
      subtitle: 'Quotations, Credit & Debit Notes',
      icon: Icons.assignment_return_rounded,
      items: [
        ReportItem('Quotations / Estimates', subtitle: 'Manage & convert to tax invoice',
            onTap: () => context.push('/quotations')),
        ReportItem('Sales Returns (Credit Notes)', subtitle: 'Customer returns & stock restoration',
            onTap: () => context.push('/credit-notes')),
        ReportItem('Purchase Returns (Debit Notes)', subtitle: 'Supplier returns & inventory adjustment',
            onTap: () => context.push('/debit-notes')),
      ],
    ),
    ReportSection(
      title: 'Loan Reports',
      subtitle: 'Borrowing & lending',
      icon: Icons.account_balance_wallet_rounded,
      items: [
        ReportItem('Loan Statement', subtitle: 'Full loan ledger', onTap: () => _openReport(context, 'Loan Statement')),
      ],
    ),
  ];

  List<ReportSection> _filteredSections(List<ReportSection> sections) {
    if (_searchQuery.isEmpty) return sections;
    final query = _searchQuery.toLowerCase();
    return sections
        .map((section) => ReportSection(
      title: section.title,
      subtitle: section.subtitle,
      icon: section.icon,
      items: section.items
          .where((item) =>
      item.title.toLowerCase().contains(query) ||
          (item.subtitle?.toLowerCase().contains(query) ?? false) ||
          section.title.toLowerCase().contains(query))
          .toList(),
    ))
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _filteredSections(_sections(context));
    final totalReports = sections.fold<int>(0, (s, e) => s + e.items.length);

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: JoynColors.primary,
        titleSpacing: 15,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          // Header stats card
          if (index == 0) {
            return Column(
              children: [
                _buildAnalyticsHeroCard(context),
                _StatsHeader(
                  totalReports: totalReports,
                  totalCategories: sections.length,
                ),
              ],
            );
          }
          return _SectionCard(
            section: sections[index - 1],
            sectionNumber: index,
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsHeroCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    backgroundColor: JoynColors.surface,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primaryText),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      'Executive KPIs & Analytics',
                      style: JoynTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: JoynColors.primaryText,
                      ),
                    ),
                  ),
                  body: const OverviewScreen(),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Business Intelligence',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Live velocity graphs, star items, dead stock & profit KPIs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
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
        border: Border.all(color: JoynColors.border),
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
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: JoynColors.secondaryText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// ═══════════════════════════════════════════════════════════════
//  STATS HEADER — Joyn primary accent
// ═══════════════════════════════════════════════════════════════
class _StatsHeader extends StatelessWidget {
  final int totalReports;
  final int totalCategories;
  const _StatsHeader({
    required this.totalReports,
    required this.totalCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JoynColors.primary,
            Color.lerp(JoynColors.primary, Colors.black, 0.18) ?? JoynColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: JoynColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles using Joyn primary
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40, right: 40,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Business Reports',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$totalReports reports across $totalCategories categories',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PREMIUM SECTION CARD — Joyn Theme
// ═══════════════════════════════════════════════════════════════
class _SectionCard extends StatefulWidget {
  final ReportSection section;
  final int sectionNumber;
  const _SectionCard({
    required this.section,
    required this.sectionNumber,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.sectionNumber * 45), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───── HEADER ─────
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        JoynColors.primary.withValues(alpha: 0.07),
                        JoynColors.primary.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon badge
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              JoynColors.primary,
                              Color.lerp(JoynColors.primary, Colors.black, 0.15) ?? JoynColors.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: JoynColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          section.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    section.title,
                                    style: JoynTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: JoynColors.primary,
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Count badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: JoynColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${section.items.length}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: JoynColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (section.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                section.subtitle!,
                                style: JoynTypography.caption.copyWith(
                                  fontSize: 11.5,
                                  color: JoynColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ───── ITEMS ─────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: section.items
                        .asMap()
                        .entries
                        .map((entry) => _ReportRow(
                      item: entry.value,
                      isLast: entry.key == section.items.length - 1,
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PREMIUM REPORT ROW — Joyn Theme
// ═══════════════════════════════════════════════════════════════
class _ReportRow extends StatefulWidget {
  final ReportItem item;
  final bool isLast;
  const _ReportRow({
    required this.item,
    required this.isLast,
  });

  @override
  State<_ReportRow> createState() => _ReportRowState();
}

class _ReportRowState extends State<_ReportRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          color: _pressed
              ? JoynColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: item.isPremium
                  ? () => _openReport(context, '${item.title} (Premium)')
                  : item.onTap,
              splashColor: JoynColors.primary.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11,
                ),
                child: Row(
                  children: [
                    // Left accent bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: _pressed ? 3 : 2,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            JoynColors.primary.withValues(
                                alpha: _pressed ? 1 : 0.35),
                            JoynColors.primary.withValues(
                                alpha: _pressed ? 0.55 : 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.8,
                              color: JoynColors.primary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              style: JoynTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: JoynColors.secondaryText,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Right icon
                    if (item.isPremium)
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB39DDB), Color(0xFF9575CD)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _crownBg.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _pressed
                              ? JoynColors.primary.withValues(alpha: 0.12)
                              : JoynColors.chipBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: _pressed
                              ? JoynColors.primary
                              : JoynColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Separator
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 14),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    JoynColors.border.withValues(alpha: 0.0),
                    JoynColors.border.withValues(alpha: 0.8),
                    JoynColors.border.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}