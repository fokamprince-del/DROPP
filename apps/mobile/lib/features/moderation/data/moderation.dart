import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../shared/modeles/contenu.dart';
import '../../messagerie/data/messagerie.dart';

/// Ce qu'on peut signaler (`typeCible` de l'API).
enum TypeCible {
  publication('PUBLICATION'),
  commentaire('COMMENTAIRE'),
  produit('PRODUIT'),
  boutique('BOUTIQUE'),
  message('MESSAGE');

  const TypeCible(this.valeur);
  final String valeur;

  static TypeCible? depuis(Object? v) {
    for (final t in values) {
      if (t.valeur == v) return t;
    }
    return null;
  }
}

/// Motif proposé par l'API (`SPAM`, `ARNAQUE`, …, `AUTRE`).
class MotifSignalement {
  const MotifSignalement({required this.code, required this.libelle});

  final String code;

  /// Libellé en français fourni par le serveur.
  final String libelle;

  /// `AUTRE` exige une description.
  bool get exigeDescription => code == 'AUTRE';

  factory MotifSignalement.fromJson(Map<String, dynamic> json) =>
      MotifSignalement(
        code: json['code'] as String,
        libelle: json['libelle'] as String,
      );
}

enum StatutSignalement { ouvert, enCours, traite, rejete }

StatutSignalement _statut(Object? v) => switch (v) {
  'EN_COURS' => StatutSignalement.enCours,
  'TRAITE' => StatutSignalement.traite,
  'REJETE' => StatutSignalement.rejete,
  _ => StatutSignalement.ouvert,
};

class Signalement {
  const Signalement({
    required this.id,
    required this.libelleMotif,
    required this.statut,
    required this.dateCreation,
    this.typeCible,
    this.cibleId,
    this.description,
  });

  final String id;
  final String libelleMotif;
  final String? description;
  final StatutSignalement statut;
  final DateTime dateCreation;
  final TypeCible? typeCible;
  final String? cibleId;

  factory Signalement.fromJson(Map<String, dynamic> json) => Signalement(
    id: json['id'] as String,
    libelleMotif:
        json['libelleMotif'] as String? ?? json['motif'] as String? ?? '',
    description: json['description'] as String?,
    statut: _statut(json['statut']),
    dateCreation: dateDepuis(json['dateCreation']),
    typeCible: TypeCible.depuis(json['typeCible']),
    cibleId: json['cibleId'] as String?,
  );
}

/// Utilisateur bloqué (`GET /moi/bloques`).
class UtilisateurBloque {
  const UtilisateurBloque({required this.profil, required this.dateBlocage});

  final Interlocuteur profil;
  final DateTime dateBlocage;

  factory UtilisateurBloque.fromJson(Map<String, dynamic> json) =>
      UtilisateurBloque(
        profil: Interlocuteur.fromJson(json),
        dateBlocage: dateDepuis(json['dateBlocage']),
      );
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.watch(apiClientProvider)),
);

/// Signalements et blocages. Signaler et bloquer exigent un téléphone
/// vérifié. Toute erreur est une `ApiException`.
class ModerationRepository {
  ModerationRepository(this._api);

  final ApiClient _api;

  /// `GET /signalements/motifs` (public).
  Future<List<MotifSignalement>> motifs() async {
    final json = await _api.get<List<dynamic>>('/signalements/motifs');
    return json
        .cast<Map<String, dynamic>>()
        .map(MotifSignalement.fromJson)
        .toList();
  }

  /// `POST /signalements` : la personne signalée ne sait pas qui l'a fait.
  /// [description] obligatoire pour `AUTRE` (1 000 caractères). 409 si déjà
  /// signalé et en cours d'examen, 400 sur son propre contenu, 404 si le
  /// contenu n'existe plus. 10 signalements par minute au plus.
  Future<void> signaler({
    required TypeCible typeCible,
    required String cibleId,
    required String motif,
    String? description,
  }) => _api.post<Object?>(
    '/signalements',
    data: {
      'typeCible': typeCible.valeur,
      'cibleId': cibleId,
      'motif': motif,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    },
  );

  /// `GET /moi/signalements` : les plus récents d'abord.
  Future<PageResultats<Signalement>> mesSignalements(int page) =>
      _api.page('/moi/signalements', Signalement.fromJson, page: page);

  /// `GET /moi/bloques` (non paginé).
  Future<List<UtilisateurBloque>> bloques() async {
    final json = await _api.get<List<dynamic>>('/moi/bloques');
    return json
        .cast<Map<String, dynamic>>()
        .map(UtilisateurBloque.fromJson)
        .toList();
  }

  /// `POST /utilisateurs/:id/bloquer` : plus de messages dans les deux sens,
  /// ni de commentaires sur ses publications, ni d'abonnement. 409 si déjà
  /// bloqué, 400 sur soi-même.
  Future<void> bloquer(String utilisateurId) =>
      _api.post<Object?>('/utilisateurs/$utilisateurId/bloquer');

  /// `DELETE /utilisateurs/:id/bloquer`. 404 s'il n'était pas bloqué.
  Future<void> debloquer(String utilisateurId) =>
      _api.delete<Object?>('/utilisateurs/$utilisateurId/bloquer');
}

final motifsSignalementProvider = FutureProvider<List<MotifSignalement>>(
  (ref) => ref.watch(moderationRepositoryProvider).motifs(),
);

final bloquesProvider = FutureProvider.autoDispose<List<UtilisateurBloque>>(
  (ref) => ref.watch(moderationRepositoryProvider).bloques(),
);
