import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/utilisateur.dart';
import 'package:dropp/features/adresses/data/adresses.dart';
import 'package:dropp/features/avis/data/mes_avis.dart';
import 'package:dropp/features/commandes/data/commandes.dart';
import 'package:dropp/features/panier/application/panier.dart';
import 'package:dropp/features/panier/data/panier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const awa = Utilisateur(
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

/// Forme exacte de `PanierService.formater` côté API.
Map<String, dynamic> panierJson({bool disponible = true, int quantite = 2}) => {
  'id': 'pa1',
  'statut': 'ACTIF',
  'articles': [
    {
      'id': 'a1',
      'varianteProduitId': 'v1',
      'quantite': quantite,
      'prixUnitaire': 25000,
      'prixModifie': false,
      'total': 25000 * quantite,
      'disponible': disponible,
      'stockDisponible': 5,
      'variante': {
        'id': 'v1',
        'sku': 'K-M',
        'nom': null,
        'attributs': {'taille': 'M', 'couleur': 'Rouge'},
      },
      'produit': {
        'id': 'p1',
        'nom': 'Robe Kaba',
        'boutiqueId': 'b1',
        'boutiqueNom': 'Awa Wax',
      },
    },
    {
      'id': 'a2',
      'varianteProduitId': 'v9',
      'quantite': 1,
      'prixUnitaire': 12500,
      'prixModifie': true,
      'total': 12500,
      'disponible': true,
      'stockDisponible': 3,
      'variante': {
        'id': 'v9',
        'nom': 'Taille unique',
        'attributs': <String, String>{},
      },
      'produit': {
        'id': 'p9',
        'nom': 'Collier',
        'boutiqueId': 'b2',
        'boutiqueNom': 'Kribi Perles',
      },
    },
  ],
  'sousTotal': disponible ? 50000 + 12500 : 12500,
  'devise': 'XAF',
  'commandable': disponible,
};

/// Forme de `CommandeService.presenter` (+ paiement / livraison).
Map<String, dynamic> commandeJson({String statut = 'EN_ATTENTE_PAIEMENT'}) => {
  'id': 'c1',
  'statut': statut,
  'montantTotal': 62500,
  'devise': 'XAF',
  'dateCreation': '2026-10-26T10:00:00.000Z',
  'sousCommandes': [
    {
      'id': 'sc1',
      'vendeurId': 'b1',
      'statut': statut,
      'sousTotal': 50000,
      'montantTotal': 50000,
      'boutiqueNom': 'Awa Wax',
      'lignes': [
        {
          'id': 'l1',
          'produitId': 'p1',
          'nomProduitSnapshot': 'Robe Kaba',
          'quantite': 2,
          'prixUnitaire': 25000,
          'varianteSnapshot': {
            'id': 'v1',
            'nom': null,
            'attributs': {'taille': 'M'},
          },
        },
      ],
    },
  ],
  'paiement': {'statut': 'NON_CONFIGURE'},
  'livraison': {'statut': 'A_DEFINIR'},
};

class FauxApi extends ApiClient {
  FauxApi(this.reponse) : super(Dio());

  Object? Function(String methode, String chemin)? reponse;
  final appels = <String>[];
  Object? dernierCorps;
  Map<String, dynamic>? derniereQuery;

  Future<T> _repondre<T>(String methode, String chemin, [Object? corps]) async {
    appels.add('$methode $chemin');
    dernierCorps = corps;
    final r = reponse!(methode, chemin);
    if (r is ApiException) throw r;
    return r as T;
  }

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) {
    derniereQuery = query;
    return _repondre('GET', chemin);
  }

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) =>
      _repondre('POST', chemin, data);

  @override
  Future<T> patch<T>(String chemin, {Object? data}) =>
      _repondre('PATCH', chemin, data);

  @override
  Future<T> put<T>(String chemin, {Object? data}) =>
      _repondre('PUT', chemin, data);

  @override
  Future<T> delete<T>(String chemin, {Object? data}) =>
      _repondre('DELETE', chemin, data);
}

