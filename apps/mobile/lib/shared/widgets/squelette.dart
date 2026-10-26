import 'package:flutter/material.dart';

/// Bloc gris qui « respire » pendant un chargement (la maquette préfère les
/// squelettes aux spinners). Ignoré par les lecteurs d'écran.
class Squelette extends StatefulWidget {
  const Squelette({
    super.key,
    this.largeur,
    this.hauteur,
    this.rayon = 8,
    this.cercle = false,
  });

  final double? largeur;
  final double? hauteur;
  final double rayon;
  final bool cercle;

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.55,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controleur.stop();
      _controleur.value = 1;
    } else if (!_controleur.isAnimating) {
      _controleur.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controleur,
        child: Container(
          width: widget.largeur,
          height: widget.hauteur,
          decoration: BoxDecoration(
            color: couleur,
            shape: widget.cercle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.cercle
                ? null
                : BorderRadius.circular(widget.rayon),
          ),
        ),
      ),
    );
  }
}
