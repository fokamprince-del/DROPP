import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/features/stories/application/barre_stories.dart';
import 'package:dropp/features/stories/data/modeles_stories.dart';
import 'package:dropp/features/stories/data/stories_repository.dart';
import 'package:dropp/shared/modeles/contenu.dart';
import 'package:flutter_test/flutter_test.dart';

Story story(String id, String boutique, {bool vue = false, int heure = 10}) =>
    Story(
      id: id,
      boutique: BoutiqueResume(id: boutique, nom: 'Boutique $boutique'),
      media: MediaContenu(id: 'm$id', type: TypeMedia.image, url: 'u'),
      dateCreation: DateTime(2026, 10, 26, heure),
      vue: vue,
    );

GroupeStories groupe(String boutique, List<Story> stories) => GroupeStories(
  boutique: BoutiqueResume(id: boutique, nom: 'Boutique $boutique'),
  stories: stories,
);

List<String> boutiques(List<GroupeStories> groupes) =>
    groupes.map((g) => g.boutique.id).toList();

class _FauxApi extends ApiClient {
  _FauxApi(this.reponse) : super(Dio());

  final Object reponse;
  final appels = <String>[];

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) async {
    appels.add('GET $chemin');
    return reponse as T;
  }
}

void main() {
  group('composerBarre', () {
    test('boutiques suivies d’abord, sans doublon avec les publiques', () {
      final barre = composerBarre(
        [
          groupe('A', [story('a1', 'A')]),
        ],
        [story('a1', 'A'), story('b1', 'B'), story('c1', 'C')],
      );
      expect(boutiques(barre), ['A', 'B', 'C']);
    });

    test('regroupe les stories publiques par boutique, des plus anciennes '
        'aux plus récentes', () {
      final barre = composerBarre(const [], [
        story('b2', 'B', heure: 12),
        story('c1', 'C', heure: 11),
        story('b1', 'B', heure: 9),
      ]);
      expect(boutiques(barre), ['B', 'C']);
      expect(barre.first.stories.map((s) => s.id), ['b1', 'b2']);
    });

    test('les boutiques entièrement vues passent après les autres', () {
      final barre = composerBarre(
        [
          groupe('A', [story('a1', 'A', vue: true)]),
          groupe('B', [story('b1', 'B')]),
        ],
        [story('c1', 'C'), story('d1', 'D')],
        vuesLocales: {'c1'},
      );
      // Suivies (B puis A vue), puis autres (D puis C vue localement).
      expect(boutiques(barre), ['B', 'A', 'D', 'C']);
    });
  });

  test('appliquerVues marque seulement les stories données', () {
    final groupes = appliquerVues(
      [
        groupe('A', [story('a1', 'A'), story('a2', 'A')]),
      ],
      {'a1'},
    );
    expect(groupes.single.stories.map((s) => s.vue), [true, false]);
    expect(groupes.single.toutesVues, isFalse);
    expect(groupes.single.premiereNonVue, 1);
  });

  test('premiereNonVue repart du début quand tout est vu', () {
    final g = groupe('A', [
      story('a1', 'A', vue: true),
      story('a2', 'A', vue: true),
    ]);
    expect(g.premiereNonVue, 0);
  });

  test('lit la réponse groupée de /stories/abonnements', () async {
    final api = _FauxApi([
      {
        'boutique': {'id': 'A', 'nom': 'Awa'},
        'toutesVues': false,
        'stories': [
          {
            'id': 's1',
            'visibilite': 'ABONNES',
            'statut': 'PUBLIEE',
            'ordreCreation': 1,
            'dateCreation': '2026-10-26T08:00:00.000Z',
            'dateExpiration': '2026-10-27T08:00:00.000Z',
            'boutique': {'id': 'A', 'nom': 'Awa'},
            'media': {
              'id': 'm1',
              'typeMedia': 'VIDEO',
              'typeMime': 'video/mp4',
              'statutTraitement': 'PRET',
              'largeur': 720,
              'hauteur': 1280,
              'duree': 12,
              'url': 'https://cdn/s1.mp4',
            },
            'vue': true,
          },
        ],
      },
    ]);
    final groupes = await StoriesRepository(api).abonnements();

    expect(api.appels, ['GET /stories/abonnements']);
    final s = groupes.single.stories.single;
    expect(s.vue, isTrue);
    expect(s.media.estVideo, isTrue);
    expect(s.media.duree, const Duration(seconds: 12));
    expect(groupes.single.toutesVues, isTrue);
  });
}
