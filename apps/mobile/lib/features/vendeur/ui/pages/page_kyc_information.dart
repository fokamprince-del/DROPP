import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/forms/champ_dropp.dart';
import '../../../../shared/forms/erreur_champ.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/theme/styles_accent.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../application/brouillon_infos_cni.dart';
import '../../application/brouillon_kyc.dart';
import '../../application/dossier_kyc.dart';
import '../../data/kyc_repository.dart';
import '../../data/modeles_kyc.dart';
import '../../domain/etape_kyc.dart';
import '../../domain/formulaire_cni.dart';
import '../widgets/animation_scan_carte.dart';
import '../widgets/champ_date.dart';
import '../widgets/page_etape_kyc.dart';

class PageKycInformations extends ConsumerStatefulWidget {
  const PageKycInformations({super.key});

  @override
  ConsumerState<PageKycInformations> createState() =>
      _PageKycInformationsState();
}

class _PageKycInformationsState extends ConsumerState<PageKycInformations> {
  final _cle = GlobalKey<FormState>();
  final _controleurs = {
    for (final champ in ChampCni.values) champ: TextEditingController(),
  };

  bool _initialise = false;
  bool _lecture = false;
  bool _apresLecture = false;
  bool _lectureIncertaine = false;
  bool _confirme = false;
  bool _envoi = false;
  String? _erreur;
  String? _info;

  /// Champs remplis par la lecture automatique et pas encore retouchés.
  final _lus = <ChampCni>{};

