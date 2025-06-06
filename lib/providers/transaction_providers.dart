import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import './budget_providers.dart';
import 'package:intl/intl.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) => TransactionService());

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactions();
});

// Provider for the currently selected month for category summary
final selectedCategoryMonthProvider = StateProvider<String>((ref) {
  // Default to the current month
  return DateFormat('yyyy-MM').format(DateTime.now());
});

final monthlyExpenseSummaryProvider = StreamProvider<Map<String, double>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  // Watch the selected month provider
  final selectedMonth = ref.watch(selectedCategoryMonthProvider);
  return service.getMonthlyExpenseSummaryByCategory(selectedMonth);
});

final monthlySpendingTrendsProvider = StreamProvider<Map<String, double>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return service.getSpendingTrendsMonthly();
}); 