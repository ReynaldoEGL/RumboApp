import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/app/app_router.dart';
import 'package:rumboapp/app/app_routes.dart';
import 'package:rumboapp/app/theme/app_theme.dart';
import 'package:rumboapp/core/providers/theme_mode_provider.dart';

class RumboApp extends ConsumerWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Rumbo',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
