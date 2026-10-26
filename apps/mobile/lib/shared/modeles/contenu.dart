/// Blocs communs aux publications et aux stories, tels que l'API les renvoie.
library;

enum TypeMedia { image, video }

enum Visibilite { public, abonnes }

Visibilite visibiliteDepuis(Object? valeur) =>
    valeur == 'ABONNES' ? Visibilite.abonnes : Visibilite.public;

DateTime dateDepuis(Object? valeur) =>
    DateTime.parse(valeur! as String).toLocal();

class BoutiqueResume {
  const BoutiqueResume({required this.id, required this.nom});

  final String id;
  final String nom;

  factory BoutiqueResume.fromJson(Map<String, dynamic> json) =>
      BoutiqueResume(id: json['id'] as String, nom: json['nom'] as String);
}

class MediaContenu {
  const MediaContenu({
    required this.id,
    required this.type,
    required this.url,
    this.largeur,
    this.hauteur,
    this.duree,
  });

  final String id;
  final TypeMedia type;

  /// Publique ou signée (contenu réservé aux abonnés) : à ne pas mettre en
  /// cache au-delà de la session.
  final String url;
  final int? largeur;
  final int? hauteur;

  /// Vidéos seulement, quand le vendeur l'a fournie.
  final Duration? duree;

  bool get estVideo => type == TypeMedia.video;

  /// Largeur / hauteur, ou `null` si les dimensions sont inconnues.
  double? get ratio {
    final l = largeur;
    final h = hauteur;
    if (l == null || h == null || l <= 0 || h <= 0) return null;
    return l / h;
  }

  factory MediaContenu.fromJson(Map<String, dynamic> json) {
    final duree = (json['duree'] as num?)?.toInt();
    return MediaContenu(
      id: json['id'] as String,
      type: json['typeMedia'] == 'VIDEO' ? TypeMedia.video : TypeMedia.image,
      url: json['url'] as String,
      largeur: (json['largeur'] as num?)?.toInt(),
      hauteur: (json['hauteur'] as num?)?.toInt(),
      duree: duree == null ? null : Duration(seconds: duree),
    );
  }
}

/// Montant de l'API : un nombre, ou une chaîne pour les `Decimal` Prisma
/// (`"25000"`, `"4500.50"`).
num lireMontant(Object? valeur) => switch (valeur) {
  final num n => n,
  final String s => num.tryParse(s) ?? 0,
  _ => 0,
};

/// Image facultative d'une boutique (logo) : `null` si absente.
String? lireUrl(Object? valeur) =>
    valeur is String && valeur.isNotEmpty ? valeur : null;
