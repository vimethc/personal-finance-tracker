import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/budget_service.dart';
import 'package:intl/intl.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

String getCurrentMonthKey() {
  final now = DateTime.now();
  return DateFormat('yyyy-MM').format(now);
}

final currentMonthBudgetProvider = StreamProvider<double?>((ref) {
  final service = ref.watch(budgetServiceProvider);
  final monthKey = getCurrentMonthKey();
  return service.getBudget(monthKey);
}); 