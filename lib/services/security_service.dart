import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:notecash/core/models/user_settings.dart';
import 'package:notecash/services/isar_service.dart';

class SecurityService {
  final IsarService _isarService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  SecurityService(this._isarService);

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setPin(String pin) async {
    var settings = await _isarService.getUserSettings();
    settings ??= UserSettings()..isSetupCompleted = false;
    settings.pinHash = _hashPin(pin);
    await _isarService.saveUserSettings(settings);
  }

  Future<bool> verifyPin(String pin) async {
    final settings = await _isarService.getUserSettings();
    if (settings?.pinHash == null) return false;
    return settings!.pinHash == _hashPin(pin);
  }

  Future<bool> hasPin() async {
    final settings = await _isarService.getUserSettings();
    return settings?.pinHash != null && settings!.pinHash!.isNotEmpty;
  }

  Future<void> removePin() async {
    final settings = await _isarService.getUserSettings();
    if (settings != null) {
      settings.pinHash = null;
      settings.isBiometricEnabled = false;
      await _isarService.saveUserSettings(settings);
    }
  }

  Future<bool> isBiometricEnabled() async {
    final settings = await _isarService.getUserSettings();
    return settings?.isBiometricEnabled ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    var settings = await _isarService.getUserSettings();
    settings ??= UserSettings()..isSetupCompleted = false;
    settings.isBiometricEnabled = enabled;
    await _isarService.saveUserSettings(settings);
  }

  Future<bool> canUseBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Xác thực để mở NoteCash',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
