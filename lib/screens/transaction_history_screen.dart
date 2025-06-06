import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_providers.dart';
import '../models/transaction_model.dart';
import 'edit_transaction_screen.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _typeFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final month = args['month'] as String?;
        final category = args['category'] as String?;

        if (month != null) {
          try {
            final date = DateFormat('yyyy-MM').parse(month);
            _startDate = DateTime(date.year, date.month, 1);
            _endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
          } catch (e) {
            print('Error parsing month argument: $e');
          }
        }

        if (category != null) {
          _categoryFilter = category;
          _typeFilter = 'expense';
        }

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: themeColor,
      ),
      backgroundColor: const Color(0xFFF3F0FF),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _typeFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  ],
                  onChanged: (val) => setState(() {
                    _typeFilter = val ?? 'all';
                    _categoryFilter = null;
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: _startDate != null && _endDate != null
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                          _categoryFilter = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: accentColor, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_startDate == null || _endDate == null
                                ? 'Date Range'
                                : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')} to ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_startDate != null && _endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _startDate = null;
                                _endDate = null;
                                _categoryFilter = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = transactions.where((t) {
                  final typeMatch = _typeFilter == 'all' || t.type == _typeFilter;
                  final dateMatch = (_startDate == null || !t.date.isBefore(_startDate!)) &&
                      (_endDate == null || !t.date.isAfter(_endDate!));
                  final categoryMatch = _categoryFilter == null || t.category == _categoryFilter;
                  return typeMatch && dateMatch && categoryMatch;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.type == 'income' ? Colors.green[400] : Colors.red[400],
                          child: Icon(
                            t.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          t.category,
                          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(color: accentColor, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          (t.type == 'income' ? '+' : '-') + '\$${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: t.type == 'income' ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditTransactionScreen(transaction: t),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
} 