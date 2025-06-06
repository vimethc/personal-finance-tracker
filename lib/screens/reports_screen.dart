import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_providers.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final expenseSummaryAsync = ref.watch(monthlyExpenseSummaryProvider);
    final spendingTrendsAsync = ref.watch(monthlySpendingTrendsProvider);
    final selectedMonth = ref.watch(selectedCategoryMonthProvider);
    final selectedMonthNotifier = ref.read(selectedCategoryMonthProvider.notifier);

    // Function to change the month
    void changeMonth(int monthsToAdd) {
      final current = DateFormat('yyyy-MM').parse(selectedMonth);
      final newMonth = DateTime(current.year, current.month + monthsToAdd);
      selectedMonthNotifier.state = DateFormat('yyyy-MM').format(newMonth);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Spending Report'),
        backgroundColor: themeColor,
      ),
      backgroundColor: const Color(0xFFF3F0FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: themeColor, size: 20),
                    onPressed: () => changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(selectedMonth)),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: themeColor, size: 20),
                    onPressed: () => changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly Spending by Category Pie Chart Section
              Text(
                'Spending by Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              expenseSummaryAsync.when(
                data: (summary) {
                  if (summary.isEmpty) {
                    return Center(child: Text('No expense data for ${DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(selectedMonth))}.'));
                  }

                  // Prepare data for the Pie Chart
                  final List<PieChartSectionData> sections = [];
                  double total = summary.values.fold(0, (sum, item) => sum + item);
                  int i = 0;
                  final colors = [
                    Colors.blue, Colors.green, Colors.orange, Colors.purple,
                    Colors.teal, Colors.pink, Colors.brown, Colors.indigo,
                  ]; // Example colors

                  summary.forEach((category, amount) {
                    final double percentage = (amount / total) * 100;
                    sections.add(
                      PieChartSectionData(
                        value: amount,
                        color: colors[i % colors.length],
                        title: '\$${amount.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: _Badge(category, color: colors[i % colors.length]),
                        badgePositionPercentageOffset: 1.0,
                      ),
                    );
                    i++;
                  });

                  return Column(
                    children: [
                      SizedBox( // Wrap PieChart in SizedBox with specific height
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(enabled: true,
                              touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  return;
                                }
                                final touchedSection = pieTouchResponse.touchedSection!;
                                final categoryIndex = touchedSection.touchedSectionIndex;
                                if (categoryIndex < 0 || categoryIndex >= summary.keys.length) {
                                  return;
                                }
                                final category = summary.keys.elementAt(categoryIndex);
                                
                                // Navigate to TransactionHistoryScreen with filters
                                Navigator.pushNamed(context, '/transactionHistory',
                                  arguments: {
                                    'month': selectedMonth,
                                    'category': category,
                                  },
                                );
                              },
                            ),
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: summary.keys.map((category) {
                          final index = summary.keys.toList().indexOf(category);
                          return _CategoryLegend(
                            color: colors[index % colors.length],
                            text: category,
                          );
                        }).toList(),
                      )
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading category summary: $e')),
              ),

              const SizedBox(height: 40),

              // Monthly Spending Trends Line Chart Section
              Text(
                'Spending Trends (Last 12 Months)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              spendingTrendsAsync.when(
                data: (monthlyTotals) {
                  if (monthlyTotals.isEmpty) {
                    return const Center(child: Text('No expense data for the last 12 months.'));
                  }

                  // Sort months and prepare data for Line Chart
                  final sortedMonths = monthlyTotals.keys.toList()..sort();
                  final List<FlSpot> spots = [];
                  final Map<int, String> monthIndexMap = {};

                  for (var i = 0; i < sortedMonths.length; i++) {
                    final monthKey = sortedMonths[i];
                    final year = int.parse(monthKey.split('-')[0]);
                    final month = int.parse(monthKey.split('-')[1]);
                    final amount = monthlyTotals[monthKey] ?? 0.0;
                    spots.add(FlSpot(i.toDouble(), amount));
                    monthIndexMap[i] = DateFormat('MMM yy').format(DateTime(year, month));
                  }

                  double maxY = spots.isNotEmpty ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) : 100;
                  if (maxY < 100) maxY = 100; // Ensure maxY is at least 100

                  return SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < sortedMonths.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(monthIndexMap[index]!, style: const TextStyle(fontSize: 10)),
                                  );
                                } else {
                                  return const Text('');
                                }
                              },
                              interval: 1.0,
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10)),
                              interval: maxY / 4, // Adjust interval based on max value
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xff37434d), width: 1),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 2,
                            color: accentColor,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: accentColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: (sortedMonths.length > 0 ? sortedMonths.length - 1 : 0).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((spot) {
                                final month = monthIndexMap[spot.x.toInt()];
                                return LineTooltipItem(
                                  '\$${spot.y.toStringAsFixed(2)}\n${month ?? '-'}',
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              }).toList();
                            },
                            getTooltipColor: (LineBarSpot touchedSpot) {
                              // Return the background color for the tooltip
                              return Colors.blueAccent;
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading spending trends: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final Color color;
  final String text;

  const _CategoryLegend({
    Key? key,
    required this.color,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}