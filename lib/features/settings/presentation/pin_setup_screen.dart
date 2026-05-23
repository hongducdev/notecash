import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:pinput/pinput.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  String? firstPin;
  bool isConfirming = false;
  String errorMessage = '';

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onCompleted(String pin) async {
    if (!isConfirming) {
      setState(() {
        firstPin = pin;
        isConfirming = true;
        pinController.clear();
        errorMessage = '';
      });
      focusNode.requestFocus();
    } else {
      if (pin == firstPin) {
        final securityService = ref.read(securityServiceProvider);
        await securityService.setPin(pin);

        final canBiometric = await securityService.canUseBiometric();

        if (mounted) {
          if (canBiometric) {
            _showBiometricPrompt(securityService);
          } else {
            ref.read(appLockControllerProvider).refresh();
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thiết lập mã PIN thành công')),
            );
          }
        }
      } else {
        setState(() {
          errorMessage = 'Mã PIN không khớp. Vui lòng thử lại.';
          pinController.clear();
        });
        focusNode.requestFocus();
      }
    }
  }

  void _showBiometricPrompt(securityService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sử dụng sinh trắc học'),
        content: const Text(
          'Thiết bị của bạn hỗ trợ sinh trắc học (vân tay/khuôn mặt). Bạn có muốn sử dụng để mở khóa ứng dụng không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(appLockControllerProvider).refresh();
              context.pop(); // close dialog
              context.pop(); // close screen
            },
            child: const Text('Không, cảm ơn'),
          ),
          FilledButton(
            onPressed: () async {
              await securityService.setBiometricEnabled(true);
              if (mounted) {
                ref.read(appLockControllerProvider).refresh();
                context.pop(); // close dialog
                context.pop(); // close screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã bật mở khóa sinh trắc học')),
                );
              }
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: colorScheme.primary, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: colorScheme.error, width: 2),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập mã khóa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isConfirming) {
              setState(() {
                isConfirming = false;
                firstPin = null;
                pinController.clear();
                errorMessage = '';
              });
              focusNode.requestFocus();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Icon(
                isConfirming ? Icons.check_circle_outline : Icons.lock_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                isConfirming ? 'Nhập lại mã PIN' : 'Nhập mã PIN mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isConfirming
                    ? 'Vui lòng xác nhận mã PIN vừa nhập'
                    : 'Mã PIN này dùng để bảo vệ dữ liệu của bạn',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Pinput(
                length: 6,
                controller: pinController,
                focusNode: focusNode,
                obscureText: true,
                obscuringCharacter: '●',
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                errorPinTheme: errorPinTheme,
                forceErrorState: errorMessage.isNotEmpty,
                onCompleted: _onCompleted,
                autofocus: true,
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(errorMessage, style: TextStyle(color: colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
