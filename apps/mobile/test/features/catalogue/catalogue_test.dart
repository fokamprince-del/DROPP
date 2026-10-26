import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/features/boutiques/data/boutiques_repository.dart';
import 'package:dropp/features/boutiques/data/modeles_boutiques.dart';
import 'package:dropp/features/catalogue/data/catalogue_repository.dart';
import 'package:dropp/features/catalogue/data/modeles_catalogue.dart';
import 'package:dropp/features/commentaires/data/commentaires.dart';
import 'package:dropp/features/interactions/data/interactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forme exacte de `GET /produits/:id` : les prix `Decimal` arrivent en
/// chaînes.
Map<String, dynamic> produitJson() => {
  'id': 'pr1',
  'nom': 'Robe Kaba',
  'description': ' Wax 100 % coton ',
  'statut': 'PUBLIE',
  'prixBase': '25000',
  'boutiqueId': 'b1',
  'categorieId': 'c1',
  'variantes': [
    {
      'id': 'v1',
      'sku': 'K-M-R',
      'nom': null,
      'attributs': {'taille': 'M', 'couleur': 'Rouge'},
      'prix': null,
      'stockDisponible': 5,
    },
    {
      'id': 'v2',
      'sku': 'K-L-R',
      'nom': null,
      'attributs': {'taille': 'L', 'couleur': 'Rouge'},
      'prix': '27500.50',
      'stockDisponible': 0,
    },
  ],
  'medias': [
    {
      'id': 'mp1',
      'ordre': 0,
      'media': {'id': 'm1', 'typeMedia': 'IMAGE', 'url': 'https://cdn/m1.jpg'},
    },
  ],
};

Map<String, dynamic> _page(
  List<Object> donnees, {
  Map<String, dynamic>? en,
}) => {
  'donnees': donnees,
  'pagination': {'total': donnees.length, 'page': 1, 'limite': 20, 'pages': 1},
  ...?en,
};

class _FauxApi extends ApiClient {
  _FauxApi(this.reponse) : super(Dio());

  final Object? reponse;
  String? chemin;
  Map<String, dynamic>? query;
  Object? corps;

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) async {
    this.chemin = chemin;
    this.query = query;
    return reponse as T;
  }

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    this.chemin = chemin;
    corps = data;
    return reponse as T;
  }
}

