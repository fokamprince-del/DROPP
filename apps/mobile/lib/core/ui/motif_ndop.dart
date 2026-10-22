import 'package:flutter/material.dart';

/// Bandeau en damier inspiré du ndop (étoffe indigo et blanche des
/// Grassfields). Purement décoratif : ignoré par les lecteurs d'écran.
class MotifNdop extends StatelessWidget {
  const MotifNdop({
    super.key,
    required this.hauteur,
    required this.couleurFonce,
    required this.couleurClair,
    this.tailleCase = 8,
  });

  final double hauteur;
  final Color couleurFonce;
  final Color couleurClair;
  final double tailleCase;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: hauteur,
          width: double.infinity,
          child: CustomPaint(
            painter: _PeintreNdop(
              couleurFonce: couleurFonce,
              couleurClair: couleurClair,
              tailleCase: tailleCase,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeintreNdop extends CustomPainter {
  const _PeintreNdop({
    required this.couleurFonce,
    required this.couleurClair,
    required this.tailleCase,
  });

  final Color couleurFonce;
  final Color couleurClair;
  final double tailleCase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final fond = Paint()..style = PaintingStyle.fill;
    final trait = Paint()
      ..color = couleurClair
      ..style = PaintingStyle.stroke
      ..strokeWidth = tailleCase / 8;

    final colonnes = (size.width / tailleCase).ceil();
    final lignes = (size.height / tailleCase).ceil();

    for (var l = 0; l < lignes; l++) {
      for (var c = 0; c < colonnes; c++) {
        final fonce = (l + c).isEven;
        final case_ = Rect.fromLTWH(
          c * tailleCase,
          l * tailleCase,
          tailleCase,
          tailleCase,
        );
        canvas.drawRect(case_, fond..color = fonce ? couleurFonce : couleurClair);
        if (fonce) {
          canvas.drawLine(case_.topLeft, case_.bottomRight, trait);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreNdop ancien) =>
      ancien.couleurFonce != couleurFonce ||
      ancien.couleurClair != couleurClair ||
      ancien.tailleCase != tailleCase;
}