import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bill_service.dart';
import '../models/bill_model.dart';

final billServiceProvider = Provider<BillService>((ref) => BillService());

final billsProvider = StreamProvider<List<BillModel>>((ref) {
  final service = ref.watch(billServiceProvider);
  return service.getBills();
}); 