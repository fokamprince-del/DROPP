import 'package:flutter/foundation.dart';

/// Configuration injectée au lancement :
/// `flutter run --dart-define=API_URL=https://api.dropp.cm/v1`
///
/// Par défaut : l'API locale vue depuis l'émulateur Android (10.0.2.2 = la
/// machine hôte). Sur un vrai téléphone, passer l'IP du PC sur le réseau local.
abstract final class Environnement {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/v1',
  );

  /// Origine du serveur (sans /v1), pour Socket.IO (namespace /temps-reel).
  static String get origineServeur => Uri.parse(apiUrl).replace(path: '').toString();

  /// À appeler au tout début de `main()` : échoue vite plutôt que de livrer
  /// une application mal configurée.
  static void verifier() => valider(apiUrl, release: kReleaseMode);

  @visibleForTesting
  static void valider(String url, {required bool release}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_URL invalide : "$url"');
    }
    if (release && uri.scheme != 'https') {
      throw StateError('API_URL doit être en https en release : "$url"');
    }
  }
}
