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
import '../../data/auth_repository.dart';
import '../../domain/validateurs.dart';
import '../messages_erreurs.dart';
import '../widgets/bandeau_message.dart';
import '../widgets/bouton_action.dart';
import '../widgets/champ_code.dart';
import '../widgets/champ_mot_de_passe.dart';
import '../widgets/lien_renvoyer_code.dart';
import '../widgets/page_acces.dart';

/// Confirmation de l'adresse email par un code à 6 chiffres, ou changement
/// d'adresse (nouvelle adresse + mot de passe, puis code).
///
/// Une adresse confirmée permet de recevoir le code « mot de passe oublié »
/// par email. Ouverte :
/// - juste après l'activation par SMS ([codeDejaEnvoye] : le serveur a déjà
///   envoyé le code, « Plus tard » mène à l'accueil) ;
/// - depuis le profil (le code est demandé à l'ouverture) ;
/// - en mode [changement] depuis le profil.
class PageConfirmationEmail extends ConsumerStatefulWidget {
  const PageConfirmationEmail({
    super.key,
    this.codeDejaEnvoye = false,
    this.changement = false,
  });

  /// Paramètre de requête : `?envoye=1`.
  static const parametreEnvoye = 'envoye';

  /// Paramètre de requête : `?changer=1`.
  static const parametreChanger = 'changer';

  final bool codeDejaEnvoye;
  final bool changement;

  @override
  ConsumerState<PageConfirmationEmail> createState() =>
      _PageConfirmationEmailState();
}

enum _Etape { saisie, code, confirmee }

class _PageConfirmationEmailState extends ConsumerState<PageConfirmationEmail> {
  final _cle = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();

  late _Etape _etape;

  /// Adresse à laquelle le code a été envoyé.
  String? _cible;

  /// Vrai quand [_cible] est une nouvelle adresse (à préciser au serveur).
  bool _nouvelleAdresse = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final utilisateur = ref.read(utilisateurConnecteProvider);
    final email = utilisateur?.email;
    if (widget.changement || email == null) {
      _etape = _Etape.saisie;
    } else if (utilisateur!.emailVerifie) {
      _etape = _Etape.confirmee;
      _cible = email;
    } else {
      _etape = _Etape.code;
      _cible = email;
      if (!widget.codeDejaEnvoye) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _renvoyer());
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  AuthRepository get _depot => ref.read(authRepositoryProvider);

  String _message(ApiException e) {
    final l10n = context.l10n;
    return messageErreurApi(
      l10n,
      e,
      specifiques: {
        TypeErreurApi.requeteInvalide: _etape == _Etape.code
            ? l10n.erreurCodeIncorrect
            : l10n.erreurRequeteInvalide,
        TypeErreurApi.expire: l10n.erreurCodeExpire,
        TypeErreurApi.conflit: l10n.erreurEmailUtilisee,
        TypeErreurApi.nonAuthentifie: l10n.erreurMotDePasseIncorrect,
      },
    );
  }

  /// Envoie (ou renvoie) le code. Renvoie `true` si c'est fait.
  Future<bool> _renvoyer() async {
    setState(() => _erreur = null);
    try {
      final cible = _cible;
      if (_nouvelleAdresse && cible != null) {
        await _depot.changerEmail(email: cible, motDePasse: _motDePasse.text);
      } else {
        await _depot.envoyerCodeEmail();
      }
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      // Déjà vérifiée (sur un autre appareil) : on met le profil à jour.
      if (e.type == TypeErreurApi.conflit && !_nouvelleAdresse) {
        await ref.read(sessionProvider.notifier).rafraichirProfil();
        if (mounted) setState(() => _etape = _Etape.confirmee);
        return false;
      }
      setState(() => _erreur = _message(e));
      return false;
    }
  }

