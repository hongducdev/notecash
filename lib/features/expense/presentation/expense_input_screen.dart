import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/expense_parser_service.dart';

class ExpenseInputScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;
  const ExpenseInputScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends ConsumerState<ExpenseInputScreen> {
  final _controller = TextEditingController();
  final _parser = ExpenseParserService();
  Expense? _previewExpense;
  bool _isIncomeSelection = false;
  PaymentMethod _paymentMethodSelection = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      _previewExpense = widget.expenseToEdit;
      _isIncomeSelection = widget.expenseToEdit!.isIncome;
      _paymentMethodSelection = widget.expenseToEdit!.paymentMethod;
      // Pre-fill controller with a string that would parse to this expense
      final amountStr = widget.expenseToEdit!.amount.toInt().toString();
      _controller.text = "${widget.expenseToEdit!.note} $amountStr";
    }
    _controller.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (_controller.text.isEmpty) {
      setState(() => _previewExpense = null);
      return;
    }
    setState(() {
      _previewExpense = _parser.parse(_controller.text)
        ..isIncome = _isIncomeSelection
        ..paymentMethod = _paymentMethodSelection;

      if (_previewExpense!.isIncome) {
        _previewExpense!.category = ExpenseCategory.income;
      }
    });
  }

  Future<void> _save() async {
    if (_previewExpense == null || _previewExpense!.amount == 0) return;

    final service = ref.read(isarServiceProvider);

    if (widget.expenseToEdit != null) {
      _previewExpense!.id = widget.expenseToEdit!.id;
      _previewExpense!.createdAt = widget.expenseToEdit!.createdAt;
    }

    await service.saveExpense(_previewExpense!);

    final savedDate = DateTime(
      _previewExpense!.createdAt.year,
      _previewExpense!.createdAt.month,
      _previewExpense!.createdAt.day,
    );
    final monthKey = DateTime(savedDate.year, savedDate.month);

    final selectedDate = ref.read(selectedDateProvider);
    final selectedDateNormalized = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final selectedMonthKey = DateTime(selectedDate.year, selectedDate.month);

    ref.invalidate(todayExpensesProvider);
    ref.invalidate(allExpensesProvider);
    ref.invalidate(dateExpensesProvider(savedDate));
    ref.invalidate(monthExpensesProvider(monthKey));
    ref.invalidate(cumulativeBalanceProvider(savedDate));

    if (savedDate != selectedDateNormalized) {
      ref.invalidate(dateExpensesProvider(selectedDateNormalized));
      ref.invalidate(cumulativeBalanceProvider(selectedDateNormalized));
    }

    if (monthKey != selectedMonthKey) {
      ref.invalidate(monthExpensesProvider(selectedMonthKey));
    }

    ref.invalidate(cashBalanceProvider);
    ref.invalidate(bankBalanceProvider);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/scan-receipt'),
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Quét hóa đơn',
          ),
          TextButton(
            onPressed: _previewExpense != null && _previewExpense!.amount > 0
                ? _save
                : null,
            child: Text(
              'Lưu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _previewExpense != null && _previewExpense!.amount > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập chi tiêu',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ví dụ: "cf 35k" hoặc "grab 120k"',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  hintText: 'Bạn đã chi gì?',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Chi tiêu'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Thu nhập'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_isIncomeSelection},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isIncomeSelection = newSelection.first;
                    if (_previewExpense != null) {
                      _previewExpense!.isIncome = _isIncomeSelection;
                      if (_previewExpense!.isIncome) {
                        _previewExpense!.category = ExpenseCategory.income;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Tiền mặt'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.bank,
                    label: Text('Ngân hàng'),
                    icon: Icon(Icons.account_balance_outlined),
                  ),
                ],
                selected: {_paymentMethodSelection},
                onSelectionChanged: (Set<PaymentMethod> newSelection) {
                  setState(() {
                    _paymentMethodSelection = newSelection.first;
                    if (_previewExpense != null) {
                      _previewExpense!.paymentMethod = _paymentMethodSelection;
                    }
                  });
                },
              ),
              const SizedBox(
                height: 100,
              ), // Khoảng trống để không bị Preview Card đè
              if (_previewExpense != null) _buildPreviewCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(_previewExpense!.category),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _previewExpense!.note.isEmpty
                      ? 'Ghi chú'
                      : _previewExpense!.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _getCategoryName(_previewExpense!.category),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_previewExpense!.isIncome ? "+" : "-"}${currencyFormat.format(_previewExpense!.amount)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _previewExpense!.isIncome ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodAndDrink:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_outlined;
      case ExpenseCategory.income:
        return Icons.attach_money_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.foodAndDrink:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.bills:
        return 'Hóa đơn';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.income:
        return 'Thu nhập';
      default:
        return 'Khác';
    }
  }
}
