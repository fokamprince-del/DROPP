import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/widgets/bandeau_message.dart';
import '../../../shared/widgets/bouton_action.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/page_acces.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../../utils/format.dart';
import '../../../utils/telephone.dart';
import '../../auth/domain/validateurs.dart';
import '../../auth/ui/pages/page_confirmation_email.dart';
import '../../auth/ui/widgets/champ_code.dart';
import '../../auth/ui/widgets/champ_mot_de_passe.dart';
import '../../auth/ui/widgets/champ_telephone.dart';
import '../../auth/ui/widgets/lien_renvoyer_code.dart';
import '../data/profil.dart';

/// Sécurité : identifiants, appareils connectés, suppression du compte.
class PageSecurite extends ConsumerWidget {
  const PageSecurite({super.key});

  Future<void> _deconnecterPartout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deconnecterPartoutTitre),
        content: Text(l10n.deconnecterPartoutTexte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deconnecterPartout),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await ref.read(profilRepositoryProvider).deconnecterPartout();
      await ref.read(sessionProvider.notifier).fermerLocalement();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    }
  }

  Future<void> _revoquer(
    BuildContext context,
    WidgetRef ref,
    SessionAppareil s,
  ) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref.read(profilRepositoryProvider).revoquerSession(s.id);
      ref.invalidate(sessionsProvider);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final sessions = ref.watch(sessionsProvider);
    final date = DateFormat.yMMMd(l10n.localeName);

    Widget titre(String texte) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacements.l,
        Espacements.l,
        Espacements.l,
        Espacements.xs,
      ),
      child: Text(
        texte,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securiteTitre)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sessionsProvider),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Espacements.xl),
          children: [
            titre(l10n.securiteIdentifiants),
            ListTile(
              leading: const FaIcon(IconesDropp.userLock),
              title: Text(l10n.motDePasseChanger),
              trailing: const FaIcon(IconesDropp.chevronRigth),
              onTap: () => unawaited(context.push<void>(Routes.motDePasse)),
            ),
            ListTile(
              leading: const FaIcon(IconesDropp.mobile),
              title: Text(l10n.telephoneChanger),
              trailing: const FaIcon(IconesDropp.chevronRigth),
              onTap: () =>
                  unawaited(context.push<void>(Routes.changerTelephone)),
            ),
            ListTile(
              leading: const FaIcon(IconesDropp.emailAt),
              title: Text(l10n.emailChangerTitre),
              trailing: const FaIcon(IconesDropp.chevronRigth),
              onTap: () => ouvrirConfirmationEmail(context, changer: true),
            ),
            titre(l10n.securiteAppareils),
            switch (sessions) {
              AsyncData(:final value) => Column(
                children: [
                  for (final s in value)
                    ListTile(
                      leading: FaIcon(
                        s.plateforme == 'IOS'
                            ? IconesDropp.iphone
                            : IconesDropp.android,
                      ),
                      title: Text(
                        s.modele ??
                            (s.plateforme == null
                                ? l10n.appareilInconnu
                                : s.plateforme == 'IOS'
                                ? 'iPhone'
                                : 'Android'),
                      ),
                      subtitle: Text(
                        s.actuelle
                            ? l10n.appareilActuel
                            : l10n.appareilDerniereUtilisation(
                                s.derniereUtilisation == null
                                    ? date.format(s.dateCreation)
                                    : tempsRelatif(
                                        l10n,
                                        s.derniereUtilisation!,
                                      ),
                              ),
                        style: s.actuelle
                            ? theme.textTheme.bodySmall?.copyWith(
                                color: metier.succes,
                                fontWeight: FontWeight.w700,
                              )
                            : theme.textTheme.bodySmall,
                      ),
                      trailing: s.actuelle
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  unawaited(_revoquer(context, ref, s)),
                              child: Text(l10n.deconnexion),
                            ),
                    ),
                ],
              ),
              AsyncError(:final error) => Padding(
                padding: const EdgeInsets.all(Espacements.l),
                child: VueErreur(
                  erreur: ApiException.depuis(error),
                  reessayer: () => ref.invalidate(sessionsProvider),
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Espacements.l),
                child: Squelette(hauteur: 56),
              ),
            },
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Espacements.l),
              child: OutlinedButton.icon(
                onPressed: () => unawaited(_deconnecterPartout(context, ref)),
                icon: const Icon(Icons.logout),
                label: Text(l10n.deconnecterPartout),
              ),
            ),
            titre(l10n.securiteCompte),
            ListTile(
              leading: FaIcon(IconesDropp.deleteForever, color: metier.erreur),
              title: Text(
                l10n.compteSupprimer,
                style: TextStyle(color: metier.erreur),
              ),
              onTap: () => unawaited(_supprimerCompte(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimerCompte(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final routeur = GoRouter.of(context);
    final motDePasse = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.compteSupprimerTitre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.compteSupprimerTexte),
            const SizedBox(height: Espacements.m),
            TextField(
              controller: motDePasse,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l10n.champMotDePasse),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.couleursMetier.erreur,
            ),
            child: Text(l10n.compteSupprimerConfirmer),
          ),
        ],
      ),
    );
    final saisi = motDePasse.text;
    motDePasse.dispose();
    if (confirme != true) return;
    try {
      await ref.read(profilRepositoryProvider).supprimerCompte(saisi);
      await ref.read(sessionProvider.notifier).fermerLocalement();
      routeur.go(Routes.accueil);
      messager.showSnackBar(SnackBar(content: Text(l10n.compteSupprime)));
    } on ApiException catch (e) {
      messager.showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {
                TypeErreurApi.nonAuthentifie: l10n.erreurMotDePasseIncorrect,
                TypeErreurApi.conflit: l10n.compteCommandesEnCours,
              },
            ),
          ),
        ),
      );
    }
  }
}

