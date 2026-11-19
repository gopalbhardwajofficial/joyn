import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../models/gst_report_models.dart';

class ManageExpensesScreen extends StatefulWidget {
  const ManageExpensesScreen({super.key});

  @override
  State<ManageExpensesScreen> createState() => _ManageExpensesScreenState();
}

class _ManageExpensesScreenState extends State<ManageExpensesScreen> {
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  double _totalExpenses = 0.0;
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'Rent & Utilities',
    'Salaries & Wages',
    'Office Supplies',
    'Transport & Fuel',
    'Marketing & Ads',
    'Maintenance',
    'General Expense'
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final cat = _selectedCategory == 'ALL' ? null : _selectedCategory;
      final res = await ApiService.getExpenses(category: cat, limit: 100);
      if (res['success'] == true) {
        final list = (res['expenses'] as List<dynamic>? ?? [])
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _expenses = list;
          _totalExpenses = (res['totalAmount'] as num?)?.toDouble() ??
              list.fold(0.0, (sum, item) => sum + item.amount);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final idx = _expenses.indexOf(expense);
    setState(() {
      _expenses.removeAt(idx);
      _totalExpenses -= expense.amount;
    });
    try {
      await ApiService.deleteExpense(expense.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _openAddExpenseModal() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'Rent & Utilities';
    String paymentMode = 'CASH';
    String expenseType = 'Indirect';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
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
                  const Text(
                    'Record New Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹) *',
                      hintText: 'e.g. 5000',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF4338CA)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Expense Category',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories.where((c) => c != 'ALL').map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode & Date Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentMode,
                          decoration: InputDecoration(
                            labelText: 'Payment Mode',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CASH', child: Text('Cash', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => paymentMode = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) setModalState(() => selectedDate = d);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expense Date',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Remarks',
                      hintText: 'e.g. Paid to vendor for supplies',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid expense amount.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                        final res = await ApiService.createExpense(
                          category: category,
                          amount: amt,
                          type: expenseType,
                          paymentMode: paymentMode,
                          notes: notesController.text.trim(),
                          expenseDate: dateStr,
                        );

                        if (res['success'] == true) {
                          _loadExpenses();
                        }
                      },
                      child: const Text('Record Expense', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  @override
  Widget build(BuildContext context) {
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
          'Operating Expenses',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openAddExpenseModal,
      ),
      body: Column(
        children: [
          // Total Overview Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL RECORDED EXPENSES',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_totalExpenses.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_expenses.length} Entries',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selectedColor: const Color(0xFF4338CA),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                      _loadExpenses();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Expenses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA), strokeWidth: 2.5))
                : RefreshIndicator(
                    color: const Color(0xFF4338CA),
                    onRefresh: _loadExpenses,
                    child: _expenses.isEmpty
                        ? _buildEmptyExpenses()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: _expenses.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final exp = _expenses[i];
                              return _buildExpenseCard(exp);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel exp) {
    return Dismissible(
      key: Key(exp.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => _deleteExpense(exp),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4338CA), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.category,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exp.expenseDate} • ${exp.paymentMode} ${exp.notes.isNotEmpty ? '• ${exp.notes}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '₹${exp.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_outlined, size: 36, color: Color(0xFF4338CA)),
          ),
          const SizedBox(height: 12),
          const Text('No Expenses Recorded', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Tap "+ Add Expense" to track your store costs.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
