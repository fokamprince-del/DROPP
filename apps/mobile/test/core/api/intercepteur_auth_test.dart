import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/core/api/intercepteur_auth.dart';
import 'package:mobile/core/api/intercepteurs.dart';
import 'package:mobile/core/auth/jetons.dart';
import 'package:mobile/core/auth/stockage_session.dart';

/// Stockage en mémoire (pas de canal natif en test).
class _StockageMemoire extends StockageSession {
  _StockageMemoire(this.jetons) : super(const FlutterSecureStorage());

  Jetons? jetons;

  @override
  Future<Jetons?> lireJetons() async => jetons;

  @override
  Future<void> ecrireJetons(Jetons nouveaux) async => jetons = nouveaux;

  @override
  Future<void> effacer() async => jetons = null;
}

/// Imite l'API : accepte seulement le jeton d'accès courant, fait tourner les
/// jetons sur /auth/refresh et refuse un refresh token déjà utilisé.
class _FauxServeur implements HttpClientAdapter {
  _FauxServeur({this.refreshAccepte = true});

  final bool refreshAccepte;
  String accesValide = 'acces-2';
  String refreshValide = 'refresh-1';
  int refreshs = 0;
  final clesIdempotence = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    clesIdempotence.add(options.headers['Idempotency-Key'] as String?);

    if (options.path == '/auth/refresh') {
      refreshs++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final envoye = (options.data as Map)['refreshToken'];
      if (!refreshAccepte || envoye != refreshValide) {
        return _json(401, {'statusCode': 401, 'message': 'Jeton invalide.'});
      }
      accesValide = 'acces-3';
      refreshValide = 'refresh-2';
      return _json(200, {
        'accessToken': 'acces-3',
        'refreshToken': 'refresh-2',
        'expiresIn': 900,
      });
    }

    if (options.path == '/auth/connexion') {
      return _json(401, {
        'statusCode': 401,
        'message': 'Identifiant ou mot de passe incorrect.',
      });
    }

    if (options.headers['Authorization'] == 'Bearer $accesValide') {
      return _json(200, {'ok': true});
    }
    return _json(401, {'statusCode': 401, 'message': 'Unauthorized'});
  }

  ResponseBody _json(int statut, Object corps) => ResponseBody.fromString(
        jsonEncode(corps),
        statut,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FauxServeur serveur;
  late _StockageMemoire stockage;
  late Dio dio;
  late int expirations;

  void monter({bool refreshAccepte = true}) {
    serveur = _FauxServeur(refreshAccepte: refreshAccepte);
    // Le serveur considère acces-1 comme expiré.
    stockage = _StockageMemoire(
      const Jetons(accessToken: 'acces-1', refreshToken: 'refresh-1'),
    );
    expirations = 0;
    final options = BaseOptions(baseUrl: 'http://api.test/v1');
    final dioRefresh = Dio(options)..httpClientAdapter = serveur;
    dio = Dio(options)..httpClientAdapter = serveur;
    dio.interceptors.addAll([
      IntercepteurIdempotence(),
      IntercepteurAuth(
        dio: dio,
        dioRefresh: dioRefresh,
        stockage: stockage,
        surSessionExpiree: () => expirations++,
      ),
      IntercepteurErreurs(),
    ]);
  }

  test('jeton expiré : un seul refresh pour des requêtes simultanées, toutes rejouées', () async {
    monter();

    final reponses = await Future.wait([
      dio.get<Map<String, dynamic>>('/panier'),
      dio.get<Map<String, dynamic>>('/notifications/compteur'),
      dio.post<Map<String, dynamic>>('/panier/articles', data: {'quantite': 1}),
    ]);

    expect(reponses.map((r) => r.statusCode), everyElement(200));
    expect(serveur.refreshs, 1);
    expect(stockage.jetons?.accessToken, 'acces-3');
    expect(stockage.jetons?.refreshToken, 'refresh-2');
    expect(expirations, 0);
  });

  test('un POST rejoué après refresh garde la même clé d\'idempotence', () async {
    monter();

    await dio.post<Map<String, dynamic>>('/commandes', data: {'adresseId': 'a1'});

    final cles = serveur.clesIdempotence.where((c) => c != null).toList();
    // Premier envoi puis rejeu ; le refresh passe par un dio sans intercepteur
    // et n'a donc pas de clé.
    expect(cles, hasLength(2));
    expect(cles.toSet(), hasLength(1));
  });

  test('refresh refusé : session expirée et jetons effacés', () async {
    monter(refreshAccepte: false);

    await expectLater(
      dio.get<Map<String, dynamic>>('/panier'),
      throwsA(isA<DioException>().having(
        (e) => (e.error as ApiException).type,
        'type',
        TypeErreurApi.nonAuthentifie,
      )),
    );
    expect(expirations, 1);
    expect(stockage.jetons, isNull);
  });

  test('401 sur la connexion : pas de refresh, message de l\'API', () async {
    monter();

    await expectLater(
      dio.post<Map<String, dynamic>>('/auth/connexion', data: {'identifiant': 'x'}),
      throwsA(isA<DioException>().having(
        (e) => (e.error as ApiException).message,
        'message',
        'Identifiant ou mot de passe incorrect.',
      )),
    );
    expect(serveur.refreshs, 0);
    expect(stockage.jetons?.accessToken, 'acces-1');
  });
}
