import 'package:flutter/material.dart';

import '../theme/couleurs.dart';
import '../theme/typographie.dart';

class LogoDropp extends StatefulWidget {
  const LogoDropp({super.key, this.taille = 48, this.anime = true});

  final double taille;
  final bool anime;

  @override
  State<LogoDropp> createState() => _LogoDroppState();
}

class _LogoDroppState extends State<LogoDropp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _courbe = CurvedAnimation(
    parent: _controleur,
    curve: Curves.easeOutCubic,
  );
  bool _demarre = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) return;
    _demarre = true;
    final reduire = MediaQuery.disableAnimationsOf(context);
    if (widget.anime && !reduire) {
      _controleur.forward();
    } else {
      _controleur.value = 1;
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: Typographie.titre,
      fontWeight: FontWeight.w700,
      fontSize: widget.taille,
      letterSpacing: -1,
      height: 1,
      color: Couleurs.blanc,
    );

    return Semantics(
      label: 'DROPP',
      excludeSemantics: true,
      child: FadeTransition(
        opacity: _courbe,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(_courbe),
          child: Text.rich(
            TextSpan(
              style: style,
              children: const [
                TextSpan(text: 'DROP'),
                TextSpan(
                  text: 'P',
                  style: TextStyle(color: Couleurs.hibiscusVif),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}