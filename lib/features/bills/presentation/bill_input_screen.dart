import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/shared/utils/currency_input_formatter.dart';
import 'package:intl/intl.dart';

class BillInputScreen extends ConsumerStatefulWidget {
  final RecurringBill? billToEdit;

  const BillInputScreen({super.key, this.billToEdit});

  @override
  ConsumerState<BillInputScreen> createState() => _BillInputScreenState();
}

class _BillInputScreenState extends ConsumerState<BillInputScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reminderDaysController = TextEditingController(text: '3');

  late DateTime _nextDueDate;
  BillFrequency _frequency = BillFrequency.monthly;
  ExpenseCategory _category = ExpenseCategory.bills;
  PaymentMethod _paymentMethod = PaymentMethod.bank;
  bool _isActive = true;
  bool _hasPickedDueDate = false;

  @override
  void initState() {
    super.initState();
    _nextDueDate = _calculateDueDate(DateTime.now(), _frequency);
    if (widget.billToEdit != null) {
      final bill = widget.billToEdit!;
      _nameController.text = bill.name;
      _amountController.text = bill.amount.toStringAsFixed(0);
      _nextDueDate = bill.nextDueDate;
      _frequency = bill.frequency;
      _category = bill.category;
      _paymentMethod = bill.paymentMethod;
      _isActive = bill.isActive;
      _reminderDaysController.text = bill.reminderDaysBefore.toString();
      _hasPickedDueDate = true;
    }
  }

  DateTime _calculateDueDate(DateTime base, BillFrequency freq) {
    int monthsToAdd = 1;
    switch (freq) {
      case BillFrequency.monthly:
        monthsToAdd = 1;
        break;
      case BillFrequency.quarterly:
        monthsToAdd = 3;
        break;
      case BillFrequency.annual:
        monthsToAdd = 12;
        break;
    }
    final totalMonths = base.month + monthsToAdd;
    final targetYear = base.year + ((totalMonths - 1) ~/ 12);
    final targetMonth = ((totalMonths - 1) % 12) + 1;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    return DateTime(
      targetYear,
      targetMonth,
      base.day > lastDayOfMonth ? lastDayOfMonth : base.day,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _reminderDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billToEdit == null ? 'Thêm hóa đơn' : 'Sửa hóa đơn'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hóa đơn',
                  hintText: 'VD: Tiền điện, Netflix, Spotify',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ngày đến hạn'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_nextDueDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillFrequency>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Tần suất'),
                items: BillFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(_getFrequencyLabel(f)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _frequency = v;
                      if (!_hasPickedDueDate) {
                        _nextDueDate = _calculateDueDate(
                          DateTime.now(),
                          _frequency,
                        );
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: ExpenseCategory.values
                    .where((c) => c != ExpenseCategory.income)
                    .map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(_getCategoryLabel(c)),
                      );
                    })
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Phương thức thanh toán',
                ),
                items: PaymentMethod.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      p == PaymentMethod.cash ? 'Tiền mặt' : 'Ngân hàng',
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reminderDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nhắc trước (ngày)',
                  hintText: '3',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _nextDueDate = picked;
        _hasPickedDueDate = true;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountStr) ?? 0;
    final reminderDays = int.tryParse(_reminderDaysController.text) ?? 3;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final bill = RecurringBill()
      ..name = name
      ..amount = amount
      ..nextDueDate = _nextDueDate
      ..frequency = _frequency
      ..category = _category
      ..paymentMethod = _paymentMethod
      ..isActive = _isActive
      ..reminderDaysBefore = reminderDays
      ..createdAt = DateTime.now();

    if (widget.billToEdit != null) {
      bill.id = widget.billToEdit!.id;
      bill.lastPaidDate = widget.billToEdit!.lastPaidDate;
      bill.createdAt = widget.billToEdit!.createdAt;
    }

    final service = ref.read(isarServiceProvider);
    await service.saveRecurringBill(bill);

    ref.invalidate(recurringBillsProvider);
    ref.invalidate(upcomingBillsProvider);

    if (mounted) context.pop();
  }

  String _getFrequencyLabel(BillFrequency f) {
    switch (f) {
      case BillFrequency.monthly:
        return 'Hàng tháng';
      case BillFrequency.quarterly:
        return 'Hàng quý';
      case BillFrequency.annual:
        return 'Hàng năm';
    }
  }

  String _getCategoryLabel(ExpenseCategory c) {
    switch (c) {
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
      case ExpenseCategory.other:
        return 'Khác';
    }
  }
}
