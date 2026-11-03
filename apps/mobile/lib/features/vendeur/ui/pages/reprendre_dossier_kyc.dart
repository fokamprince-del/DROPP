import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../application/dossier_kyc.dart';
import '../../data/modeles_kyc.dart';
import '../../domain/etape_kyc.dart';
import '../../domain/messages_kyc.dart';
import '../widgets/dossier_en_verification.dart';

/// Parcours de vérification : liste des étapes (toutes les étapes terminées
/// restent modifiables) et bouton pour reprendre là où le serveur dit que le
/// dossier en est.
class ReprendreDossierKyc extends ConsumerWidget {
  const ReprendreDossierKyc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ref
        .watch(dossierKycProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(Espacements.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (erreur, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BandeauMessage(
                message: messageErreurKyc(l10n, ApiException.depuis(erreur)),
              ),
              const SizedBox(height: Espacements.l),
              OutlinedButton(
                onPressed: () => ref.invalidate(dossierKycProvider),
                child: Text(l10n.reessayer),
              ),
            ],
          ),
          data: (dossier) {
            final etape = etapeSuivante(dossier);
            if (dossier != null && etape == EtapeKyc.dossier) {
              return DossierEnVerification(dossier: dossier);
            }
            final statuts = statutDesEtapes(dossier);
            final avance =
                dossier != null &&
                (dossier.documents.isNotEmpty || dossier.donnees.complet);
            final motif = dossier?.motifRejet;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (dossier?.statut == StatutDossierKyc.rejete) ...[
                  BandeauMessage(
                    message: (motif == null || motif.isEmpty)
                        ? l10n.kycDossierRefuseSansMotif
                        : l10n.kycDossierRefuse(motif),
                  ),
                  const SizedBox(height: Espacements.l),
                ],
                Text(
                  l10n.kycIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Espacements.xl),
                Text(l10n.kycTonParcours, style: theme.textTheme.titleMedium),
                const SizedBox(height: Espacements.m),
                for (final entree in statuts.entries)
                  _LigneEtape(etape: entree.key, statut: entree.value),
                const SizedBox(height: Espacements.m),
                FilledButton(
                  onPressed: () =>
                      unawaited(context.push<void>(routePourEtape(etape))),
                  child: Text(avance ? l10n.kycReprendre : l10n.kycCommencer),
                ),
              ],
            );
          },
        );
  }
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({required this.etape, required this.statut});

  final EtapeKyc etape;
  final StatutEtapeKyc statut;

  String _titre(AppLocalizations l10n) => switch (etape) {
    EtapeKyc.cni => l10n.kycEtapeCniTitre,
    EtapeKyc.informations => l10n.kycEtapeInfosTitre,
    EtapeKyc.selfie => l10n.kycEtapeSelfieTitre,
    EtapeKyc.recapitulatif => l10n.kycEtapeRecapTitre,
    EtapeKyc.dossier => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final verrouillee = statut == StatutEtapeKyc.verrouillee;

    final IconData icone;
    final Color couleur;
    final String texteStatut;
    switch (statut) {
      case StatutEtapeKyc.terminee:
        icone = Icons.check_circle;
        couleur = metier.succes;
        texteStatut = l10n.kycEtapeTerminee;
      case StatutEtapeKyc.aFaire:
        icone = Icons.radio_button_unchecked;
        couleur = theme.colorScheme.primary;
        texteStatut = l10n.kycEtapeAFaire;
      case StatutEtapeKyc.verrouillee:
        icone = Icons.lock_outline;
        couleur = theme.colorScheme.outline;
        texteStatut = l10n.kycEtapeVerrouillee;
    }

    final titre = _titre(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacements.m),
      child: Semantics(
        button: !verrouillee,
        enabled: !verrouillee,
        label: '$titre, $texteStatut',
        excludeSemantics: true,
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Rayons.borduresCarte,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: Rayons.borduresCarte,
            onTap: verrouillee
                ? null
                : () => unawaited(context.push<void>(routePourEtape(etape))),
            child: Padding(
              padding: const EdgeInsets.all(Espacements.l),
              child: Row(
                children: [
                  Icon(icone, color: couleur),
                  const SizedBox(width: Espacements.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: theme.textTheme.titleSmall),
                        const SizedBox(height: Espacements.xs),
                        Text(
                          texteStatut,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!verrouillee) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
