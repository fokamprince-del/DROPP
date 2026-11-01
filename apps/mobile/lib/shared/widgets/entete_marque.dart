import 'package:flutter/material.dart';

import '../theme/couleurs.dart';
import '../theme/espacements.dart';
import 'logo_dropp.dart';
import 'motif_ndop.dart';

/// Bandeau de marque des écrans d'accès : logo, titre, motif ndop.
class EnteteMarque extends StatelessWidget {
  const EnteteMarque({super.key, required this.titre, this.sousTitre});

  final String titre;
  final String? sousTitre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Couleurs.indigo, Couleurs.nuit],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacements.xl,
                Espacements.s,
                Espacements.xl,
                Espacements.xxl,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LogoDropp(taille: 30, anime: false),
                      const SizedBox(height: Espacements.s),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Couleurs.hibiscusVif,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: Espacements.l),
                      Semantics(
                        header: true,
                        child: Text(
                          titre,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Couleurs.blanc,
                          ),
                        ),
                      ),
                      if (sousTitre != null) ...[
                        const SizedBox(height: Espacements.s),
                        Text(
                          sousTitre!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Couleurs.texteSombre.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MotifNdop(
                hauteur: 8,
                couleurFonce: Couleurs.indigo,
                couleurClair: Couleurs.coton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
