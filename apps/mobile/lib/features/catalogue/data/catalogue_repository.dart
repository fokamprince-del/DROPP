import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import 'modeles_catalogue.dart';

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => CatalogueRepository(ref.watch(apiClientProvider)),
);

/// Routes publiques du catalogue : consultables sans compte. Avec une
/// session, le jeton est envoyé quand même (l'API en déduit `enFavori`, que
/// l'app ne lit pas : les favoris viennent de `/moi/etats`).
///
/// Toute erreur est une `ApiException`.
class CatalogueRepository {
  CatalogueRepository(this._api);

  final ApiClient _api;

  /// Produits par page dans les grilles (l'API accepte jusqu'à 100).
  static const taillePage = 20;

  /// `GET /categories` : catégories actives (non paginées), triées par nom,
  /// avec leurs sous-catégories et le nombre de produits publiés (celui d'une
  /// catégorie parente inclut ses sous-catégories).
  Future<List<Categorie>> categories() async {
    final json = await _api.get<List<dynamic>>('/categories');
    return json.cast<Map<String, dynamic>>().map(Categorie.fromJson).toList();
  }

  /// `GET /produits` : produits publiés de boutiques visibles.
  ///
  /// - `q` cherche dans le nom **et** la description (100 caractères max) ;
  /// - une catégorie parente inclut ses sous-catégories ;
  /// - la fourchette de prix porte sur le prix effectif d'au moins une
  ///   variante ;
  /// - `enStock` garde les produits ayant au moins une variante en stock ;
  /// - [boutiqueId] limite à une boutique (sa page).
  ///
  /// Chaque produit porte `prixMin` (le plus bas de ses variantes) et
  /// l'image d'ordre 0 en 400 px de large. La liste ne donne ni le stock ni
  /// le nom de la boutique.
  Future<PageResultats<ProduitResume>> produits(
    FiltresCatalogue filtres,
    int page, {
    String? boutiqueId,
  }) => _api.page(
    '/produits',
    ProduitResume.fromJson,
    page: page,
    limite: taillePage,
    query: {...filtres.versQuery(), 'boutiqueId': ?boutiqueId},
  );

  /// `GET /produits/:id` : variantes (attributs, prix, stock) et médias
  /// triés. 404 si le produit n'est pas publié ou si sa boutique est
  /// suspendue. Ne contient ni le nom de la boutique (le charger avec
  /// `boutiqueProvider`) ni l'état favori.
  Future<ProduitDetail> produit(String id) async => ProduitDetail.fromJson(
    await _api.get<Map<String, dynamic>>('/produits/$id'),
  );

  /// `GET /produits/:id/avis` : avis publics, les plus récents d'abord
  /// ([limite] : 50 au plus). Chaque page porte aussi le résumé de tous les
  /// avis (moyenne, total, répartition) : le lire avec [resumeDe]. Les
  /// auteurs n'apparaissent que par leur prénom.
  Future<PageResultats<Avis>> avis(
    String produitId,
    int page, {
    int limite = 20,
  }) => _api.page(
    '/produits/$produitId/avis',
    Avis.fromJson,
    page: page,
    limite: limite,
  );
}

/// Résumé renvoyé à côté de la première page d'avis.
ResumeAvis resumeDe(PageResultats<Avis> page) {
  final resume = page.brut['resume'];
  return resume is Map<String, dynamic>
      ? ResumeAvis.fromJson(resume)
      : const ResumeAvis();
}
