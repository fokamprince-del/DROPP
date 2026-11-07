import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dropp/core/api/api_client.dart';
import 'package:dropp/core/auth/jetons.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/stockage_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FauxStockage extends StockageSession {
  _FauxStockage({this.jetons, this.profil})
    : super(const FlutterSecureStorage());

  final Jetons? jetons;
  final Map<String, dynamic>? profil;

  @override
  Future<Jetons?> lireJetons() async => jetons;

  @override
  Future<Map<String, dynamic>?> lireProfil() async => profil;

  @override
  Future<void> ecrireProfil(Map<String, dynamic> profil) async {}

  @override
  Future<void> effacer() async {}
}

/// Serveur injoignable : la requête ne se termine jamais.
class _ApiSansReponse extends ApiClient {
  _ApiSansReponse() : super(Dio());

  @override
  Future<T> get<T>(String chemin, {Map<String, dynamic>? query}) =>
      Completer<T>().future;
}

ProviderContainer _conteneur(_FauxStockage stockage) {
  final conteneur = ProviderContainer(
    overrides: [
      stockageSessionProvider.overrideWithValue(stockage),
      apiClientProvider.overrideWithValue(_ApiSansReponse()),
    ],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

Future<void> _attendre() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('sans jetons : session anonyme', () async {
    final conteneur = _conteneur(_FauxStockage());
    expect(conteneur.read(sessionProvider), isA<SessionInconnue>());
    await _attendre();
    expect(conteneur.read(sessionProvider), isA<SessionAnonyme>());
  });

  test('avec un profil mémorisé : connecté sans attendre le réseau', () async {
    final conteneur = _conteneur(
      _FauxStockage(
        jetons: const Jetons(accessToken: 'a', refreshToken: 'r'),
        profil: {
          'id': 'u1',
          'prenom': 'Awa',
          'nom': 'Ngo Bassa',
          'statutCompte': 'ACTIF',
        },
      ),
    );
    conteneur.read(sessionProvider);
    await _attendre();

    final session = conteneur.read(sessionProvider);
    expect(session, isA<SessionConnectee>());
    expect(
      (session as SessionConnectee).utilisateur.nomComplet,
      'Awa Ngo Bassa',
    );
  });
}
