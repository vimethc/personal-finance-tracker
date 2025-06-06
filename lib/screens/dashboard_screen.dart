import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_providers.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_history_screen.dart';
import 'budget_planning_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt_rounded, color: accentColor),
            tooltip: 'Transaction History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.savings_rounded, color: accentColor),
            tooltip: 'Budget Planning',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BudgetPlanningScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.pie_chart_rounded, color: accentColor),
            tooltip: 'Monthly Report',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: transactionsAsync.when(
          data: (transactions) {
            double totalIncome = 0;
            double totalExpenses = 0;
            for (final t in transactions) {
              if (t.type == 'income') {
                totalIncome += t.amount;
              } else if (t.type == 'expense') {
                totalExpenses += t.amount;
              }
            }
            final double remainingBudget = totalIncome - totalExpenses;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _SummaryCard(
                      label: 'Income',
                      value: totalIncome,
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.green[400]!,
                    ),
                    const SizedBox(width: 16),
                    _SummaryCard(
                      label: 'Expenses',
                      value: totalExpenses,
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.red[400]!,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SummaryCard(
                  label: 'Remaining Budget',
                  value: remainingBudget,
                  icon: Icons.account_balance_wallet_rounded,
                  color: accentColor,
                  isLarge: true,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    transactions.isEmpty
                        ? 'No transactions yet. Add your first one!'
                        : 'Welcome to your personal finance dashboard!',
                    style: TextStyle(fontSize: 18, color: themeColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isLarge;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLarge = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: isLarge ? 2 : 1,
      child: Container(
        margin: isLarge ? null : const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isLarge ? 40 : 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isLarge ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 