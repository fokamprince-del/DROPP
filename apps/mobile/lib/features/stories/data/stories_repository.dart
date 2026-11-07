import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import 'modeles_stories.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>(
  (ref) => StoriesRepository(ref.watch(apiClientProvider)),
);

/// Stories actives (moins de 24 h, ou jusqu'à leur date d'expiration).
///
/// Toute erreur est une `ApiException`.
class StoriesRepository {
  StoriesRepository(this._api);

  final ApiClient _api;

  /// `GET /stories/abonnements` (connexion requise, non paginé) : stories
  /// des boutiques suivies, y compris celles réservées aux abonnés,
  /// **regroupées par boutique** (des plus anciennes aux plus récentes) avec
  /// l'état `vue` de chaque story ; les boutiques non entièrement vues en
  /// premier.
  Future<List<GroupeStories>> abonnements() async {
    final json = await _api.get<List<dynamic>>('/stories/abonnements');
    return json
        .cast<Map<String, dynamic>>()
        .map(GroupeStories.fromJson)
        .toList();
  }

  /// `GET /stories` (public) : stories publiques actives, **à plat** (non
  /// regroupées) et les plus récentes d'abord, sans état `vue`. Le
  /// regroupement est fait par `composerBarre`.
  Future<PageResultats<Story>> publiques({int limite = 50}) =>
      _api.page('/stories', Story.fromJson, limite: limite);

  /// `POST /stories/:id/vue` (connexion requise) : idempotent. Les vues de
  /// la boutique sur ses propres stories ne sont pas comptées. 404 si la
  /// story a expiré entre-temps.
  Future<void> marquerVue(String id) => _api.post<Object?>('/stories/$id/vue');
}
