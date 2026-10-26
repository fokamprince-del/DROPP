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

  // ── Email (session requise) ──────────────────────────────────────────────
  // Le serveur envoie déjà un code automatiquement après l'activation par
  // SMS si un email a été donné à l'inscription. Codes à 6 chiffres envoyés
  // par email (Resend, via le worker), valables 5 minutes, 60 s entre deux
  // envois.

  /// `POST /auth/email/envoyer-code` : (r)envoie un code à l'adresse
  /// actuelle et la renvoie. 400 s'il n'y a pas d'email, 409 s'il est déjà
  /// vérifié, 429 si on redemande trop vite.
  Future<String> envoyerCodeEmail() async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/email/envoyer-code',
    );
    return json['email'] as String;
  }

  /// `POST /auth/email/changer` : envoie un code à la **nouvelle** adresse,
  /// qui n'est enregistrée qu'après [verifierEmail]. [motDePasse] est exigé
  /// si le compte en a un (401 s'il est faux). 409 si l'adresse est déjà
  /// utilisée, 400 si c'est déjà la sienne.
  Future<String> changerEmail({
    required String email,
    required String motDePasse,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/email/changer',
      data: {'email': email.trim().toLowerCase(), 'motDePasse': motDePasse},
    );
    return json['email'] as String;
  }

  /// `POST /auth/email/verifier` : valide le code. [email] seulement pour un
  /// changement d'adresse (sinon l'adresse actuelle). 400 si le code est faux
  /// ou expiré, 410 après trop d'essais (redemander un code), 409 si
  /// l'adresse a été prise entre-temps.
  Future<void> verifierEmail(String code, {String? email}) =>
      _api.post<Object?>(
        '/auth/email/verifier',
        data: {'code': code, 'email': ?email},
      );
}
