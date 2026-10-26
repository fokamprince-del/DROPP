import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/jetons.dart';
import '../../../core/auth/session.dart';
import '../../../core/upload/service_upload.dart';
import '../../../shared/modeles/contenu.dart';
import '../../auth/data/modeles_auth.dart';

/// Taille maximale de la photo de profil (images seulement), comme l'API.
const tailleMaxPhotoProfilMo = 5;

/// Profil complet (`GET /users/me`).
class ProfilComplet {
  const ProfilComplet({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.dateInscription,
    this.pseudo,
    this.email,
    this.telephone,
    this.photoUrl,
    this.sexe,
    this.boutiqueId,
    this.boutiqueNom,
  });

  final String id;
  final String prenom;
  final String nom;

  /// `@pseudo` public (mentions), en minuscules ; `null` s'il n'est pas choisi.
  final String? pseudo;
  final String? email;
  final String? telephone;
  final String? photoUrl;
  final Sexe? sexe;
  final DateTime dateInscription;

  /// Renseignés pour un vendeur qui a créé sa boutique.
  final String? boutiqueId;
  final String? boutiqueNom;

  String get nomComplet => '$prenom $nom'.trim();

  factory ProfilComplet.fromJson(Map<String, dynamic> json) {
    final vendeur = json['vendeur'] as Map<String, dynamic>?;
    final boutique = vendeur?['boutique'] as Map<String, dynamic>?;
    Sexe? sexe;
    for (final s in Sexe.values) {
      if (s.valeurApi == json['sexe']) sexe = s;
    }
    return ProfilComplet(
      id: json['id'] as String,
      prenom: json['prenom'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      pseudo: json['pseudo'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      photoUrl: lireUrl(json['photoProfilUrl']),
      sexe: sexe,
      dateInscription: dateDepuis(json['dateInscription']),
      boutiqueId: boutique?['id'] as String?,
      boutiqueNom: boutique?['nom'] as String?,
    );
  }
}

/// Format d'un pseudo, comme l'API : 3 à 30 caractères parmi minuscules,
/// chiffres, « _ » et « . ».
final formatPseudo = RegExp(r'^[a-z0-9_.]{3,30}$');

/// `@Awa_Wax ` → `awa_wax`.
String normaliserPseudo(String brut) =>
    brut.trim().replaceFirst(RegExp('^@'), '').toLowerCase();

/// Session ouverte sur un appareil (`GET /auth/sessions`).
class SessionAppareil {
  const SessionAppareil({
    required this.id,
    required this.dateCreation,
    this.actuelle = false,
    this.plateforme,
    this.modele,
    this.adresseIp,
    this.derniereUtilisation,
  });

  final String id;

  /// Celle de cet appareil.
  final bool actuelle;

  /// `ANDROID` ou `IOS`, si l'appareil a été déclaré.
  final String? plateforme;
  final String? modele;
  final String? adresseIp;
  final DateTime dateCreation;
  final DateTime? derniereUtilisation;

  factory SessionAppareil.fromJson(Map<String, dynamic> json) {
    final appareil = json['appareil'] as Map<String, dynamic>?;
    final derniere = json['dateDerniereUtilisation'];
    return SessionAppareil(
      id: json['id'] as String,
      actuelle: json['actuelle'] as bool? ?? false,
      plateforme: appareil?['plateforme'] as String?,
      modele: appareil?['modele'] as String?,
      adresseIp: json['adresseIpCreation'] as String?,
      dateCreation: dateDepuis(json['dateCreation']),
      derniereUtilisation: derniere == null ? null : dateDepuis(derniere),
    );
  }
}

final profilRepositoryProvider = Provider<ProfilRepository>(
  (ref) => ProfilRepository(ref.watch(apiClientProvider)),
);

/// Profil et sécurité du compte (session requise). Toute erreur est une
/// `ApiException`.
class ProfilRepository {
  ProfilRepository(this._api);

  final ApiClient _api;

  // ── Profil ───────────────────────────────────────────────────────────────

  Future<ProfilComplet> obtenir() async =>
      ProfilComplet.fromJson(await _api.get<Map<String, dynamic>>('/users/me'));

  /// `PATCH /users/me` : seuls les champs fournis changent. 409 si le pseudo
  /// est pris, 400 s'il est réservé (« dropp… », « admin »…).
  Future<ProfilComplet> modifier({
    String? prenom,
    String? nom,
    String? pseudo,
    Sexe? sexe,
  }) async => ProfilComplet.fromJson(
    await _api.patch<Map<String, dynamic>>(
      '/users/me',
      data: {
        if (prenom != null) 'prenom': prenom.trim(),
        if (nom != null) 'nom': nom.trim(),
        if (pseudo != null) 'pseudo': normaliserPseudo(pseudo),
        'sexe': ?sexe?.valeurApi,
      },
    ),
  );

  /// `GET /users/pseudo-disponible` (public).
  Future<bool> pseudoDisponible(String pseudo) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/users/pseudo-disponible',
      query: {'pseudo': normaliserPseudo(pseudo)},
    );
    return json['disponible'] as bool? ?? false;
  }

