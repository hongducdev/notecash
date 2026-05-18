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
  Expense? _scannedResult;
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isScanning = true;
        _scannedResult = null;
      });

      try {
        final result = await _ocrService.scanReceipt(_imageFile!);
        setState(() {
          _scannedResult = result;
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
    if (_scannedResult == null) return;

    final service = ref.read(isarServiceProvider);
    await service.saveExpense(_scannedResult!);

    // Refresh providers
    ref.invalidate(expensesProvider);
    ref.invalidate(todayExpensesProvider);
    ref.invalidate(allExpensesProvider);
    ref.invalidate(dateExpensesProvider);

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
          if (_scannedResult != null)
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
            else if (_scannedResult != null)
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
              _scannedResult = null;
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
                _buildEditableRow(
                  'Ghi chú',
                  _scannedResult!.note,
                  (val) => _scannedResult!.note = val,
                  colorScheme,
                ),
                Divider(color: colorScheme.outlineVariant),
                _buildEditableRow(
                  'Số tiền',
                  currencyFormat.format(_scannedResult!.amount),
                  (val) {
                    final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                    _scannedResult!.amount = double.tryParse(cleanVal) ?? 0;
                  },
                  colorScheme,
                  keyboardType: TextInputType.number,
                ),
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
                    value: _scannedResult!.category,
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _scannedResult!.category = val);
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
}