  @override
  void initState() {
    super.initState();
    _remplir(ref.read(brouillonInfosCniProvider));
    // Modifier un provider est interdit pendant la construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dossier = ref.read(dossierKycProvider).value;
      if (dossier != null) _initialiserDepuisServeur(dossier);
    });
  }

  @override
  void dispose() {
    for (final controleur in _controleurs.values) {
      controleur.dispose();
    }
    super.dispose();
  }

  void _remplir(FormulaireCni formulaire) {
    for (final champ in ChampCni.values) {
      _controleurs[champ]!.text = formulaire.valeur(champ);
    }
  }

  FormulaireCni _formulaireActuel() => FormulaireCni(
    valeurs: {for (final e in _controleurs.entries) e.key: e.value.text},
  );

  /// Reprend ce que le serveur a déjà enregistré, une seule fois, et
  /// seulement si l'utilisateur n'a encore rien saisi.
  void _initialiserDepuisServeur(DossierKyc dossier) {
    if (_initialise) return;
    _initialise = true;
    if (!_formulaireActuel().vide) return;
    final formulaire = FormulaireCni.depuisDonnees(dossier.donnees);
    if (formulaire.vide) return;
    ref.read(brouillonInfosCniProvider.notifier).initialiser(dossier.donnees);
    _remplir(formulaire);
    if (mounted) setState(() {});
  }

  void _surChangement(ChampCni champ, String valeur) {
    ref.read(brouillonInfosCniProvider.notifier).modifier(champ, valeur);
    setState(() => _lus.remove(champ));
  }

  Future<bool> _confirmerRemplacement() async {
    final l10n = context.l10n;
    final accord = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: Text(l10n.kycRemplacerSaisieTitre),
        content: Text(l10n.kycRemplacerSaisieTexte),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(false),
            child: Text(l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexte).pop(true),
            child: Text(l10n.kycRemplacer),
          ),
        ],
      ),
    );
    return accord ?? false;
  }

  Future<void> _lireCarte() async {
    if (_lecture || _envoi) return;
    if (!_formulaireActuel().vide && !await _confirmerRemplacement()) return;
    if (!mounted) return;

    final l10n = context.l10n;
    final depot = ref.read(kycRepositoryProvider);
    final notifier = ref.read(brouillonInfosCniProvider.notifier);
    final mouvementReduit = MediaQuery.disableAnimationsOf(context);

    setState(() {
      _lecture = true;
      _erreur = null;
      _info = null;
      _lectureIncertaine = false;
    });
    try {
      final debut = DateTime.now();
      final resultat = await depot.extraireCni();

      // Laisse l'animation se voir un instant.
      const minimum = Duration(milliseconds: 1500);
      final ecoule = DateTime.now().difference(debut);
      if (!mouvementReduit && ecoule < minimum) {
        await Future<void>.delayed(minimum - ecoule);
      }
      if (!mounted) return;

      final lus = FormulaireCni.valeursLues(resultat.donnees).keys.toSet();
      if (lus.isEmpty) {
        setState(() => _info = l10n.kycLectureEchec);
        return;
      }
      notifier.appliquerExtraction(resultat.donnees);
      _remplir(ref.read(brouillonInfosCniProvider));
      setState(() {
        _lus
          ..clear()
          ..addAll(lus);
        _apresLecture = true;
        _confirme = false;
        _lectureIncertaine =
            resultat.avertissement != null ||
            (resultat.confiance ?? 100) < seuilConfianceBasse;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.introuvable: l10n.kycLectureIntrouvable,
            TypeErreurApi.delaiDepasse: l10n.kycLectureLente,
          },
        );
      });
    } finally {
      if (mounted) setState(() => _lecture = false);
    }
  }

  Future<void> _confirmer() async {
    FocusScope.of(context).unfocus();
    if (_envoi || _lecture || !_confirme) return;
    if (!_cle.currentState!.validate()) return;
    final donnees = _formulaireActuel().versDonnees();
    if (donnees == null) return;

    final l10n = context.l10n;
    final depot = ref.read(kycRepositoryProvider);
    final routeur = GoRouter.of(context);

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await depot.confirmerCni(donnees);
      if (!mounted) return;
      ref.invalidate(dossierKycProvider);
      unawaited(routeur.push<void>(Routes.kycSelfie));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {TypeErreurApi.requeteInvalide: l10n.kycInfosRefusees},
        );
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _retour() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.devenirVendeur);
    }
  }

  Widget _blocAutomatique() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;

    if (_lecture) {
      final recto = ref
          .watch(brouillonKycProvider)
          .photo(TypeDocumentKyc.cniRecto);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimationScanCarte(fichier: recto?.fichier),
          const SizedBox(height: Espacements.m),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.kycLectureEnCours,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(Espacements.l),
      decoration: BoxDecoration(
        color: metier.accentFond,
        borderRadius: Rayons.borduresCarte,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espacements.s),
          Text(l10n.kycAutoExplication, style: theme.textTheme.bodySmall),
          const SizedBox(height: Espacements.m),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: boutonContourAccent(context),
              onPressed: _envoi ? null : _lireCarte,
              child: Text(l10n.kycAutoTitre),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dossierKycProvider, (_, suivant) {
      final dossier = suivant.value;
      if (dossier != null) _initialiserDepuisServeur(dossier);
    });

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final actif = !_lecture && !_envoi;
    final aujourdhui = DateTime.now();
    final expiree = carteExpiree(_controleurs[ChampCni.expiration]!.text);

    String? aide(ChampCni champ) {
      if (_lus.contains(champ)) return l10n.kycLuSurCarte;
      if (_apresLecture && _controleurs[champ]!.text.trim().isEmpty) {
        return l10n.kycChampAComplete;
      }
      return null;
    }

    Color? couleurAide(ChampCni champ) {
      if (_lus.contains(champ)) return metier.accent;
      if (_apresLecture && _controleurs[champ]!.text.trim().isEmpty) {
        return metier.attente;
      }
      return null;
    }

    Widget texte(
      ChampCni champ,
      String libelle, {
      required ErreurChamp? Function(String?) validateur,
      TextCapitalization capitalisation = TextCapitalization.words,
      List<TextInputFormatter>? formateurs,
      int longueurMax = 100,
    }) => ChampDropp(
      libelle: libelle,
      controleur: _controleurs[champ]!,
      validateur: validateur,
      capitalisation: capitalisation,
      formateurs: formateurs,
      longueurMax: longueurMax,
      surChangement: (v) => _surChangement(champ, v),
      actif: actif,
      aide: aide(champ),
      couleurAide: couleurAide(champ),
    );

    Widget date(
      ChampCni champ,
      String libelle, {
      required ErreurChamp? Function(String?) validateur,
      required DateTime premier,
      required DateTime dernier,
      TextInputAction action = TextInputAction.next,
    }) => ChampDate(
      libelle: libelle,
      controleur: _controleurs[champ]!,
      validateur: validateur,
      premierJour: premier,
      dernierJour: dernier,
      actionClavier: action,
      surChangement: (v) => _surChangement(champ, v),
      actif: actif,
      aide: champ == ChampCni.expiration && expiree
          ? l10n.kycCarteExpiree
          : aide(champ),
      couleurAide: champ == ChampCni.expiration && expiree
          ? metier.erreur
          : couleurAide(champ),
    );

    const espace = SizedBox(height: Espacements.l);

    return PageEtapeKyc(
      etape: 2,
      total: etapesKycTotal,
      titre: l10n.kycInfosTitre,
      explication: l10n.kycInfosExplication,
      enfants: [
        if (_erreur != null) ...[BandeauMessage(message: _erreur!), espace],
        if (_info != null) ...[
          BandeauMessage(message: _info!, erreur: false),
          espace,
        ],
        if (_lectureIncertaine) ...[
          BandeauMessage(message: l10n.kycLectureIncertaine, erreur: false),
          espace,
        ],
        _blocAutomatique(),
        const SizedBox(height: Espacements.l),
        Center(
          child: Text(
            l10n.kycOuMain,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: Espacements.l),
        Form(
          key: _cle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              texte(ChampCni.nom, l10n.kycChampNom, validateur: validerRequis),
              espace,
              texte(
                ChampCni.prenom,
                l10n.kycChampPrenom,
                validateur: validerRequis,
              ),
              espace,
              texte(
                ChampCni.numero,
                l10n.kycChampNumero,
                validateur: validerNumeroCni,
                capitalisation: TextCapitalization.characters,
                formateurs: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
                ],
                longueurMax: 30,
              ),
              espace,
              date(
                ChampCni.naissance,
                l10n.kycChampNaissance,
                validateur: validerDateNaissance,
                premier: DateTime(1900),
                dernier: aujourdhui,
              ),
              espace,
              texte(
                ChampCni.lieu,
                l10n.kycChampLieu,
                validateur: validerRequis,
              ),
              espace,
              date(
                ChampCni.delivrance,
                l10n.kycChampDelivrance,
                validateur: validerDateDelivrance,
                premier: DateTime(1980),
                dernier: aujourdhui,
              ),
              espace,
              date(
                ChampCni.expiration,
                l10n.kycChampExpiration,
                validateur: (v) => validerDateExpiration(
                  v,
                  _controleurs[ChampCni.delivrance]!.text,
                ),
                premier: DateTime(1980),
                dernier: DateTime(aujourdhui.year + 30),
                action: TextInputAction.done,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacements.l),
        CheckboxListTile(
          value: _confirme,
          onChanged: actif
              ? (v) => setState(() => _confirme = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kycInfosConformes),
        ),
      ],
      actions: [
        FilledButton(
          onPressed: (_confirme && actif) ? _confirmer : null,
          child: _envoi
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.kycInfosConfirmer),
        ),
        OutlinedButton(onPressed: _retour, child: Text(l10n.kycRetour)),
      ],
    );
  }
}
