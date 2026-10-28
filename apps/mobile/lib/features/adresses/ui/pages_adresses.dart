import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/rayons.dart';
import '../../../shared/widgets/bandeau_message.dart';
import '../../../shared/widgets/bouton_action.dart';
import '../../../shared/widgets/champ_dropp.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../auth/domain/validateurs.dart';
import '../data/adresses.dart';

String libelleType(AppLocalizations l10n, TypeAdresse type) => switch (type) {
  TypeAdresse.livraison => l10n.adresseLivraison,
  TypeAdresse.facturation => l10n.adresseFacturation,
  TypeAdresse.autre => l10n.adresseAutre,
};

/// Carnet d'adresses : principale d'abord ; toucher pour modifier.
class PageAdresses extends ConsumerWidget {
  const PageAdresses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final etat = ref.watch(adressesProvider);

    final Widget corps = switch (etat) {
      AsyncData(:final value) when value.isEmpty => ListView(
        children: [
          EtatVide(
            icone: Icons.location_on_outlined,
            titre: l10n.adressesVide,
            texte: l10n.adressesVideTexte,
          ),
        ],
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.all(Espacements.l),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: Espacements.s),
        itemBuilder: (context, i) {
          final a = value[i];
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: Rayons.borduresCarte,
            child: InkWell(
              borderRadius: Rayons.borduresCarte,
              onTap: () =>
                  unawaited(context.push<void>(Routes.adresse(a.id), extra: a)),
              child: Container(
                padding: const EdgeInsets.all(Espacements.m),
                decoration: BoxDecoration(
                  borderRadius: Rayons.borduresCarte,
                  border: Border.all(
                    color: a.estPrincipale
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      a.type == TypeAdresse.livraison
                          ? Icons.local_shipping_outlined
                          : Icons.location_on_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: Espacements.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              libelleType(l10n, a.type),
                              if (a.estPrincipale) l10n.adressePrincipale,
                            ].join(' · '),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [a.ligne1, ?a.ligne2].join(', '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(a.localite, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AsyncError(:final error) => Center(
        child: VueErreur(
          erreur: ApiException.depuis(error),
          reessayer: () => ref.invalidate(adressesProvider),
        ),
      ),
      _ => ListView(
        padding: const EdgeInsets.all(Espacements.l),
        children: const [
          Squelette(hauteur: 76, rayon: 16),
          SizedBox(height: Espacements.s),
          Squelette(hauteur: 76, rayon: 16),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adressesTitre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(context.push<void>(Routes.nouvelleAdresse)),
        icon: const Icon(Icons.add),
        label: Text(l10n.adresseAjouter),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adressesProvider),
        child: corps,
      ),
    );
  }
}

/// Ajout ([adresse] `null`) ou modification d'une adresse.
class PageFormulaireAdresse extends ConsumerStatefulWidget {
  const PageFormulaireAdresse({super.key, this.adresse});

  final Adresse? adresse;

  @override
  ConsumerState<PageFormulaireAdresse> createState() =>
      _PageFormulaireAdresseState();
}

class _PageFormulaireAdresseState extends ConsumerState<PageFormulaireAdresse> {
  final _cle = GlobalKey<FormState>();
  late final Adresse? _a = widget.adresse;
  late TypeAdresse _type = _a?.type ?? TypeAdresse.livraison;
  late bool _principale = _a?.estPrincipale ?? false;
  late final _ligne1 = TextEditingController(text: _a?.ligne1);
  late final _ligne2 = TextEditingController(text: _a?.ligne2);
  late final _ville = TextEditingController(text: _a?.ville);
  late final _region = TextEditingController(text: _a?.region);
  late final _pays = TextEditingController(text: _a?.pays ?? 'Cameroun');
  late final _codePostal = TextEditingController(text: _a?.codePostal);
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    for (final c in [_ligne1, _ligne2, _ville, _region, _pays, _codePostal]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();
    if (!_cle.currentState!.validate() || _envoi) return;
    final l10n = context.l10n;
    final depot = ref.read(adressesRepositoryProvider);
    final saisie = SaisieAdresse(
      type: _type,
      ligne1: _ligne1.text,
      ligne2: _ligne2.text,
      ville: _ville.text,
      region: _region.text,
      pays: _pays.text,
      codePostal: _codePostal.text,
      estPrincipale: _principale,
    );
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final a = _a;
      if (a == null) {
        await depot.ajouter(saisie);
      } else {
        await depot.modifier(a.id, saisie);
      }
      ref.invalidate(adressesProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _supprimer() async {
    final a = _a;
    if (a == null) return;
    final l10n = context.l10n;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adresseSupprimerTitre),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.supprimer),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    setState(() => _envoi = true);
    try {
      await ref.read(adressesRepositoryProvider).supprimer(a.id);
      ref.invalidate(adressesProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = messageErreurApi(l10n, e);
          _envoi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final erreur = _erreur;

    Widget champ(
      TextEditingController c,
      String libelle, {
      bool requis = false,
      int max = 100,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: Espacements.l),
      child: ChampDropp(
        libelle: libelle,
        controleur: c,
        validateur: requis ? validerRequis : null,
        capitalisation: TextCapitalization.sentences,
        longueurMax: max,
        actif: !_envoi,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_a == null ? l10n.adresseAjouter : l10n.adresseModifier),
        actions: [
          if (_a != null)
            IconButton(
              tooltip: l10n.supprimer,
              onPressed: _envoi ? null : _supprimer,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.all(Espacements.l),
          children: [
            if (erreur != null) ...[
              BandeauMessage(message: erreur),
              const SizedBox(height: Espacements.l),
            ],
            SegmentedButton<TypeAdresse>(
              showSelectedIcon: false,
              segments: [
                for (final t in TypeAdresse.values)
                  ButtonSegment(value: t, label: Text(libelleType(l10n, t))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: Espacements.l),
            champ(_ligne1, l10n.adresseLigne1, requis: true, max: 255),
            champ(_ligne2, l10n.adresseLigne2, max: 255),
            champ(_ville, l10n.adresseVille, requis: true),
            champ(_region, l10n.adresseRegion),
            champ(_pays, l10n.adressePays, requis: true),
            champ(_codePostal, l10n.adresseCodePostal, max: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adresseDefinirPrincipale),
              value: _principale,
              onChanged: _envoi ? null : (v) => setState(() => _principale = v),
            ),
            const SizedBox(height: Espacements.l),
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
