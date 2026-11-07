import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/features/vendeur/data/vendeur_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FauxApi extends ApiClient {
  _FauxApi() : super(Dio());

  String? chemin;
  Options? options;

  @override
  Future<T> post<T>(String chemin, {Object? data, Options? options}) async {
    this.chemin = chemin;
    this.options = options;
    return null as T;
  }
}

void main() {
  test("devenirVendeur joint la clé d'idempotence", () async {
    final api = _FauxApi();
    await VendeurRepository(api).devenirVendeur(cleIdempotence: 'cle-1');

    expect(api.chemin, '/sellers/devenir');
    expect(api.options?.headers?['Idempotency-Key'], 'cle-1');
  });
}
