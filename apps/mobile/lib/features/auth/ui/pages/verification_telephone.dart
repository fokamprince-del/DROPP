import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../utils/telephone.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../domain/validateurs.dart';
import '../messages_erreurs.dart';
import '../navigation_auth.dart';
import '../widgets/bouton_action.dart';
import '../widgets/champ_code.dart';
import '../widgets/lien_renvoyer_code.dart';
import '../widgets/page_acces.dart';
import 'page_confirmation_email.dart';

class PageVerificationTelephone extends ConsumerStatefulWidget {
  const PageVerificationTelephone({super.key});

  @override
  ConsumerState<PageVerificationTelephone> createState() =>
      _PageVerificationTelephoneState();
}

class _PageVerificationTelephoneState
    extends ConsumerState<PageVerificationTelephone> {
  final _code = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Écran ouvert sans vérification en cours (app relancée) : retour au début.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flux = ref.read(fluxVerificationProvider);
      if (flux == null || flux.objectif != ObjectifVerification.activation) {
        context.go(cheminAvecRetour(context, Routes.connexion));
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verifier(String code) async {
    final flux = ref.read(fluxVerificationProvider);
    if (flux == null || _envoi) return;

    final l10n = context.l10n;
    if (validerCode(code) != null) {
      setState(() => _erreur = l10n.erreurCodeIncomplet);
      return;
    }
    final depot = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final fluxNotifier = ref.read(fluxVerificationProvider.notifier);
    // Lus avant l'ouverture de session : la page est fermée juste après.
    final conteneur = ProviderScope.containerOf(context);
    final routeur = GoRouter.of(context);

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final jetons = await depot.verifierTelephone(
        verificationToken: flux.verificationToken,
        code: code,
      );
      // Le routeur quitte cette page dès que la session est ouverte.
      await session.ouvrir(jetons);
      fluxNotifier.terminer();
      // Email donné à l'inscription : le serveur vient d'y envoyer un code
      // de confirmation. On propose de le saisir (« Plus tard » possible).
      final utilisateur = conteneur.read(utilisateurConnecteProvider);
      if (utilisateur != null &&
          utilisateur.email != null &&
          !utilisateur.emailVerifie) {
        routeur.go(cheminConfirmationEmail(envoye: true));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.requeteInvalide: l10n.erreurCodeIncorrect,
            TypeErreurApi.nonAuthentifie: l10n.erreurCodeIncorrect,
            TypeErreurApi.expire: l10n.erreurCodeExpire,
          },
        );
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<bool> _renvoyer() async {
    final flux = ref.read(fluxVerificationProvider);
    if (flux == null) return false;

    final l10n = context.l10n;
    final depot = ref.read(authRepositoryProvider);
    final fluxNotifier = ref.read(fluxVerificationProvider.notifier);
    try {
      final token = await depot.renvoyerCode(flux.verificationToken);
      fluxNotifier.remplacerToken(token);
      if (mounted) setState(() => _erreur = null);
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = messageErreurApi(
            l10n,
            e,
            specifiques: {
              TypeErreurApi.nonAuthentifie: l10n.erreurVerificationExpiree,
            },
          );
        });
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flux = ref.watch(fluxVerificationProvider);
    if (flux == null) return const Scaffold();

    final l10n = context.l10n;
    final destinataire = flux.identifiant.startsWith('+')
        ? l10n.codeEnvoyeA(masquerTelephone(flux.identifiant))
        : l10n.codeEnvoyeAuCompte;

    return PageAcces(
      titre: l10n.codeTitre,
      sousTitre: destinataire,
      enfants: [
        ChampCode(controleur: _code, surComplet: _verifier, erreur: _erreur),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.codeVerifier,
          enCours: _envoi,
          surAppui: () => _verifier(_code.text),
        ),
        const SizedBox(height: Espacements.s),
        LienRenvoyerCode(surRenvoyer: _renvoyer),
      ],
    );
  }
}
