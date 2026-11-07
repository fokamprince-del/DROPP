import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/temps_reel/temps_reel.dart';
import '../l10n/app_localizations.dart';
import '../shared/theme/theme_dropp.dart';

class DroppApp extends ConsumerWidget {
  const DroppApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Connexion temps réel ouverte tant qu'un utilisateur est connecté.
    ref.watch(tempsReelProvider);
    return MaterialApp.router(
      title: 'DROPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeDropp.clair,
      darkTheme: ThemeDropp.sombre,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Langue inconnue : français, pas anglais.
      localeResolutionCallback: (locale, supportees) => supportees.firstWhere(
        (s) => s.languageCode == locale?.languageCode,
        orElse: () => const Locale('fr'),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
