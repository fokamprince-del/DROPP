import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/utilisateur.dart';
import 'package:dropp/features/interactions/application/interactions.dart';
import 'package:dropp/features/interactions/data/etats_interactions.dart';
import 'package:dropp/features/interactions/data/interactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _awa = Utilisateur(
  id: 'u1',
  prenom: 'Awa',
  nom: 'Ngo',
  email: null,
  emailVerifie: false,
  telephone: '+237670000001',
  telephoneVerifie: true,
  statutCompte: 'ACTIF',
  estClient: true,
  estVendeur: false,
  statutVendeur: null,
);

ApiException _erreur(TypeErreurApi type) =>
    ApiException(type: type, message: 'x');

/// Répond comme le serveur ; `reponse` permet de retarder ou d'échouer.
class _FauxDepot extends InteractionsRepository {
  _FauxDepot() : super(ApiClient(Dio()));

  EtatsInteractions etatsInitiaux = const EtatsInteractions();
  Future<int> Function()? reponse;
  final appels = <String>[];

  @override
  Future<EtatsInteractions> etats() async => etatsInitiaux;

  Future<int> _repondre(String appel, int defaut) {
    appels.add(appel);
    return reponse?.call() ?? Future.value(defaut);
  }

  @override
  Future<int> aimerPublication(String id) => _repondre('like $id', 11);

  @override
  Future<int> nePlusAimerPublication(String id) => _repondre('unlike $id', 9);

  @override
  Future<int> suivre(String boutiqueId) => _repondre('suivre $boutiqueId', 51);

  @override
  Future<void> ajouterFavoriProduit(String id) async =>
      _repondre('favori $id', 0);
}

/// `/moi/etats` répond quand le test le décide.
class _FauxDepotLent extends _FauxDepot {
  _FauxDepotLent(this._etats);

  final Future<EtatsInteractions> _etats;

  @override
  Future<EtatsInteractions> etats() => _etats;
}

ProviderContainer _conteneur(_FauxDepot depot, {Utilisateur? utilisateur}) {
  final c = ProviderContainer(
    overrides: [
      interactionsRepositoryProvider.overrideWithValue(depot),
      utilisateurConnecteProvider.overrideWithValue(utilisateur),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('connecté : les états de /moi/etats sont chargés', () async {
    final depot = _FauxDepot()
      ..etatsInitiaux = EtatsInteractions.fromJson(const {
        'likesPublications': ['p1'],
        'abonnements': ['b1'],
      });
    final c = _conteneur(depot, utilisateur: _awa);
    c.read(interactionsProvider);
    await pumpEventQueue();

    expect(c.read(interactionsProvider).likesPublications, {'p1'});
    expect(c.read(interactionsProvider).abonnements, {'b1'});
  });

  test(
    'un j\'aime s\'affiche tout de suite, puis prend le total du serveur',
    () async {
      final attente = Completer<int>();
      final depot = _FauxDepot()..reponse = () => attente.future;
      final c = _conteneur(depot, utilisateur: _awa);
      final notifier = c.read(interactionsProvider.notifier);

      final action = notifier.basculerLikePublication('p1', 9);
      expect(c.read(interactionsProvider).likesPublications, {'p1'});
      expect(c.read(interactionsProvider).likesPublication('p1', 9), 10);

      attente.complete(42);
      await action;
      expect(c.read(interactionsProvider).likesPublication('p1', 9), 42);
      expect(depot.appels, ['like p1']);
    },
  );

  test(
    'un refus du serveur annule l\'affichage et remonte l\'erreur',
    () async {
      final depot = _FauxDepot()
        ..reponse = () => Future.error(_erreur(TypeErreurApi.interdit));
      final c = _conteneur(depot, utilisateur: _awa);

      await expectLater(
        c.read(interactionsProvider.notifier).basculerLikePublication('p1', 9),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(interactionsProvider).likesPublications, isEmpty);
      expect(c.read(interactionsProvider).likesPublication('p1', 9), 9);
    },
  );

  test(
    'une action faite avant l\'arrivée des états n\'est pas effacée',
    () async {
      final etats = Completer<EtatsInteractions>();
      final depot = _FauxDepotLent(etats.future);
      final c = _conteneur(depot, utilisateur: _awa);

      await c
          .read(interactionsProvider.notifier)
          .basculerLikePublication('p1', 0);
      etats.complete(
        EtatsInteractions.fromJson(const {
          'likesPublications': ['p2'],
        }),
      );
      await pumpEventQueue();

      expect(c.read(interactionsProvider).likesPublications, {'p1', 'p2'});
      expect(c.read(interactionsProvider).likesPublication('p1', 0), 11);
    },
  );

  test('« déjà aimé » (409) garde l\'état affiché sans erreur', () async {
    final depot = _FauxDepot()
      ..reponse = () => Future.error(_erreur(TypeErreurApi.conflit));
    final c = _conteneur(depot, utilisateur: _awa);

    await c
        .read(interactionsProvider.notifier)
        .basculerLikePublication('p1', 9);
    expect(c.read(interactionsProvider).likesPublications, {'p1'});
  });

  test('un double appui pendant la requête est ignoré', () async {
    final attente = Completer<int>();
    final depot = _FauxDepot()..reponse = () => attente.future;
    final c = _conteneur(depot, utilisateur: _awa);
    final notifier = c.read(interactionsProvider.notifier);

    final premier = notifier.basculerLikePublication('p1', 9);
    await notifier.basculerLikePublication('p1', 10);
    attente.complete(10);
    await premier;

    expect(depot.appels, ['like p1']);
    expect(c.read(interactionsProvider).likesPublications, {'p1'});
  });

  test('suivre met à jour l\'abonnement et le nombre d\'abonnés', () async {
    final depot = _FauxDepot();
    final c = _conteneur(depot, utilisateur: _awa);

    await c.read(interactionsProvider.notifier).basculerAbonnement('b1', 50);
    expect(c.read(interactionsProvider).abonnements, {'b1'});
    expect(c.read(interactionsProvider).abonnes('b1', 50), 51);
  });

  test('favori produit : bascule sans compteur', () async {
    final depot = _FauxDepot();
    final c = _conteneur(depot, utilisateur: _awa);

    await c.read(interactionsProvider.notifier).basculerFavoriProduit('pr1');
    expect(c.read(interactionsProvider).favorisProduits, {'pr1'});
    expect(depot.appels, ['favori pr1']);
  });

  test('synchroniserAbonnement aligne l\'état sans requête', () {
    final depot = _FauxDepot();
    final c = _conteneur(depot, utilisateur: _awa);

    c
        .read(interactionsProvider.notifier)
        .synchroniserAbonnement('b1', suivie: true);
    expect(c.read(interactionsProvider).abonnements, {'b1'});
    expect(depot.appels, isEmpty);
  });

  test('commentaires publiés ou supprimés ajustent le compteur', () {
    final c = _conteneur(_FauxDepot(), utilisateur: _awa);
    final notifier = c.read(interactionsProvider.notifier)
      ..noterCommentaire('p1', 1)
      ..noterCommentaire('p1', 1)
      ..noterCommentaire('p1', -1);
    expect(notifier, isNotNull);
    expect(c.read(interactionsProvider).commentaires('p1', 12), 13);
  });
}
