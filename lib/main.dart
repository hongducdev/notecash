import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/core/theme.dart';
import 'package:notecash/features/settings/presentation/lock_screen.dart';
import 'package:notecash/services/home_widget_service.dart';
import 'package:notecash/services/bill_reminder_service.dart';
import 'package:notecash/services/notification_recognition_service.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HomeWidgetService.init();
  await BillReminderService.init();
  await NotificationRecognitionService.init();

  final container = ProviderContainer();
  final isarService = container.read(isarServiceProvider);
  await isarService.init();
  NotificationRecognitionService.setDatabaseService(isarService);
  await NotificationRecognitionService.loadTrackedAppsFromDb();

  final appLockController = container.read(appLockControllerProvider);
  await appLockController.init();

  runApp(
    UncontrolledProviderScope(container: container, child: const NoteCashApp()),
  );
}

class NoteCashApp extends ConsumerStatefulWidget {
  const NoteCashApp({super.key});

  @override
  ConsumerState<NoteCashApp> createState() => _NoteCashAppState();
}

class _NoteCashAppState extends ConsumerState<NoteCashApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _homeWidgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupHomeWidget();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _homeWidgetClickSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationRecognitionService.startListening());
    }
    if (state == AppLifecycleState.paused) {
      ref.read(appLockControllerProvider).lockIfNeeded();
    }
  }

  void _setupHomeWidget() {
    HomeWidget.setAppGroupId('group.notecash');
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    _homeWidgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _setupNotificationListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationRecognitionService.startListening());
    });
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri?.host == 'add-expense') {
      router.push('/add-expense');
    } else if (uri?.host == 'dashboard') {
      router.go('/');
    } else if (uri?.host == 'bills') {
      router.push('/bills');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLock = ref.watch(appLockControllerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme =
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFFD82D8B),
              brightness: Brightness.light,
            );
        final darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFFD82D8B),
              brightness: Brightness.dark,
            );

        return ListenableBuilder(
          listenable: appLock,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'NoteCash',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme(lightScheme),
              darkTheme: AppTheme.theme(darkScheme),
              themeMode: ThemeMode.system,
              routerConfig: router,
              builder: (context, child) {
                if (appLock.isLocked) {
                  return const LockScreen();
                }
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }
}
