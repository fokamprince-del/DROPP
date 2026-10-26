import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../data/etats_interactions.dart';
import '../data/interactions_repository.dart';

final interactionsProvider =
    NotifierProvider<InteractionsNotifier, EtatsInteractions>(
      InteractionsNotifier.new,
    );

/// Likes, favoris et abonnements de l'utilisateur connecté, partagés par
/// tous les écrans. Chargés depuis `GET /moi/etats` à la connexion, vides
/// pour un visiteur.
///
/// Chaque action s'affiche tout de suite (mise à jour optimiste), puis est
/// annulée si le serveur refuse ; l'erreur est relancée pour que l'écran
/// l'affiche.
class InteractionsNotifier extends Notifier<EtatsInteractions> {
  InteractionsRepository get _depot => ref.read(interactionsRepositoryProvider);

  /// Une seule requête à la fois par élément : un double appui est ignoré.
  final _enCours = <String>{};

  /// Changements faits pendant le chargement de `/moi/etats` : rejoués sur
  /// les états reçus pour ne pas effacer un j'aime donné entre-temps.
  /// `null` une fois chargé (ou pour un visiteur).
  List<EtatsInteractions Function(EtatsInteractions)>? _enAttente;

  /// Incrémenté à chaque changement de session : un chargement d'avant est
  /// ignoré.
  int _generation = 0;

  @override
  EtatsInteractions build() {
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    _generation++;
    _enAttente = null;
    if (utilisateur != null) {
      _enAttente = [];
      unawaited(_charger(_generation));
    }
    return const EtatsInteractions();
  }

  Future<void> _charger(int generation) async {
    try {
      final etats = await _depot.etats();
      if (!ref.mounted || generation != _generation) return;
      final correctifs = _enAttente ?? const [];
      _enAttente = null;
      state = correctifs.fold(etats, (e, corriger) => corriger(e));
    } on ApiException {
      // Sans les états, tout s'affiche « non aimé » ; les actions restent
      // possibles et le serveur tranche.
      if (generation == _generation) _enAttente = null;
    }
  }

  void _modifier(EtatsInteractions Function(EtatsInteractions) changement) {
    state = changement(state);
    _enAttente?.add(changement);
  }

  Future<void> basculerLikePublication(String id, int affiches) {
    final avant = state.likesPublications.contains(id);
    return _basculer(
      cle: 'like:$id',
      avant: avant,
      appliquer: (e, aime) => e.copyWith(
        likesPublications: avecOuSans(e.likesPublications, id, present: aime),
        likesParPublication: {
          ...e.likesParPublication,
          id: _compteur(affiches, avant: avant, apres: aime),
        },
      ),
      envoyer: (aime) => aime
          ? _depot.aimerPublication(id)
          : _depot.nePlusAimerPublication(id),
      total: (e, total) => e.copyWith(
        likesParPublication: {...e.likesParPublication, id: total},
      ),
    );
  }

  Future<void> basculerLikeCommentaire(String id, int affiches) {
    final avant = state.likesCommentaires.contains(id);
    return _basculer(
      cle: 'like-commentaire:$id',
      avant: avant,
      appliquer: (e, aime) => e.copyWith(
        likesCommentaires: avecOuSans(e.likesCommentaires, id, present: aime),
        likesParCommentaire: {
          ...e.likesParCommentaire,
          id: _compteur(affiches, avant: avant, apres: aime),
        },
      ),
      envoyer: (aime) => aime
          ? _depot.aimerCommentaire(id)
          : _depot.nePlusAimerCommentaire(id),
      total: (e, total) => e.copyWith(
        likesParCommentaire: {...e.likesParCommentaire, id: total},
      ),
    );
  }

  /// [estFavori] : état connu de l'écran (« Mes favoris »), prioritaire sur
  /// les états pas encore chargés.
  Future<void> basculerFavoriPublication(String id, {bool? estFavori}) =>
      _basculer(
        cle: 'favori-publication:$id',
        avant: estFavori ?? state.favorisPublications.contains(id),
        appliquer: (e, favori) => e.copyWith(
          favorisPublications: avecOuSans(
            e.favorisPublications,
            id,
            present: favori,
          ),
        ),
        envoyer: (favori) async {
          await (favori
              ? _depot.ajouterFavoriPublication(id)
              : _depot.retirerFavoriPublication(id));
          return null;
        },
      );

