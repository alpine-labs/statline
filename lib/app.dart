import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'presentation/screens/settings/settings_screen.dart';

/// Root widget for the StatLine app.
class StatLineApp extends ConsumerWidget {
  const StatLineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'StatLine',
      debugShowCheckedModeBanner: false,
      theme: StatLineTheme.lightTheme(),
      darkTheme: StatLineTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
