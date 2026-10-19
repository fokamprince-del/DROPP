import 'package:dio/dio.dart';

import '../auth/jetons.dart';
import '../auth/stockage_session.dart';

/// Ajoute le jeton d'accès et le renouvelle sur un 401.
///
/// Un seul refresh à la fois : le serveur fait tourner le refresh token à
/// chaque appel, et un ancien jeton présenté une seconde fois est traité comme
/// un vol (toutes les sessions de l'appareil sont fermées). Les requêtes qui
/// échouent pendant un refresh attendent donc le même appel puis sont rejouées.
class IntercepteurAuth extends Interceptor {
  IntercepteurAuth({
    required Dio dio,
    required Dio dioRefresh,
    required StockageSession stockage,
    required void Function() surSessionExpiree,
  })  : _dio = dio,
        _dioRefresh = dioRefresh,
        _stockage = stockage,
        _surSessionExpiree = surSessionExpiree;

  /// Routes qui n'envoient jamais de jeton et dont le 401 est une vraie réponse
  /// (mauvais mot de passe, code faux…), pas un jeton expiré.
  static const routesSansJeton = {
    '/auth/inscription',
    '/auth/verifier-telephone',
    '/auth/renvoyer-code',
    '/auth/connexion',
    '/auth/refresh',
    '/auth/mot-de-passe-oublie',
    '/auth/reinitialiser-mot-de-passe',
  };

  static const _cleRejouee = 'dropp.rejouee';

  final Dio _dio;
  final Dio _dioRefresh;
  final StockageSession _stockage;
  final void Function() _surSessionExpiree;

  Future<Jetons?>? _refreshEnCours;

  static bool _sansJeton(RequestOptions options) =>
      routesSansJeton.contains(options.path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_sansJeton(options)) {
      final jetons = await _stockage.lireJetons();
      if (jetons != null) {
        options.headers['Authorization'] = 'Bearer ${jetons.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final jetonEnvoye = options.headers['Authorization'] as String?;

    if (err.response?.statusCode != 401 ||
        _sansJeton(options) ||
        jetonEnvoye == null ||
        options.extra[_cleRejouee] == true) {
      return handler.next(err);
    }

    final Jetons? nouveaux;
    try {
      nouveaux = await _rafraichir(jetonEnvoye);
    } on DioException {
      // Réseau coupé pendant le refresh : la session reste valide.
      return handler.next(err);
    }

    if (nouveaux == null) {
      _surSessionExpiree();
      return handler.next(err);
    }

    options.headers['Authorization'] = 'Bearer ${nouveaux.accessToken}';
    options.extra[_cleRejouee] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<Jetons?> _rafraichir(String jetonEnvoye) =>
      _refreshEnCours ??= _executerRefresh(jetonEnvoye).whenComplete(() {
        _refreshEnCours = null;
      });

  /// `null` = session terminée côté serveur. Lève une [DioException] si le
  /// serveur est injoignable.
  Future<Jetons?> _executerRefresh(String jetonEnvoye) async {
    final actuels = await _stockage.lireJetons();
    if (actuels == null) return null;

    // Un autre refresh s'est terminé depuis l'envoi de cette requête.
    if (jetonEnvoye != 'Bearer ${actuels.accessToken}') return actuels;

    try {
      final reponse = await _dioRefresh.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': actuels.refreshToken},
      );
      final jetons = Jetons.fromJson(reponse.data!);
      await _stockage.ecrireJetons(jetons);
      return jetons;
    } on DioException catch (e) {
      final statut = e.response?.statusCode;
      if (statut == 401 || statut == 403) {
        await _stockage.effacer();
        return null;
      }
      rethrow;
    }
  }
}
