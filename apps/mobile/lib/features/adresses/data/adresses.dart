import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

enum TypeAdresse {
  livraison('LIVRAISON'),
  facturation('FACTURATION'),
  autre('AUTRE');

  const TypeAdresse(this.valeur);
  final String valeur;

  static TypeAdresse depuis(Object? valeur) => TypeAdresse.values.firstWhere(
    (t) => t.valeur == valeur,
    orElse: () => autre,
  );
}

class Adresse {
  const Adresse({
    required this.id,
    required this.type,
    required this.ligne1,
    required this.ville,
    required this.pays,
    this.ligne2,
    this.region,
    this.codePostal,
    this.estPrincipale = false,
  });

  final String id;
  final TypeAdresse type;

  /// Quartier, rue, point de repère (« Akwa, rue Joffre, face pharmacie »).
  final String ligne1;
  final String? ligne2;
  final String ville;
  final String? region;
  final String pays;
  final String? codePostal;

  /// Adresse proposée par défaut ; une seule par compte.
  final bool estPrincipale;

  /// « Douala, Littoral, Cameroun ».
  String get localite =>
      [ville, ?region, pays].where((m) => m.trim().isNotEmpty).join(', ');

  factory Adresse.fromJson(Map<String, dynamic> json) {
    String? texte(String cle) {
      final v = (json[cle] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return Adresse(
      id: json['id'] as String,
      type: TypeAdresse.depuis(json['type']),
      ligne1: json['ligne1'] as String,
      ligne2: texte('ligne2'),
      ville: json['ville'] as String,
      region: texte('region'),
      pays: json['pays'] as String,
      codePostal: texte('codePostal'),
      estPrincipale: json['estPrincipale'] as bool? ?? false,
    );
  }
}

/// Champs d'une adresse à créer ou modifier.
class SaisieAdresse {
  const SaisieAdresse({
    required this.type,
    required this.ligne1,
    required this.ville,
    required this.pays,
    this.ligne2,
    this.region,
    this.codePostal,
    this.estPrincipale = false,
  });

  final TypeAdresse type;
  final String ligne1;
  final String? ligne2;
  final String ville;
  final String? region;
  final String pays;
  final String? codePostal;
  final bool estPrincipale;

  /// Les champs facultatifs vides sont envoyés vides (et non omis) pour
  /// qu'une modification puisse les effacer.
  Map<String, dynamic> toJson() => {
    'type': type.valeur,
    'ligne1': ligne1.trim(),
    'ligne2': ligne2?.trim() ?? '',
    'ville': ville.trim(),
    'region': region?.trim() ?? '',
    'pays': pays.trim(),
    'codePostal': codePostal?.trim() ?? '',
    'estPrincipale': estPrincipale,
  };
}

final adressesRepositoryProvider = Provider<AdressesRepository>(
  (ref) => AdressesRepository(ref.watch(apiClientProvider)),
);

/// Carnet d'adresses du client (profil client et téléphone vérifié). Toute
/// erreur est une `ApiException`.
///
/// Les commandes ne prennent pas encore d'adresse : la livraison n'est pas
/// branchée côté serveur. Le carnet sert à préparer ce moment.
class AdressesRepository {
  AdressesRepository(this._api);

  final ApiClient _api;

  /// `GET /clients/me` : adresses de la principale à la plus ancienne.
  Future<List<Adresse>> lister() async {
    final json = await _api.get<Map<String, dynamic>>('/clients/me');
    return (json['adresses'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Adresse.fromJson)
        .toList();
  }

  /// `POST /clients/me/adresses` : la première adresse devient principale ;
  /// une nouvelle adresse principale retire ce statut aux autres.
  Future<Adresse> ajouter(SaisieAdresse saisie) async => Adresse.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/clients/me/adresses',
      data: saisie.toJson(),
    ),
  );

  /// `PATCH /clients/me/adresses/:id`. 404 si elle n'est pas à l'utilisateur.
  Future<Adresse> modifier(String id, SaisieAdresse saisie) async =>
      Adresse.fromJson(
        await _api.patch<Map<String, dynamic>>(
          '/clients/me/adresses/$id',
          data: saisie.toJson(),
        ),
      );

  /// `DELETE /clients/me/adresses/:id`. Supprimer la principale ne désigne
  /// pas d'autre adresse principale (règle actuelle du serveur).
  Future<void> supprimer(String id) =>
      _api.delete<Object?>('/clients/me/adresses/$id');
}

final adressesProvider = FutureProvider.autoDispose<List<Adresse>>(
  (ref) => ref.watch(adressesRepositoryProvider).lister(),
);
