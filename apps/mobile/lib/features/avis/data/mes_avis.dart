import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/modeles/contenu.dart';
import '../../commandes/data/commandes.dart';

/// Article livré pas encore noté (`GET /moi/avis/a-noter`).
class ArticleANoter {
  const ArticleANoter({
    required this.ligneId,
    required this.nomProduit,
    required this.dateCommande,
    this.produitId,
    this.variante,
  });

  /// Ligne de sous-commande : c'est elle qui est notée.
  final String ligneId;
  final String? produitId;
  final String nomProduit;
  final String? variante;
  final DateTime dateCommande;

  factory ArticleANoter.fromJson(Map<String, dynamic> json) => ArticleANoter(
    ligneId: json['ligneSousCommandeId'] as String,
    produitId: json['produitId'] as String?,
    nomProduit: json['nomProduit'] as String? ?? '',
    variante: descriptionVariante(json['variante']),
    dateCommande: dateDepuis(json['dateCommande']),
  );
}

final mesAvisRepositoryProvider = Provider<MesAvisRepository>(
  (ref) => MesAvisRepository(ref.watch(apiClientProvider)),
);

/// Avis laissés par le client (profil client et téléphone vérifié). Un avis
/// porte sur un article **livré** ; il est modifiable et supprimable pendant
/// 30 jours (403 ensuite). Il n'existe pas de route « mes avis » : un avis
/// déjà donné se retrouve sur la fiche du produit. Toute erreur est une
/// `ApiException`.
class MesAvisRepository {
  MesAvisRepository(this._api);

  final ApiClient _api;

  /// `GET /moi/avis/a-noter` (non paginé, 50 au plus) : articles livrés
  /// sans avis, du plus récent au plus ancien.
  Future<List<ArticleANoter>> aNoter() async {
    final json = await _api.get<List<dynamic>>('/moi/avis/a-noter');
    return json
        .cast<Map<String, dynamic>>()
        .map(ArticleANoter.fromJson)
        .toList();
  }

  /// `POST /avis` : note de 1 à 5, commentaire facultatif (2 000 caractères).
  /// 403 si l'article n'est pas encore livré, 409 s'il a déjà un avis.
  Future<void> creer({
    required String ligneId,
    required int note,
    String? commentaire,
  }) => _api.post<Object?>(
    '/avis',
    data: {
      'ligneSousCommandeId': ligneId,
      'note': note,
      if (commentaire != null && commentaire.trim().isNotEmpty)
        'commentaire': commentaire.trim(),
    },
  );

  /// `PATCH /avis/:id` : 403 après 30 jours, 404 si ce n'est pas le sien.
  Future<void> modifier(
    String avisId, {
    required int note,
    String? commentaire,
  }) => _api.patch<Object?>(
    '/avis/$avisId',
    data: {
      'note': note,
      if (commentaire != null && commentaire.trim().isNotEmpty)
        'commentaire': commentaire.trim(),
    },
  );

  /// `DELETE /avis/:id` (204) : mêmes conditions que la modification.
  Future<void> supprimer(String avisId) =>
      _api.delete<Object?>('/avis/$avisId');
}

final articlesANoterProvider = FutureProvider.autoDispose<List<ArticleANoter>>(
  (ref) => ref.watch(mesAvisRepositoryProvider).aNoter(),
);
