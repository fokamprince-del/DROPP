import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'api_exception.dart';

/// Une clé `Idempotency-Key` par POST : si la réponse se perd et que la même
/// requête est rejouée (refresh, nouvel essai de dio), le serveur renvoie la
/// réponse déjà calculée au lieu de créer un doublon (commande, paiement…).
///
/// Pour qu'un bouton « Réessayer » garde la même clé, passer la sienne :
/// `Options(headers: {'Idempotency-Key': cle})`.
class IntercepteurIdempotence extends Interceptor {
  static const entete = 'Idempotency-Key';
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'POST' && !options.headers.containsKey(entete)) {
      options.headers[entete] = _uuid.v4();
    }
    handler.next(options);
  }
}

/// Toute erreur dio porte une [ApiException] dans `error` : les écrans n'ont
/// qu'un seul type d'erreur à gérer.
class IntercepteurErreurs extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) return handler.next(err);
    handler.next(err.copyWith(error: ApiException.depuis(err)));
  }
}
