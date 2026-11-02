import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/upload/service_upload.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/defiler_vers.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/brouillon_infos_cni.dart';
import '../../application/brouillon_kyc.dart';
import '../../application/dossier_kyc.dart';
import '../../data/kyc_repository.dart';
import '../../data/modeles_kyc.dart';
import '../../domain/etape_kyc.dart';
import '../../domain/formulaire_cni.dart';
import '../../domain/libelles_etape.dart';
import '../../domain/soumission_kyc.dart';
import '../widgets/apercu_photo.dart';
import '../widgets/page_etape_kyc.dart';

class PageKycRecapitulatif extends ConsumerStatefulWidget {
  const PageKycRecapitulatif({super.key});

  @override
  ConsumerState<PageKycRecapitulatif> createState() =>
      _PageKycRecapitulatifState();
}

class _PageKycRecapitulatifState extends ConsumerState<PageKycRecapitulatif> {
  final _cleBandeau = GlobalKey();
  bool _consentement = false;
  bool _numeroVisible = false;
  bool _envoi = false;
  String? _erreur;

  /// Un UUID par action de soumission, valable pour un même contenu de dossier.
  String? _cleIdempotence;
  String? _signatureCle;

  void _afficherErreur(String message) {
    setState(() => _erreur = message);
    defilerVers(_cleBandeau, estMonte: () => mounted);
  }

  Future<bool> _dejaSoumis(KycRepository depot) async {
    try {
      final dossier = await depot.monDossier();
      return dossier != null && dossier.statut.enVerification;
    } on ApiException {
      return false;
    }
  }

