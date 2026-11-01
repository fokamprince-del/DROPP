import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/rayons.dart';

/// Carte sous une ligne de balayage hibiscus, avec des coins de visée.
/// Habille l'attente de la lecture : décoratif, ignoré des lecteurs d'écran
/// (le texte « lecture en cours » est annoncé à côté). Sans animation si
/// l'appareil demande de réduire les animations.
class AnimationScanCarte extends StatefulWidget {
  const AnimationScanCarte({super.key, this.fichier});

  /// Recto de la carte, si on l'a en mémoire ; sinon une silhouette.
  final XFile? fichier;

  @override
  State<AnimationScanCarte> createState() => _AnimationScanCarteState();
}

class _AnimationScanCarteState extends State<AnimationScanCarte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _demarre = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) return;
    _demarre = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controleur.value = 0.5;
    } else {
      _controleur.repeat();
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fichier = widget.fichier;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: Rayons.borduresCarte,
        child: AspectRatio(
          aspectRatio: 85.6 / 54,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (fichier != null)
                Image.file(
                  File(fichier.path),
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const _SilhouetteCarte(),
                )
              else
                const _SilhouetteCarte(),
              const ColoredBox(color: Colors.black26),
              CustomPaint(
                painter: _PeintreScan(
                  animation: _controleur,
                  fixe: MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SilhouetteCarte extends StatelessWidget {
  const _SilhouetteCarte();

  Widget _barre(double largeur) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: largeur,
      child: Container(
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Couleurs.nuit,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_barre(1), _barre(0.75), _barre(0.9), _barre(0.55)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeintreScan extends CustomPainter {
  _PeintreScan({required this.animation, required this.fixe})
    : super(repaint: animation);

  final Animation<double> animation;
  final bool fixe;

  static const _couleur = Couleurs.hibiscusVif;

  @override
  void paint(Canvas canvas, Size size) {
    final coin = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const marge = 10.0;
    const longueur = 22.0;
    final gauche = marge;
    final droite = size.width - marge;
    final haut = marge;
    final bas = size.height - marge;

    void angle(double x, double y, double dx, double dy) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + dx * longueur, y), coin)
        ..drawLine(Offset(x, y), Offset(x, y + dy * longueur), coin);
    }

    angle(gauche, haut, 1, 1);
    angle(droite, haut, -1, 1);
    angle(gauche, bas, 1, -1);
    angle(droite, bas, -1, -1);

    if (fixe) return;

    final y = Curves.easeInOut.transform(animation.value) * size.height;
    const trainee = 56.0;
    final zone = Rect.fromLTWH(0, y - trainee, size.width, trainee);
    final degrade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_couleur.withValues(alpha: 0), _couleur.withValues(alpha: 0.4)],
    ).createShader(zone);
    canvas
      ..drawRect(zone, Paint()..shader = degrade)
      ..drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = _couleur
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_PeintreScan ancien) => ancien.fixe != fixe;
}
