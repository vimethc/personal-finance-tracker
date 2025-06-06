import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bill_providers.dart';
import 'add_bill_screen.dart'; // We will create this screen next
import 'package:intl/intl.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        backgroundColor: themeColor,
      ),
      backgroundColor: const Color(0xFFF3F0FF),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(child: Text('No bills added yet. Tap the + to add your first bill!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        bill.isPaid ? Icons.check_circle_outline : Icons.payments_outlined,
                        color: bill.isPaid ? Colors.green : Colors.redAccent,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.description,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: themeColor,
                                decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '\$${bill.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: bill.isPaid ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TODO: Add onTap for editing/marking as paid
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                const SizedBox(height: 16),
                Text(
                  'Failed to load bills.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
        },
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 