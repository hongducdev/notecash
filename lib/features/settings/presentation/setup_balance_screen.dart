import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/shared/utils/currency_input_formatter.dart';

class SetupBalanceScreen extends ConsumerStatefulWidget {
  const SetupBalanceScreen({super.key});

  @override
  ConsumerState<SetupBalanceScreen> createState() => _SetupBalanceScreenState();
}

class _SetupBalanceScreenState extends ConsumerState<SetupBalanceScreen> {
  final _cashController = TextEditingController();
  final _bankController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final cash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    final bank = double.tryParse(_bankController.text.replaceAll('.', '')) ?? 0;

    final settings = UserSettings()
      ..initialCashBalance = cash
      ..initialBankBalance = bank
      ..isSetupCompleted = true
      ..updatedAt = DateTime.now();

    await ref.read(isarServiceProvider).saveUserSettings(settings);

    // Refresh providers to reflect the new balance
    ref.invalidate(userSettingsProvider);
    ref.invalidate(cumulativeBalanceProvider);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Chào mừng bạn đến với NoteCash',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Để bắt đầu, vui lòng nhập số dư hiện tại của bạn.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              _buildInputCard(
                context,
                title: 'Tiền mặt',
                subtitle: 'Tiền trong ví, ngăn kéo...',
                icon: Icons.payments_outlined,
                controller: _cashController,
              ),
              const SizedBox(height: 24),
              _buildInputCard(
                context,
                title: 'Ngân hàng',
                subtitle: 'Tiền trong tài khoản, thẻ...',
                icon: Icons.account_balance_outlined,
                controller: _bankController,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveAndContinue,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Bắt đầu sử dụng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: '₫',
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
