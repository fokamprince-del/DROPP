import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../catalogue/data/modeles_catalogue.dart';
import '../data/boutiques_repository.dart';
import '../data/modeles_boutiques.dart';

/// Page publique d'une boutique ; rechargée à la connexion (état
/// d'abonnement, « ma boutique »).
final boutiqueProvider = FutureProvider.autoDispose.family<Boutique, String>((
  ref,
  id,
) {
  ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
  return ref.watch(boutiquesRepositoryProvider).obtenir(id);
});

final resumeAvisBoutiqueProvider = FutureProvider.autoDispose
    .family<ResumeAvis, String>(
      (ref, id) => ref.watch(boutiquesRepositoryProvider).resumeAvis(id),
    );
