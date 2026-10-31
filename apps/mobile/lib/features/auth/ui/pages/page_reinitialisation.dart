import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/bouton_action.dart';
import '../../../../shared/widgets/libelles_erreurs.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../../../shared/widgets/page_acces.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../domain/validateurs.dart';
import '../navigation_auth.dart';
import '../widgets/champ_code.dart';
import '../widgets/champ_mot_de_passe.dart';
import '../widgets/lien_renvoyer_code.dart';

class PageReinitialisation extends ConsumerStatefulWidget {
  const PageReinitialisation({super.key});

  @override
  ConsumerState<PageReinitialisation> createState() =>
      _PageReinitialisationState();
}

class _PageReinitialisationState extends ConsumerState<PageReinitialisation> {
  final _cle = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _erreurCode;

  /// Un UUID par action de l'utilisateur, réutilisé à chaque nouvel essai
  /// tant que la saisie ne change pas.
  String? _cleIdempotence;
  String _derniereSaisie = '';

  @override
  void initState() {
    super.initState();
    _code.addListener(_nouvelleSaisie);
    _motDePasse.addListener(_nouvelleSaisie);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flux = ref.read(fluxVerificationProvider);
      if (flux == null ||
          flux.objectif != ObjectifVerification.reinitialisation) {
        context.go(cheminAvecRetour(context, Routes.connexion));
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  void _nouvelleSaisie() {
    final saisie = '${_code.text}|${_motDePasse.text}';
    if (saisie != _derniereSaisie) {
      _derniereSaisie = saisie;
      _cleIdempotence = null;
    }
  }

  Future<void> _soumettre() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final erreurCode = validerCode(_code.text);
    final formulaireValide = _cle.currentState!.validate();
    setState(() => _erreurCode = erreurCode?.libelle(l10n));

    final flux = ref.read(fluxVerificationProvider);
    if (erreurCode != null || !formulaireValide || flux == null || _envoi) {
      return;
    }

    final depot = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final fluxNotifier = ref.read(fluxVerificationProvider.notifier);
    final cle = _cleIdempotence ??= const Uuid().v4();

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final jetons = await depot.reinitialiserMotDePasse(
        verificationToken: flux.verificationToken,
        code: _code.text,
        nouveauMotDePasse: _motDePasse.text,
        cleIdempotence: cle,
      );
      // Connecté directement : le routeur quitte cette page.
      await session.ouvrir(jetons);
      fluxNotifier.terminer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.requeteInvalide: l10n.erreurCodeIncorrect,
            TypeErreurApi.nonAuthentifie: l10n.erreurCodeIncorrect,
            TypeErreurApi.expire: l10n.erreurCodeExpire,
            TypeErreurApi.conflit: l10n.erreurRequeteEnCours,
          },
        );
      });
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Le contrat ne garantit pas que `/renvoyer-code` accepte ce jeton :
  /// on redemande un code avec l'identifiant mémorisé.
  Future<bool> _renvoyer() async {
    final flux = ref.read(fluxVerificationProvider);
    if (flux == null) return false;

    final l10n = context.l10n;
    final depot = ref.read(authRepositoryProvider);
    final fluxNotifier = ref.read(fluxVerificationProvider.notifier);
    try {
      final token = await depot.motDePasseOublie(flux.identifiant);
      fluxNotifier.remplacerToken(token);
      if (mounted) setState(() => _erreur = null);
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flux = ref.watch(fluxVerificationProvider);
    if (flux == null) return const Scaffold();

    final l10n = context.l10n;
    return PageAcces(
      titre: l10n.reinitTitre,
      sousTitre: l10n.reinitSousTitre,
      enfants: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        ChampCode(controleur: _code, erreur: _erreurCode),
        const SizedBox(height: Espacements.l),
        Form(
          key: _cle,
          child: ChampMotDePasse(
            controleur: _motDePasse,
            libelle: l10n.champNouveauMotDePasse,
            nouveau: true,
            surSoumission: (_) => _soumettre(),
            actif: !_envoi,
          ),
        ),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.reinitBouton,
          enCours: _envoi,
          surAppui: _soumettre,
        ),
        const SizedBox(height: Espacements.s),
        LienRenvoyerCode(surRenvoyer: _renvoyer),
      ],
    );
  }
}
