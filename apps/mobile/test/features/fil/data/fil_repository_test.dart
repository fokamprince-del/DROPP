import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/features/fil/data/fil_repository.dart';
import 'package:dropp/shared/modeles/contenu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forme exacte renvoyée par `PublicationsService.presenter` côté API.
Map<String, dynamic> publicationJson({String id = 'p1'}) => {
  'id': id,
  'contenu': '  Nouvelle collection wax  ',
  'type': 'CARROUSEL',
  'visibilite': 'ABONNES',
  'statut': 'PUBLIEE',
  'nombreVues': 1250,
  'dateCreation': '2026-10-25T10:00:00.000Z',
  'dateModification': '2026-10-25T10:00:00.000Z',
  'boutique': {'id': 'b1', 'nom': 'Awa Wax Couture'},
  'medias': [
    {
      'id': 'mp1',
      'ordre': 0,
      'media': {
        'id': 'm1',
        'typeMedia': 'IMAGE',
        'typeMime': 'image/jpeg',
        'statutTraitement': 'PRET',
        'largeur': 1080,
        'hauteur': 1350,
        'duree': null,
        'url': 'https://cdn/m1.jpg',
      },
    },
    {
      'id': 'mp2',
      'ordre': 1,
      'media': {
        'id': 'm2',
        'typeMedia': 'VIDEO',
        'typeMime': 'video/mp4',
        'statutTraitement': 'PRET',
        'largeur': null,
        'hauteur': null,
        'duree': 42,
        'url': 'https://cdn/m2.mp4',
      },
    },
  ],
  'produits': [
    {
      'id': 'pr1',
      'nom': 'Robe Kaba',
      'prixBase': 25000,
      'imageUrl': 'https://cdn/pr1.jpg',
    },
    {'id': 'pr2', 'nom': 'Foulard', 'prixBase': 4500.5, 'imageUrl': null},
  ],
  'likes': 87,
  'commentaires': 12,
};

Map<String, dynamic> pageJson(List<Map<String, dynamic>> donnees) => {
  'donnees': donnees,
  'pagination': {'total': donnees.length, 'page': 1, 'limite': 10, 'pages': 1},
};

class _FauxApi extends ApiClient {
  _FauxApi(this.reponse) : super(Dio());

  final Object reponse;
  final appels = <String>[];
  Map<String, dynamic>? derniereRequete;

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) async {
    appels.add('GET $chemin');
    derniereRequete = query;
    return reponse as T;
  }

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    appels.add('POST $chemin');
    return null as T;
  }
}

void main() {
  test('lit une publication telle que l’API la renvoie', () async {
    final api = _FauxApi(publicationJson());
    final p = await FilRepository(api).obtenir('p1');

    expect(api.appels, ['GET /publications/p1']);
    expect(p.contenu, 'Nouvelle collection wax');
    expect(p.visibilite, Visibilite.abonnes);
    expect(p.nombreVues, 1250);
    expect(p.boutique.nom, 'Awa Wax Couture');
    expect(p.likes, 87);
    expect(p.commentaires, 12);
    expect(p.dateCreation.isUtc, isFalse);

    expect(p.medias, hasLength(2));
    expect(p.medias.first.estVideo, isFalse);
    expect(p.medias.first.ratio, closeTo(0.8, 0.001));
    expect(p.medias.last.estVideo, isTrue);
    expect(p.medias.last.duree, const Duration(seconds: 42));
    expect(p.medias.last.ratio, isNull);

    expect(p.produits.map((e) => e.nom), ['Robe Kaba', 'Foulard']);
    expect(p.produits.last.prix, 4500.5);
    expect(p.produits.last.imageUrl, isNull);
  });

  test('un texte vide devient absent', () async {
    final json = publicationJson()..['contenu'] = '   ';
    final p = await FilRepository(_FauxApi(json)).obtenir('p1');
    expect(p.contenu, isNull);
  });

  test(
    'le fil « Pour toi » interroge la route publique, par pages de 10',
    () async {
      final api = _FauxApi(pageJson([publicationJson()]));
      final page = await FilRepository(api).pourToi(2);

      expect(api.appels, ['GET /publications']);
      expect(api.derniereRequete, {'page': 2, 'limite': 10});
      expect(page.donnees.single.id, 'p1');
    },
  );

  test('le fil « Abonnements » interroge sa route', () async {
    final api = _FauxApi(pageJson([]));
    await FilRepository(api).abonnements(1);
    expect(api.appels, ['GET /publications/fil/abonnements']);
  });

  test('une vue est envoyée sur la route de la publication', () async {
    final api = _FauxApi(const {});
    await FilRepository(api).marquerVue('p9');
    expect(api.appels, ['POST /publications/p9/vue']);
  });
}
