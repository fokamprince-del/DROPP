import '../../../shared/modeles/contenu.dart';

/// Produit lié à une publication (5 au plus).
class ProduitLie {
  const ProduitLie({
    required this.id,
    required this.nom,
    required this.prix,
    this.imageUrl,
  });

  final String id;
  final String nom;
  final num prix;
  final String? imageUrl;

  factory ProduitLie.fromJson(Map<String, dynamic> json) => ProduitLie(
    id: json['id'] as String,
    nom: json['nom'] as String,
    prix: json['prixBase'] as num,
    imageUrl: json['imageUrl'] as String?,
  );
}

class Publication {
  const Publication({
    required this.id,
    required this.boutique,
    required this.medias,
    required this.produits,
    required this.dateCreation,
    this.contenu,
    this.visibilite = Visibilite.public,
    this.nombreVues = 0,
    this.likes = 0,
    this.commentaires = 0,
  });

  final String id;
  final String? contenu;
  final Visibilite visibilite;
  final int nombreVues;
  final DateTime dateCreation;
  final BoutiqueResume boutique;

  /// Dans l'ordre choisi par le vendeur.
  final List<MediaContenu> medias;
  final List<ProduitLie> produits;
  final int likes;
  final int commentaires;

  factory Publication.fromJson(Map<String, dynamic> json) {
    // `medias` : [{ id, ordre, media: {…} }], déjà triés par l'API.
    final medias = (json['medias'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((m) => MediaContenu.fromJson(m['media'] as Map<String, dynamic>))
        .toList();
    final produits = (json['produits'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ProduitLie.fromJson)
        .toList();
    final contenu = (json['contenu'] as String?)?.trim();
    return Publication(
      id: json['id'] as String,
      contenu: contenu == null || contenu.isEmpty ? null : contenu,
      visibilite: visibiliteDepuis(json['visibilite']),
      nombreVues: (json['nombreVues'] as num? ?? 0).toInt(),
      dateCreation: dateDepuis(json['dateCreation']),
      boutique: BoutiqueResume.fromJson(
        json['boutique'] as Map<String, dynamic>,
      ),
      medias: medias,
      produits: produits,
      likes: (json['likes'] as num? ?? 0).toInt(),
      commentaires: (json['commentaires'] as num? ?? 0).toInt(),
    );
  }
}
