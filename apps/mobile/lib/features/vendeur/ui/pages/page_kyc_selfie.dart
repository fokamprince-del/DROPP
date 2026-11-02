import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/brouillon_kyc.dart';
import '../../application/dossier_kyc.dart';
import '../../data/kyc_repository.dart';
import '../../data/modeles_kyc.dart';
import '../../domain/etape_kyc.dart';
import '../widgets/emplacement_document.dart';
import '../widgets/page_etape_kyc.dart';
import 'capture_selfie.dart';

// TODO(lot 2): détection de présence réelle (anti-usurpation), voir
// docs/reports-lot-2.md. Aujourd'hui : caméra avant imposée + comparaison du
// visage avec la CNI côté serveur, après la soumission.
class PageKycSelfie extends ConsumerStatefulWidget {
  const PageKycSelfie({super.key});

  @override
  ConsumerState<PageKycSelfie> createState() => _PageKycSelfieState();
}

class _PageKycSelfieState extends ConsumerState<PageKycSelfie> {
  static const _type = TypeDocumentKyc.photoFaciale;

  bool _enCours = false;
  String? _erreur;

  Future<void> _prendre() async {
    final l10n = context.l10n;
    final brouillon = ref.read(brouillonKycProvider.notifier);
    setState(() => _erreur = null);

    final photo = await ref.read(captureSelfieProvider).capturer(context);
    if (photo == null) return;
    if (photo.taille > tailleMaxDocumentKyc) {
      if (mounted) setState(() => _erreur = l10n.kycPhotoTropLourde);
      return;
    }
    // Choisie, pas encore envoyée : l'utilisateur doit la valider.
    brouillon.choisir(_type, photo);
  }

  Future<void> _envoyer() async {
    if (_enCours) return;
    final photo = ref.read(brouillonKycProvider).photo(_type);
    if (photo == null) return;
    final l10n = context.l10n;
    final depot = ref.read(kycRepositoryProvider);
    final brouillon = ref.read(brouillonKycProvider.notifier);

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await depot.envoyerDocument(type: _type, fichier: photo);
      brouillon.marquerEnvoyee(_type);
      if (mounted) ref.invalidate(dossierKycProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _retour() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.devenirVendeur);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dossier = ref.watch(dossierKycProvider);
    final brouillon = ref.watch(brouillonKycProvider);
    final document = dossier.value?.document(_type);
    final envoye =
        document != null &&
        !document.refuse &&
        !brouillon.enAttenteDEnvoi(_type);

    return PageEtapeKyc(
      etape: 3,
      total: etapesKycTotal,
      titre: l10n.kycSelfieTitre,
      explication: l10n.kycSelfieExplication,
      enfants: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        const _Consignes(),
        const SizedBox(height: Espacements.l),
        EmplacementDocument(
          titre: l10n.kycSelfie,
          description: l10n.kycApercuSelfie,
          photo: brouillon.photo(_type),
          document: document,
          enAttente: brouillon.enAttenteDEnvoi(_type),
          enCours: _enCours,
          actif: true,
          ratio: 3 / 4,
          autoriserGalerie: false,
          iconeVide: Icons.face_outlined,
          libellePrendre: l10n.kycPrendreSelfie,
          surChoisir: (_) => unawaited(_prendre()),
          surEnvoyer: _envoyer,
        ),
      ],
      actions: [
        FilledButton(
          onPressed: envoye
              ? () => unawaited(context.push<void>(Routes.kycRecapitulatif))
              : null,
          child: Text(l10n.kycContinuer),
        ),
        OutlinedButton(onPressed: _retour, child: Text(l10n.kycRetour)),
      ],
    );
  }
}

class _Consignes extends StatelessWidget {
  const _Consignes();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final consignes = [
      (Icons.wb_sunny_outlined, l10n.kycConsigne1),
      (Icons.visibility_outlined, l10n.kycConsigne2),
      (Icons.face_outlined, l10n.kycConsigne3),
      (Icons.do_not_disturb_on_outlined, l10n.kycConsigne4),
      (Icons.blur_off, l10n.kycConsigne5),
    ];

    return Container(
      padding: const EdgeInsets.all(Espacements.l),
      decoration: BoxDecoration(
        color: metier.accentFond,
        borderRadius: Rayons.borduresCarte,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.kycConsignesTitre, style: theme.textTheme.titleSmall),
          const SizedBox(height: Espacements.s),
          for (final (icone, texte) in consignes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espacements.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, size: 20, color: metier.accent),
                  const SizedBox(width: Espacements.m),
                  Expanded(
                    child: Text(texte, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
