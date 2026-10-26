import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import 'modeles_fil.dart';

final filRepositoryProvider = Provider<FilRepository>(
  (ref) => FilRepository(ref.watch(apiClientProvider)),
);

/// Toute erreur est une `ApiException`.
class FilRepository {
  FilRepository(this._api);

  final ApiClient _api;

  /// Petites pages : chaque publication charge des médias.
  static const taillePage = 10;

  /// Fil « Pour toi » : publications publiques, sans compte.
  Future<PageResultats<Publication>> pourToi(int page) => _api.page(
    '/publications',
    Publication.fromJson,
    page: page,
    limite: taillePage,
  );

  /// Fil « Abonnements » : boutiques suivies (connexion requise).
  Future<PageResultats<Publication>> abonnements(int page) => _api.page(
    '/publications/fil/abonnements',
    Publication.fromJson,
    page: page,
    limite: taillePage,
  );

  Future<Publication> obtenir(String id) async => Publication.fromJson(
    await _api.get<Map<String, dynamic>>('/publications/$id'),
  );

  /// Le serveur compte au plus une vue par personne et par 24 h.
  Future<void> marquerVue(String id) =>
      _api.post<Object?>('/publications/$id/vue');
}
