import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fil_repository.dart';

final vuesPublicationsProvider = Provider<VuesPublications>(
  (ref) => VuesPublications(ref.watch(filRepositoryProvider).marquerVue),
);

/// Signale chaque publication affichée, une seule fois par lancement :
/// remonter dans le fil n'envoie pas de nouvelle requête. Le serveur
/// dédoublonne aussi sur 24 h.
class VuesPublications {
  VuesPublications(this._envoyer);

  final Future<void> Function(String id) _envoyer;
  final _signalees = <String>{};

  Future<void> signaler(String id) async {
    if (!_signalees.add(id)) return;
    try {
      await _envoyer(id);
    } on Exception {
      // Hors connexion : on réessaiera au prochain affichage.
      _signalees.remove(id);
    }
  }
}
