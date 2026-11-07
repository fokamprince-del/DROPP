import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/temps_reel/temps_reel.dart';
import '../data/notifications.dart';

final compteurNotificationsProvider =
    AsyncNotifierProvider<CompteurNotificationsNotifier, int>(
      CompteurNotificationsNotifier.new,
    );

/// Notifications non lues (cloche de l'accueil) : lues sur l'API à
/// l'ouverture de session, puis tenues à jour par le temps réel (nouvelle
/// notification : +1 ; lecture ou suppression : total envoyé par le
/// serveur).
class CompteurNotificationsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    if (utilisateur == null) return 0;

    final tempsReel = ref.watch(tempsReelProvider);
    final abonnements = [
      tempsReel
          .ecouter(EvenementsTempsReel.notificationNouvelle)
          .listen((_) => state = AsyncData((state.value ?? 0) + 1)),
      tempsReel.ecouter(EvenementsTempsReel.notificationsCompteur).listen((d) {
        final n = d['nonLues'];
        if (n is num) state = AsyncData(n.toInt());
      }),
    ];
    ref.onDispose(() {
      for (final a in abonnements) {
        a.cancel();
      }
    });

    try {
      return await ref.watch(notificationsRepositoryProvider).compteur();
    } on ApiException {
      return state.value ?? 0;
    }
  }

  /// Total renvoyé par une action (lecture, tout lire).
  void definir(int nonLues) => state = AsyncData(nonLues);
}
