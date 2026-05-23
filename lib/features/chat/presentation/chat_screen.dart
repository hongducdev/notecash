import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/expense/domain/expense.dart';
import 'package:notecash/features/bills/domain/recurring_bill.dart';
import 'package:notecash/services/expense_parser_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _parser = ExpenseParserService();
  final _speech = stt.SpeechToText();
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addWelcomeMessage();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            'Xin chào! Tôi có thể giúp bạn thêm chi tiêu hoặc hóa đơn định kỳ.\n\nVí dụ:\n• "cf 35k" - Thêm chi tiêu\n• "tiền điện 200k hàng tháng" - Thêm hóa đơn định kỳ',
        isUser: false,
        timestamp: DateTime.now(),
        isWelcome: true,
      ),
    );
  }

  void _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(localeId: 'vi_VN'),
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImageAndScan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _controller.text = recognizedText.text;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi quét văn bản: $e')));
      }
    } finally {
      textRecognizer.close();
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });

    _controller.clear();
    _scrollToBottom();

    final parsed = _parser.parse(text);

    final isRecurringBill =
        text.contains('hàng tháng') ||
        text.contains('hàng quý') ||
        text.contains('hàng năm') ||
        text.contains('định kỳ');

    setState(() {
      _messages.add(
        ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          parsedExpense: parsed,
          isRecurringBill: isRecurringBill,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveAsExpense(Expense expense) async {
    final service = ref.read(isarServiceProvider);
    await service.saveExpense(expense);

    final savedDate = DateTime(
      expense.createdAt.year,
      expense.createdAt.month,
      expense.createdAt.day,
    );
    final monthKey = DateTime(savedDate.year, savedDate.month);

    ref.invalidate(todayExpensesProvider);
    ref.invalidate(dateExpensesProvider(savedDate));
    ref.invalidate(monthExpensesProvider(monthKey));
    ref.invalidate(cumulativeBalanceProvider(savedDate));
    ref.invalidate(cashBalanceProvider);
    ref.invalidate(bankBalanceProvider);

    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Đã lưu chi tiêu thành công!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _saveAsRecurringBill(Expense parsed, String originalText) async {
    BillFrequency frequency = BillFrequency.monthly;
    if (originalText.contains('hàng quý')) {
      frequency = BillFrequency.quarterly;
    } else if (originalText.contains('hàng năm')) {
      frequency = BillFrequency.annual;
    }

    final bill = RecurringBill()
      ..name = parsed.note.isEmpty ? 'Hóa đơn' : parsed.note
      ..amount = parsed.amount
      ..nextDueDate = DateTime.now().add(const Duration(days: 30))
      ..frequency = frequency
      ..category = parsed.category
      ..paymentMethod = parsed.paymentMethod
      ..isActive = true
      ..reminderDaysBefore = 3
      ..createdAt = DateTime.now();

    final service = ref.read(isarServiceProvider);
    await service.saveRecurringBill(bill);

    ref.invalidate(recurringBillsProvider);
    ref.invalidate(upcomingBillsProvider);

    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Đã lưu hóa đơn định kỳ thành công!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý chi tiêu'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.parsedExpense != null) {
      return _buildParsedExpenseCard(message);
    }

    if (message.isWelcome) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.waving_hand,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildParsedExpenseCard(ChatMessage message) {
    final expense = message.parsedExpense!;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note.isEmpty ? 'Ghi chú' : expense.note,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getCategoryName(expense.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _saveAsExpense(expense),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Lưu chi tiêu'),
                ),
              ),
              if (message.isRecurringBill) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final userMessage = _messages.lastWhere(
                        (m) => m.isUser && m.text.isNotEmpty,
                      );
                      _saveAsRecurringBill(expense, userMessage.text);
                    },
                    icon: const Icon(Icons.repeat, size: 18),
                    label: const Text('Lưu định kỳ'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImageAndScan,
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Quét hóa đơn',
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Nhập chi tiêu...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            tooltip: 'Nhập bằng giọng nói',
            color: _isListening ? Colors.red : null,
          ),
          IconButton(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send),
            tooltip: 'Gửi',
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Expense? parsedExpense;
  final bool isRecurringBill;
  final bool isWelcome;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.parsedExpense,
    this.isRecurringBill = false,
    this.isWelcome = false,
  });
}
