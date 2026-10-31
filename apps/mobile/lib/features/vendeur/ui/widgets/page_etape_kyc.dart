import 'package:flutter/material.dart';

import '../../../../shared/theme/espacements.dart';
import 'indicateur_etapes.dart';

/// Page d'une étape : indicateur, titre, explication, contenu défilant, et
/// actions fixes en bas (le bouton retour Android et la flèche pilotent la
/// pile de navigation).
class PageEtapeKyc extends StatelessWidget {
  const PageEtapeKyc({
    super.key,
    required this.etape,
    required this.titre,
    required this.explication,
    required this.enfants,
    required this.actions,
    this.total,
  });

  final int etape;
  final int? total;
  final String titre;
  final String explication;
  final List<Widget> enfants;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Espacements.xl,
                      Espacements.s,
                      Espacements.xl,
                      Espacements.xl,
                    ),
                    children: [
                      IndicateurEtapes(etape: etape, total: total ?? 4),
                      const SizedBox(height: Espacements.l),
                      Text(titre, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: Espacements.s),
                      Text(
                        explication,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Espacements.xl),
                      ...enfants,
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espacements.xl,
                    Espacements.m,
                    Espacements.xl,
                    Espacements.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: Espacements.m),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}