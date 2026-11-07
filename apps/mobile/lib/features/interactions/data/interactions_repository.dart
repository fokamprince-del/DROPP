import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'etats_interactions.dart';

final interactionsRepositoryProvider = Provider<InteractionsRepository>(
  (ref) => InteractionsRepository(ref.watch(apiClientProvider)),
);

/// Plateformes acceptées par `POST /publications/:id/partager` (enum
/// `PlatformePartage` de l'API ; `INSTAGRAM` existe côté serveur mais n'est
/// pas proposé dans l'app).
enum PlateformePartage {
  whatsapp('WHATSAPP'),
  copierLien('COPIER_LIEN'),

  /// Partage dans la messagerie DROPP (module à venir).
  interne('INTERNE');

  const PlateformePartage(this.valeur);

  /// Valeur envoyée dans le corps `{ plateforme }`.
  final String valeur;
}

/// Actions de l'utilisateur sur les contenus des autres : j'aime, favoris,
/// abonnements, partage.
///
/// **Toutes les routes exigent** une session, un profil client actif et un
/// téléphone vérifié (décorateur `@Client()` de l'API). Sans cela : 401
/// (pas de session, géré par l'intercepteur) ou 403
/// ([TypeErreurApi.interdit]).
///
/// **Pas idempotentes côté serveur** : aimer deux fois renvoie 409
/// ([TypeErreurApi.conflit]), retirer un j'aime absent renvoie 404
/// ([TypeErreurApi.introuvable]). C'est `InteractionsNotifier` qui traite
/// ces deux cas comme des réussites ; ne pas appeler ce dépôt directement
/// depuis un écran.
///
/// Un contenu invisible pour l'utilisateur (publication réservée aux abonnés,
/// boutique suspendue, compte bloqué) répond 404.
///
/// Toute erreur est une `ApiException`.
class InteractionsRepository {
  InteractionsRepository(this._api);

  final ApiClient _api;

  /// `GET /moi/etats` : identifiants de tout ce que l'utilisateur a aimé,
  /// mis en favori et suivi, en une requête. Appelé à chaque ouverture de
  /// session.
  Future<EtatsInteractions> etats() async => EtatsInteractions.fromJson(
    await _api.get<Map<String, dynamic>>('/moi/etats'),
  );

  /// `POST /publications/:id/like` → nouveau nombre de j'aime.
  /// 409 si déjà aimée. Notifie la boutique (une fois par personne).
  Future<int> aimerPublication(String id) async =>
      _total(await _api.post<Map<String, dynamic>>('/publications/$id/like'));

  /// `DELETE /publications/:id/like` → nouveau nombre de j'aime.
  /// 404 si elle n'était pas aimée.
  Future<int> nePlusAimerPublication(String id) async =>
      _total(await _api.delete<Map<String, dynamic>>('/publications/$id/like'));

  /// `POST /commentaires/:id/like` → nouveau nombre de j'aime du
  /// commentaire. 409 si déjà aimé, 404 si le commentaire a été supprimé.
  Future<int> aimerCommentaire(String id) async =>
      _total(await _api.post<Map<String, dynamic>>('/commentaires/$id/like'));

  /// `DELETE /commentaires/:id/like` → nouveau nombre de j'aime.
  /// 404 s'il n'était pas aimé.
  Future<int> nePlusAimerCommentaire(String id) async =>
      _total(await _api.delete<Map<String, dynamic>>('/commentaires/$id/like'));

  /// `POST /publications/:id/favori` (réponse `{ publicationId, enFavori }`,
  /// ignorée). 409 si déjà en favori.
  Future<void> ajouterFavoriPublication(String id) =>
      _api.post<Object?>('/publications/$id/favori');

  /// `DELETE /publications/:id/favori`. 404 si elle n'était pas en favori.
  Future<void> retirerFavoriPublication(String id) =>
      _api.delete<Object?>('/publications/$id/favori');

  /// `POST /produits/:id/favori` (réponse `{ produitId, enFavori: true }`,
  /// ignorée). 409 si déjà en favori.
  Future<void> ajouterFavoriProduit(String id) =>
      _api.post<Object?>('/produits/$id/favori');

  /// `DELETE /produits/:id/favori`. 404 s'il n'était pas en favori.
  Future<void> retirerFavoriProduit(String id) =>
      _api.delete<Object?>('/produits/$id/favori');

  /// `POST /vendeurs/:id/suivre` → nouveau nombre d'abonnés.
  ///
  /// La boutique et son vendeur ont le **même identifiant** : passer l'id de
  /// la boutique. 409 si déjà suivie, 400 si c'est sa propre boutique, 404 si
  /// le vendeur n'est pas actif ou s'il y a un blocage entre les deux
  /// comptes. Notifie la boutique.
  Future<int> suivre(String boutiqueId) async => _abonnes(
    await _api.post<Map<String, dynamic>>('/vendeurs/$boutiqueId/suivre'),
  );

  /// `DELETE /vendeurs/:id/suivre` → nouveau nombre d'abonnés.
  /// 404 si elle n'était pas suivie.
  Future<int> nePlusSuivre(String boutiqueId) async => _abonnes(
    await _api.delete<Map<String, dynamic>>('/vendeurs/$boutiqueId/suivre'),
  );

  /// `POST /publications/:id/partager` → lien profond à diffuser
  /// (`dropp://publications/:id`, schéma `app.deepLinkScheme` de l'API).
  ///
  /// Enregistre un partage par personne et par publication (les suivants ne
  /// sont pas recomptés). Le total renvoyé (`partages`) n'est pas affiché
  /// pour l'instant.
  Future<String> partager(
    String publicationId,
    PlateformePartage plateforme,
  ) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/publications/$publicationId/partager',
      data: {'plateforme': plateforme.valeur},
    );
    return json['lienProfond'] as String;
  }

  /// Réponses `{ publicationId | commentaireId, likes }`.
  static int _total(Map<String, dynamic> json) =>
      (json['likes'] as num).toInt();

  /// Réponses `{ vendeurId, abonnes }`.
  static int _abonnes(Map<String, dynamic> json) =>
      (json['abonnes'] as num).toInt();
}
