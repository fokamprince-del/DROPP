import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../shared/modeles/contenu.dart';

/// Produit mis en favori (`GET /moi/favoris/produits`).
class FavoriProduit {
  const FavoriProduit({
    required this.produitId,
    required this.nom,
    required this.prix,
    required this.enVente,
    this.boutiqueNom,
  });

  final String produitId;
  final String nom;

  /// Prix de base (la liste ne donne pas le prix des variantes).
  final num prix;
  final String? boutiqueNom;

  /// Faux si le produit a été retiré de la vente depuis.
  final bool enVente;

  factory FavoriProduit.fromJson(Map<String, dynamic> json) {
    final p = json['produit'] as Map<String, dynamic>;
    final boutique = p['boutique'] as Map<String, dynamic>?;
    return FavoriProduit(
      produitId: p['id'] as String,
      nom: p['nom'] as String,
      prix: lireMontant(p['prixBase']),
      enVente: p['statut'] == 'PUBLIE',
      boutiqueNom: boutique?['nom'] as String?,
    );
  }
}

/// Publication enregistrée (`GET /moi/favoris/publications`).
class FavoriPublication {
  const FavoriPublication({
    required this.publicationId,
    required this.dateCreation,
    this.contenu,
    this.boutiqueNom,
  });

  final String publicationId;
  final String? contenu;
  final String? boutiqueNom;
  final DateTime dateCreation;

  factory FavoriPublication.fromJson(Map<String, dynamic> json) {
    final p = json['publication'] as Map<String, dynamic>;
    final boutique = p['boutique'] as Map<String, dynamic>?;
    return FavoriPublication(
      publicationId: p['id'] as String,
      contenu: p['contenu'] as String?,
      boutiqueNom: boutique?['nom'] as String?,
      dateCreation: dateDepuis(p['dateCreation']),
    );
  }
}

final favorisRepositoryProvider = Provider<FavorisRepository>(
  (ref) => FavorisRepository(ref.watch(apiClientProvider)),
);

/// Listes de favoris (profil client). Ajouter ou retirer passe par
/// `interactionsProvider`. 20 par page, fixé par le serveur. Ces listes ne
/// renvoient pas d'URL d'image. Toute erreur est une `ApiException`.
class FavorisRepository {
  FavorisRepository(this._api);

  final ApiClient _api;

  Future<PageResultats<FavoriProduit>> produits(int page) =>
      _api.page('/moi/favoris/produits', FavoriProduit.fromJson, page: page);

  Future<PageResultats<FavoriPublication>> publications(int page) => _api.page(
    '/moi/favoris/publications',
    FavoriPublication.fromJson,
    page: page,
  );
}