  Future<void> _envoyerNouvelleAdresse() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final cible = await _depot.changerEmail(
        email: _email.text,
        motDePasse: _motDePasse.text,
      );
      if (!mounted) return;
      setState(() {
        _cible = cible;
        _nouvelleAdresse = true;
        _etape = _Etape.code;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = _message(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _verifier(String code) async {
    if (_envoi) return;
    final l10n = context.l10n;
    if (validerCode(code) != null) {
      setState(() => _erreur = l10n.erreurCodeIncomplet);
      return;
    }
    final messager = ScaffoldMessenger.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await _depot.verifierEmail(code, email: _nouvelleAdresse ? _cible : null);
      await ref.read(sessionProvider.notifier).rafraichirProfil();
      if (!mounted) return;
      messager.showSnackBar(SnackBar(content: Text(l10n.emailConfirmee)));
      _terminer();
    } on ApiException catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() => _erreur = _message(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Après l'activation : vers l'accueil. Depuis le profil : retour.
  void _terminer() {
    if (!widget.codeDejaEnvoye && context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.accueil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plusTard = widget.codeDejaEnvoye
        ? [
            TextButton(
              onPressed: () => context.go(Routes.accueil),
              child: Text(l10n.emailPlusTard),
            ),
          ]
        : const <Widget>[];

    final erreur = _erreur;
    final bandeau = [
      if (erreur != null) ...[
        BandeauMessage(message: erreur),
        const SizedBox(height: Espacements.l),
      ],
    ];

    return switch (_etape) {
      _Etape.saisie => PageAcces(
        titre: ref.read(utilisateurConnecteProvider)?.email == null
            ? l10n.emailAjouterTitre
            : l10n.emailChangerTitre,
        sousTitre: l10n.emailChangerSousTitre,
        actions: plusTard,
        enfants: [
          ...bandeau,
          Form(
            key: _cle,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChampDropp(
                    libelle: l10n.champEmail,
                    controleur: _email,
                    validateur: (v) =>
                        validerRequis(v) ?? validerEmailFacultatif(v),
                    typeClavier: TextInputType.emailAddress,
                    indicesAutoRemplissage: const [AutofillHints.email],
                    longueurMax: 254,
                    actif: !_envoi,
                  ),
                  const SizedBox(height: Espacements.l),
                  ChampMotDePasse(
                    controleur: _motDePasse,
                    surSoumission: (_) => _envoyerNouvelleAdresse(),
                    actif: !_envoi,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Espacements.xl),
          BoutonAction(
            libelle: l10n.emailRecevoirCode,
            enCours: _envoi,
            surAppui: _envoyerNouvelleAdresse,
          ),
        ],
      ),
      _Etape.code => PageAcces(
        titre: l10n.emailTitre,
        sousTitre: l10n.emailSousTitre(_cible ?? ''),
        actions: plusTard,
        enfants: [
          ...bandeau,
          ChampCode(controleur: _code, surComplet: _verifier),
          const SizedBox(height: Espacements.xl),
          BoutonAction(
            libelle: l10n.emailConfirmer,
            enCours: _envoi,
            surAppui: () => _verifier(_code.text),
          ),
          const SizedBox(height: Espacements.s),
          LienRenvoyerCode(surRenvoyer: _renvoyer),
          if (!_nouvelleAdresse)
            TextButton(
              onPressed: () => setState(() {
                _erreur = null;
                _etape = _Etape.saisie;
              }),
              child: Text(l10n.emailChangerLien),
            ),
        ],
      ),
      _Etape.confirmee => PageAcces(
        titre: l10n.emailTitreConfirmee,
        sousTitre: l10n.emailDejaConfirmee(_cible ?? ''),
        enfants: [
          OutlinedButton(
            onPressed: () => setState(() {
              _erreur = null;
              _etape = _Etape.saisie;
            }),
            child: Text(l10n.emailChangerLien),
          ),
        ],
      ),
    };
  }
}

/// Chemin de l'écran, avec ses paramètres.
String cheminConfirmationEmail({bool envoye = false, bool changer = false}) {
  final parametres = {
    if (envoye) PageConfirmationEmail.parametreEnvoye: '1',
    if (changer) PageConfirmationEmail.parametreChanger: '1',
  };
  return Uri(
    path: Routes.confirmerEmail,
    queryParameters: parametres.isEmpty ? null : parametres,
  ).toString();
}

/// Pour les boutons qui ouvrent l'écran sans attendre.
void ouvrirConfirmationEmail(BuildContext context, {bool changer = false}) =>
    unawaited(context.push<void>(cheminConfirmationEmail(changer: changer)));
