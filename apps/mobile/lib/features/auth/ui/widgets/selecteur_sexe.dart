import 'package:flutter/material.dart';

import '../../../../../core/l10n/contexte_l10n.dart';
import '../../../../../shared/theme/espacements.dart';
import '../../data/modeles_auth.dart';
import '../../domain/validateurs.dart';
import 'libelles_erreurs.dart';

/// Aucune valeur préremplie : l'utilisateur choisit.
class SelecteurSexe extends StatelessWidget {
  const SelecteurSexe({
    super.key,
    required this.valeur,
    required this.surChangement,
    this.afficherErreur = false,
  });

  final Sexe? valeur;
  final ValueChanged<Sexe?> surChangement;

  /// À activer par l'écran quand il tente de valider sans choix.
  final bool afficherErreur;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.champSexe, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: Espacements.xs),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<Sexe>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
            segments: [
              ButtonSegment(
                value: Sexe.masculin,
                label: Text(l10n.sexeMasculin),
              ),
              ButtonSegment(value: Sexe.feminin, label: Text(l10n.sexeFeminin)),
              ButtonSegment(value: Sexe.autre, label: Text(l10n.sexeAutre)),
            ],
            selected: valeur == null ? <Sexe>{} : {valeur!},
            onSelectionChanged: (choix) =>
                surChangement(choix.isEmpty ? null : choix.first),
          ),
        ),
        if (afficherErreur && valeur == null)
          Padding(
            padding: const EdgeInsets.only(top: Espacements.s),
            child: Text(
              ErreurChamp.requis.libelle(l10n),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: schema.error),
            ),
          ),
      ],
    );
  }
}