  /// [estFavori] : voir [basculerFavoriPublication].
  Future<void> basculerFavoriProduit(String id, {bool? estFavori}) => _basculer(
    cle: 'favori-produit:$id',
    avant: estFavori ?? state.favorisProduits.contains(id),
    appliquer: (e, favori) => e.copyWith(
      favorisProduits: avecOuSans(e.favorisProduits, id, present: favori),
    ),
    envoyer: (favori) async {
      await (favori
          ? _depot.ajouterFavoriProduit(id)
          : _depot.retirerFavoriProduit(id));
      return null;
    },
  );

  /// [affiches] : nombre d'abonnés affiché avant l'appui.
  Future<void> basculerAbonnement(String boutiqueId, int affiches) {
    final avant = state.abonnements.contains(boutiqueId);
    return _basculer(
      cle: 'abonnement:$boutiqueId',
      avant: avant,
      appliquer: (e, suivie) => e.copyWith(
        abonnements: avecOuSans(e.abonnements, boutiqueId, present: suivie),
        abonnesParBoutique: {
          ...e.abonnesParBoutique,
          boutiqueId: _compteur(affiches, avant: avant, apres: suivie),
        },
      ),
      envoyer: (suivie) =>
          suivie ? _depot.suivre(boutiqueId) : _depot.nePlusSuivre(boutiqueId),
      total: (e, total) => e.copyWith(
        abonnesParBoutique: {...e.abonnesParBoutique, boutiqueId: total},
      ),
    );
  }

  /// Aligne l'état local sur ce que dit une page boutique, sans requête
  /// (états pas encore chargés, abonnement pris sur un autre appareil).
  void synchroniserAbonnement(String boutiqueId, {required bool suivie}) {
    if (_enCours.contains('abonnement:$boutiqueId')) return;
    if (state.abonnements.contains(boutiqueId) == suivie) return;
    _modifier(
      (e) => e.copyWith(
        abonnements: avecOuSans(e.abonnements, boutiqueId, present: suivie),
      ),
    );
  }

  /// Commentaire publié (+1) ou supprimé (-1) depuis cet appareil.
  void noterCommentaire(String publicationId, int variation) {
    _modifier(
      (e) => e.copyWith(
        commentairesAjoutes: {
          ...e.commentairesAjoutes,
          publicationId:
              (e.commentairesAjoutes[publicationId] ?? 0) + variation,
        },
      ),
    );
  }

  static int _compteur(
    int affiches, {
    required bool avant,
    required bool apres,
  }) {
    if (avant == apres) return affiches;
    return apres ? affiches + 1 : (affiches - 1).clamp(0, affiches);
  }

  Future<void> _basculer({
    required String cle,
    required bool avant,
    required EtatsInteractions Function(EtatsInteractions, bool) appliquer,
    required Future<int?> Function(bool) envoyer,
    EtatsInteractions Function(EtatsInteractions, int)? total,
  }) async {
    if (!_enCours.add(cle)) return;
    final apres = !avant;
    _modifier((e) => appliquer(e, apres));
    try {
      final nouveauTotal = await envoyer(apres);
      if (nouveauTotal != null && total != null && ref.mounted) {
        _modifier((e) => total(e, nouveauTotal));
      }
    } on ApiException catch (e) {
      // Déjà dans l'état voulu côté serveur (autre appareil, état pas encore
      // chargé) : on garde l'affichage.
      final dejaFait = apres
          ? e.type == TypeErreurApi.conflit
          : e.type == TypeErreurApi.introuvable;
      if (dejaFait) return;
      if (ref.mounted) _modifier((e) => appliquer(e, avant));
      rethrow;
    } finally {
      _enCours.remove(cle);
    }
  }
}
