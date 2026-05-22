import 'package:flutter/foundation.dart';
import 'package:notecash/services/security_service.dart';

class AppLockController extends ChangeNotifier {
  AppLockController(this._securityService);

  final SecurityService _securityService;

  bool _isInitialized = false;
  bool _isLocked = false;

  bool get isInitialized => _isInitialized;
  bool get isLocked => _isLocked;

  Future<void> init() async {
    _isLocked = await _securityService.hasPin();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> lockIfNeeded() async {
    final hasPin = await _securityService.hasPin();
    if (!hasPin) return;
    _isLocked = true;
    notifyListeners();
  }

  void unlock() {
    if (!_isLocked) return;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final hasPin = await _securityService.hasPin();
    if (!hasPin && _isLocked) {
      _isLocked = false;
    }
    notifyListeners();
  }
}
