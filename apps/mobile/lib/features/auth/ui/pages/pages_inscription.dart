import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/forms/champ_dropp.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/theme/styles_accent.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/bouton_action.dart';
import '../../../../shared/widgets/indicateur_etapes.dart';
import '../../../../shared/widgets/message_temporaire.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../../../shared/widgets/page_acces.dart';
import '../../../../utils/telephone.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../data/modeles_auth.dart';
import '../../domain/validateurs.dart';
import '../navigation_auth.dart';
import '../widgets/bouton_google.dart';
import '../widgets/champ_mot_de_passe.dart';
import '../widgets/champ_telephone.dart';
import '../widgets/selecteur_sexe.dart';
import '../widgets/separateur_ou.dart';

class PageInscription extends ConsumerStatefulWidget {
  const PageInscription({super.key});

  @override
  ConsumerState<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends ConsumerState<PageInscription> {
  final _cleIdentite = GlobalKey<FormState>();
  final _cleCompte = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController.fromValue(
    TextEditingValue(
      text: indicatifParDefaut,
      selection: TextSelection.collapsed(offset: indicatifParDefaut.length),
    ),
  );
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  Sexe? _sexe;

  /// 0 : identité, 1 : compte. Les contrôleurs vivent dans cet état : revenir
  /// à l'étape 1 ne perd aucune saisie.
  int _etape = 0;
  bool _tentativeIdentite = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _telephone.dispose();
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  void _continuer() {
    FocusScope.of(context).unfocus();
    setState(() => _tentativeIdentite = true);
    final valide = _cleIdentite.currentState!.validate();
    if (valide && _sexe != null) setState(() => _etape = 1);
  }

  Future<void> _soumettre() async {
    FocusScope.of(context).unfocus();
    final sexe = _sexe;
    if (!_cleCompte.currentState!.validate() || sexe == null || _envoi) return;

    final l10n = context.l10n;
    final telephone = normaliserTelephone(_telephone.text)!;
    final depot = ref.read(authRepositoryProvider);
    final flux = ref.read(fluxVerificationProvider.notifier);
    final routeur = GoRouter.of(context);
    final versVerification = cheminAvecRetour(
      context,
      Routes.verificationTelephone,
    );

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final token = await depot.inscrire(
        DonneesInscription(
          prenom: _prenom.text,
          nom: _nom.text,
          sexe: sexe,
          telephone: telephone,
          email: _email.text,
          motDePasse: _motDePasse.text,
        ),
      );
      flux.demarrer(
        FluxVerification(
          objectif: ObjectifVerification.activation,
          verificationToken: token,
          identifiant: telephone,
        ),
      );
      unawaited(routeur.push<void>(versVerification));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {TypeErreurApi.conflit: l10n.erreurCompteExistant},
        );
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _versConnexion() =>
      context.pushReplacement(cheminAvecRetour(context, Routes.connexion));

  Widget _etapeIdentite() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _cleIdentite,
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChampDropp(
                  libelle: l10n.champPrenom,
                  controleur: _prenom,
                  icone: IconesDropp.user,
                  validateur: validerRequis,
                  typeClavier: TextInputType.name,
                  capitalisation: TextCapitalization.words,
                  indicesAutoRemplissage: const [AutofillHints.givenName],
                  longueurMax: 100,
                ),
                const SizedBox(height: Espacements.l),
                ChampDropp(
                  libelle: l10n.champNom,
                  controleur: _nom,
                  icone: IconesDropp.user,
                  validateur: validerRequis,
                  typeClavier: TextInputType.name,
                  capitalisation: TextCapitalization.words,
                  indicesAutoRemplissage: const [AutofillHints.familyName],
                  longueurMax: 100,
                  actionClavier: TextInputAction.done,
                ),
                const SizedBox(height: Espacements.l),
                SelecteurSexe(
                  valeur: _sexe,
                  afficherErreur: _tentativeIdentite,
                  surChangement: (sexe) => setState(() => _sexe = sexe),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.continuer,
          enCours: false,
          surAppui: _continuer,
        ),
      ],
    );
  }

  Widget _etapeCompte() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Form(
          key: _cleCompte,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChampTelephone(controleur: _telephone, actif: !_envoi),
                const SizedBox(height: Espacements.l),
                ChampDropp(
                  libelle: l10n.champEmailFacultatif,
                  controleur: _email,
                  icone: IconesDropp.solidMail,
                  validateur: validerEmailFacultatif,
                  typeClavier: TextInputType.emailAddress,
                  indicesAutoRemplissage: const [AutofillHints.email],
                  longueurMax: 254,
                  actif: !_envoi,
                ),
                const SizedBox(height: Espacements.l),
                ChampMotDePasse(
                  controleur: _motDePasse,
                  nouveau: true,
                  surSoumission: (_) => _soumettre(),
                  actif: !_envoi,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.inscriptionBouton,
          enCours: _envoi,
          surAppui: _soumettre,
        ),
        const SizedBox(height: Espacements.m),
        Text(
          l10n.inscriptionConditions,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Espacements.l),
        const SeparateurOu(),
        const SizedBox(height: Espacements.l),
        BoutonGoogle(
          libelle: l10n.googleSInscrire,
          surAppui: () =>
              afficherMessageTemporaire(context, l10n.fonctionnaliteBientot),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      // Au deuxième écran, « retour » revient au premier au lieu de quitter.
      canPop: _etape == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _etape == 1) setState(() => _etape = 0);
      },
      child: PageAcces(
        titre: l10n.inscriptionTitre,
        sousTitre: _etape == 0
            ? l10n.inscriptionSousTitreIdentite
            : l10n.inscriptionSousTitreCompte,
        enfants: [
          IndicateurEtapes(etape: _etape + 1, total: 2),
          const SizedBox(height: Espacements.xl),
          if (_etape == 0) _etapeIdentite() else _etapeCompte(),
          const SizedBox(height: Espacements.m),
          TextButton(
            onPressed: _versConnexion,
            style: lienAccent(context),
            child: Text(l10n.jaiDejaUnCompte),
          ),
        ],
      ),
    );
  }
}
