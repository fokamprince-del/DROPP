import '../../../shared/modeles/contenu.dart';

/// Boutique publique : résultat de recherche (`GET /boutiques`) ou page
/// complète (`GET /boutiques/:id`, avec statistiques et état d'abonnement).
class Boutique {
  const Boutique({
    required this.id,
    required this.nom,
    this.description,
    this.biographie,
    this.ville,
    this.quartier,
    this.logoUrl,
    this.banniereUrl,
    this.abonnes = 0,
    this.produits,
    this.publications,
    this.estAbonne = false,
    this.estMaBoutique = false,
  });

  final String id;
  final String nom;
  final String? description;
  final String? biographie;
  final String? ville;
  final String? quartier;
  final String? logoUrl;
  final String? banniereUrl;
  final int abonnes;

  /// Page complète seulement.
  final int? produits;
  final int? publications;
  final bool estAbonne;
  final bool estMaBoutique;

  /// « Douala, Akwa », ou `null`.
  String? get lieu {
    final morceaux = [
      ville,
      quartier,
    ].whereType<String>().where((m) => m.trim().isNotEmpty);
    return morceaux.isEmpty ? null : morceaux.join(', ');
  }

  BoutiqueResume get resume => BoutiqueResume(id: id, nom: nom);

  factory Boutique.fromJson(Map<String, dynamic> json) {
    final stats = json['statistiques'] as Map<String, dynamic>?;
    String? texte(String cle) {
      final v = (json[cle] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return Boutique(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: texte('description'),
      biographie: texte('biographie'),
      ville: texte('ville'),
      quartier: texte('quartier'),
      logoUrl: lireUrl(json['logoUrl']),
      banniereUrl: lireUrl(json['banniereUrl']),
      abonnes: ((stats?['abonnes'] ?? json['abonnes']) as num? ?? 0).toInt(),
      produits: (stats?['produits'] as num?)?.toInt(),
      publications: (stats?['publications'] as num?)?.toInt(),
      estAbonne: json['estAbonne'] as bool? ?? false,
      estMaBoutique: json['estMaBoutique'] as bool? ?? false,
    );
  }
}

/// Ligne de `GET /moi/abonnements`.
class AbonnementBoutique {
  const AbonnementBoutique({
    required this.boutiqueId,
    required this.nom,
    required this.depuis,
    this.logoUrl,
    this.muet = false,
  });

  final String boutiqueId;
  final String nom;
  final String? logoUrl;
  final bool muet;
  final DateTime depuis;

  factory AbonnementBoutique.fromJson(Map<String, dynamic> json) {
    final boutique = json['boutique'] as Map<String, dynamic>;
    return AbonnementBoutique(
      boutiqueId: boutique['id'] as String,
      nom: boutique['nom'] as String,
      logoUrl: lireUrl(boutique['logoUrl']),
      muet: json['muet'] as bool? ?? false,
      depuis: dateDepuis(json['depuis']),
    );
  }
}
