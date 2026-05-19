import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/core/theme.dart';
import 'package:notecash/services/home_widget_service.dart';
import 'package:notecash/services/notification_recognition_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HomeWidgetService.init();
  await NotificationRecognitionService.init();

  final container = ProviderContainer();
  final isarService = container.read(isarServiceProvider);
  await isarService.init();
  NotificationRecognitionService.setDatabaseService(isarService);

  runApp(
    UncontrolledProviderScope(container: container, child: const NoteCashApp()),
  );
}

class NoteCashApp extends ConsumerStatefulWidget {
  const NoteCashApp({super.key});

  @override
  ConsumerState<NoteCashApp> createState() => _NoteCashAppState();
}

class _NoteCashAppState extends ConsumerState<NoteCashApp> {
  @override
  void initState() {
    super.initState();
    _setupHomeWidget();
    _setupNotificationListener();
  }

  void _setupHomeWidget() {
    HomeWidget.setAppGroupId('group.notecash');
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _setupNotificationListener() {
    NotificationRecognitionService.startListening();
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri?.host == 'add-expense') {
      router.push('/add-expense');
    } else if (uri?.host == 'dashboard') {
      router.go('/'); // Quay về trang chủ
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Fallback schemes if dynamic color is not available
        final lightScheme =
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            );
        final darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            );

        return MaterialApp.router(
          title: 'NoteCash',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(lightScheme),
          darkTheme: AppTheme.theme(darkScheme),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
