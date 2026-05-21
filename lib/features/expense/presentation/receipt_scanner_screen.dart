import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/services/ocr_service.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isScanning = false;
  ReceiptScanResult? _scanResult;
  File? _imageFile;
  PaymentMethod _paymentMethodSelection = PaymentMethod.cash;
  _ReceiptSaveMode _saveMode = _ReceiptSaveMode.multiple;
  List<_ReceiptItemDraft> _itemDrafts = <_ReceiptItemDraft>[];
  String _merchantDraft = '';
  ExpenseCategory _singleCategoryDraft = ExpenseCategory.other;
  double _singleTotalDraft = 0;

  void _addItemDraft() {
    setState(() {
      _itemDrafts = [
        ..._itemDrafts,
        _ReceiptItemDraft(
          name: '',
          amount: 0,
          category: ExpenseCategory.other,
          confidence: 0,
        ),
      ];
      _saveMode = _ReceiptSaveMode.multiple;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isScanning = true;
        _scanResult = null;
        _itemDrafts = <_ReceiptItemDraft>[];
      });

      try {
        final result = await _ocrService.scanReceiptDetailed(_imageFile!);
        setState(() {
          _scanResult = result;
          _merchantDraft = result?.merchant ?? '';
          _singleTotalDraft = result?.total ?? 0;
          _singleCategoryDraft = result == null
              ? ExpenseCategory.other
              : _detectCategoryForReceipt(result);
          _itemDrafts = (result?.items ?? const <ReceiptItem>[])
              .map(
                (e) => _ReceiptItemDraft(
                  name: e.name,
                  amount: e.amount,
                  category: e.category,
                  confidence: e.confidence,
                ),
              )
              .toList();
          _saveMode = _ReceiptSaveMode.single;
          _isScanning = false;
        });
      } catch (e) {
        setState(() => _isScanning = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi quét hóa đơn: $e')));
        }
      }
    }
  }

  Future<void> _save() async {
    final service = ref.read(isarServiceProvider);

    final now = DateTime.now();
    final savedDate = DateTime(now.year, now.month, now.day);

    if (_saveMode == _ReceiptSaveMode.single) {
      if (_singleTotalDraft <= 0) return;
      final expense = Expense()
        ..note = _merchantDraft.trim().isEmpty
            ? 'Hóa đơn'
            : _merchantDraft.trim()
        ..amount = _singleTotalDraft
        ..category = _singleCategoryDraft
        ..isIncome = false
        ..paymentMethod = _paymentMethodSelection
        ..createdAt = now;

      await service.saveExpense(expense);
    } else {
      final items = _itemDrafts
          .where((e) => !e.deleted)
          .where((e) => e.amount > 0 && e.name.trim().isNotEmpty)
          .toList(growable: false);
      if (items.isEmpty) return;

      final expenses = items
          .map(
            (e) => Expense()
              ..note = e.name.trim()
              ..amount = e.amount
              ..category = e.category
              ..isIncome = false
              ..paymentMethod = _paymentMethodSelection
              ..createdAt = now,
          )
          .toList(growable: false);

      await service.saveExpenses(expenses);
    }

    final monthKey = DateTime(savedDate.year, savedDate.month);

    ref.invalidate(todayExpensesProvider);
    ref.invalidate(dateExpensesProvider(savedDate));
    ref.invalidate(monthExpensesProvider(monthKey));
    ref.invalidate(cumulativeBalanceProvider(savedDate));
    ref.invalidate(cashBalanceProvider);
    ref.invalidate(bankBalanceProvider);

    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Quét hóa đơn',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (_scanResult != null)
            TextButton(
              onPressed: _save,
              child: Text(
                'Lưu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_imageFile == null)
              _buildImagePlaceholder(colorScheme)
            else
              _buildImagePreview(colorScheme),

            const SizedBox(height: 32),

            if (_isScanning)
              _buildScanningIndicator(colorScheme)
            else if (_scanResult != null)
              _buildResultCard(colorScheme)
            else
              _buildActionButtons(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có ảnh hóa đơn',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Image.file(
            _imageFile!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          IconButton.filledTonal(
            onPressed: () => setState(() {
              _imageFile = null;
              _scanResult = null;
              _itemDrafts = <_ReceiptItemDraft>[];
            }),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator(ColorScheme colorScheme) {
    return Column(
      children: [
        CircularProgressIndicator(color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Đang phân tích hóa đơn...',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ColorScheme colorScheme) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final items = _itemDrafts.where((e) => !e.deleted).toList(growable: false);
    final itemsSum = items.fold<double>(0, (acc, e) => acc + e.amount);
    final totalGap = _singleTotalDraft - itemsSum;
    final hasGap = totalGap.abs() >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kết quả quét',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              label: Text(
                'Quét lại',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<_ReceiptSaveMode>(
                        segments: const [
                          ButtonSegment(
                            value: _ReceiptSaveMode.multiple,
                            label: Text('Nhiều khoản'),
                            icon: Icon(Icons.view_list_outlined),
                          ),
                          ButtonSegment(
                            value: _ReceiptSaveMode.single,
                            label: Text('1 khoản'),
                            icon: Icon(Icons.summarize_outlined),
                          ),
                        ],
                        selected: {_saveMode},
                        onSelectionChanged: (s) {
                          setState(() {
                            _saveMode = s.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  onSelectionChanged: (s) =>
                      setState(() => _paymentMethodSelection = s.first),
                ),
                const SizedBox(height: 12),
                _buildEditableRow(
                  'Cửa hàng',
                  _merchantDraft,
                  (val) => _merchantDraft = val,
                  colorScheme,
                ),
                Divider(color: colorScheme.outlineVariant),
                _buildEditableRow(
                  'Tổng cộng',
                  currencyFormat.format(_singleTotalDraft),
                  (val) {
                    final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                    _singleTotalDraft = double.tryParse(cleanVal) ?? 0;
                  },
                  colorScheme,
                  keyboardType: TextInputType.number,
                ),
                if (_saveMode == _ReceiptSaveMode.single) ...[
                  Divider(color: colorScheme.outlineVariant),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    trailing: DropdownButton<ExpenseCategory>(
                      dropdownColor: colorScheme.surfaceContainerLow,
                      value: _singleCategoryDraft,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _singleCategoryDraft = val);
                        }
                      },
                      items: ExpenseCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            _getCategoryName(cat),
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ] else ...[
                  Divider(color: colorScheme.outlineVariant),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addItemDraft,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm sản phẩm'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Text(
                      'Chưa có sản phẩm. Hãy bấm “Thêm sản phẩm” để nhập thủ công.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    Column(
                      children: [
                        for (final item in _itemDrafts)
                          if (!item.deleted)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReceiptItemEditor(
                                draft: item,
                                currencyFormat: currencyFormat,
                                onChanged: () => setState(() {}),
                                onDelete: () =>
                                    setState(() => item.deleted = true),
                              ),
                            ),
                        Divider(color: colorScheme.outlineVariant),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tổng sản phẩm'),
                          trailing: Text(
                            currencyFormat.format(itemsSum),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (hasGap)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Chênh lệch so với tổng cộng',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(
                              currencyFormat.format(totalGap),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: totalGap.abs() >= 1
                                    ? colorScheme.tertiary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(
    String label,
    String value,
    Function(String) onChanged,
    ColorScheme colorScheme, {
    TextInputType? keyboardType,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      ),
      trailing: SizedBox(
        width: 150,
        child: TextFormField(
          initialValue: value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: onChanged,
          keyboardType: keyboardType,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Chọn từ máy'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
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

  ExpenseCategory _detectCategoryForReceipt(ReceiptScanResult result) {
    if (result.items.isEmpty) return ExpenseCategory.other;
    final counts = <ExpenseCategory, int>{};
    for (final i in result.items) {
      counts[i.category] = (counts[i.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty ? ExpenseCategory.other : sorted.first.key;
  }
}

enum _ReceiptSaveMode { multiple, single }

class _ReceiptItemDraft {
  String name;
  double amount;
  ExpenseCategory category;
  double confidence;
  bool deleted;

  _ReceiptItemDraft({
    required this.name,
    required this.amount,
    required this.category,
    required this.confidence,
  }) : deleted = false;
}

class _ReceiptItemEditor extends StatelessWidget {
  final _ReceiptItemDraft draft;
  final NumberFormat currencyFormat;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ReceiptItemEditor({
    required this.draft,
    required this.currencyFormat,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.name,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  onChanged: (v) {
                    draft.name = v;
                    onChanged();
                  },
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseCategory>(
                      value: draft.category,
                      dropdownColor: colorScheme.surfaceContainerLow,
                      isExpanded: true,
                      onChanged: (val) {
                        if (val == null) return;
                        draft.category = val;
                        onChanged();
                      },
                      items: ExpenseCategory.values
                          .where((c) => c != ExpenseCategory.income)
                          .map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(_getCategoryName(cat)),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextFormField(
                  initialValue: currencyFormat.format(draft.amount),
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                    draft.amount = double.tryParse(cleanVal) ?? 0;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
