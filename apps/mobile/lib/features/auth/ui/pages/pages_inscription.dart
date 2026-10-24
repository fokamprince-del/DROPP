import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/champ_dropp.dart';
import '../../../../utils/telephone.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../data/modeles_auth.dart';
import '../../domain/validateurs.dart';
import '../messages_erreurs.dart';
import '../navigation_auth.dart';
import '../widgets/bandeau_message.dart';
import '../widgets/bouton_action.dart';
import '../widgets/champ_mot_de_passe.dart';
import '../widgets/champ_telephone.dart';
import '../widgets/page_acces.dart';
import '../widgets/selecteur_sexe.dart';

class PageInscription extends ConsumerStatefulWidget {
  const PageInscription({super.key});

  @override
  ConsumerState<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends ConsumerState<PageInscription> {
  final _cle = GlobalKey<FormState>();
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
  bool _tentative = false;
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

  Future<void> _soumettre() async {
    FocusScope.of(context).unfocus();
    setState(() => _tentative = true);
    final formulaireValide = _cle.currentState!.validate();
    final sexe = _sexe;
    if (!formulaireValide || sexe == null || _envoi) return;

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

  void _versConnexion() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(cheminAvecRetour(context, Routes.connexion));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageAcces(
      titre: l10n.inscriptionTitre,
      sousTitre: l10n.inscriptionSousTitre,
      enfants: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Form(
          key: _cle,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ChampDropp(
                        libelle: l10n.champPrenom,
                        controleur: _prenom,
                        validateur: validerRequis,
                        typeClavier: TextInputType.name,
                        capitalisation: TextCapitalization.words,
                        indicesAutoRemplissage: const [AutofillHints.givenName],
                        longueurMax: 100,
                        actif: !_envoi,
                      ),
                    ),
                    const SizedBox(width: Espacements.m),
                    Expanded(
                      child: ChampDropp(
                        libelle: l10n.champNom,
                        controleur: _nom,
                        validateur: validerRequis,
                        typeClavier: TextInputType.name,
                        capitalisation: TextCapitalization.words,
                        indicesAutoRemplissage: const [
                          AutofillHints.familyName,
                        ],
                        longueurMax: 100,
                        actif: !_envoi,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espacements.l),
                SelecteurSexe(
                  valeur: _sexe,
                  afficherErreur: _tentative,
                  surChangement: (sexe) => setState(() => _sexe = sexe),
                ),
                const SizedBox(height: Espacements.l),
                ChampTelephone(controleur: _telephone, actif: !_envoi),
                const SizedBox(height: Espacements.l),
                ChampDropp(
                  libelle: l10n.champEmailFacultatif,
                  controleur: _email,
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
        const SizedBox(height: Espacements.s),
        TextButton(
          onPressed: _versConnexion,
          child: Text(l10n.jaiDejaUnCompte),
        ),
      ],
    );
  }
}