void main() {
  group('ProduitDetail', () {
    test('lit les prix Decimal envoyés en chaînes', () async {
      final p = await CatalogueRepository(_FauxApi(produitJson()))
          .produit('pr1');
      expect(p.prixBase, 25000);
      expect(p.variantes.last.prix, 27500.5);
      expect(p.description, 'Wax 100 % coton');
      expect(p.medias.single.url, 'https://cdn/m1.jpg');
    });

    test('prix effectif, prix minimum, stock et attributs', () async {
      final p = await CatalogueRepository(_FauxApi(produitJson()))
          .produit('pr1');
      expect(p.prixDe(p.variantes.first), 25000);
      expect(p.prixDe(p.variantes.last), 27500.5);
      expect(p.prixMin, 25000);
      expect(p.prixVariable, isTrue);
      expect(p.stockTotal, 5);
      expect(p.attributs, ['taille', 'couleur']);
      expect(p.variantes.first.attributs, {'taille': 'M', 'couleur': 'Rouge'});
    });
  });

  group('FiltresCatalogue', () {
    test('ne transmet que les filtres renseignés', () {
      const f = FiltresCatalogue(
        q: '  robe ',
        prixMax: 10000,
        tri: TriCatalogue.prixCroissant,
        enStock: true,
      );
      expect(f.versQuery(), {
        'q': 'robe',
        'prixMax': 10000,
        'tri': 'prix_croissant',
        'enStock': 'true',
      });
      expect(f.nombreActifs, 3);
      expect(const FiltresCatalogue().versQuery(), isEmpty);
    });

    test('avec() efface un champ passé à null et garde les autres', () {
      const f = FiltresCatalogue(q: 'robe', categorieId: 'c1', prixMin: 5);
      final g = f.avec(categorieId: null);
      expect(g.categorieId, isNull);
      expect(g.q, 'robe');
      expect(g.prixMin, 5);
      expect(
        f.sansFiltres(),
        const FiltresCatalogue(q: 'robe', categorieId: 'c1'),
      );
    });
  });

  test('le catalogue envoie filtres et boutique, et lit prixMin', () async {
    final api = _FauxApi(
      _page([
        {
          'id': 'pr1',
          'nom': 'Robe',
          'prixMin': '9000',
          'boutiqueId': 'b1',
          'imagePrincipale': null,
          'enFavori': false,
        },
      ]),
    );
    final page = await CatalogueRepository(
      api,
    ).produits(const FiltresCatalogue(categorieId: 'c1'), 2, boutiqueId: 'b1');

    expect(api.chemin, '/produits');
    expect(api.query, {
      'categorieId': 'c1',
      'boutiqueId': 'b1',
      'page': 2,
      'limite': 20,
    });
    expect(page.donnees.single.prixMin, 9000);
    expect(page.donnees.single.imageUrl, isNull);
  });

  test('catégories : arbre avec compteurs', () async {
    final api = _FauxApi([
      {
        'id': 'mode',
        'nom': 'Mode',
        'nombreProduits': 12,
        'enfants': [
          {'id': 'robes', 'nom': 'Robes', 'nombreProduits': 7},
        ],
      },
    ]);
    final categories = await CatalogueRepository(api).categories();
    expect(categories.single.enfants.single.nom, 'Robes');
    expect(categories.single.nombreProduits, 12);
  });

  test('avis : résumé lu à côté de la première page', () async {
    final api = _FauxApi(
      _page(
        [
          {
            'id': 'a1',
            'note': 5,
            'commentaire': 'Top',
            'dateCreation': '2026-10-20T10:00:00.000Z',
            'auteur': {'id': 'u', 'prenom': 'Nadège', 'pseudo': null},
          },
        ],
        en: {
          'resume': {
            'moyenne': 4.8,
            'total': 38,
            'repartition': {'1': 0, '2': 1, '3': 2, '4': 5, '5': 30},
          },
        },
      ),
    );
    final page = await CatalogueRepository(api).avis('pr1', 1, limite: 3);
    final resume = resumeDe(page);

    expect(api.query, {'page': 1, 'limite': 3});
    expect(page.donnees.single.auteur, 'Nadège');
    expect(resume.moyenne, 4.8);
    expect(resume.total, 38);
    expect(resume.repartition[5], 30);
  });

  group('Boutique', () {
    test('page complète : statistiques et état d’abonnement', () {
      final b = Boutique.fromJson({
        'id': 'b1',
        'nom': 'Awa Wax',
        'description': '',
        'ville': 'Douala',
        'quartier': 'Akwa',
        'logoUrl': null,
        'banniereUrl': 'https://cdn/b.jpg',
        'statistiques': {'abonnes': 120, 'produits': 8, 'publications': 3},
        'estAbonne': true,
        'estMaBoutique': false,
      });
      expect(b.abonnes, 120);
      expect(b.produits, 8);
      expect(b.description, isNull);
      expect(b.lieu, 'Douala, Akwa');
      expect(b.estAbonne, isTrue);
    });

    test('résultat de recherche : abonnés à la racine', () {
      final b = Boutique.fromJson({'id': 'b1', 'nom': 'Awa', 'abonnes': 4});
      expect(b.abonnes, 4);
      expect(b.lieu, isNull);
    });

    test('mes abonnements', () async {
      final api = _FauxApi(
        _page([
          {
            'boutique': {'id': 'b1', 'nom': 'Awa', 'logoUrl': null},
            'muet': false,
            'depuis': '2026-09-01T10:00:00.000Z',
          },
        ]),
      );
      final page = await BoutiquesRepository(api).mesAbonnements(1);
      expect(api.chemin, '/moi/abonnements');
      expect(page.donnees.single.boutiqueId, 'b1');
    });
  });

  group('Commentaires', () {
    test('lit un commentaire racine avec son aperçu de réponses', () {
      final c = Commentaire.fromJson({
        'id': 'c1',
        'contenu': 'Dispo en M ?',
        'estCreateur': false,
        'dateCreation': '2026-10-26T08:00:00.000Z',
        'utilisateur': {'id': 'u1', 'prenom': 'Awa', 'nom': 'Ngo'},
        'likes': 2,
        'totalReponses': 4,
        'likeParMoi': false,
        'reponses': [
          {
            'id': 'r1',
            'contenu': 'Oui !',
            'estCreateur': true,
            'dateCreation': '2026-10-26T09:00:00.000Z',
            'utilisateur': {'id': 'b1', 'prenom': 'Kribi', 'nom': 'Perles'},
            'likes': 0,
          },
        ],
      });
      expect(c.auteur, 'Awa Ngo');
      expect(c.totalReponses, 4);
      expect(c.reponses.single.estCreateur, isTrue);
    });

    test('une réponse est publiée avec son parent', () async {
      final api = _FauxApi({
        'id': 'r2',
        'contenu': 'Merci',
        'parentId': 'c1',
        'estCreateur': false,
        'dateCreation': '2026-10-26T10:00:00.000Z',
        'utilisateur': {
          'id': 'u1',
          'prenom': 'Awa',
          'nom': 'Ngo',
          'pseudo': 'awa',
        },
        'mentions': <Object>[],
      });
      final r = await CommentairesRepository(api)
          .publier('p1', '  Merci  ', parentId: 'c1');

      expect(api.chemin, '/publications/p1/commentaires');
      expect(api.corps, {'contenu': 'Merci', 'parentId': 'c1'});
      expect(r.likes, 0);
    });
  });

  test('le partage envoie la plateforme et renvoie le lien profond', () async {
    final api = _FauxApi({
      'publicationId': 'p1',
      'lienProfond': 'dropp://publications/p1',
      'plateforme': 'WHATSAPP',
      'partages': 3,
    });
    final lien = await InteractionsRepository(api)
        .partager('p1', PlateformePartage.whatsapp);

    expect(api.chemin, '/publications/p1/partager');
    expect(api.corps, {'plateforme': 'WHATSAPP'});
    expect(lien, 'dropp://publications/p1');
  });
}
