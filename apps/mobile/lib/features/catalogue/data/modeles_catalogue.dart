import 'package:flutter/foundation.dart';

import '../../../shared/modeles/contenu.dart';

/// Catégorie de l'onglet Découvrir, avec ses sous-catégories. Le total d'une
/// catégorie parente inclut ses sous-catégories.
class Categorie {
  const Categorie({
    required this.id,
    required this.nom,
    this.nombreProduits = 0,
    this.enfants = const [],
  });

  final String id;
  final String nom;
  final int nombreProduits;
  final List<Categorie> enfants;

  factory Categorie.fromJson(Map<String, dynamic> json) => Categorie(
    id: json['id'] as String,
    nom: json['nom'] as String,
    nombreProduits: (json['nombreProduits'] as num? ?? 0).toInt(),
    enfants: (json['enfants'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Categorie.fromJson)
        .toList(),
  );
}

/// Produit dans une grille (catalogue, page boutique).
class ProduitResume {
  const ProduitResume({
    required this.id,
    required this.nom,
    required this.prixMin,
    required this.boutiqueId,
    this.imageUrl,
  });

  final String id;
  final String nom;

  /// Prix le plus bas parmi les variantes (« à partir de »).
  final num prixMin;
  final String boutiqueId;
  final String? imageUrl;

  factory ProduitResume.fromJson(Map<String, dynamic> json) => ProduitResume(
    id: json['id'] as String,
    nom: json['nom'] as String,
    prixMin: lireMontant(json['prixMin']),
    boutiqueId: json['boutiqueId'] as String,
    imageUrl: lireUrl(json['imagePrincipale']),
  );
}

class Variante {
  const Variante({
    required this.id,
    required this.stock,
    this.nom,
    this.prix,
    this.attributs = const {},
  });

  final String id;
  final String? nom;

  /// `null` : la variante est au prix de base du produit.
  final num? prix;
  final int stock;

  /// Par exemple `{taille: M, couleur: Rouge}`.
  final Map<String, String> attributs;

  bool get enStock => stock > 0;

