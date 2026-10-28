import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/widgets/bandeau_message.dart';
import '../../../shared/widgets/bouton_action.dart';
import '../../../shared/widgets/champ_dropp.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../auth/data/modeles_auth.dart';
import '../../auth/domain/validateurs.dart';
import '../../auth/ui/widgets/selecteur_sexe.dart';
import '../data/profil.dart';

/// Disponibilité du pseudo saisi.
enum _EtatPseudo { inchange, verification, disponible, pris, invalide }

/// Prénom, nom, pseudo (disponibilité vérifiée pendant la saisie) et sexe.
class PageModifierProfil extends ConsumerStatefulWidget {
  const PageModifierProfil({super.key});

  @override
  ConsumerState<PageModifierProfil> createState() => _PageModifierProfilState();
}

class _PageModifierProfilState extends ConsumerState<PageModifierProfil> {
  final _cle = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _pseudo = TextEditingController();
  Sexe? _sexe;
  ProfilComplet? _initial;
  _EtatPseudo _etatPseudo = _EtatPseudo.inchange;
  Timer? _minuteurPseudo;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _minuteurPseudo?.cancel();
    _prenom.dispose();
    _nom.dispose();
    _pseudo.dispose();
    super.dispose();
  }

  void _remplir(ProfilComplet p) {
    if (_initial != null) return;
    _initial = p;
    _prenom.text = p.prenom;
    _nom.text = p.nom;
    _pseudo.text = p.pseudo ?? '';
    _sexe = p.sexe;
  }

  void _surPseudo(String texte) {
    _minuteurPseudo?.cancel();
    final pseudo = normaliserPseudo(texte);
    if (pseudo.isEmpty || pseudo == _initial?.pseudo) {
      setState(() => _etatPseudo = _EtatPseudo.inchange);
      return;
    }
    if (!formatPseudo.hasMatch(pseudo)) {
      setState(() => _etatPseudo = _EtatPseudo.invalide);
      return;
    }
    setState(() => _etatPseudo = _EtatPseudo.verification);
    _minuteurPseudo = Timer(const Duration(milliseconds: 400), () async {
      try {
        final libre = await ref
            .read(profilRepositoryProvider)
            .pseudoDisponible(pseudo);
        if (mounted && normaliserPseudo(_pseudo.text) == pseudo) {
          setState(
            () =>
                _etatPseudo = libre ? _EtatPseudo.disponible : _EtatPseudo.pris,
          );
        }
      } on ApiException {
        if (mounted) setState(() => _etatPseudo = _EtatPseudo.inchange);
      }
    });
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;
    if (_etatPseudo == _EtatPseudo.pris ||
        _etatPseudo == _EtatPseudo.invalide) {
      return;
    }
    final l10n = context.l10n;
    final initial = _initial!;
    final pseudo = normaliserPseudo(_pseudo.text);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(profilRepositoryProvider)
          .modifier(
            prenom: _prenom.text != initial.prenom ? _prenom.text : null,
            nom: _nom.text != initial.nom ? _nom.text : null,
            pseudo: pseudo.isNotEmpty && pseudo != initial.pseudo
                ? pseudo
                : null,
            sexe: _sexe != initial.sexe ? _sexe : null,
          );
      // Le nom affiché vient aussi de la session (/auth/me).
      await ref.read(sessionProvider.notifier).rafraichirProfil();
      ref.invalidate(profilProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.conflit: l10n.pseudoPris,
            TypeErreurApi.requeteInvalide: l10n.pseudoReserve,
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metier = context.couleursMetier;
    final profil = ref.watch(profilProvider).value;
    if (profil != null) _remplir(profil);
    final erreur = _erreur;

    final (Widget? icone, String? aide) = switch (_etatPseudo) {
      _EtatPseudo.verification => (
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        null,
      ),
      _EtatPseudo.disponible => (
        Icon(Icons.check_circle, color: metier.succes),
        l10n.pseudoDisponible,
      ),
      _EtatPseudo.pris => (
        Icon(Icons.cancel, color: metier.erreur),
        l10n.pseudoPris,
      ),
      _EtatPseudo.invalide => (
        Icon(Icons.info_outline, color: metier.attente),
        l10n.pseudoFormat,
      ),
      _EtatPseudo.inchange => (null, null),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilModifier)),
      body: profil == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _cle,
              child: ListView(
                padding: const EdgeInsets.all(Espacements.l),
                children: [
                  if (erreur != null) ...[
                    BandeauMessage(message: erreur),
                    const SizedBox(height: Espacements.l),
                  ],
                  ChampDropp(
                    libelle: l10n.champPrenom,
                    controleur: _prenom,
                    validateur: validerRequis,
                    capitalisation: TextCapitalization.words,
                    longueurMax: 100,
                    actif: !_envoi,
                  ),
                  const SizedBox(height: Espacements.l),
                  ChampDropp(
                    libelle: l10n.champNom,
                    controleur: _nom,
                    validateur: validerRequis,
                    capitalisation: TextCapitalization.words,
                    longueurMax: 100,
                    actif: !_envoi,
                  ),
                  const SizedBox(height: Espacements.l),
                  ChampDropp(
                    libelle: l10n.champPseudo,
                    controleur: _pseudo,
                    longueurMax: 31,
                    actif: !_envoi,
                    suffixe: icone == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: icone,
                          ),
                    surChangement: _surPseudo,
                  ),
                  if (aide != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Espacements.xs),
                      child: Text(
                        aide,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: Espacements.l),
                  SelecteurSexe(
                    valeur: _sexe,
                    surChangement: (s) => setState(() => _sexe = s),
                  ),
                  const SizedBox(height: Espacements.xl),
                  BoutonAction(
                    libelle: l10n.enregistrer,
                    enCours: _envoi,
                    surAppui: _enregistrer,
                  ),
                ],
              ),
            ),
    );
  }
}
