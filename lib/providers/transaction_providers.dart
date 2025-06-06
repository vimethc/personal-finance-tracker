import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) => TransactionService());

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactions();
}); 