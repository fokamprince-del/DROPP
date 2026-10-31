import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../application/dossier_kyc.dart';
import '../../data/modeles_kyc.dart';

class DossierEnVerification extends ConsumerWidget {
  const DossierEnVerification({super.key, required this.dossier});

  final DossierKyc dossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    final cni =
        dossier.document(TypeDocumentKyc.cniRecto) != null &&
        dossier.document(TypeDocumentKyc.cniVerso) != null;
    final selfie = dossier.document(TypeDocumentKyc.photoFaciale) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: Espacements.l),
        Text(
          l10n.kycEnVerificationTitre,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Espacements.s),
        Text(
          l10n.kycEnVerificationTexte,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Espacements.xl),
        _Etape(
          libelle: l10n.kycEtapeTelephone,
          acquis: utilisateur?.telephoneVerifie ?? false,
        ),
        _Etape(libelle: l10n.kycEtapeCni, acquis: cni),
        _Etape(libelle: l10n.kycEtapeSelfie, acquis: selfie),
        _Etape(libelle: l10n.kycEtapeValidation, acquis: false, enCours: true),
        const SizedBox(height: Espacements.xl),
        FilledButton(
          onPressed: () async {
            await ref.read(sessionProvider.notifier).rafraichirProfil();
            if (!context.mounted) return;
            ref.invalidate(dossierKycProvider);
          }, 
          child: Text(l10n.kycActualiser)),
        const SizedBox(height: Espacements.m),
        OutlinedButton(
          onPressed: () => context.go(Routes.profil),
          child: Text(l10n.kycRetourProfil),
        ),
      ],
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({
    required this.libelle,
    required this.acquis,
    this.enCours = false,
  });

  final String libelle;
  final bool acquis;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacements.s),
      child: Row(
        children: [
          if (enCours)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              acquis ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: acquis ? metier.succes : theme.colorScheme.outline,
            ),
          const SizedBox(width: Espacements.m),
          Expanded(child: Text(libelle, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
