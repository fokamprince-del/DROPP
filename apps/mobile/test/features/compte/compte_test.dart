import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:dropp/core/temps_reel/temps_reel.dart';
import 'package:dropp/features/auth/data/modeles_auth.dart';
import 'package:dropp/features/interactions/application/interactions.dart';
import 'package:dropp/features/interactions/data/favoris.dart';
import 'package:dropp/features/messagerie/application/non_lus.dart';
import 'package:dropp/features/moderation/data/moderation.dart';
import 'package:dropp/features/notifications/application/compteur.dart';
import 'package:dropp/features/notifications/data/notifications.dart';
import 'package:dropp/features/profil/data/profil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../achat/achat_test.dart' show FauxApi, awa;

/// Temps réel sans connexion : les tests injectent les événements.
TempsReel tempsReelFactice() =>
    TempsReel(lireJeton: () async => null, renouvelerJeton: () async => null);

ProviderContainer conteneur(FauxApi api, TempsReel tempsReel) {
  final c = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      utilisateurConnecteProvider.overrideWithValue(awa),
      tempsReelProvider.overrideWithValue(tempsReel),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Temps réel', () {
    test(
      'un message reçu d’un autre incrémente les non-lus, pas le sien',
      () async {
        final tr = tempsReelFactice();
        final c = conteneur(FauxApi((_, _) => {'nonLus': 2}), tr);
        expect(await c.read(nonLusProvider.future), 2);

        tr.simuler(EvenementsTempsReel.messageNouveau, {'expediteurId': 'b1'});
        tr.simuler(EvenementsTempsReel.messageNouveau, {
          'expediteurId': awa.id,
        });
        await pumpEventQueue();
        expect(c.read(nombreMessagesNonLusProvider), 3);
      },
    );

    test('compteur de notifications : +1 à l’arrivée, total du serveur '
        'après une lecture', () async {
      final tr = tempsReelFactice();
      final c = conteneur(FauxApi((_, _) => {'nonLues': 4}), tr);
      expect(await c.read(compteurNotificationsProvider.future), 4);

      tr.simuler(EvenementsTempsReel.notificationNouvelle, {'id': 'n9'});
      await pumpEventQueue();
      expect(c.read(compteurNotificationsProvider).value, 5);

      tr.simuler(EvenementsTempsReel.notificationsCompteur, {'nonLues': 0});
      await pumpEventQueue();
      expect(c.read(compteurNotificationsProvider).value, 0);
    });
  });

  group('Notifications', () {
    Map<String, dynamic> notification(Map<String, dynamic> donnees) => {
      'id': 'n1',
      'type': 'COMMANDE',
      'titre': 'Commande enregistrée',
      'contenu': 'Finalisez le paiement…',
      'donnees': donnees,
      'estLu': false,
      'dateCreation': '2026-10-26T10:00:00.000Z',
    };

    test('destination selon les données liées', () {
      expect(
        NotificationApp.fromJson(notification({'commandeId': 'c1'}))
            .destination,
        Routes.commande('c1'),
      );
      expect(
        NotificationApp.fromJson(
          notification({'conversationId': 'cv1', 'messageId': 'm1'}),
        ).destination,
        Routes.conversation('cv1'),
      );
      expect(
        NotificationApp.fromJson(notification({'utilisateurId': 'u2'}))
            .destination,
        isNull,
      );
      expect(
        NotificationApp.fromJson(notification({})).type,
        TypeNotification.commande,
      );
    });

    test('routes et préférences', () async {
      final api = FauxApi(
        (m, chemin) => switch (chemin) {
          '/notifications/preferences' => [
            {'type': 'MESSAGE', 'active': true},
            {'type': 'PROMOTION', 'active': false},
          ],
          _ => {'nonLues': 0},
        },
      );
      final depot = NotificationsRepository(api);

      expect(await depot.marquerLue('n1'), 0);
      expect(await depot.toutLire(), 0);
      final prefs = await depot.modifierPreference(
        TypeNotification.promotion,
        active: false,
      );
      expect(api.dernierCorps, {
        'preferences': [
          {'type': 'PROMOTION', 'active': false},
        ],
      });
      expect(prefs[TypeNotification.promotion], isFalse);
      expect(api.appels, [
        'PATCH /notifications/n1/lue',
        'POST /notifications/tout-lire',
        'PUT /notifications/preferences',
      ]);
    });
  });

  group('Modération', () {
    test('signaler : description seulement si fournie', () async {
      final api = FauxApi((_, _) => null);
      await ModerationRepository(api).signaler(
        typeCible: TypeCible.commentaire,
        cibleId: 'c1',
        motif: 'SPAM',
        description: '  ',
      );
      expect(api.dernierCorps, {
        'typeCible': 'COMMENTAIRE',
        'cibleId': 'c1',
        'motif': 'SPAM',
      });
    });

    test('mes signalements et bloqués', () async {
      final api = FauxApi(
        (_, chemin) => switch (chemin) {
          '/moi/signalements' => {
            'donnees': [
              {
                'id': 's1',
                'motif': 'ARNAQUE',
                'libelleMotif': 'Arnaque ou fraude',
                'statut': 'EN_COURS',
                'dateCreation': '2026-10-20T10:00:00.000Z',
                'typeCible': 'PRODUIT',
                'cibleId': 'p1',
              },
            ],
            'pagination': {'total': 1, 'page': 1, 'limite': 20, 'pages': 1},
          },
          _ => [
            {
              'id': 'u2',
              'prenom': 'Paul',
              'nom': 'Etoa',
              'photoProfilUrl': null,
              'boutique': null,
              'dateBlocage': '2026-10-21T10:00:00.000Z',
            },
          ],
        },
      );
      final depot = ModerationRepository(api);
      final s = (await depot.mesSignalements(1)).donnees.single;
      expect(s.statut, StatutSignalement.enCours);
      expect(s.typeCible, TypeCible.produit);
      final b = (await depot.bloques()).single;
      expect(b.profil.nomAffiche, 'Paul Etoa');

      await depot.debloquer('u2');
      expect(api.appels.last, 'DELETE /utilisateurs/u2/bloquer');
    });
  });

  group('Profil et sécurité', () {
    test('lit le profil complet, boutique comprise', () {
      final p = ProfilComplet.fromJson({
        'id': 'u1',
        'prenom': 'Awa',
        'nom': 'Ngo',
        'pseudo': 'awa.wax',
        'email': null,
        'telephone': '+237670000001',
        'photoProfilUrl': 'https://cdn/p.jpg',
        'sexe': 'FEMININ',
        'dateInscription': '2026-09-01T10:00:00.000Z',
        'vendeur': {
          'statutVendeur': 'ACTIF',
          'boutique': {'id': 'u1', 'nom': 'Awa Wax', 'statut': 'ACTIVE'},
        },
      });
      expect(p.nomComplet, 'Awa Ngo');
      expect(p.sexe, Sexe.feminin);
      expect(p.boutiqueNom, 'Awa Wax');
    });

    test(
      'modifier n’envoie que les champs changés, pseudo normalisé',
      () async {
        final api = FauxApi(
          (_, _) => {
            'id': 'u1',
            'prenom': 'Awa',
            'nom': 'Ngo',
            'dateInscription': '2026-09-01T10:00:00.000Z',
          },
        );
        await ProfilRepository(api).modifier(pseudo: ' @Awa_Wax ');
        expect(api.dernierCorps, {'pseudo': 'awa_wax'});
        expect(normaliserPseudo('@Awa.Wax'), 'awa.wax');
        expect(formatPseudo.hasMatch('ab'), isFalse);
        expect(formatPseudo.hasMatch('awa_wax'), isTrue);
      },
    );

    test('sessions : appareil et session actuelle', () async {
      final api = FauxApi(
        (_, _) => [
          {
            'id': 's1',
            'methodeAuth': 'MOT_DE_PASSE',
            'adresseIpCreation': '1.2.3.4',
            'dateCreation': '2026-10-20T10:00:00.000Z',
            'dateDerniereUtilisation': null,
            'dateExpiration': '2026-11-20T10:00:00.000Z',
            'appareil': {'plateforme': 'ANDROID', 'modele': 'Tecno Spark'},
            'actuelle': true,
          },
        ],
      );
      final s = (await ProfilRepository(api).sessions()).single;
      expect(s.actuelle, isTrue);
      expect(s.modele, 'Tecno Spark');
      expect(s.derniereUtilisation, isNull);
    });

    test('changer de mot de passe renvoie de nouveaux jetons', () async {
      final api = FauxApi(
        (_, _) => {'accessToken': 'a2', 'refreshToken': 'r2', 'expiresIn': 900},
      );
      final jetons = await ProfilRepository(api)
          .changerMotDePasse(ancien: 'ancien1', nouveau: 'nouveau22');
      expect(api.dernierCorps, {
        'ancienMotDePasse': 'ancien1',
        'nouveauMotDePasse': 'nouveau22',
      });
      expect(jetons.accessToken, 'a2');
    });
  });

  group('Favoris', () {
    test('lit les favoris produits (prix Decimal en chaîne)', () async {
      final api = FauxApi(
        (_, _) => {
          'donnees': [
            {
              'dateCreation': '2026-10-26T10:00:00.000Z',
              'produit': {
                'id': 'p1',
                'nom': 'Robe Kaba',
                'prixBase': '25000',
                'statut': 'ARCHIVE',
                'boutique': {'id': 'b1', 'nom': 'Awa Wax'},
                'medias': <Object>[],
              },
            },
          ],
          'pagination': {'total': 1, 'page': 1, 'limite': 20, 'pages': 1},
        },
      );
      final f = (await FavorisRepository(api).produits(1)).donnees.single;
      expect(f.prix, 25000);
      expect(f.enVente, isFalse);
      expect(f.boutiqueNom, 'Awa Wax');
    });

    test('depuis « Mes favoris », retirer même si les états ne sont pas '
        'chargés', () async {
      final api = FauxApi(
        (m, chemin) => chemin == '/moi/etats' ? <String, dynamic>{} : null,
      );
      final c = conteneur(api, tempsReelFactice());
      await c
          .read(interactionsProvider.notifier)
          .basculerFavoriProduit('p1', estFavori: true);
      expect(api.appels, contains('DELETE /produits/p1/favori'));
      expect(c.read(interactionsProvider).favorisProduits, isEmpty);
    });
  });
}
