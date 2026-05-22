import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/core/providers.dart';
import 'package:pinput/pinput.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  bool isBiometricAvailable = false;
  bool isBiometricEnabled = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final securityService = ref.read(securityServiceProvider);
    final canUse = await securityService.canUseBiometric();
    final enabled = await securityService.isBiometricEnabled();
    
    if (mounted) {
      setState(() {
        isBiometricAvailable = canUse;
        isBiometricEnabled = enabled;
      });
    }

    if (canUse && enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometric();
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    final securityService = ref.read(securityServiceProvider);
    final authenticated = await securityService.authenticateWithBiometric();
    if (authenticated && mounted) {
      ref.read(appLockControllerProvider).unlock();
    }
  }

  void _onCompleted(String pin) async {
    final securityService = ref.read(securityServiceProvider);
    final isValid = await securityService.verifyPin(pin);
    if (isValid) {
      if (mounted) {
        ref.read(appLockControllerProvider).unlock();
      }
    } else {
      setState(() {
        errorMessage = 'Mã PIN không chính xác';
        pinController.clear();
      });
      focusNode.requestFocus();
    }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.lock_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Nhập mã PIN của bạn',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Để truy cập ứng dụng NoteCash',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
                Text(
                  errorMessage,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
              const Spacer(),
              if (isBiometricAvailable && isBiometricEnabled) ...[
                IconButton(
                  icon: const Icon(Icons.fingerprint, size: 64),
                  color: colorScheme.primary,
                  onPressed: _authenticateBiometric,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bấm để sử dụng sinh trắc học',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
