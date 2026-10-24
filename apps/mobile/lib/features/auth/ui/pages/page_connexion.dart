import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/champ_dropp.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../data/modeles_auth.dart';
import '../../domain/identifiant.dart';
import '../messages_erreurs.dart';
import '../navigation_auth.dart';
import '../widgets/bandeau_message.dart';
import '../widgets/bouton_action.dart';
import '../widgets/champ_mot_de_passe.dart';
import '../widgets/page_acces.dart';

class PageConnexion extends ConsumerStatefulWidget {
  const PageConnexion({super.key});

  @override
  ConsumerState<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends ConsumerState<PageConnexion> {
  final _cle = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;

    final l10n = context.l10n;
    final identifiant = normaliserIdentifiant(_identifiant.text)!;
    final depot = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
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
      final resultat = await depot.connecter(
        identifiant: identifiant,
        motDePasse: _motDePasse.text,
      );
      switch (resultat) {
        case ConnexionReussie(:final jetons):
          // Le routeur quitte cette page dès que la session est ouverte.
          await session.ouvrir(jetons);
        case VerificationRequise(:final verificationToken):
          flux.demarrer(
            FluxVerification(
              objectif: ObjectifVerification.activation,
              verificationToken: verificationToken,
              identifiant: identifiant,
            ),
          );
          unawaited(routeur.push<void>(versVerification));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.nonAuthentifie: l10n.erreurIdentifiantsIncorrects,
            // Un mot de passe trop court est refusé en 400 par le serveur.
            TypeErreurApi.requeteInvalide: l10n.erreurIdentifiantsIncorrects,
          },
        );
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final expiree = session is SessionAnonyme && session.expiree;

    return PageAcces(
      titre: l10n.connexionTitre,
      sousTitre: l10n.connexionSousTitre,
      enfants: [
        if (expiree) ...[
          BandeauMessage(message: l10n.sessionExpiree, erreur: false),
          const SizedBox(height: Espacements.l),
        ],
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
                ChampDropp(
                  libelle: l10n.champIdentifiant,
                  controleur: _identifiant,
                  validateur: validerIdentifiant,
                  typeClavier: TextInputType.emailAddress,
                  indicesAutoRemplissage: const [AutofillHints.username],
                  actif: !_envoi,
                ),
                const SizedBox(height: Espacements.l),
                ChampMotDePasse(
                  controleur: _motDePasse,
                  surSoumission: (_) => _soumettre(),
                  actif: !_envoi,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => unawaited(
              context.push<void>(
                cheminAvecRetour(context, Routes.motDePasseOublie),
              ),
            ),
            child: Text(l10n.motDePasseOublieLien),
          ),
        ),
        const SizedBox(height: Espacements.s),
        BoutonAction(
          libelle: l10n.connexionBouton,
          enCours: _envoi,
          surAppui: _soumettre,
        ),
        const SizedBox(height: Espacements.m),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => unawaited(
              context.push<void>(cheminAvecRetour(context, Routes.inscription)),
            ),
            child: Text(l10n.creerUnCompte),
          ),
        ),
      ],
    );
  }
}
