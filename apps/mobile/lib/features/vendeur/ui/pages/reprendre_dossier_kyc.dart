import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/dossier_kyc.dart';
import '../../data/modeles_kyc.dart';
import '../../domain/etape_kyc.dart'; 
import '../widgets/dossier_en_verification.dart';

/// Point d'entrée du parcours : propose de commencer ou de reprendre là où le
/// serveur dit que le dossier en est.
class ReprendreDossierKyc extends ConsumerWidget {
  const ReprendreDossierKyc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ref.watch(dossierKycProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(Espacements.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (erreur, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BandeauMessage(
                message: messageErreurApi(l10n, ApiException.depuis(erreur)),
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
            final avance = dossier != null &&
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