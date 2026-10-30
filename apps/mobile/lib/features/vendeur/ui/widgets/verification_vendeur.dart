import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/upload/choix_media.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/dossier_kyc.dart';
import '../../data/kyc_repository.dart';
import '../../data/modeles_kyc.dart';
import '../../data/selecteur_photo.dart';

/// Parcours de vérification d'un vendeur en attente : documents, puis (lot
/// suivant) informations de la CNI et envoi du dossier.
class VerificationVendeur extends ConsumerStatefulWidget {
  const VerificationVendeur({super.key});

  @override
  ConsumerState<VerificationVendeur> createState() =>
      _VerificationVendeurState();
}

class _VerificationVendeurState extends ConsumerState<VerificationVendeur> {
  final _enCours = <TypeDocumentKyc>{};
  String? _erreur;

  Future<void> _envoyer(TypeDocumentKyc type, {required bool galerie}) async {
    if (_enCours.contains(type)) return;
    final l10n = context.l10n;
    final selecteur = ref.read(selecteurPhotoProvider);
    final depot = ref.read(kycRepositoryProvider);
    setState(() {
      _enCours.add(type);
      _erreur = null;
    });
    String? chemin ;
    try {
      final photo = await selecteur.prendre(
        selfie: type == TypeDocumentKyc.photoFaciale,
        galerie: galerie,
        tailleMaxMo: tailleMaxDocumentKyc,
      );
      if (photo == null) return;
      chemin = photo.fichier.path;
      await depot.envoyerDocument(type: type, fichier: photo);
      if (mounted) ref.invalidate(dossierKycProvider);
    } on FichierRefuse catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e.raison == FichierRefuseRaison.formatNonSupporte
              ? l10n.kycFormatNonSupporte
              : e.raison == FichierRefuseRaison.indisponible
              ? l10n.kycCameraIndisponible
              : l10n.fichierTropGros(e.tailleMaxMo ?? tailleMaxDocumentKyc);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (chemin != null) await selecteur.supprimer(chemin);
      if (mounted) setState(() => _enCours.remove(type));
    }
  }

  Future<void> _actualiser() async {
    await ref.read(sessionProvider.notifier).rafraichirProfil();
    if (mounted) ref.invalidate(dossierKycProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dossier = ref.watch(dossierKycProvider);

    return dossier.when(
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
      data: (d) => d != null && d.statut.enVerification
          ? _EnVerification(dossier: d, surActualiser: _actualiser)
          : _etapes(d, l10n),
    );
  }

  Widget _etapes(DossierKyc? dossier, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final rejete = dossier?.statut == StatutDossierKyc.rejete;
    final motif = dossier?.motifRejet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rejete) ...[
          BandeauMessage(
            message: (motif == null || motif.isEmpty)
                ? l10n.kycDossierRefuseSansMotif
                : l10n.kycDossierRefuse(motif),
          ),
          const SizedBox(height: Espacements.l),
        ],
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Text(
          l10n.kycIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Espacements.l),
        Text(l10n.kycTitreDocuments, style: theme.textTheme.titleMedium),
        const SizedBox(height: Espacements.s),
        for (final type in TypeDocumentKyc.values)
          _LigneDocument(
            type: type,
            document: dossier?.document(type),
            enCours: _enCours.contains(type),
            surChoix: (galerie) => _envoyer(type, galerie: galerie),
          ),
        // Étape suivante (vérification des informations de la CNI, consentement
        // et envoi du dossier) : lot suivant.
      ],
    );
  }
}

class _LigneDocument extends StatelessWidget {
  const _LigneDocument({
    required this.type,
    required this.document,
    required this.enCours,
    required this.surChoix,
  });

  final TypeDocumentKyc type;
  final DocumentKyc? document;
  final bool enCours;

  /// `true` : choisir dans la galerie.
  final ValueChanged<bool> surChoix;

  String _libelle(AppLocalizations l10n) => switch (type) {
    TypeDocumentKyc.cniRecto => l10n.kycCniRecto,
    TypeDocumentKyc.cniVerso => l10n.kycCniVerso,
    TypeDocumentKyc.photoFaciale => l10n.kycSelfie,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final doc = document;
    final refuse = doc?.refuse ?? false;
    final estSelfie = type == TypeDocumentKyc.photoFaciale;

    final IconData icone;
    final Color couleurIcone;
    if (doc == null) {
      icone = Icons.radio_button_unchecked;
      couleurIcone = theme.colorScheme.outline;
    } else if (refuse) {
      icone = Icons.error_outline;
      couleurIcone = metier.erreur;
    } else {
      icone = Icons.check_circle;
      couleurIcone = metier.succes;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Espacements.m),
      padding: const EdgeInsets.all(Espacements.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Rayons.borduresCarte,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleurIcone, size: 22),
              const SizedBox(width: Espacements.s),
              Expanded(
                child: Text(_libelle(l10n), style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Espacements.xs),
          Text(
            estSelfie ? l10n.kycAideSelfie : l10n.kycAideCni,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (doc != null)
            Padding(
              padding: const EdgeInsets.only(top: Espacements.s),
              child: Text(
                refuse ? l10n.kycRefuse : l10n.kycEnvoye,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: refuse ? metier.erreur : metier.succes,
                ),
              ),
            ),
          const SizedBox(height: Espacements.m),
          if (enCours)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Espacements.s),
                Text(l10n.kycEnvoiEnCours),
              ],
            )
          else
            Wrap(
              spacing: Espacements.s,
              children: [
                OutlinedButton(
                  onPressed: () => surChoix(false),
                  child: Text(
                    doc == null ? l10n.kycPrendrePhoto : l10n.kycReprendrePhoto,
                  ),
                ),
                if (!estSelfie)
                  TextButton(
                    onPressed: () => surChoix(true),
                    child: Text(l10n.kycGalerie),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EnVerification extends ConsumerWidget {
  const _EnVerification({required this.dossier, required this.surActualiser});

  final DossierKyc dossier;
  final Future<void> Function() surActualiser;

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
        FilledButton(onPressed: surActualiser, child: Text(l10n.kycActualiser)),
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