void main() {
  group('Panier', () {
    test('lit le panier, regroupe par boutique et compte les articles', () {
      final p = Panier.fromJson(panierJson());
      expect(p.nombreArticles, 3);
      expect(p.parBoutique.keys, ['b1', 'b2']);
      expect(p.articles.first.descriptionVariante, 'M · Rouge');
      expect(p.articles.last.descriptionVariante, 'Taille unique');
      expect(p.articles.last.prixModifie, isTrue);
      expect(p.sousTotal, 62500);
      expect(p.commandable, isTrue);
    });

    test('routes et corps des actions', () async {
      final api = FauxApi((_, _) => panierJson());
      final depot = PanierRepository(api);
      await depot.ajouter('v1', quantite: 2);
      expect(api.dernierCorps, {'varianteProduitId': 'v1', 'quantite': 2});
      await depot.modifierQuantite('a1', 3);
      expect(api.dernierCorps, {'quantite': 3});
      await depot.supprimer('a1');
      expect(api.appels, [
        'POST /panier/articles',
        'PATCH /panier/articles/a1',
        'DELETE /panier/articles/a1',
      ]);
    });

    ProviderContainer conteneur(FauxApi api, {Utilisateur? utilisateur}) {
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          utilisateurConnecteProvider.overrideWithValue(utilisateur),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('visiteur : panier vide, sans requête', () async {
      final api = FauxApi((_, _) => panierJson());
      final c = conteneur(api);
      expect(await c.read(panierProvider.future), same(Panier.vide));
      expect(c.read(nombreArticlesPanierProvider), 0);
      expect(api.appels, isEmpty);
    });

    test('une action remplace le panier par celui du serveur', () async {
      final api = FauxApi(
        (m, _) => m == 'GET' ? panierJson(quantite: 1) : panierJson(),
      );
      final c = conteneur(api, utilisateur: awa);
      await c.read(panierProvider.future);
      expect(c.read(nombreArticlesPanierProvider), 2);

      await c.read(panierProvider.notifier).modifierQuantite('a1', 2);
      expect(c.read(nombreArticlesPanierProvider), 3);
    });

    test('un refus laisse le panier affiché et remonte l’erreur', () async {
      final api = FauxApi(
        (m, _) => m == 'GET'
            ? panierJson()
            : const ApiException(
                type: TypeErreurApi.requeteInvalide,
                message: 'Stock insuffisant',
              ),
      );
      final c = conteneur(api, utilisateur: awa);
      await c.read(panierProvider.future);

      await expectLater(
        c.read(panierProvider.notifier).ajouter('v1', quantite: 50),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(nombreArticlesPanierProvider), 3);
    });
  });

  group('Commandes', () {
    test('lit une commande et la variante figée', () {
      final c = Commande.fromJson(commandeJson());
      expect(c.statut, StatutCommande.enAttentePaiement);
      expect(c.annulable, isTrue);
      expect(c.nombreArticles, 2);
      expect(c.sousCommandes.single.boutiqueId, 'b1');
      final ligne = c.sousCommandes.single.lignes.single;
      expect(ligne.variante, 'M');
      expect(ligne.total, 50000);
      expect(
        c.echeancePaiement.difference(c.dateCreation),
        delaiPaiementCommande,
      );
    });

    test('statut inconnu : traité comme une commande payée', () {
      expect(StatutCommande.depuis('NOUVEAU_STATUT'), StatutCommande.nouvelle);
      expect(
        Commande.fromJson(commandeJson(statut: 'ANNULEE')).annulable,
        isFalse,
      );
    });

    test('passer une commande n’envoie pas de corps', () async {
      final api = FauxApi((_, _) => commandeJson());
      await CommandesRepository(api).passer();
      await CommandesRepository(api).annuler('c1');
      expect(api.appels, ['POST /commandes', 'POST /commandes/c1/annuler']);
      expect(api.dernierCorps, isNull);
    });
  });

  group('Adresses', () {
    test('lit les adresses de /clients/me ; champs vides = absents', () async {
      final api = FauxApi(
        (_, _) => {
          'statutClient': 'ACTIF',
          'adresses': [
            {
              'id': 'ad1',
              'type': 'LIVRAISON',
              'ligne1': 'Akwa, rue Joffre',
              'ligne2': '',
              'ville': 'Douala',
              'region': 'Littoral',
              'pays': 'Cameroun',
              'codePostal': null,
              'latitude': '4.0510000',
              'estPrincipale': true,
            },
          ],
        },
      );
      final a = (await AdressesRepository(api).lister()).single;
      expect(api.appels, ['GET /clients/me']);
      expect(a.type, TypeAdresse.livraison);
      expect(a.ligne2, isNull);
      expect(a.localite, 'Douala, Littoral, Cameroun');
      expect(a.estPrincipale, isTrue);
    });

    test('la saisie envoie les champs facultatifs vides pour les effacer', () {
      const s = SaisieAdresse(
        type: TypeAdresse.autre,
        ligne1: ' Bastos ',
        ville: 'Yaoundé',
        pays: 'Cameroun',
      );
      expect(s.toJson(), {
        'type': 'AUTRE',
        'ligne1': 'Bastos',
        'ligne2': '',
        'ville': 'Yaoundé',
        'region': '',
        'pays': 'Cameroun',
        'codePostal': '',
        'estPrincipale': false,
      });
    });
  });

  group('Avis', () {
    test('articles à noter', () async {
      final api = FauxApi(
        (_, _) => [
          {
            'ligneSousCommandeId': 'l1',
            'produitId': 'p1',
            'nomProduit': 'Robe Kaba',
            'variante': {
              'nom': null,
              'attributs': {'taille': 'M'},
            },
            'commandeId': 'c1',
            'dateCommande': '2026-10-20T10:00:00.000Z',
          },
        ],
      );
      final a = (await MesAvisRepository(api).aNoter()).single;
      expect(api.appels, ['GET /moi/avis/a-noter']);
      expect(a.ligneId, 'l1');
      expect(a.variante, 'M');
    });

    test('un commentaire vide n’est pas envoyé', () async {
      final api = FauxApi((_, _) => null);
      await MesAvisRepository(api)
          .creer(ligneId: 'l1', note: 5, commentaire: '   ');
      expect(api.dernierCorps, {'ligneSousCommandeId': 'l1', 'note': 5});

      await MesAvisRepository(api)
          .modifier('av1', note: 4, commentaire: 'Bien');
      expect(api.appels.last, 'PATCH /avis/av1');
      expect(api.dernierCorps, {'note': 4, 'commentaire': 'Bien'});
    });
  });
}
