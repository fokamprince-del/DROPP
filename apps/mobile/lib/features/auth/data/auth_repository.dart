import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/jetons.dart';
import 'modeles_auth.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

/// Routes d'accès publiques. Toute erreur est une `ApiException`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  static const _enteteIdempotence = 'Idempotency-Key';

  /// Renvoie le `verificationToken` à joindre au code SMS.
  Future<String> inscrire(DonneesInscription donnees) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/inscription',
      data: donnees.toJson(),
    );
    return json['verificationToken'] as String;
  }

  Future<Jetons> verifierTelephone({
    required String verificationToken,
    required String code,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/verifier-telephone',
      data: {'verificationToken': verificationToken, 'code': code},
    );
    return Jetons.fromJson(json);
  }

  /// Renvoie un NOUVEAU `verificationToken` : il remplace l'ancien.
  Future<String> renvoyerCode(String verificationToken) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/renvoyer-code',
      data: {'verificationToken': verificationToken},
    );
    return json['verificationToken'] as String;
  }

  Future<ResultatConnexion> connecter({
    required String identifiant,
    required String motDePasse,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/connexion',
      data: {'identifiant': identifiant, 'motDePasse': motDePasse},
    );
    if (json['verificationRequise'] == true) {
      return VerificationRequise(json['verificationToken'] as String);
    }
    return ConnexionReussie(Jetons.fromJson(json));
  }

  /// Même réponse que le compte existe ou non (pas d'énumération de comptes).
  Future<String> motDePasseOublie(String identifiant) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/mot-de-passe-oublie',
      data: {'identifiant': identifiant},
    );
    return json['verificationToken'] as String;
  }

  /// [cleIdempotence] : un UUID v4 généré UNE fois par action de
  /// l'utilisateur et réutilisé tel quel à chaque nouvel essai.
  Future<Jetons> reinitialiserMotDePasse({
    required String verificationToken,
    required String code,
    required String nouveauMotDePasse,
    required String cleIdempotence,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/reinitialiser-mot-de-passe',
      data: {
        'verificationToken': verificationToken,
        'code': code,
        'nouveauMotDePasse': nouveauMotDePasse,
      },
      options: Options(headers: {_enteteIdempotence: cleIdempotence}),
    );
    return Jetons.fromJson(json);
  }
}
