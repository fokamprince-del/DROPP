import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/etoiles.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../../../utils/format.dart';
import '../../../avis/data/mes_avis.dart';
import '../../../avis/ui/avis_ui.dart';
import '../../data/modeles_catalogue.dart';

/// Un avis : étoiles, prénom, date et commentaire. Sur son propre avis, un
/// menu permet de le modifier ou de le supprimer (30 jours).
class CarteAvis extends ConsumerWidget {
  const CarteAvis({super.key, required this.avis, this.surChangement});

  final Avis avis;

  /// Appelé après une modification ou une suppression (recharger la liste).
  final VoidCallback? surChangement;

  Future<void> _modifier(BuildContext context, WidgetRef ref) async {
    final fait = await ouvrirNotation(
      context,
      titre: context.l10n.avisModifier,
      noteInitiale: avis.note,
      commentaireInitial: avis.commentaire,
      envoyer: (note, commentaire) => ref
          .read(mesAvisRepositoryProvider)
          .modifier(avis.id, note: note, commentaire: commentaire),
    );
    if (fait) surChangement?.call();
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.avisSupprimerTitre),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.supprimer),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await ref.read(mesAvisRepositoryProvider).supprimer(avis.id);
      surChangement?.call();
    } on ApiException catch (e) {
      messager.showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {TypeErreurApi.interdit: l10n.avisNonModifiable},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estMien =
        avis.auteurId != null &&
        ref.watch(utilisateurConnecteProvider)?.id == avis.auteurId;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Espacements.m),
        decoration: BoxDecoration(
          color: schema.surface,
          borderRadius: Rayons.borduresCarte,
          border: Border.all(color: schema.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    avis.auteur,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: Espacements.s),
                Semantics(
                  label: l10n.avisNote(avis.note),
                  child: Etoiles(note: avis.note.toDouble()),
                ),
                if (estMien) ...[
                  const Spacer(),
                  PopupMenuButton<bool>(
                    tooltip: l10n.avisMesActions,
                    onSelected: (modifier) => unawaited(
                      modifier
                          ? _modifier(context, ref)
                          : _supprimer(context, ref),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: true,
                        child: Text(l10n.avisModifier),
                      ),
                      PopupMenuItem(value: false, child: Text(l10n.supprimer)),
                    ],
                  ),
                ],
              ],
            ),
            if (avis.commentaire != null) ...[
              const SizedBox(height: Espacements.xs),
              Text(avis.commentaire!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: Espacements.xs),
            Text(
              '${l10n.avisAchatVerifie} · ${tempsRelatif(l10n, avis.dateCreation)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: schema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moyenne en grand, étoiles, total et répartition des notes.
class ResumeAvisVue extends StatelessWidget {
  const ResumeAvisVue({super.key, required this.resume});

  final ResumeAvis resume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final moyenne = resume.moyenne ?? 0;
    final plusGrand = resume.repartition.values.fold(
      0,
      (a, b) => a > b ? a : b,
    );

    return Padding(
      padding: const EdgeInsets.all(Espacements.l),
      child: Row(
        children: [
          Semantics(
            label: l10n.avisMoyenne(formaterNote(moyenne, l10n.localeName)),
            excludeSemantics: true,
            child: Column(
              children: [
                Text(
                  formaterNote(moyenne, l10n.localeName),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: Typographie.titre,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Etoiles(note: moyenne, taille: 16),
                const SizedBox(height: Espacements.xs),
                Text(
                  l10n.avisNombre(resume.total),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: schema.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Espacements.xl),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                children: [
                  for (var note = 5; note >= 1; note--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            child: Text(
                              '$note',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(width: Espacements.xs),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: plusGrand == 0
                                    ? 0
                                    : (resume.repartition[note] ?? 0) /
                                          plusGrand,
                                color: Etoiles.couleur,
                                backgroundColor: schema.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
