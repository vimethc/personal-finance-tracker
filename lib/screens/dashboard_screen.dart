import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_providers.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_history_screen.dart';
import 'budget_planning_screen.dart';
import 'reports_screen.dart';
import 'bills_screen.dart';
import 'user_profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // Start the animation when the widget is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.account_circle_rounded, color: accentColor),
            tooltip: 'User Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
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
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Income',
                          value: totalIncome,
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.green[400]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Expenses',
                          value: totalExpenses,
                          icon: Icons.arrow_upward_rounded,
                          color: Colors.red[400]!,
                        ),
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
                          ? 'Add your first transaction to see summary!'
                          : 'Welcome back!',
                      style: TextStyle(fontSize: 18, color: themeColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (transactions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: transactions.length > 5 ? 5 : transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: Icon(
                                transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                                color: transaction.type == 'income' ? Colors.green[400] : Colors.red[400],
                              ),
                              title: Text(transaction.description),
                              trailing: Text(
                                '\$${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.type == 'income' ? Colors.green[400] : Colors.red[400],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ),
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