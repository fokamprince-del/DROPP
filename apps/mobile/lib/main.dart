import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/page_configuration_invalide.dart';
import 'core/config/environnement.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    Environnement.verifier();
  } on StateError catch (e) {
    // Lever ici laisserait l'écran blanc d'Android : on affiche l'erreur.
    runApp(PageConfigurationInvalide(message: e.message));
    return;
  }
  debugPrint('API_URL = ${Environnement.apiUrl}');
  runApp(const ProviderScope(child: DroppApp()));
}
