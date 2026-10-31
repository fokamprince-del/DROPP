import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/upload/service_upload.dart';
import '../data/modeles_kyc.dart';

/// Photos choisies pendant cette session, en mémoire seulement (jamais sur
/// disque). Elles servent aux aperçus. Le serveur reste la source de vérité de
/// ce qui a été envoyé.
@immutable
class BrouillonKyc {
  const BrouillonKyc({this.photos = const {}, this.envoyees = const {}});

  final Map<TypeDocumentKyc, FichierLocal> photos;
  final Set<TypeDocumentKyc> envoyees;

  FichierLocal? photo(TypeDocumentKyc type) => photos[type];

  /// Choisie mais pas encore envoyée : l'utilisateur doit la valider.
  bool enAttenteDEnvoi(TypeDocumentKyc type) =>
      photos.containsKey(type) && !envoyees.contains(type);
}

final brouillonKycProvider =
    NotifierProvider<BrouillonKycNotifier, BrouillonKyc>(
  BrouillonKycNotifier.new,
);

class BrouillonKycNotifier extends Notifier<BrouillonKyc> {
  @override
  BrouillonKyc build() {
    // Repart de zéro quand l'utilisateur change (déconnexion, autre compte).
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
    return const BrouillonKyc();
  }

  void choisir(TypeDocumentKyc type, FichierLocal photo) {
    state = BrouillonKyc(
      photos: {...state.photos, type: photo},
      envoyees: {...state.envoyees}..remove(type),
    );
  }

  void marquerEnvoyee(TypeDocumentKyc type) {
    state = BrouillonKyc(
      photos: state.photos,
      envoyees: {...state.envoyees, type},
    );
  }

  void retirer(TypeDocumentKyc type) {
    state = BrouillonKyc(
      photos: {...state.photos}..remove(type),
      envoyees: {...state.envoyees}..remove(type),
    );
  }

  void vider() => state = const BrouillonKyc();
}