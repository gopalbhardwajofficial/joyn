import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/api_service.dart';
import '../../notifications/models/notification_model.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isDispatchingBatch = false;

  List<OverdueDebtor> _debtors = [];
  List<PaymentReminderLog> _history = [];
  double _totalOverdue = 0.0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDebtors(),
      _loadHistory(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadDebtors() async {
    try {
      final res = await ApiService.getOverdueDebtors();
      if (res['success'] == true) {
        final list = (res['debtors'] as List<dynamic>? ?? [])
            .map((item) => OverdueDebtor.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _debtors = list;
          _totalOverdue = double.tryParse(res['totalOverdueAmount']?.toString() ?? '0') ?? 0.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiService.getRemindersHistory(limit: 50);
      if (res['success'] == true) {
        final list = (res['history'] as List<dynamic>? ?? [])
            .map((item) => PaymentReminderLog.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _history = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _openSendReminderDialog(OverdueDebtor debtor) async {
    final noteController = TextEditingController();
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF4338CA), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Payment Reminder',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              debtor.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Balance Due:',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${debtor.balanceDue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Optional Custom Note / Deadline:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Kindly settle before Friday to avoid account hold.',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.chat_rounded, size: 20),
                      label: Text(
                        isSending ? 'Preparing Reminder...' : 'Dispatch via WhatsApp / Share',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      onPressed: isSending
                          ? null
                          : () async {
                              final navigator = Navigator.of(ctx);
                              final messenger = ScaffoldMessenger.of(context);
                              setModalState(() => isSending = true);
                              final res = await ApiService.sendPaymentReminder(
                                partyId: debtor.id,
                                channel: 'WHATSAPP',
                                customNote: noteController.text.trim(),
                              );
                              setModalState(() => isSending = false);

                              navigator.pop();

                              if (res['success'] == true) {
                                final text = res['messageText'] ?? '';
                                final upi = res['paymentLink'] ?? '';

                                // Share directly to WhatsApp / System Share Sheet
                                await Share.share(text, subject: 'Payment Due Reminder');

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Payment reminder dispatched for ${debtor.name}'),
                                    backgroundColor: const Color(0xFF10B981),
                                    action: upi.isNotEmpty
                                        ? SnackBarAction(
                                            label: 'Copy UPI',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: upi));
                                            },
                                          )
                                        : null,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                if (mounted) {
                                  _loadData();
                                }
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Failed to prepare reminder.'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _triggerBatchDispatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batch Automated Reminders', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Queue payment reminders for all ${_debtors.length} overdue debtors (Total ₹${_totalOverdue.toStringAsFixed(2)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDispatchingBatch = true);
    final res = await ApiService.triggerBatchAutomatedReminders();
    setState(() => _isDispatchingBatch = false);

    if (!mounted) return;
    if (res['success'] == true) {
      final count = res['dispatchedCount'] ?? 0;
      final amt = res['totalRemindedAmount'] ?? 0.0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully queued $count reminders for ₹${amt.toStringAsFixed(2)}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Batch dispatch failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<OverdueDebtor> get _filteredDebtors {
    if (_searchQuery.trim().isEmpty) return _debtors;
    final q = _searchQuery.toLowerCase();
    return _debtors.where((d) {
      return d.name.toLowerCase().contains(q) || d.contactNumber.contains(q) || d.city.toLowerCase().contains(q);
    }).toList();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDebtors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment Reminders',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4338CA),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4338CA),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Overdue Debtors (${_debtors.length})'),
            Tab(text: 'Reminder History (${_history.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4338CA),
                strokeWidth: 2.5,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Overdue Debtors
                RefreshIndicator(
                  color: const Color(0xFF4338CA),
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Overview Header Banner
                      _buildOverviewBanner(),
                      const SizedBox(height: 16),

                      // Search input
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search debtors by name, phone...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4338CA)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Debtor cards
                      if (filtered.isEmpty)
                        _buildEmptyDebtors()
                      else
                        ...filtered.map((d) => _buildDebtorCard(d)),
                    ],
                  ),
                ),

                // Tab 2: Reminders History
                RefreshIndicator(
                  color: const Color(0xFF4338CA),
                  onRefresh: _loadData,
                  child: _history.isEmpty
                      ? _buildEmptyHistory()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final log = _history[i];
                            return _buildHistoryCard(log);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
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
              const Text(
                'TOTAL RECEIVABLES OVERDUE',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_debtors.length} Debtors',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_totalOverdue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4338CA),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: _isDispatchingBatch
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4338CA)),
                    )
                  : const Icon(Icons.flash_on_rounded, size: 18),
              label: Text(
                _isDispatchingBatch ? 'Queueing Batch...' : 'Queue Reminders for All Debtors',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: _isDispatchingBatch || _debtors.isEmpty ? null : _triggerBatchDispatch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorCard(OverdueDebtor debtor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  debtor.name.isNotEmpty ? debtor.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${debtor.contactNumber.isNotEmpty ? debtor.contactNumber : 'No contact'} ${debtor.city.isNotEmpty ? '• ${debtor.city}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${debtor.balanceDue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const Text(
                    'Overdue Due',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    debtor.lastReminderSent != null
                        ? 'Sent: ${DateFormat('dd MMM, hh:mm a').format(debtor.lastReminderSent!)}'
                        : 'No reminder sent yet',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text(
                  'Send Reminder',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _openSendReminderDialog(debtor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(PaymentReminderLog log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: log.channel == 'WHATSAPP'
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              log.channel == 'WHATSAPP' ? Icons.chat_rounded : Icons.sms_outlined,
              color: log.channel == 'WHATSAPP'
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF4338CA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.partyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.reminderType} • ${_formatDateTime(log.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${log.amountDue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: log.status == 'SENT'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: log.status == 'SENT'
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDebtors() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Zero Overdue Debtors!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'All customers have settled their balances in full.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No Reminders Dispatched Yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sent reminders will appear here for audit tracking.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

