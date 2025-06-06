import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_providers.dart';
import '../providers/transaction_providers.dart';

class BudgetPlanningScreen extends ConsumerStatefulWidget {
  const BudgetPlanningScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetPlanningScreen> createState() => _BudgetPlanningScreenState();
}

class _BudgetPlanningScreenState extends ConsumerState<BudgetPlanningScreen> {
  final _budgetController = TextEditingController();
  bool _isEditing = false;
  String? _error;
  bool _isLoading = false;

  Future<void> _saveBudget(double amount) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(budgetServiceProvider);
      final monthKey = getCurrentMonthKey();
      await service.setBudget(amount, monthKey);
      setState(() => _isEditing = false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF512DA8);
    final accentColor = const Color(0xFF9575CD);
    final budgetAsync = ref.watch(currentMonthBudgetProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    double totalExpenses = 0;
    transactionsAsync.whenData((transactions) {
      totalExpenses = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
        backgroundColor: themeColor,
      ),
      backgroundColor: const Color(0xFFF3F0FF),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            budgetAsync.when(
              data: (budget) {
                final spent = totalExpenses;
                final remaining = (budget ?? 0) - spent;
                final percent = (budget != null && budget > 0)
                    ? (spent / budget).clamp(0.0, 1.0)
                    : 0.0;
                return Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedModernBudgetProgress(
                            percent: percent,
                            spent: spent,
                            remaining: remaining,
                            budget: budget ?? 0,
                            themeColor: themeColor,
                            accentColor: accentColor,
                            exceeded: percent >= 1.0,
                            size: 220,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'This Month\'s Budget',
                            style: TextStyle(fontSize: 22, color: themeColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _budgetController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Set Budget',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          final value = double.tryParse(_budgetController.text.trim());
                                          if (value == null || value <= 0) {
                                            setState(() => _error = 'Enter a valid budget');
                                          } else {
                                            _saveBudget(value);
                                          }
                                        },
                                  child: const Text('Save'),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  budget != null ? '\$${budget.toStringAsFixed(2)}' : 'No budget set',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: themeColor,
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                      _budgetController.text = budget?.toString() ?? '';
                                    });
                                  },
                                ),
                              ],
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_error!, style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedModernBudgetProgress extends StatefulWidget {
  final double percent;
  final double spent;
  final double remaining;
  final double budget;
  final Color themeColor;
  final Color accentColor;
  final bool exceeded;
  final double size;

  const AnimatedModernBudgetProgress({
    Key? key,
    required this.percent,
    required this.spent,
    required this.remaining,
    required this.budget,
    required this.themeColor,
    required this.accentColor,
    required this.exceeded,
    this.size = 160,
  }) : super(key: key);

  @override
  State<AnimatedModernBudgetProgress> createState() => _AnimatedModernBudgetProgressState();
}

class _AnimatedModernBudgetProgressState extends State<AnimatedModernBudgetProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(begin: 0, end: widget.percent).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedModernBudgetProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percent).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ModernBudgetProgress(
          percent: _animation.value,
          spent: widget.spent,
          remaining: widget.remaining,
          budget: widget.budget,
          themeColor: widget.themeColor,
          accentColor: widget.accentColor,
          exceeded: widget.exceeded,
          size: widget.size,
        );
      },
    );
  }
}

class ModernBudgetProgress extends StatelessWidget {
  final double percent;
  final double spent;
  final double remaining;
  final double budget;
  final Color themeColor;
  final Color accentColor;
  final bool exceeded;
  final double size;

  const ModernBudgetProgress({
    Key? key,
    required this.percent,
    required this.spent,
    required this.remaining,
    required this.budget,
    required this.themeColor,
    required this.accentColor,
    required this.exceeded,
    this.size = 160,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow for depth
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.10),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Background circle
              CustomPaint(
                size: Size(size, size),
                painter: _CircleBgPainter(color: accentColor.withOpacity(0.12)),
              ),
              // Progress arc
              CustomPaint(
                size: Size(size, size),
                painter: _CircleProgressPainter(
                  percent: percent,
                  gradient: SweepGradient(
                    colors: exceeded
                        ? [Colors.red, Colors.redAccent]
                        : [themeColor, accentColor],
                    startAngle: 0.0,
                    endAngle: 3.14 * 2,
                  ),
                  exceeded: exceeded,
                ),
              ),
              // Icon and percent
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: exceeded ? Colors.red : themeColor, size: 38),
                  const SizedBox(height: 8),
                  Text(
                    '${(percent * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: exceeded ? Colors.red : themeColor,
                    ),
                  ),
                  Text('Used', style: TextStyle(color: accentColor)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text('Spent', style: TextStyle(fontSize: 15, color: accentColor, fontWeight: FontWeight.w600)),
                Text('${spent.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Column(
              children: [
                Text('Remaining', style: TextStyle(fontSize: 15, color: accentColor, fontWeight: FontWeight.w600)),
                Text('${remaining.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleBgPainter extends CustomPainter {
  final Color color;
  _CircleBgPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 7, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleProgressPainter extends CustomPainter {
  final double percent;
  final SweepGradient gradient;
  final bool exceeded;
  _CircleProgressPainter({required this.percent, required this.gradient, required this.exceeded});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final angle = 2 * 3.141592653589793 * percent.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 8),
      -3.141592653589793 / 2,
      angle,
      false,
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 