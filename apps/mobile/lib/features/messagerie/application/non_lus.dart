import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/temps_reel/temps_reel.dart';
import '../data/messagerie.dart';

final nonLusProvider = AsyncNotifierProvider<NonLusNotifier, int>(
  NonLusNotifier.new,
);

/// Pastille de l'onglet Messages.
final nombreMessagesNonLusProvider = Provider<int>(
  (ref) => ref.watch(nonLusProvider).value ?? 0,
);

/// Messages reçus non lus : lus sur l'API à l'ouverture de session et en
/// quittant une discussion, puis comptés en direct à chaque message reçu
/// par le temps réel.
class NonLusNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    // La messagerie exige un téléphone vérifié (403 sinon).
    if (utilisateur == null || !utilisateur.telephoneVerifie) return 0;

    final abonnement = ref
        .watch(tempsReelProvider)
        .ecouter(EvenementsTempsReel.messageNouveau)
        .listen((donnees) {
          if (donnees['expediteurId'] == utilisateur.id) return;
          state = AsyncData((state.value ?? 0) + 1);
        });
    ref.onDispose(abonnement.cancel);

    try {
      return await ref.watch(messagerieRepositoryProvider).nonLus();
    } on ApiException {
      return state.value ?? 0;
    }
  }

  void rafraichir() => ref.invalidateSelf();
}
