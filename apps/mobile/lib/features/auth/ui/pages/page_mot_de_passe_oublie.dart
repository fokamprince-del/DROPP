import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/bouton_action.dart';
import '../../../../shared/widgets/champ_dropp.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../../../shared/widgets/page_acces.dart';
import '../../application/flux_verification.dart';
import '../../data/auth_repository.dart';
import '../../domain/identifiant.dart';
import '../navigation_auth.dart';

class PageMotDePasseOublie extends ConsumerStatefulWidget {
  const PageMotDePasseOublie({super.key});

  @override
  ConsumerState<PageMotDePasseOublie> createState() =>
      _PageMotDePasseOublieState();
}

class _PageMotDePasseOublieState extends ConsumerState<PageMotDePasseOublie> {
  final _cle = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;

    final l10n = context.l10n;
    final identifiant = normaliserIdentifiant(_identifiant.text)!;
    final depot = ref.read(authRepositoryProvider);
    final flux = ref.read(fluxVerificationProvider.notifier);
    final routeur = GoRouter.of(context);
    final versReinitialisation = cheminAvecRetour(
      context,
      Routes.reinitialiserMotDePasse,
    );

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final token = await depot.motDePasseOublie(identifiant);
      flux.demarrer(
        FluxVerification(
          objectif: ObjectifVerification.reinitialisation,
          verificationToken: token,
          identifiant: identifiant,
        ),
      );
      unawaited(routeur.push<void>(versReinitialisation));
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageAcces(
      titre: l10n.oubliTitre,
      sousTitre: l10n.oubliSousTitre,
      enfants: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Form(
          key: _cle,
          child: ChampDropp(
            libelle: l10n.champIdentifiant,
            controleur: _identifiant,
            validateur: validerIdentifiant,
            typeClavier: TextInputType.emailAddress,
            actionClavier: TextInputAction.done,
            indicesAutoRemplissage: const [AutofillHints.username],
            surSoumission: (_) => _envoyer(),
            actif: !_envoi,
          ),
        ),
        const SizedBox(height: Espacements.l),
        BandeauMessage(message: l10n.oubliSecurite, erreur: false),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.oubliBouton,
          enCours: _envoi,
          surAppui: _envoyer,
        ),
      ],
    );
  }
}
