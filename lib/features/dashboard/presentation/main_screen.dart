import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/dashboard/presentation/dashboard_screen.dart';
import 'package:notecash/services/notification_recognition_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final hasReadPermission =
        await NotificationListenerService.isPermissionGranted();
    final canSendNotifications =
        await NotificationRecognitionService.areQuickAddNotificationsEnabled();

    if ((!hasReadPermission || !canSendNotifications) && mounted) {
      context.go('/notification-permission');
      return;
    }

    final isarService = ref.read(isarServiceProvider);
    final isCompleted = await isarService.isSetupCompleted();

    if (!isCompleted && mounted) {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const DashboardScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-expense'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
