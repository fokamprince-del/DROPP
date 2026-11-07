import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../core/router/routes.dart';
import '../../../shared/modeles/contenu.dart';

enum TypeNotification {
  commande('COMMANDE'),
  paiement('PAIEMENT'),
  message('MESSAGE'),
  social('SOCIAL'),
  promotion('PROMOTION'),
  systeme('SYSTEME'),
  securite('SECURITE');

  const TypeNotification(this.valeur);
  final String valeur;

  static TypeNotification depuis(Object? v) => TypeNotification.values
      .firstWhere((t) => t.valeur == v, orElse: () => systeme);
}

class NotificationApp {
  const NotificationApp({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.dateCreation,
    this.donnees = const {},
    this.lue = false,
  });

  final String id;
  final TypeNotification type;
  final String titre;
  final String contenu;

  /// Identifiants liés : `commandeId`, `conversationId`, `publicationId`,
  /// `produitId`…
  final Map<String, dynamic> donnees;
  final bool lue;
  final DateTime dateCreation;

  NotificationApp copierLue() => NotificationApp(
    id: id,
    type: type,
    titre: titre,
    contenu: contenu,
    dateCreation: dateCreation,
    donnees: donnees,
    lue: true,
  );

  /// Écran à ouvrir au toucher, ou `null`.
  String? get destination {
    String? id(String cle) =>
        donnees[cle] is String ? donnees[cle] as String : null;
    if (id('conversationId') case final c?) return Routes.conversation(c);
    if (id('commandeId') case final c?) return Routes.commande(c);
    if (id('publicationId') case final p?) return Routes.publication(p);
    if (id('produitId') case final p?) return Routes.produit(p);
    return null;
  }

  factory NotificationApp.fromJson(Map<String, dynamic> json) =>
      NotificationApp(
        id: json['id'] as String,
        type: TypeNotification.depuis(json['type']),
        titre: json['titre'] as String? ?? '',
        contenu: json['contenu'] as String? ?? '',
        donnees: json['donnees'] is Map
            ? Map<String, dynamic>.from(json['donnees'] as Map)
            : const {},
        lue: json['estLu'] as bool? ?? false,
        dateCreation: dateDepuis(json['dateCreation']),
      );
}

/// Types dont on peut couper les push (les autres sont toujours envoyés).
const typesConfigurables = [
  TypeNotification.message,
  TypeNotification.social,
  TypeNotification.promotion,
];

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

/// Notifications de l'utilisateur (session requise). Toute erreur est une
/// `ApiException`.
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  /// `GET /notifications` : les plus récentes d'abord ; [nonLues] pour ne
  /// garder que celles-là. La réponse porte aussi le total non lu (`brut`).
  Future<PageResultats<NotificationApp>> lister(
    int page, {
    bool nonLues = false,
  }) => _api.page(
    '/notifications',
    NotificationApp.fromJson,
    page: page,
    query: {if (nonLues) 'nonLues': 'true'},
  );

  /// `GET /notifications/compteur`.
  Future<int> compteur() async =>
      _nonLues(await _api.get<Map<String, dynamic>>('/notifications/compteur'));

  /// `PATCH /notifications/:id/lue` → nouveau total non lu.
  Future<int> marquerLue(String id) async => _nonLues(
    await _api.patch<Map<String, dynamic>>('/notifications/$id/lue'),
  );

  /// `POST /notifications/tout-lire` → nouveau total (0).
  Future<int> toutLire() async => _nonLues(
    await _api.post<Map<String, dynamic>>('/notifications/tout-lire'),
  );

  /// `DELETE /notifications/:id` (204).
  Future<void> supprimer(String id) =>
      _api.delete<Object?>('/notifications/$id');

  /// `GET /notifications/preferences` : un booléen par type configurable
  /// (activé par défaut). Une préférence coupe le **push**, pas la
  /// notification dans l'app.
  Future<Map<TypeNotification, bool>> preferences() async =>
      _preferences(await _api.get<List<dynamic>>('/notifications/preferences'));

  /// `PUT /notifications/preferences` → toutes les préférences à jour.
  Future<Map<TypeNotification, bool>> modifierPreference(
    TypeNotification type, {
    required bool active,
  }) async => _preferences(
    await _api.put<List<dynamic>>(
      '/notifications/preferences',
      data: {
        'preferences': [
          {'type': type.valeur, 'active': active},
        ],
      },
    ),
  );

  static int _nonLues(Map<String, dynamic> json) =>
      (json['nonLues'] as num? ?? 0).toInt();

  static Map<TypeNotification, bool> _preferences(List<dynamic> json) => {
    for (final p in json.cast<Map<String, dynamic>>())
      TypeNotification.depuis(p['type']): p['active'] as bool? ?? true,
  };
}
