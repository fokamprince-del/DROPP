import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../auth/stockage_session.dart';
import '../config/environnement.dart';
import 'api_exception.dart';
import 'intercepteur_auth.dart';
import 'intercepteurs.dart';
import 'pagination.dart';

final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: Environnement.apiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  );
  final dio = Dio(options);

  dio.interceptors.addAll([
    IntercepteurIdempotence(),
    IntercepteurAuth(
      dio: dio,
      // Sans intercepteur : un refresh ne doit jamais déclencher un refresh.
      dioRefresh: Dio(options),
      stockage: ref.watch(stockageSessionProvider),
      // Lu au moment de l'expiration seulement : pas de dépendance circulaire
      // (la session utilise elle-même l'API).
      surSessionExpiree: () => ref.read(sessionProvider.notifier).expirer(),
    ),
    IntercepteurErreurs(),
    if (kDebugMode) LogInterceptor(requestBody: true, responseBody: false),
  ]);

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

/// Point d'entrée des dépôts (`features/*/data`). Chemins relatifs à `/v1`,
/// avec le `/` initial : `api.get('/produits')`. Toute erreur est une
/// [ApiException].
///
/// Ne pas l'utiliser pour envoyer un fichier vers une URL signée R2 : elle
/// ajouterait le jeton et le préfixe de l'API.
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) =>
      _appel(() => dio.get<T>(chemin, queryParameters: _sansNull(query)));

  Future<T> post<T>(String chemin, {Object? data, Options? options}) =>
      _appel(() => dio.post<T>(chemin, data: data, options: options));

  Future<T> patch<T>(String chemin, {Object? data}) =>
      _appel(() => dio.patch<T>(chemin, data: data));

  Future<T> put<T>(String chemin, {Object? data}) =>
      _appel(() => dio.put<T>(chemin, data: data));

  Future<T> delete<T>(String chemin, {Object? data}) =>
      _appel(() => dio.delete<T>(chemin, data: data));

  /// Liste paginée : `{ donnees, pagination }`.
  Future<PageResultats<T>> page<T>(
    String chemin,
    T Function(Map<String, dynamic>) depuisJson, {
    int page = 1,
    int limite = 20,
    Map<String, dynamic>? query,
  }) async {
    final json = await get<Map<String, dynamic>>(
      chemin,
      query: {...?query, 'page': page, 'limite': limite},
    );
    return PageResultats.fromJson(json, depuisJson);
  }

  Future<T> _appel<T>(Future<Response<T>> Function() requete) async {
    try {
      final reponse = await requete();
      return reponse.data as T;
    } catch (e) {
      throw ApiException.depuis(e);
    }
  }

  static Map<String, dynamic>? _sansNull(Map<String, dynamic>? query) =>
      query == null ? null : (Map.of(query)..removeWhere((_, v) => v == null));
}
