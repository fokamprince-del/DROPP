import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../shared/modeles/contenu.dart';

/// Commentaire racine ou réponse (un seul niveau de réponses).
class Commentaire {
  const Commentaire({
    required this.id,
    required this.contenu,
    required this.auteurId,
    required this.auteur,
    required this.dateCreation,
    this.estCreateur = false,
    this.likes = 0,
    this.totalReponses = 0,
    this.reponses = const [],
  });

  final String id;
  final String contenu;
  final String auteurId;

  /// « Prénom Nom ».
  final String auteur;
  final DateTime dateCreation;

  /// Écrit par la boutique qui a publié.
  final bool estCreateur;
  final int likes;

  /// Racine seulement : toutes ses réponses, dont [reponses] est l'aperçu.
  final int totalReponses;
  final List<Commentaire> reponses;

  factory Commentaire.fromJson(Map<String, dynamic> json) {
    final u = json['utilisateur'] as Map<String, dynamic>;
    final nom = [u['prenom'], u['nom']].whereType<String>().join(' ').trim();
    return Commentaire(
      id: json['id'] as String,
      contenu: json['contenu'] as String,
      auteurId: u['id'] as String,
      auteur: nom.isEmpty ? (u['pseudo'] as String? ?? '') : nom,
      dateCreation: dateDepuis(json['dateCreation']),
      estCreateur: json['estCreateur'] as bool? ?? false,
      likes: (json['likes'] as num? ?? 0).toInt(),
      totalReponses: (json['totalReponses'] as num? ?? 0).toInt(),
      reponses: (json['reponses'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Commentaire.fromJson)
          .toList(),
    );
  }
}

final commentairesRepositoryProvider = Provider<CommentairesRepository>(
  (ref) => CommentairesRepository(ref.watch(apiClientProvider)),
);

/// Commentaires d'une publication. La lecture est publique ; écrire,
/// aimer et supprimer exigent un profil client et un téléphone vérifié.
///
/// Les commentaires d'une publication réservée aux abonnés ne sont visibles
/// que des abonnés : sinon 404, comme la publication.
///
/// Toute erreur est une `ApiException`.
class CommentairesRepository {
  CommentairesRepository(this._api);

  final ApiClient _api;

  /// `GET /publications/:id/commentaires` : commentaires racines visibles,
  /// les plus récents d'abord, chacun avec ses trois premières réponses et
  /// `totalReponses`. 20 par page, fixé par le serveur (pas de `limite`).
  /// `likeParMoi` est renvoyé mais l'app utilise `interactionsProvider`.
  Future<PageResultats<Commentaire>> lister(String publicationId, int page) =>
      _api.page(
        '/publications/$publicationId/commentaires',
        Commentaire.fromJson,
        page: page,
      );

  /// `GET /commentaires/:id/reponses` : réponses visibles d'un commentaire
  /// racine, les plus anciennes d'abord, 20 par page.
  Future<PageResultats<Commentaire>> reponses(String commentaireId, int page) =>
      _api.page(
        '/commentaires/$commentaireId/reponses',
        Commentaire.fromJson,
        page: page,
      );

  /// `POST /publications/:id/commentaires` (2 000 caractères max, espaces
  /// retirés aux bouts) → le commentaire créé, sans compteurs (0 j'aime).
  ///
  /// [parentId] : réponse à un commentaire **racine** ; répondre à une
  /// réponse est refusé (400). Les `@pseudo` existants sont notifiés, comme
  /// la boutique et l'auteur du commentaire parent. 403 s'il y a un blocage
  /// entre l'utilisateur et la boutique.
  Future<Commentaire> publier(
    String publicationId,
    String contenu, {
    String? parentId,
  }) async => Commentaire.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/publications/$publicationId/commentaires',
      data: {'contenu': contenu.trim(), 'parentId': ?parentId},
    ),
  );

  /// `DELETE /commentaires/:id` (204) : l'auteur peut supprimer les siens,
  /// la boutique tous ceux de ses publications ; sinon 403. Le commentaire
  /// est masqué (statut `SUPPRIME`), ses réponses disparaissent de la liste.
  Future<void> supprimer(String commentaireId) =>
      _api.delete<Object?>('/commentaires/$commentaireId');
}
