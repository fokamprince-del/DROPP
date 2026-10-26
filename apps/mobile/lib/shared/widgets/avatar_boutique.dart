import 'package:flutter/material.dart';

import '../theme/couleurs.dart';
import '../theme/typographie.dart';

/// Pastille ronde avec l'initiale de la boutique (l'API ne renvoie pas encore
/// de logo). Décorative : le nom est toujours affiché à côté.
class AvatarBoutique extends StatelessWidget {
  const AvatarBoutique({super.key, required this.nom, this.taille = 36});

  final String nom;
  final double taille;

  @override
  Widget build(BuildContext context) {
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
