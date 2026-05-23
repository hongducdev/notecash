import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/features/bills/presentation/bills_screen.dart';
import 'package:notecash/features/chat/presentation/chat_screen.dart';
import 'package:notecash/features/dashboard/presentation/dashboard_screen.dart';
import 'package:notecash/features/settings/presentation/settings_screen.dart';
import 'package:notecash/services/notification_recognition_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

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
    final pages = [
      const DashboardScreen(),
      const BillsScreen(),
      const ChatScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Trợ lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 || _selectedIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(
                _selectedIndex == 0 ? '/add-expense' : '/add-bill',
              ),
              child: Icon(_selectedIndex == 0 ? Icons.add : Icons.receipt_long),
            ),
    );
  }
}
