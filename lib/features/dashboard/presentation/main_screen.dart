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

    // Map UI navigation index to actual page index
    int getPageIndex(int navIndex) {
      if (navIndex < 2) return navIndex;
      if (navIndex > 2) return navIndex - 1;
      return _selectedIndex > 2
          ? _selectedIndex - 1
          : _selectedIndex; // fallback
    }

    // Map actual page index to UI navigation index
    int getNavIndex(int pageIndex) {
      if (pageIndex < 2) return pageIndex;
      return pageIndex + 1;
    }

    final activeNavIndex = getNavIndex(_selectedIndex);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeNavIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push(_selectedIndex == 1 ? '/add-bill' : '/add-expense');
            return;
          }
          setState(() {
            _selectedIndex = getPageIndex(index);
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(
              _selectedIndex == 1
                  ? Icons.add_box_outlined
                  : Icons.add_circle_outline,
              size: 28,
            ),
            selectedIcon: Icon(
              _selectedIndex == 1 ? Icons.add_box : Icons.add_circle,
              size: 28,
            ),
            label: _selectedIndex == 1 ? 'Thêm HĐ' : 'Thêm GD',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Trợ lý',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
