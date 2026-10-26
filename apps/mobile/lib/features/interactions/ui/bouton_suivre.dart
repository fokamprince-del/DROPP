import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/contexte_l10n.dart';
import '../application/interactions.dart';
import 'actions_connectees.dart';

/// « Suivre » (plein) ou « Abonné » (contour). Un visiteur est envoyé vers la
/// connexion.
class BoutonSuivre extends ConsumerWidget {
  const BoutonSuivre({
    super.key,
    required this.boutiqueId,
    this.abonnesRecus = 0,
    this.compact = false,
    this.largeurPleine = false,
  });

  final String boutiqueId;

  /// Nombre d'abonnés connu de l'écran, pour la mise à jour optimiste.
  final int abonnesRecus;
  final bool compact;
  final bool largeurPleine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final suivie = ref.watch(
      interactionsProvider.select((e) => e.abonnements.contains(boutiqueId)),
    );
    final affiches = ref.watch(
      interactionsProvider.select((e) => e.abonnes(boutiqueId, abonnesRecus)),
    );

    void basculer() => unawaited(
      actionConnectee(
        context,
        ref,
        () => ref
            .read(interactionsProvider.notifier)
            .basculerAbonnement(boutiqueId, affiches),
      ),
    );

    final taille = compact ? const Size(0, 36) : const Size(0, 48);
    final padding = compact ? const EdgeInsets.symmetric(horizontal: 14) : null;
    final Widget bouton = suivie
        ? OutlinedButton.icon(
            onPressed: basculer,
            style: OutlinedButton.styleFrom(
              minimumSize: taille,
              padding: padding,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.boutiqueAbonne),
          )
        : FilledButton(
            onPressed: basculer,
            style: FilledButton.styleFrom(
              minimumSize: taille,
              padding: padding,
            ),
            child: Text(l10n.boutiqueSuivre),
          );

    return Semantics(
      toggled: suivie,
      child: largeurPleine
          ? SizedBox(width: double.infinity, child: bouton)
          : bouton,
    );
  }
}
