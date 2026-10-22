import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/contexte_l10n.dart';
import '../../shared/theme/couleurs.dart';
import '../../shared/theme/espacements.dart';
import '../../shared/widgets/logo_dropp.dart';
import '../../shared/widgets/motif_ndop.dart';

/// Affichée le temps de lire la session au lancement.
class PageDemarrage extends StatelessWidget {
  const PageDemarrage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Couleurs.nuit,
        body: SafeArea(
          child: Column(
            children: [
              const MotifNdop(
                hauteur: 20,
                couleurFonce: Couleurs.indigo,
                couleurClair: Couleurs.coton,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LogoDropp(),
                      const SizedBox(height: Espacements.m),
                      Text(
                        context.l10n.baselineApp,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Couleurs.texteSombre.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const MotifNdop(
                hauteur: 20,
                couleurFonce: Couleurs.indigo,
                couleurClair: Couleurs.coton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
