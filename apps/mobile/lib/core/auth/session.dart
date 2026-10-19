import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'jetons.dart';
import 'stockage_session.dart';
import 'utilisateur.dart';

sealed class EtatSession {
  const EtatSession();
}

/// Démarrage : lecture du stockage en cours.
final class SessionInconnue extends EtatSession {
  const SessionInconnue();
}

final class SessionAnonyme extends EtatSession {
  const SessionAnonyme({this.expiree = false});

  /// Déconnexion imposée par le serveur (jeton révoqué, compte suspendu…) :
  /// l'écran de connexion peut l'expliquer.
  final bool expiree;
}

final class SessionConnectee extends EtatSession {
  const SessionConnectee(this.utilisateur);

  final Utilisateur utilisateur;
}

final sessionProvider = NotifierProvider<SessionNotifier, EtatSession>(
  SessionNotifier.new,
);

/// Raccourci pour les écrans : l'utilisateur connecté, ou `null`.
final utilisateurConnecteProvider = Provider<Utilisateur?>((ref) {
  final session = ref.watch(sessionProvider);
  return session is SessionConnectee ? session.utilisateur : null;
});

class SessionNotifier extends Notifier<EtatSession> {
  StockageSession get _stockage => ref.read(stockageSessionProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  EtatSession build() {
    _demarrer();
    return const SessionInconnue();
  }

  Future<void> _demarrer() async {
    final jetons = await _stockage.lireJetons();
    if (jetons == null) {
      state = const SessionAnonyme();
      return;
    }
    await rafraichirProfil();
  }

  /// À appeler par les écrans d'auth (Dev B) avec les jetons reçus de
  /// `/auth/connexion` ou `/auth/verifier-telephone`.
  Future<void> ouvrir(Jetons jetons) async {
    await _stockage.ecrireJetons(jetons);
    await rafraichirProfil();
  }

  /// Recharge `/auth/me` (après être devenu vendeur, avoir changé d'email…).
  Future<void> rafraichirProfil() async {
    try {
      final json = await _api.get<Map<String, dynamic>>('/auth/me');
      await _stockage.ecrireProfil(json);
      state = SessionConnectee(Utilisateur.fromJson(json));
    } on ApiException catch (e) {
      if (e.type == TypeErreurApi.nonAuthentifie) {
        // L'intercepteur a déjà tenté un refresh et appelé expirer().
        if (state is! SessionAnonyme) await expirer();
        return;
      }
      // Hors connexion : on garde la session avec le dernier profil connu.
      if (state is SessionInconnue) {
        final profil = await _stockage.lireProfil();
        state = profil != null
            ? SessionConnectee(Utilisateur.fromJson(profil))
            : const SessionAnonyme();
      }
    }
  }

  /// Ferme la session de cet appareil.
  Future<void> deconnecter() async {
    try {
      await _api.post('/auth/deconnexion');
    } on ApiException {
      // Hors connexion ou jeton déjà invalide : la déconnexion locale suffit.
    }
    await _stockage.effacer();
    state = const SessionAnonyme();
  }

  /// Appelé par l'intercepteur quand le refresh est refusé.
  Future<void> expirer() async {
    await _stockage.effacer();
    state = const SessionAnonyme(expiree: true);
  }
}
