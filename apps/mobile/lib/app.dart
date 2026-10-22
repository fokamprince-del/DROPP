import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_dropp.dart';

class DroppApp extends ConsumerWidget {
  const DroppApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'DROPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeDropp.clair,
      darkTheme: ThemeDropp.sombre,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
