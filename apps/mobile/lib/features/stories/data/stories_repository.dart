import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import 'modeles_stories.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>(
  (ref) => StoriesRepository(ref.watch(apiClientProvider)),
);

/// Toute erreur est une `ApiException`.
class StoriesRepository {
  StoriesRepository(this._api);

  final ApiClient _api;

  /// Boutiques suivies, non vues d'abord (connexion requise).
  Future<List<GroupeStories>> abonnements() async {
    final json = await _api.get<List<dynamic>>('/stories/abonnements');
    return json
        .cast<Map<String, dynamic>>()
        .map(GroupeStories.fromJson)
        .toList();
  }

  /// Stories publiques actives, les plus récentes d'abord.
  Future<PageResultats<Story>> publiques({int limite = 50}) =>
      _api.page('/stories', Story.fromJson, limite: limite);

  /// Idempotent. Connexion requise.
  Future<void> marquerVue(String id) => _api.post<Object?>('/stories/$id/vue');
}
