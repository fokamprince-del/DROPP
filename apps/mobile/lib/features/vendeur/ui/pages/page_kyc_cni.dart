import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/upload/choix_media.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/brouillon_kyc.dart';
import '../../application/dossier_kyc.dart';
import '../../data/kyc_repository.dart';
import '../../data/modeles_kyc.dart';
import '../../data/selecteur_photo.dart';
import '../../domain/etape_kyc.dart';
import '../widgets/emplacement_document.dart';
import '../widgets/page_etape_kyc.dart';

class PageKycCni extends ConsumerStatefulWidget {
  const PageKycCni({super.key});

  @override
  ConsumerState<PageKycCni> createState() => _PageKycCniState();
}

class _PageKycCniState extends ConsumerState<PageKycCni> {
  final _enCours = <TypeDocumentKyc>{};
  String? _erreur;

  Future<void> _choisir(TypeDocumentKyc type, {required bool galerie}) async {
    final l10n = context.l10n;
    final selecteur = ref.read(selecteurPhotoProvider);
    final brouillon = ref.read(brouillonKycProvider.notifier);
    setState(() => _erreur = null);
    try {
      final photo = await selecteur.prendre(selfie: false, galerie: galerie);
      if (photo == null) return;
      // Choisie, pas encore envoyée : l'utilisateur doit la valider.
      brouillon.choisir(type, photo);
    } on FichierRefuse catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.raison == FichierRefuseRaison.formatNonSupporte
            ? l10n.kycFormatNonSupporte
            : e.raison == FichierRefuseRaison.indisponible
            ? l10n.kycCameraIndisponible
            : l10n.fichierTropGros(e.tailleMaxMo ?? tailleMaxDocumentKyc);
      });
    }
  }

  Future<void> _envoyer(TypeDocumentKyc type) async {
    if (_enCours.contains(type)) return;
    final photo = ref.read(brouillonKycProvider).photo(type);
    if (photo == null) return;
    final l10n = context.l10n;
    final depot = ref.read(kycRepositoryProvider);
    final brouillon = ref.read(brouillonKycProvider.notifier);

    setState(() {
      _enCours.add(type);
      _erreur = null;
    });
    try {
      await depot.envoyerDocument(type: type, fichier: photo);
      brouillon.marquerEnvoyee(type);
      if (mounted) ref.invalidate(dossierKycProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _enCours.remove(type));
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
    final donnees = dossier.value;

    bool envoye(TypeDocumentKyc type) {
      final document = donnees?.document(type);
      return document != null &&
          !document.refuse &&
          !brouillon.enAttenteDEnvoi(type);
    }

    final rectoOk = envoye(TypeDocumentKyc.cniRecto);
    final versoOk = envoye(TypeDocumentKyc.cniVerso);

    Widget emplacement(
      TypeDocumentKyc type,
      String titre,
      String description, {
      required bool actif,
    }) => EmplacementDocument(
      titre: titre,
      description: description,
      photo: brouillon.photo(type),
      document: donnees?.document(type),
      enAttente: brouillon.enAttenteDEnvoi(type),
      enCours: _enCours.contains(type),
      actif: actif,
      indice: actif ? null : l10n.kycVersoApresRecto,
      surChoisir: (galerie) => _choisir(type, galerie: galerie),
      surEnvoyer: () => _envoyer(type),
    );

    return PageEtapeKyc(
      etape: 1,
      total: etapesKycTotal,
      titre: l10n.kycCniTitre,
      explication: l10n.kycCniExplication,
      enfants: [
        if (dossier.hasError && !dossier.hasValue) ...[
          BandeauMessage(
            message: messageErreurApi(
              l10n,
              ApiException.depuis(dossier.error!),
            ),
          ),
          const SizedBox(height: Espacements.l),
        ],
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Text(l10n.kycAideCni, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Espacements.l),
        emplacement(
          TypeDocumentKyc.cniRecto,
          l10n.kycCniRecto,
          l10n.kycApercuRecto,
          actif: true,
        ),
        emplacement(
          TypeDocumentKyc.cniVerso,
          l10n.kycCniVerso,
          l10n.kycApercuVerso,
          actif: rectoOk,
        ),
      ],
      actions: [
        FilledButton(
          onPressed: (rectoOk && versoOk)
              ? () => unawaited(context.push<void>(Routes.kycInformations))
              : null,
          child: Text(l10n.kycContinuer),
        ),
        OutlinedButton(onPressed: _retour, child: Text(l10n.kycRetour)),
      ],
    );
  }
}
