import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/dashboard/presentation/widgets/expense_tile.dart';

class ExpenseGroupTile extends ConsumerStatefulWidget {
  final Expense headerExpense;
  final List<Expense> childExpenses;

  const ExpenseGroupTile({
    super.key,
    required this.headerExpense,
    required this.childExpenses,
  });

  @override
  ConsumerState<ExpenseGroupTile> createState() => _ExpenseGroupTileState();
}

class _ExpenseGroupTileState extends ConsumerState<ExpenseGroupTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.headerExpense.note,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.childExpenses.length} sản phẩm',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${currencyFormat.format(widget.headerExpense.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Column(
                children: widget.childExpenses
                    .map((expense) => ExpenseTile(expense: expense))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
