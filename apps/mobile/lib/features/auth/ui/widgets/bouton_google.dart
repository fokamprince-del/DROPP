import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../shared/theme/espacements.dart';

/// Bouton « avec Google ». Le logo est un REPÈRE PROVISOIRE : à remplacer par
/// le logo officiel et sa charte (couleurs du bouton, marges) lors de
/// l'implémentation. Ne pas le redessiner à la main.
class BoutonGoogle extends StatelessWidget {
  const BoutonGoogle({
    super.key,
    required this.libelle,
    required this.surAppui,
  });

  final String libelle;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: surAppui,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _RepereLogo(),
            const SizedBox(width: Espacements.m),
            Flexible(child: Text(libelle, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _RepereLogo extends StatelessWidget {
  const _RepereLogo() : size = 32, strokeWidth = 1;

  final double size;

  /// Facteur d'épaisseur du logo.
  /// 1 = épaisseur normale.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: strokeWidth,
        child: SvgPicture.asset(
          'assets/icons/google_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}