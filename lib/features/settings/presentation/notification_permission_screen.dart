import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/services/notification_recognition_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen>
    with WidgetsBindingObserver {
  bool _loading = false;
  bool? _hasReadPermission;
  bool? _canSendNotifications;
  bool? _setupCompleted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final hasRead = await NotificationListenerService.isPermissionGranted();
    final canSend =
        await NotificationRecognitionService.areQuickAddNotificationsEnabled();
    final setupCompleted = await ref
        .read(isarServiceProvider)
        .isSetupCompleted();

    if (!mounted) return;
    setState(() {
      _hasReadPermission = hasRead;
      _canSendNotifications = canSend;
      _setupCompleted = setupCompleted;
    });
  }

  Future<void> _requestReadPermission() async {
    if (_loading) return;
    setState(() => _loading = true);
    await NotificationRecognitionService.startListening();
    await _refreshStatus();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _requestSendPermission() async {
    if (_loading) return;
    setState(() => _loading = true);
    await NotificationRecognitionService.requestQuickAddNotificationPermission();
    await _refreshStatus();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _continue() {
    final setupCompleted = _setupCompleted ?? false;
    if (setupCompleted) {
      context.go('/');
    } else {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRead = _hasReadPermission;
    final canSend = _canSendNotifications;
    final ready = hasRead == true && canSend == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quyền thông báo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Bật quyền để NoteCash tự nhận diện giao dịch và nhắc nhập nhanh.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _PermissionCard(
              title: 'Đọc thông báo (Notification Access)',
              description:
                  'Cho phép NoteCash đọc nội dung thông báo từ app ngân hàng/ví bạn chọn.',
              granted: hasRead,
              loading: _loading,
              onPressed: _requestReadPermission,
              buttonText: 'Cấp quyền',
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              title: 'Gửi thông báo (Quick Add)',
              description:
                  'Cho phép NoteCash hiển thị thông báo nhập nhanh ngay trên thanh thông báo.',
              granted: canSend,
              loading: _loading,
              onPressed: _requestSendPermission,
              buttonText: 'Cho phép',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: ready && !_loading ? _continue : null,
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool? granted;
  final bool loading;
  final VoidCallback onPressed;
  final String buttonText;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.granted,
    required this.loading,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = granted;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: loading ? null : onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool? status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = status;
    final label = s == null ? '...' : (s ? 'Đã cấp' : 'Chưa cấp');
    final Color bg = s == true
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final Color fg = s == true
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
