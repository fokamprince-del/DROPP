import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

final vendeurRepositoryProvider = Provider<VendeurRepository>(
  (ref) => VendeurRepository(ref.watch(apiClientProvider)),
);

class VendeurRepository {
  VendeurRepository(this._api);

  final ApiClient _api;

  /// `POST /sellers/devenir` (204). [cleIdempotence] : un UUID par action de
  /// l'utilisateur, réutilisé à chaque nouvel essai.
  Future<void> devenirVendeur({required String cleIdempotence}) =>
      _api.post<void>(
        '/sellers/devenir',
        options: Options(headers: {'Idempotency-Key': cleIdempotence}),
      );
}