  factory Variante.fromJson(Map<String, dynamic> json) {
    final attributs = json['attributs'];
    return Variante(
      id: json['id'] as String,
      nom: json['nom'] as String?,
      prix: json['prix'] == null ? null : lireMontant(json['prix']),
      stock: (json['stockDisponible'] as num? ?? 0).toInt(),
      attributs: attributs is Map
          ? {
              for (final e in attributs.entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {},
    );
  }
}

class ProduitDetail {
  const ProduitDetail({
    required this.id,
    required this.nom,
    required this.prixBase,
    required this.boutiqueId,
    this.description,
    this.variantes = const [],
    this.medias = const [],
  });

  final String id;
  final String nom;
  final String? description;
  final num prixBase;
  final String boutiqueId;
  final List<Variante> variantes;
  final List<MediaContenu> medias;

  /// Prix d'une variante : le sien, sinon le prix de base.
  num prixDe(Variante? variante) => variante?.prix ?? prixBase;

  num get prixMin => variantes.isEmpty
      ? prixBase
      : variantes.map(prixDe).reduce((a, b) => a < b ? a : b);

  /// Les prix diffèrent selon la variante : afficher « à partir de ».
  bool get prixVariable => variantes.map(prixDe).toSet().length > 1;

  int get stockTotal => variantes.fold(0, (s, v) => s + v.stock);

  /// Noms des attributs dans l'ordre d'apparition (`taille`, `couleur`…).
  List<String> get attributs =>
      {for (final v in variantes) ...v.attributs.keys}.toList();

  factory ProduitDetail.fromJson(Map<String, dynamic> json) {
    final description = (json['description'] as String?)?.trim();
    return ProduitDetail(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: description == null || description.isEmpty
          ? null
          : description,
      prixBase: lireMontant(json['prixBase']),
      boutiqueId: json['boutiqueId'] as String,
      variantes: (json['variantes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Variante.fromJson)
          .toList(),
      // `medias` : [{ id, ordre, media: {…} }], déjà triés.
      medias: (json['medias'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((m) => MediaContenu.fromJson(m['media'] as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Avis {
  const Avis({
    required this.id,
    required this.note,
    required this.auteur,
    required this.dateCreation,
    this.commentaire,
    this.auteurId,
  });

  final String id;
  final int note;
  final String? commentaire;

  /// Prénom seulement : le nom de famille n'est jamais public.
  final String auteur;

  /// Pour reconnaître ses propres avis (modifiables 30 jours).
  final String? auteurId;
  final DateTime dateCreation;

  factory Avis.fromJson(Map<String, dynamic> json) {
    final auteur = json['auteur'] as Map<String, dynamic>? ?? const {};
    final commentaire = (json['commentaire'] as String?)?.trim();
    return Avis(
      id: json['id'] as String,
      note: (json['note'] as num).toInt(),
      commentaire: commentaire == null || commentaire.isEmpty
          ? null
          : commentaire,
      auteur:
          (auteur['prenom'] as String?) ?? (auteur['pseudo'] as String?) ?? '',
      auteurId: auteur['id'] as String?,
      dateCreation: dateDepuis(json['dateCreation']),
    );
  }
}

@immutable
class ResumeAvis {
  const ResumeAvis({this.moyenne, this.total = 0, this.repartition = const {}});

  /// `null` tant qu'il n'y a aucun avis.
  final double? moyenne;
  final int total;

  /// Nombre d'avis par note, de 1 à 5.
  final Map<int, int> repartition;

  factory ResumeAvis.fromJson(Map<String, dynamic> json) {
    final repartition = json['repartition'] as Map? ?? const {};
    return ResumeAvis(
      moyenne: (json['moyenne'] as num?)?.toDouble(),
      total: (json['total'] as num? ?? 0).toInt(),
      repartition: {
        for (final e in repartition.entries)
          if ((int.tryParse('${e.key}'), e.value) case (
            final note?,
            final num n,
          ))
            note: n.toInt(),
      },
    );
  }
}

/// Tris de `GET /produits` (paramètre `tri`).
enum TriCatalogue {
  recents('recents'),
  prixCroissant('prix_croissant'),
  prixDecroissant('prix_decroissant'),
  populaires('populaires');

  const TriCatalogue(this.valeur);
  final String valeur;
}

/// Recherche et filtres du catalogue.
@immutable
class FiltresCatalogue {
  const FiltresCatalogue({
    this.q,
    this.categorieId,
    this.prixMin,
    this.prixMax,
    this.tri = TriCatalogue.recents,
    this.enStock = false,
  });

  final String? q;
  final String? categorieId;
  final int? prixMin;
  final int? prixMax;
  final TriCatalogue tri;
  final bool enStock;

  /// Pastille du bouton Filtres : prix, stock et tri (la catégorie a ses
  /// propres puces).
  int get nombreActifs =>
      (prixMin != null || prixMax != null ? 1 : 0) +
      (enStock ? 1 : 0) +
      (tri != TriCatalogue.recents ? 1 : 0);

  Map<String, dynamic> versQuery() => {
    if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
    'categorieId': ?categorieId,
    'prixMin': ?prixMin,
    'prixMax': ?prixMax,
    if (tri != TriCatalogue.recents) 'tri': tri.valeur,
    if (enStock) 'enStock': 'true',
  };

  /// Les valeurs `null` passées effacent le champ (contrairement à un
  /// `copyWith` classique) : utiliser [Garder] pour ne pas y toucher.
  FiltresCatalogue avec({
    Object? q = const Garder(),
    Object? categorieId = const Garder(),
    Object? prixMin = const Garder(),
    Object? prixMax = const Garder(),
    TriCatalogue? tri,
    bool? enStock,
  }) => FiltresCatalogue(
    q: q is Garder ? this.q : q as String?,
    categorieId: categorieId is Garder
        ? this.categorieId
        : categorieId as String?,
    prixMin: prixMin is Garder ? this.prixMin : prixMin as int?,
    prixMax: prixMax is Garder ? this.prixMax : prixMax as int?,
    tri: tri ?? this.tri,
    enStock: enStock ?? this.enStock,
  );

  /// Garde la recherche et la catégorie, efface le reste.
  FiltresCatalogue sansFiltres() =>
      FiltresCatalogue(q: q, categorieId: categorieId);

  @override
  bool operator ==(Object other) =>
      other is FiltresCatalogue &&
      other.q == q &&
      other.categorieId == categorieId &&
      other.prixMin == prixMin &&
      other.prixMax == prixMax &&
      other.tri == tri &&
      other.enStock == enStock;

  @override
  int get hashCode =>
      Object.hash(q, categorieId, prixMin, prixMax, tri, enStock);
}

/// Marqueur « ne pas modifier ce champ » pour [FiltresCatalogue.avec].
class Garder {
  const Garder();
}
