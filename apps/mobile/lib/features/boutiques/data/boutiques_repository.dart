import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../catalogue/data/modeles_catalogue.dart';
import 'modeles_boutiques.dart';

final boutiquesRepositoryProvider = Provider<BoutiquesRepository>(
  (ref) => BoutiquesRepository(ref.watch(apiClientProvider)),
);

/// Pages publiques des boutiques et abonnements de l'utilisateur.
///
/// Une boutique a le même identifiant que son vendeur (et que le compte
/// utilisateur du vendeur) : c'est cet identifiant qu'attendent
/// `/vendeurs/:id/suivre` et `?boutiqueId=`.
///
/// Toute erreur est une `ApiException`.
class BoutiquesRepository {
  BoutiquesRepository(this._api);

  final ApiClient _api;

  /// `GET /boutiques` (public) : boutiques actives, les plus suivies d'abord ;
  /// [q] cherche dans le nom seulement. 20 par page (50 au plus côté API).
  /// Chaque résultat porte son nombre d'abonnés, pas l'état d'abonnement :
  /// celui-ci vient de `/moi/etats`.
  Future<PageResultats<Boutique>> rechercher(String? q, int page) => _api.page(
    '/boutiques',
    Boutique.fromJson,
    page: page,
    query: {if (q != null && q.trim().isNotEmpty) 'q': q.trim()},
  );

  /// `GET /boutiques/:id` (public) : profil, statistiques (abonnés, produits
  /// publiés, publications en ligne) et, avec une session, `estAbonne` et
  /// `estMaBoutique`. 404 si la boutique est suspendue ou inexistante.
  Future<Boutique> obtenir(String id) async =>
      Boutique.fromJson(await _api.get<Map<String, dynamic>>('/boutiques/$id'));

  /// `GET /boutiques/:id/avis/resume` (public) : note moyenne (une
  /// décimale, `null` sans avis), total et répartition, sur tous les
  /// articles vendus par la boutique.
  Future<ResumeAvis> resumeAvis(String id) async => ResumeAvis.fromJson(
    await _api.get<Map<String, dynamic>>('/boutiques/$id/avis/resume'),
  );

  /// `GET /moi/abonnements` (connexion requise) : boutiques suivies, les
  /// plus récentes d'abord, y compris celles mises en sourdine (`muet`) ;
  /// les boutiques suspendues sont exclues. 20 par page.
  Future<PageResultats<AbonnementBoutique>> mesAbonnements(int page) =>
      _api.page('/moi/abonnements', AbonnementBoutique.fromJson, page: page);
}
