import 'package:flutter/material.dart';

import '../shared/theme/couleurs.dart';
import '../shared/theme/espacements.dart';
import '../shared/theme/theme_dropp.dart';
import '../shared/widgets/logo_dropp.dart';

/// Affichée à la place de l'app quand la configuration de compilation est
/// invalide (API_URL). Sans elle, l'erreur part avant `runApp` et l'APK
/// reste sur un écran blanc.
class PageConfigurationInvalide extends StatelessWidget {
  const PageConfigurationInvalide({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DROPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeDropp.sombre,
      home: Scaffold(
        backgroundColor: Couleurs.nuit,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Espacements.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoDropp(),
                  const SizedBox(height: Espacements.l),
                  const Text(
                    'Application mal configurée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Couleurs.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Espacements.s),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Couleurs.texteSombre),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