/// Changer de mot de passe : les autres appareils sont déconnectés.
class PageChangerMotDePasse extends ConsumerStatefulWidget {
  const PageChangerMotDePasse({super.key});

  @override
  ConsumerState<PageChangerMotDePasse> createState() =>
      _PageChangerMotDePasseState();
}

class _PageChangerMotDePasseState extends ConsumerState<PageChangerMotDePasse> {
  final _cle = GlobalKey<FormState>();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final jetons = await ref
          .read(profilRepositoryProvider)
          .changerMotDePasse(ancien: _ancien.text, nouveau: _nouveau.text);
      // Toutes les sessions ont été révoquées : on repart sur les nouvelles.
      await ref.read(sessionProvider.notifier).ouvrir(jetons);
      messager.showSnackBar(SnackBar(content: Text(l10n.motDePasseChange)));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.nonAuthentifie: l10n.erreurMotDePasseActuel,
            TypeErreurApi.requeteInvalide: l10n.erreurMotDePasseRefuse,
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final erreur = _erreur;
    return PageAcces(
      titre: l10n.motDePasseChanger,
      sousTitre: l10n.motDePasseChangerTexte,
      enfants: [
        if (erreur != null) ...[
          BandeauMessage(message: erreur),
          const SizedBox(height: Espacements.l),
        ],
        Form(
          key: _cle,
          child: AutofillGroup(
            child: Column(
              children: [
                ChampMotDePasse(
                  controleur: _ancien,
                  libelle: l10n.champMotDePasseActuel,
                  actionClavier: TextInputAction.next,
                  actif: !_envoi,
                ),
                const SizedBox(height: Espacements.l),
                ChampMotDePasse(
                  controleur: _nouveau,
                  libelle: l10n.champNouveauMotDePasse,
                  nouveau: true,
                  surSoumission: (_) => _valider(),
                  actif: !_envoi,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.enregistrer,
          enCours: _envoi,
          surAppui: _valider,
        ),
      ],
    );
  }
}

/// Changer de numéro : nouveau numéro et mot de passe, puis code SMS reçu
/// sur le nouveau numéro.
class PageChangerTelephone extends ConsumerStatefulWidget {
  const PageChangerTelephone({super.key});

  @override
  ConsumerState<PageChangerTelephone> createState() =>
      _PageChangerTelephoneState();
}

class _PageChangerTelephoneState extends ConsumerState<PageChangerTelephone> {
  final _cle = GlobalKey<FormState>();
  final _telephone = TextEditingController.fromValue(
    const TextEditingValue(
      text: indicatifParDefaut,
      selection: TextSelection.collapsed(offset: indicatifParDefaut.length),
    ),
  );
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();

  /// Numéro normalisé auquel le code a été envoyé.
  String? _cible;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _telephone.dispose();
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  ProfilRepository get _depot => ref.read(profilRepositoryProvider);

  String _message(ApiException e) {
    final l10n = context.l10n;
    return messageErreurApi(
      l10n,
      e,
      specifiques: {
        TypeErreurApi.nonAuthentifie: l10n.erreurMotDePasseIncorrect,
        TypeErreurApi.conflit: l10n.telephoneDejaUtilise,
        TypeErreurApi.requeteInvalide: _cible == null
            ? l10n.erreurTelephoneInvalide
            : l10n.erreurCodeIncorrect,
        TypeErreurApi.expire: l10n.erreurCodeExpire,
        TypeErreurApi.interdit: l10n.erreurCodeIncorrect,
      },
    );
  }

  Future<void> _demander() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;
    final numero = normaliserTelephone(_telephone.text)!;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await _depot.demanderChangementTelephone(
        nouveauTelephone: numero,
        motDePasse: _motDePasse.text,
      );
      if (mounted) setState(() => _cible = numero);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = _message(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<bool> _renvoyer() async {
    final cible = _cible;
    if (cible == null) return false;
    try {
      await _depot.demanderChangementTelephone(
        nouveauTelephone: cible,
        motDePasse: _motDePasse.text,
      );
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = _message(e));
      return false;
    }
  }

  Future<void> _confirmer(String code) async {
    final cible = _cible;
    if (cible == null || _envoi) return;
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
      await _depot.confirmerChangementTelephone(
        nouveauTelephone: cible,
        code: code,
      );
      await ref.read(sessionProvider.notifier).rafraichirProfil();
      ref.invalidate(profilProvider);
      messager.showSnackBar(SnackBar(content: Text(l10n.telephoneChange)));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() {
        _envoi = false;
        _erreur = _message(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final erreur = _erreur;
    final cible = _cible;
    final bandeau = [
      if (erreur != null) ...[
        BandeauMessage(message: erreur),
        const SizedBox(height: Espacements.l),
      ],
    ];

    if (cible != null) {
      return PageAcces(
        titre: l10n.codeTitre,
        sousTitre: l10n.codeEnvoyeA(masquerTelephone(cible)),
        enfants: [
          ...bandeau,
          ChampCode(controleur: _code, surComplet: _confirmer, actif: !_envoi),
          const SizedBox(height: Espacements.xl),
          BoutonAction(
            libelle: l10n.codeVerifier,
            enCours: _envoi,
            surAppui: () => _confirmer(_code.text),
          ),
          const SizedBox(height: Espacements.s),
          LienRenvoyerCode(surRenvoyer: _renvoyer),
        ],
      );
    }

    return PageAcces(
      titre: l10n.telephoneChanger,
      sousTitre: l10n.telephoneChangerTexte,
      enfants: [
        ...bandeau,
        Form(
          key: _cle,
          child: Column(
            children: [
              ChampTelephone(controleur: _telephone, actif: !_envoi),
              const SizedBox(height: Espacements.l),
              ChampMotDePasse(
                controleur: _motDePasse,
                surSoumission: (_) => _demander(),
                actif: !_envoi,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.inscriptionBouton,
          enCours: _envoi,
          surAppui: _demander,
        ),
      ],
    );
  }
}
