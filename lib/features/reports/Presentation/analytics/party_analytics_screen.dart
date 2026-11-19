import 'package:flutter/material.dart';
import '../../../../core/theme/joyn_colors.dart';
import '../../../../core/theme/joyn_typography.dart';
import '../../models/kpi_analytics_models.dart';

class PartyAnalyticsScreen extends StatefulWidget {
  final List<PartySalesMetric> topCustomers;
  final List<PartySalesMetric> topSuppliers;
  final Map<String, double> creditAging;
  final double totalReceivables;
  final String dateRangeLabel;

  const PartyAnalyticsScreen({
    super.key,
    required this.topCustomers,
    required this.topSuppliers,
    required this.creditAging,
    required this.totalReceivables,
    required this.dateRangeLabel,
  });

  @override
  State<PartyAnalyticsScreen> createState() => _PartyAnalyticsScreenState();
}

class _PartyAnalyticsScreenState extends State<PartyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = widget.topCustomers.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.partyCode.toLowerCase().contains(q) ||
          p.contactNumber.contains(q);
    }).toList();

    final filteredSuppliers = widget.topSuppliers.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.partyCode.toLowerCase().contains(q) ||
          p.contactNumber.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: JoynColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Party & Credit Analytics',
              style: JoynTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: JoynColors.primaryText,
              ),
            ),
            Text(
              'Period: ${widget.dateRangeLabel}',
              style: JoynTypography.caption.copyWith(
                fontSize: 11,
                color: JoynColors.secondaryText,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: JoynColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: JoynColors.primary,
              unselectedLabelColor: JoynColors.secondaryText,
              labelStyle: JoynTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              indicatorColor: JoynColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text('Customers (${widget.topCustomers.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text('Suppliers (${widget.topSuppliers.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 16),
                      SizedBox(width: 4),
                      Text('Credit Aging'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search box (shown on Customers & Suppliers tabs)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 2) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: JoynColors.surface,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by party name, PRT-code or phone...',
                    hintStyle: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: JoynColors.secondaryText),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: JoynColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JoynColors.primary, width: 1.5),
                    ),
                  ),
                ),
              );
            },
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPartyList(filteredCustomers, isCustomer: true),
                _buildPartyList(filteredSuppliers, isCustomer: false),
                _buildCreditAgingView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyList(List<PartySalesMetric> parties, {required bool isCustomer}) {
    if (parties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 54, color: JoynColors.secondaryText.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              isCustomer ? 'No customer transactions found' : 'No supplier purchases found',
              style: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: parties.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final party = parties[index];
        final rank = index + 1;
        final rankColor = rank == 1
            ? const Color(0xFFEAB308)
            : rank == 2
                ? const Color(0xFF94A3B8)
                : rank == 3
                    ? const Color(0xFFB45309)
                    : JoynColors.secondaryText;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JoynColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JoynColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: JoynTypography.caption.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: JoynTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: JoynColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (party.partyCode.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: JoynColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              party.partyCode,
                              style: JoynTypography.caption.copyWith(
                                color: JoynColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${party.orderCount} ${isCustomer ? 'Invoices' : 'Orders'}',
                          style: JoynTypography.caption.copyWith(
                            color: JoynColors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${party.totalVolume.toStringAsFixed(2)}',
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isCustomer ? const Color(0xFF16A34A) : JoynColors.primary,
                    ),
                  ),
                  if (party.balanceDue > 0)
                    Text(
                      'Due: ₹${party.balanceDue.toStringAsFixed(0)}',
                      style: JoynTypography.caption.copyWith(
                        color: JoynColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditAgingView() {
    final tiers = [
      {
        'label': '0 - 15 Days',
        'sub': 'Recently generated invoices (Healthy)',
        'amount': widget.creditAging['0 - 15 Days'] ?? 0.0,
        'color': const Color(0xFF10B981),
        'icon': Icons.sentiment_very_satisfied_rounded,
      },
      {
        'label': '16 - 30 Days',
        'sub': 'Standard payment terms (Normal)',
        'amount': widget.creditAging['16 - 30 Days'] ?? 0.0,
        'color': const Color(0xFF3B82F6),
        'icon': Icons.sentiment_satisfied_rounded,
      },
      {
        'label': '31 - 60 Days',
        'sub': 'Overdue - Follow-up needed',
        'amount': widget.creditAging['31 - 60 Days'] ?? 0.0,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.sentiment_neutral_rounded,
      },
      {
        'label': '60+ Days',
        'sub': 'Critical Risk - Urgent recovery required',
        'amount': widget.creditAging['60+ Days'] ?? 0.0,
        'color': const Color(0xFFEF4444),
        'icon': Icons.warning_rounded,
      },
    ];

    final totalAging = tiers.fold(0.0, (sum, t) => sum + (t['amount'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Receivables Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [JoynColors.primary, JoynColors.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: JoynColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL MARKET RECEIVABLES',
                      style: JoynTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "You'll Get",
                        style: JoynTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.totalReceivables.toStringAsFixed(2)}',
                  style: JoynTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Outstanding payments pending from all customers and debtors',
                  style: JoynTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Credit Aging Risk Breakdown',
            style: JoynTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: JoynColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          // Tier cards
          ...tiers.map((tier) {
            final amt = tier['amount'] as double;
            final color = tier['color'] as Color;
            final icon = tier['icon'] as IconData;
            final share = totalAging > 0 ? (amt / totalAging) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JoynColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JoynColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier['label'] as String,
                              style: JoynTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: JoynColors.primaryText,
                              ),
                            ),
                            Text(
                              tier['sub'] as String,
                              style: JoynTypography.caption.copyWith(
                                color: JoynColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${amt.toStringAsFixed(2)}',
                        style: JoynTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 6,
                      backgroundColor: JoynColors.border.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

