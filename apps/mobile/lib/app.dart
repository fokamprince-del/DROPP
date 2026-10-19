import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

class DroppApp extends ConsumerWidget {
  const DroppApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'DROPP',
      debugShowCheckedModeBanner: false,
      // Thème provisoire : remplacé par le thème de Dev B (core/ui).
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
