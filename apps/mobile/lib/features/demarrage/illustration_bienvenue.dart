import 'package:flutter/material.dart';

import '../../shared/theme/couleurs.dart';
import '../../shared/theme/rayons.dart';

/// Trois cartes dégradées en éventail, avec une icône. Décoratif : ignoré par
/// les lecteurs d'écran.
class IllustrationBienvenue extends StatelessWidget {
  const IllustrationBienvenue({super.key, required this.icones});

  /// Trois icônes : carte principale, puis les deux cartes d'appoint.
  final List<IconData> icones;

  static const _degrades = [
    [Couleurs.hibiscus, Couleurs.indigo],
    [Color(0xFF1F8A5B), Couleurs.indigo],
    [Color(0xFFE07A3C), Couleurs.hibiscus],
  ];

  Widget _carte(int i, double taille, double angle, Offset decalage) {
    return Transform.translate(
      offset: decalage,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: taille,
          height: taille * 1.15,
          decoration: BoxDecoration(
            borderRadius: Rayons.borduresCarte,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _degrades[i],
            ),
          ),
          child: Icon(icones[i], size: taille * 0.4, color: Couleurs.blanc),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _carte(1, 120, 0.12, const Offset(70, -20)),
            _carte(2, 110, -0.10, const Offset(-70, 30)),
            _carte(0, 140, -0.03, Offset.zero),
          ],
        ),
      ),
    );
  }
}