  Future<void> _soumettre() async {
    if (_envoi) return;
    final dossier = ref.read(dossierKycProvider).value;
    final brouillon = ref.read(brouillonKycProvider);
    final l10n = context.l10n;
    if (dossier == null || !_consentement) return;

    if (TypeDocumentKyc.values.any(brouillon.enAttenteDEnvoi)) {
      _afficherErreur(l10n.kycPhotoEnAttente);
      return;
    }
    if (!pretASoumettre(dossier)) {
      _afficherErreur(l10n.kycSoumettreIncomplet);
      return;
    }

    // Capturé avant les attentes : l'écran peut être quitté entre-temps.
    final depot = ref.read(kycRepositoryProvider);
    final photos = ref.read(brouillonKycProvider.notifier);
    final infos = ref.read(brouillonInfosCniProvider.notifier);
    final conteneur = ProviderScope.containerOf(context);
    final routeur = GoRouter.of(context);
    final messager = ScaffoldMessenger.of(context);

    final signature = signatureDossier(dossier);
    if (_cleIdempotence == null || _signatureCle != signature) {
      _cleIdempotence = const Uuid().v4();
      _signatureCle = signature;
    }
    final cle = _cleIdempotence!;

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    var transmis = false;
    try {
      await depot.soumettre(consentement: true, cleIdempotence: cle);
      transmis = true;
    } on ApiException catch (e) {
      if (issueIncertaine(e.type)) {
        // Le serveur a peut-être enregistré la soumission : on vérifie
        // avant de proposer un nouvel essai.
        transmis = await _dejaSoumis(depot);
      } else {
        _cleIdempotence = null;
      }
      if (!transmis && mounted) {
        _afficherErreur(
          messageErreurApi(
            l10n,
            e,
            specifiques: {
              TypeErreurApi.requeteInvalide: l10n.kycSoumissionRefusee,
              TypeErreurApi.conflit: l10n.kycSoumissionEnCours,
            },
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }

    if (!transmis) return;
    photos.vider();
    infos.vider();
    conteneur.invalidate(dossierKycProvider);
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.kycSoumisSucces),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    routeur.go(Routes.devenirVendeur);
  }

  void _modifier(String route) =>
      unawaited(context.push<void>(cheminDepuisRecapitulatif(route)));

  void _retour() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.devenirVendeur);
    }
  }

  List<Widget> _contenu(DossierKyc dossier, BrouillonKyc brouillon) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const espace = SizedBox(height: Espacements.l);
    final manquantes = etapesIncompletes(dossier);
    final d = dossier.donnees;

    String texte(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.kycDonneeNonRenseignee : v;
    String jour(DateTime? j) =>
        j == null ? l10n.kycDonneeNonRenseignee : formaterJour(j);

    final numero = d.numeroCni;
    final aUnNumero = numero != null && numero.isNotEmpty;
    final numeroAffiche = !aUnNumero
        ? l10n.kycDonneeNonRenseignee
        : (_numeroVisible ? numero : masquerNumeroCni(numero));

    DocumentKyc? document(TypeDocumentKyc t) => dossier.document(t);
    Widget ligneDocument(
      TypeDocumentKyc type,
      String titre,
      String description,
      String route,
      IconData iconeVide,
    ) => _LigneDocumentRecap(
      titre: titre,
      description: description,
      photo: brouillon.photo(type),
      document: document(type),
      enAttente: brouillon.enAttenteDEnvoi(type),
      iconeVide: iconeVide,
      surModifier: () => _modifier(route),
    );

    return [
      if (manquantes.isNotEmpty) ...[
        BandeauMessage(message: l10n.kycSoumettreIncomplet, erreur: false),
        const SizedBox(height: Espacements.s),
        for (final etape in manquantes)
          _EtapeManquante(
            titre: titreEtape(l10n, etape),
            surAppui: () => _modifier(routePourEtape(etape)),
          ),
        espace,
      ],
      if (TypeDocumentKyc.values.any(brouillon.enAttenteDEnvoi)) ...[
        BandeauMessage(message: l10n.kycPhotoEnAttente, erreur: false),
        espace,
      ],
      _Section(
        titre: l10n.kycRecapInfosTitre,
        actionLibelle: l10n.kycModifier,
        surAction: () => _modifier(Routes.kycInformations),
        enfants: [
          _LigneInfo(libelle: l10n.kycChampNom, valeur: texte(d.nomLegal)),
          _LigneInfo(
            libelle: l10n.kycChampPrenom,
            valeur: texte(d.prenomLegal),
          ),
          _LigneInfo(
            libelle: l10n.kycChampNumero,
            valeur: numeroAffiche,
            actionLibelle: aUnNumero
                ? (_numeroVisible ? l10n.kycMasquer : l10n.kycAfficher)
                : null,
            surAction: () => setState(() => _numeroVisible = !_numeroVisible),
          ),
          _LigneInfo(
            libelle: l10n.kycChampNaissance,
            valeur: jour(d.dateNaissance),
          ),
          _LigneInfo(
            libelle: l10n.kycChampLieu,
            valeur: texte(d.lieuNaissance),
          ),
          _LigneInfo(
            libelle: l10n.kycChampDelivrance,
            valeur: jour(d.dateEtablissement),
          ),
          _LigneInfo(
            libelle: l10n.kycChampExpiration,
            valeur: jour(d.dateExpiration),
          ),
        ],
      ),
      espace,
      _Section(
        titre: l10n.kycRecapDocumentsTitre,
        enfants: [
          ligneDocument(
            TypeDocumentKyc.cniRecto,
            l10n.kycCniRecto,
            l10n.kycApercuRecto,
            Routes.kycCni,
            Icons.badge_outlined,
          ),
          ligneDocument(
            TypeDocumentKyc.cniVerso,
            l10n.kycCniVerso,
            l10n.kycApercuVerso,
            Routes.kycCni,
            Icons.badge_outlined,
          ),
          ligneDocument(
            TypeDocumentKyc.photoFaciale,
            l10n.kycSelfie,
            l10n.kycApercuSelfie,
            Routes.kycSelfie,
            Icons.face_outlined,
          ),
        ],
      ),
      espace,
      CheckboxListTile(
        value: _consentement,
        onChanged: _envoi
            ? null
            : (v) => setState(() => _consentement = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.kycConsentement),
      ),
      const SizedBox(height: Espacements.s),
      Text(
        l10n.kycSoumettreExplication,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dossierAsync = ref.watch(dossierKycProvider);
    final dossier = dossierAsync.value;
    final brouillon = ref.watch(brouillonKycProvider);
    final pret =
        pretASoumettre(dossier) &&
        !TypeDocumentKyc.values.any(brouillon.enAttenteDEnvoi);

    final List<Widget> contenu;
    if (dossier != null) {
      contenu = _contenu(dossier, brouillon);
    } else if (dossierAsync.hasError) {
      contenu = [
        BandeauMessage(
          message: messageErreurApi(
            l10n,
            ApiException.depuis(dossierAsync.error!),
          ),
        ),
        const SizedBox(height: Espacements.l),
        OutlinedButton(
          onPressed: () => ref.invalidate(dossierKycProvider),
          child: Text(l10n.reessayer),
        ),
      ];
    } else {
      contenu = const [Center(child: CircularProgressIndicator())];
    }

    return PageEtapeKyc(
      etape: 4,
      total: etapesKycTotal,
      titre: l10n.kycRecapTitre,
      explication: l10n.kycRecapExplication,
      enfants: [
        if (_erreur != null) ...[
          KeyedSubtree(
            key: _cleBandeau,
            child: BandeauMessage(message: _erreur!),
          ),
          const SizedBox(height: Espacements.l),
        ],
        ...contenu,
      ],
      actions: [
        FilledButton(
          onPressed: (pret && _consentement && !_envoi) ? _soumettre : null,
          child: _envoi
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.kycSoumettre),
        ),
        OutlinedButton(
          onPressed: _envoi ? null : _retour,
          child: Text(l10n.kycRetour),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.titre,
    required this.enfants,
    this.actionLibelle,
    this.surAction,
  });

  final String titre;
  final List<Widget> enfants;
  final String? actionLibelle;
  final VoidCallback? surAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              Expanded(child: Text(titre, style: theme.textTheme.titleSmall)),
              if (actionLibelle != null)
                TextButton(onPressed: surAction, child: Text(actionLibelle!)),
            ],
          ),
          const SizedBox(height: Espacements.s),
          ...enfants,
        ],
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo({
    required this.libelle,
    required this.valeur,
    this.actionLibelle,
    this.surAction,
  });

  final String libelle;
  final String valeur;
  final String? actionLibelle;
  final VoidCallback? surAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacements.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(valeur, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (actionLibelle != null)
            TextButton(onPressed: surAction, child: Text(actionLibelle!)),
        ],
      ),
    );
  }
}

