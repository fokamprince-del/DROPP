import 'package:flutter/material.dart';

/// Note sur 5 en étoiles (lecture seule), couleur kola de la maquette.
class Etoiles extends StatelessWidget {
  const Etoiles({super.key, required this.note, this.taille = 14});

  /// De 0 à 5 ; arrondie à la demi-étoile.
  final double note;
  final double taille;

  static const couleur = Color(0xFFE5A92E);

  @override
  Widget build(BuildContext context) {
    final demi = (note * 2).round() / 2;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              demi >= i
                  ? Icons.star_rounded
                  : demi >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: taille,
              color: couleur,
            ),
        ],
      ),
    );
  }
}
