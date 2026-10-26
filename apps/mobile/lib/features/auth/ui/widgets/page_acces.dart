import 'package:flutter/material.dart';

import '../../../../shared/theme/espacements.dart';

/// Page d'écran d'accès : flèche retour, titre, contenu défilant centré.
class PageAcces extends StatelessWidget {
  const PageAcces({
    super.key,
    required this.titre,
    required this.enfants,
    this.sousTitre,
    this.actions = const [],
  });

  final String titre;
  final String? sousTitre;
  final List<Widget> enfants;

  /// Boutons à droite de la barre (« Plus tard »…).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: actions),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                Espacements.xl,
                Espacements.s,
                Espacements.xl,
                Espacements.xl,
              ),
              children: [
                Text(titre, style: theme.textTheme.headlineSmall),
                if (sousTitre != null) ...[
                  const SizedBox(height: Espacements.s),
                  Text(
                    sousTitre!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Espacements.xl),
                ...enfants,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