  /// `POST /users/me/photo/signature` : JPEG, PNG ou WebP, 5 Mo.
  Future<SignatureUpload> signaturePhoto(String typeMime, int taille) async =>
      SignatureUpload.fromJson(
        await _api.post<Map<String, dynamic>>(
          '/users/me/photo/signature',
          data: {'typeMime': typeMime, 'taille': taille},
        ),
      );

  /// `PUT /users/me/photo` : remplace la photo (l'ancienne est supprimée).
  Future<ProfilComplet> confirmerPhoto(String cleStockage) async =>
      ProfilComplet.fromJson(
        await _api.put<Map<String, dynamic>>(
          '/users/me/photo',
          data: {'cleStockage': cleStockage},
        ),
      );

  Future<ProfilComplet> supprimerPhoto() async => ProfilComplet.fromJson(
    await _api.delete<Map<String, dynamic>>('/users/me/photo'),
  );

  // ── Sécurité ─────────────────────────────────────────────────────────────

  /// `GET /auth/sessions` : sessions actives, la plus récente d'abord.
  Future<List<SessionAppareil>> sessions() async {
    final json = await _api.get<List<dynamic>>('/auth/sessions');
    return json
        .cast<Map<String, dynamic>>()
        .map(SessionAppareil.fromJson)
        .toList();
  }

  /// `DELETE /auth/sessions/:id` : déconnecte cet appareil-là.
  Future<void> revoquerSession(String id) =>
      _api.delete<Object?>('/auth/sessions/$id');

  /// `POST /auth/deconnecter-partout` : toutes les sessions, y compris
  /// celle-ci (fermer ensuite la session locale).
  Future<void> deconnecterPartout() =>
      _api.post<Object?>('/auth/deconnecter-partout');

  /// `POST /auth/mot-de-passe/changer` → **nouveaux jetons** : toutes les
  /// autres sessions sont fermées. 401 si l'ancien est faux, 400 s'il est
  /// trop faible ou identique.
  Future<Jetons> changerMotDePasse({
    required String ancien,
    required String nouveau,
  }) async => Jetons.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/auth/mot-de-passe/changer',
      data: {'ancienMotDePasse': ancien, 'nouveauMotDePasse': nouveau},
    ),
  );

  /// `POST /auth/telephone/changer` : code SMS envoyé au **nouveau** numéro.
  /// 401 si le mot de passe est faux, 409 si le numéro est déjà utilisé.
  Future<void> demanderChangementTelephone({
    required String nouveauTelephone,
    required String motDePasse,
  }) => _api.post<Object?>(
    '/auth/telephone/changer',
    data: {'nouveauTelephone': nouveauTelephone, 'motDePasse': motDePasse},
  );

  /// `POST /auth/telephone/confirmer` : le numéro est remplacé.
  Future<void> confirmerChangementTelephone({
    required String nouveauTelephone,
    required String code,
  }) => _api.post<Object?>(
    '/auth/telephone/confirmer',
    data: {'nouveauTelephone': nouveauTelephone, 'code': code},
  );

  /// `POST /auth/compte/supprimer` : 401 si le mot de passe est faux, 409
  /// s'il reste des commandes en cours (achats ou ventes). Toutes les
  /// sessions sont révoquées.
  Future<void> supprimerCompte(String motDePasse) => _api.post<Object?>(
    '/auth/compte/supprimer',
    data: {'motDePasse': motDePasse},
  );
}

/// Profil de l'utilisateur connecté ; relu à chaque changement de session.
final profilProvider = FutureProvider.autoDispose<ProfilComplet>((ref) {
  ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
  return ref.watch(profilRepositoryProvider).obtenir();
});

final sessionsProvider = FutureProvider.autoDispose<List<SessionAppareil>>(
  (ref) => ref.watch(profilRepositoryProvider).sessions(),
);
