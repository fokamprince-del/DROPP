import 'package:flutter/material.dart';

import '../theme/couleurs.dart';
import '../theme/typographie.dart';
import 'image_reseau.dart';

/// Logo rond de la boutique, ou son initiale sur un dégradé indigo quand
/// l'API n'en fournit pas. Décoratif : le nom est toujours affiché à côté.
class AvatarBoutique extends StatelessWidget {
  const AvatarBoutique({
    super.key,
    required this.nom,
    this.taille = 36,
    this.logoUrl,
  });

  final String nom;
  final double taille;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    if (url != null) {
      return ExcludeSemantics(
        child: ClipOval(
          child: ImageReseau(url: url, largeur: taille, hauteur: taille),
        ),
      );
    }

    final initiale = nom.trim().isEmpty
        ? '?'
        : nom.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: taille,
        height: taille,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3446A8), Couleurs.indigo],
          ),
        ),
        child: Text(
          initiale,
          style: TextStyle(
            fontFamily: Typographie.titre,
            fontWeight: FontWeight.w700,
            fontSize: taille * 0.45,
            height: 1,
            color: Couleurs.blanc,
          ),
        ),
      ),
    );
  }
}
