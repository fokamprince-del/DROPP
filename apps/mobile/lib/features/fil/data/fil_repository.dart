import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import 'modeles_fil.dart';

final filRepositoryProvider = Provider<FilRepository>(
  (ref) => FilRepository(ref.watch(apiClientProvider)),
);

/// Publications (fil, détail, page boutique) et comptage des vues.
///
/// Chaque publication arrive avec ses médias (URL publique, ou URL signée
/// à durée limitée si elle est réservée aux abonnés), ses produits liés
/// encore publiés (5 au plus) et ses compteurs `likes` / `commentaires`.
/// Elle ne dit pas si l'utilisateur l'a aimée : voir `interactionsProvider`.
///
/// Toute erreur est une `ApiException`.
class FilRepository {
  FilRepository(this._api);

  final ApiClient _api;

  /// Petites pages : chaque publication charge des médias.
  static const taillePage = 10;

  /// `GET /publications` : fil « Pour toi », publications publiques en
  /// ligne, les plus récentes d'abord. Sans compte.
  Future<PageResultats<Publication>> pourToi(int page) => _api.page(
    '/publications',
    Publication.fromJson,
    page: page,
    limite: taillePage,
  );

  /// `GET /publications/fil/abonnements` (connexion requise) : publications
  /// des boutiques suivies, y compris celles réservées aux abonnés.
  Future<PageResultats<Publication>> abonnements(int page) => _api.page(
    '/publications/fil/abonnements',
    Publication.fromJson,
    page: page,
    limite: taillePage,
  );

  /// `GET /publications?boutiqueId=` : publications d'une boutique, avec
  /// celles réservées aux abonnés si on la suit (ou si c'est la sienne).
  Future<PageResultats<Publication>> deBoutique(String boutiqueId, int page) =>
      _api.page(
        '/publications',
        Publication.fromJson,
        page: page,
        limite: taillePage,
        query: {'boutiqueId': boutiqueId},
      );

  /// `GET /publications/:id` : 404 si elle n'est plus en ligne, ou si elle
  /// est réservée aux abonnés et qu'on ne suit pas la boutique.
  Future<Publication> obtenir(String id) async => Publication.fromJson(
    await _api.get<Map<String, dynamic>>('/publications/$id'),
  );

  /// `POST /publications/:id/vue` (sans compte possible) : le serveur compte
  /// au plus une vue par personne (ou par adresse IP pour un visiteur) et
  /// par 24 h. À appeler quand la publication est réellement à l'écran :
  /// passer par `VuesPublications`, qui évite les doublons.
  Future<void> marquerVue(String id) =>
      _api.post<Object?>('/publications/$id/vue');
}
