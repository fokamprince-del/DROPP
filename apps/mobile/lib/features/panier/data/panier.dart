import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/modeles/contenu.dart';

class ArticlePanier {
  const ArticlePanier({
    required this.id,
    required this.varianteId,
    required this.quantite,
    required this.prixUnitaire,
    required this.total,
    required this.produitId,
    required this.produitNom,
    required this.boutiqueId,
    required this.boutiqueNom,
    this.varianteNom,
    this.attributs = const {},
    this.prixModifie = false,
    this.disponible = true,
    this.stockDisponible = 0,
  });

  final String id;
  final String varianteId;
  final int quantite;

  /// Prix **actuel** de la variante (recalculé à chaque affichage).
  final num prixUnitaire;
  final num total;

  /// Le prix a changé depuis l'ajout au panier.
  final bool prixModifie;

  /// Faux si le produit n'est plus en vente ou si le stock est insuffisant :
  /// la commande est alors impossible tant que l'article reste au panier.
  final bool disponible;
  final int stockDisponible;
  final String? varianteNom;
  final Map<String, String> attributs;
  final String produitId;
  final String produitNom;
  final String boutiqueId;
  final String boutiqueNom;

  /// « M · Rouge », le nom de la variante, ou `null`.
  String? get descriptionVariante {
    if (attributs.isNotEmpty) return attributs.values.join(' · ');
    return varianteNom;
  }

  factory ArticlePanier.fromJson(Map<String, dynamic> json) {
    final variante = json['variante'] as Map<String, dynamic>? ?? const {};
    final produit = json['produit'] as Map<String, dynamic>;
    final attributs = variante['attributs'];
    return ArticlePanier(
      id: json['id'] as String,
      varianteId: json['varianteProduitId'] as String,
      quantite: (json['quantite'] as num).toInt(),
      prixUnitaire: lireMontant(json['prixUnitaire']),
      total: lireMontant(json['total']),
      prixModifie: json['prixModifie'] as bool? ?? false,
      disponible: json['disponible'] as bool? ?? false,
      stockDisponible: (json['stockDisponible'] as num? ?? 0).toInt(),
      varianteNom: variante['nom'] as String?,
      attributs: attributs is Map
          ? {
              for (final e in attributs.entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {},
      produitId: produit['id'] as String,
      produitNom: produit['nom'] as String,
      boutiqueId: produit['boutiqueId'] as String,
      boutiqueNom: produit['boutiqueNom'] as String? ?? '',
    );
  }
}

class Panier {
  const Panier({
    this.articles = const [],
    this.sousTotal = 0,
    this.commandable = false,
  });

  static const vide = Panier();

  final List<ArticlePanier> articles;

  /// Somme des articles **disponibles**.
  final num sousTotal;

  /// Au moins un article, et tous disponibles.
  final bool commandable;

  int get nombreArticles => articles.fold(0, (s, a) => s + a.quantite);

  /// Articles regroupés par boutique, dans l'ordre d'ajout.
  Map<String, List<ArticlePanier>> get parBoutique {
    final groupes = <String, List<ArticlePanier>>{};
    for (final a in articles) {
      groupes.putIfAbsent(a.boutiqueId, () => []).add(a);
    }
    return groupes;
  }

  factory Panier.fromJson(Map<String, dynamic> json) => Panier(
    articles: (json['articles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ArticlePanier.fromJson)
        .toList(),
    sousTotal: lireMontant(json['sousTotal']),
    commandable: json['commandable'] as bool? ?? false,
  );
}

final panierRepositoryProvider = Provider<PanierRepository>(
  (ref) => PanierRepository(ref.watch(apiClientProvider)),
);

/// Panier actif de l'utilisateur (profil client et téléphone vérifié).
/// Chaque action renvoie le panier complet, prix et disponibilités
/// recalculés. Toute erreur est une `ApiException`.
class PanierRepository {
  PanierRepository(this._api);

  final ApiClient _api;

  /// `GET /panier` : panier vide (`id: null`) s'il n'y en a pas encore.
  Future<Panier> obtenir() async =>
      Panier.fromJson(await _api.get<Map<String, dynamic>>('/panier'));

  /// `POST /panier/articles` : ajoute [quantite] à la quantité déjà au
  /// panier pour cette variante. 400 si le stock est insuffisant (message
  /// avec la quantité disponible), si on dépasse 1 000, ou si c'est son
  /// propre produit ; 404 si la variante n'est plus en vente.
  Future<Panier> ajouter(String varianteId, {int quantite = 1}) async =>
      Panier.fromJson(
        await _api.post<Map<String, dynamic>>(
          '/panier/articles',
          data: {'varianteProduitId': varianteId, 'quantite': quantite},
        ),
      );

  /// `PATCH /panier/articles/:id` : nouvelle quantité (1 à 1 000). Le stock
  /// n'est pas vérifié ici : l'article passe « indisponible » s'il dépasse.
  Future<Panier> modifierQuantite(String articleId, int quantite) async =>
      Panier.fromJson(
        await _api.patch<Map<String, dynamic>>(
          '/panier/articles/$articleId',
          data: {'quantite': quantite},
        ),
      );

  /// `DELETE /panier/articles/:id`.
  Future<Panier> supprimer(String articleId) async => Panier.fromJson(
    await _api.delete<Map<String, dynamic>>('/panier/articles/$articleId'),
  );
}