class _LigneDocumentRecap extends StatelessWidget {
  const _LigneDocumentRecap({
    required this.titre,
    required this.description,
    required this.photo,
    required this.document,
    required this.enAttente,
    required this.iconeVide,
    required this.surModifier,
  });

  final String titre;
  final String description;
  final FichierLocal? photo;
  final DocumentKyc? document;
  final bool enAttente;
  final IconData iconeVide;
  final VoidCallback surModifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final refuse = document?.refuse ?? false;

    final IconData icone;
    final Color couleur;
    final String statut;
    if (enAttente) {
      icone = Icons.visibility_outlined;
      couleur = theme.colorScheme.primary;
      statut = l10n.kycStatutAVerifier;
    } else if (refuse) {
      icone = Icons.error_outline;
      couleur = metier.erreur;
      statut = l10n.kycRefuse;
    } else if (document != null) {
      icone = Icons.check_circle;
      couleur = metier.succes;
      statut = l10n.kycEnvoye;
    } else {
      icone = Icons.radio_button_unchecked;
      couleur = theme.colorScheme.onSurfaceVariant;
      statut = l10n.kycStatutAImporter;
    }
    final fichier = photo?.fichier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacements.s),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: Rayons.borduresChamp,
            child: SizedBox(
              width: 76,
              height: 56,
              child: fichier == null
                  ? ColoredBox(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.04,
                      ),
                      child: Icon(iconeVide, color: theme.colorScheme.outline),
                    )
                  : Semantics(
                      image: true,
                      button: true,
                      label: description,
                      hint: l10n.kycAgrandir,
                      child: GestureDetector(
                        onTap: () => agrandirPhoto(context, fichier),
                        child: Image.file(
                          File(fichier.path),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: Espacements.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: theme.textTheme.titleSmall),
                const SizedBox(height: Espacements.xs),
                Row(
                  children: [
                    Icon(icone, size: 16, color: couleur),
                    const SizedBox(width: Espacements.xs),
                    Flexible(
                      child: Text(
                        statut,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: couleur,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(onPressed: surModifier, child: Text(l10n.kycModifier)),
        ],
      ),
    );
  }
}

class _EtapeManquante extends StatelessWidget {
  const _EtapeManquante({required this.titre, required this.surAppui});

  final String titre;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.radio_button_unchecked),
      title: Text(titre),
      trailing: const Icon(Icons.chevron_right),
      onTap: surAppui,
    );
  }
}
