import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/core/router.dart';
import 'package:notecash/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final isarService = container.read(isarServiceProvider);
  await isarService.init();

  runApp(
    UncontrolledProviderScope(container: container, child: const NoteCashApp()),
  );
}

class NoteCashApp extends StatelessWidget {
  const NoteCashApp({super.key});

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
