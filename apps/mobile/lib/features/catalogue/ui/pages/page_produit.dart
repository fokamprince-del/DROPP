import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/etoiles.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../../../shared/widgets/vue_erreur.dart';
import '../../../../utils/format.dart';
import '../../../boutiques/application/boutiques_providers.dart';
import '../../../fil/ui/widgets/medias_publication.dart';
import '../../../interactions/application/interactions.dart';
import '../../../interactions/ui/actions_connectees.dart';
import '../../../messagerie/ui/page_discussion.dart';
import '../../../moderation/data/moderation.dart';
import '../../../moderation/ui/moderation_ui.dart';
import '../../../panier/application/panier.dart';
import '../../application/catalogue_providers.dart';
import '../../data/catalogue_repository.dart';
import '../../data/modeles_catalogue.dart';
import '../widgets/avis.dart';
import '../widgets/carte_produit.dart';

/// Fiche produit : photos, prix, variantes et stock, boutique, avis.
class PageProduit extends ConsumerWidget {
  const PageProduit({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(produitProvider(id));
    return switch (etat) {
      AsyncData(:final value) => _Fiche(produit: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Espacements.xl),
            child: VueErreur(
              erreur: ApiException.depuis(error),
              reessayer: () => ref.invalidate(produitProvider(id)),
            ),
          ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AspectRatio(aspectRatio: 1, child: Squelette(rayon: 0)),
            Padding(
              padding: EdgeInsets.all(Espacements.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Squelette(largeur: 200, hauteur: 14),
                  SizedBox(height: Espacements.m),
                  Squelette(largeur: 120, hauteur: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _Fiche extends ConsumerStatefulWidget {
  const _Fiche({required this.produit});

  final ProduitDetail produit;

  @override
  ConsumerState<_Fiche> createState() => _FicheState();
}

class _FicheState extends ConsumerState<_Fiche> {
  /// Valeur choisie pour chaque attribut (`taille` → `M`).
  late Map<String, String> _choix;

  /// Variantes sans attributs : choisies par leur nom.
  Variante? _variante;

  ProduitDetail get _p => widget.produit;

  @override
  void initState() {
    super.initState();
    // Présélection : la première variante en stock.
    final premiere = _p.variantes.isEmpty
        ? null
        : _p.variantes.firstWhere(
            (v) => v.enStock,
            orElse: () => _p.variantes.first,
          );
    _choix = {...?premiere?.attributs};
    _variante = premiere;
  }

  Variante? get _varianteChoisie {
    final variantes = _p.variantes;
    if (variantes.isEmpty) return null;
    final attributs = _p.attributs;
    if (attributs.isEmpty) return _variante;
    for (final v in variantes) {
      if (attributs.every((a) => v.attributs[a] == _choix[a])) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = _p;
    final variante = _varianteChoisie;
    final favori = ref.watch(
      interactionsProvider.select((e) => e.favorisProduits.contains(p.id)),
    );

    final prix = variante != null
        ? formaterPrix(p.prixDe(variante))
        : p.prixVariable
        ? l10n.prixAPartirDe(formaterPrix(p.prixMin))
        : formaterPrix(p.prixBase);

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _BarreAchat(produit: p, variante: variante),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Center(
          child: _BoutonRond(
            icone: Icons.arrow_back,
            libelle: MaterialLocalizations.of(context).backButtonTooltip,
            surAppui: () => context.pop(),
          ),
        ),
        actions: [
          if (ref.watch(utilisateurConnecteProvider)?.id != p.boutiqueId)
            _BoutonRond(
              icone: Icons.flag_outlined,
              libelle: l10n.signaler,
              surAppui: () => unawaited(
                ouvrirSignalement(
                  context,
                  ref,
                  typeCible: TypeCible.produit,
                  cibleId: p.id,
                ),
              ),
            ),
          BoutonFavoriProduit(produitId: p.id, favori: favori),
          const SizedBox(width: Espacements.xs),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + Espacements.xxl,
        ),
        children: [
          MediasPublication(medias: p.medias, ratio: 1, lecture: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacements.l,
              Espacements.m,
              Espacements.l,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nom,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Espacements.xs),
                Text(
                  prix,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: Typographie.titre,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Espacements.s),
                Wrap(
                  spacing: Espacements.s,
                  runSpacing: Espacements.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _BadgeStock(produit: p, variante: variante),
                    _NoteProduit(produitId: p.id),
                  ],
                ),
                if (p.variantes.length > 1 || p.attributs.isNotEmpty) ...[
                  const SizedBox(height: Espacements.l),
                  _SelecteurVariantes(
                    produit: p,
                    choix: _choix,
                    variante: _variante,
                    surAttribut: (attribut, valeur) =>
                        setState(() => _choix = {..._choix, attribut: valeur}),
                    surVariante: (v) => setState(() => _variante = v),
                  ),
                ],
                if (p.description != null) ...[
                  const SizedBox(height: Espacements.l),
                  Text(
                    p.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Espacements.l),
                _LigneBoutique(boutiqueId: p.boutiqueId),
                const SizedBox(height: Espacements.xl),
                _ApercuAvis(produitId: p.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Puces par attribut (taille, couleur…) ; une valeur sans stock reste
/// choisissable mais apparaît barrée.
class _SelecteurVariantes extends StatelessWidget {
  const _SelecteurVariantes({
    required this.produit,
    required this.choix,
    required this.variante,
    required this.surAttribut,
    required this.surVariante,
  });

  final ProduitDetail produit;
  final Map<String, String> choix;
  final Variante? variante;
  final void Function(String attribut, String valeur) surAttribut;
  final ValueChanged<Variante> surVariante;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titre = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget puce(
      String libelle,
      bool choisie,
      bool disponible,
      VoidCallback f,
    ) => ChoiceChip(
      label: Text(
        libelle,
        style: disponible
            ? null
            : const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      tooltip: disponible ? null : l10n.stockRupture,
      selected: choisie,
      showCheckmark: false,
      onSelected: (_) => f(),
    );

    // Variantes sans attributs : une puce par nom.
    if (produit.attributs.isEmpty) {
      return Wrap(
        spacing: Espacements.s,
        runSpacing: Espacements.s,
        children: [
          for (final (i, v) in produit.variantes.indexed)
            puce(
              v.nom ?? l10n.varianteNumero(i + 1),
              variante?.id == v.id,
              v.enStock,
              () => surVariante(v),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final attribut in produit.attributs) ...[
          Text(
            '${_capitaliser(attribut)} : ${choix[attribut] ?? '—'}',
            style: titre,
          ),
          const SizedBox(height: Espacements.xs),
          Wrap(
            spacing: Espacements.s,
            runSpacing: Espacements.s,
            children: [
              for (final valeur in _valeurs(attribut))
                puce(
                  valeur,
                  choix[attribut] == valeur,
                  _disponible(attribut, valeur),
                  () => surAttribut(attribut, valeur),
                ),
            ],
          ),
          const SizedBox(height: Espacements.m),
        ],
      ],
    );
  }

  List<String> _valeurs(String attribut) =>
      {for (final v in produit.variantes) ?v.attributs[attribut]}.toList();

  /// Une variante en stock existe avec cette valeur et les autres choix.
  bool _disponible(String attribut, String valeur) => produit.variantes.any(
    (v) =>
        v.enStock &&
        v.attributs[attribut] == valeur &&
        choix.entries.every(
          (c) => c.key == attribut || v.attributs[c.key] == c.value,
        ),
  );

  static String _capitaliser(String texte) =>
      texte.isEmpty ? texte : '${texte[0].toUpperCase()}${texte.substring(1)}';
}

class _BadgeStock extends StatelessWidget {
  const _BadgeStock({required this.produit, required this.variante});

  final ProduitDetail produit;
  final Variante? variante;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metier = context.couleursMetier;
    final v = variante;
    final stock = v?.stock ?? produit.stockTotal;
    if (produit.variantes.isEmpty) return const SizedBox.shrink();

    final (texte, couleur, fond) = stock <= 0
        ? (l10n.stockRupture, metier.erreur, metier.erreurFond)
        : stock <= 3
        ? (l10n.stockPlusQue(stock), metier.attente, metier.attenteFond)
        : (l10n.stockEnStock, metier.succes, metier.succesFond);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          texte,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: couleur, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _NoteProduit extends ConsumerWidget {
  const _NoteProduit({required this.produitId});

  final String produitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(apercuAvisProvider(produitId)).value;
    if (page == null) return const SizedBox.shrink();
    final resume = resumeDe(page);
    final moyenne = resume.moyenne;
    if (resume.total == 0 || moyenne == null) return const SizedBox.shrink();
    return Semantics(
      label: l10n.avisMoyenne(formaterNote(moyenne, l10n.localeName)),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Etoiles(note: moyenne),
          const SizedBox(width: Espacements.xs),
          Text(
            '${formaterNote(moyenne, l10n.localeName)} '
            '(${l10n.avisNombre(resume.total)})',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Boutique du produit : logo, nom, abonnés ; ouvre sa page.
class _LigneBoutique extends ConsumerWidget {
  const _LigneBoutique({required this.boutiqueId});

  final String boutiqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final boutique = ref.watch(boutiqueProvider(boutiqueId)).value;
    final abonnes = ref.watch(
      interactionsProvider.select(
        (e) => e.abonnes(boutiqueId, boutique?.abonnes ?? 0),
      ),
    );

    return Material(
      color: schema.surface,
      borderRadius: Rayons.borduresCarte,
      child: InkWell(
        borderRadius: Rayons.borduresCarte,
        onTap: () => unawaited(context.push<void>(Routes.boutique(boutiqueId))),
        child: Container(
          padding: const EdgeInsets.all(Espacements.m),
          decoration: BoxDecoration(
            borderRadius: Rayons.borduresCarte,
            border: Border.all(color: schema.outline),
          ),
          child: boutique == null
              ? const Row(
                  children: [
                    Squelette(largeur: 40, hauteur: 40, cercle: true),
                    SizedBox(width: Espacements.m),
                    Squelette(largeur: 140, hauteur: 12),
                  ],
                )
              : Row(
                  children: [
                    AvatarBoutique(
                      nom: boutique.nom,
                      logoUrl: boutique.logoUrl,
                      taille: 40,
                    ),
                    const SizedBox(width: Espacements.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boutique.nom,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              l10n.boutiqueAbonnes(abonnes),
                              ?boutique.lieu,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: schema.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Trois derniers avis et lien vers tous les avis.
class _ApercuAvis extends ConsumerWidget {
  const _ApercuAvis({required this.produitId});

  final String produitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final page = ref.watch(apercuAvisProvider(produitId)).value;
    if (page == null) return const SizedBox.shrink();
    final total = resumeDe(page).total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.avisTitreNombre(total),
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: Typographie.titre,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Espacements.s),
        if (page.donnees.isEmpty)
          Text(
            l10n.avisAucun,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          for (final avis in page.donnees)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacements.s),
              child: CarteAvis(
                avis: avis,
                surChangement: () =>
                    ref.invalidate(apercuAvisProvider(produitId)),
              ),
            ),
          if (total > page.donnees.length)
            OutlinedButton(
              onPressed: () =>
                  unawaited(context.push<void>(Routes.avisProduit(produitId))),
              child: Text(l10n.avisVoirTous(total)),
            ),
        ],
      ],
    );
  }
}

/// « Écrire à la boutique » et « Ajouter au panier » (maquette). Masquée
/// sur ses propres produits.
class _BarreAchat extends ConsumerStatefulWidget {
  const _BarreAchat({required this.produit, required this.variante});

  final ProduitDetail produit;

  /// `null` tant que toutes les options ne sont pas choisies.
  final Variante? variante;

  @override
  ConsumerState<_BarreAchat> createState() => _BarreAchatState();
}

class _BarreAchatState extends ConsumerState<_BarreAchat> {
  bool _ajout = false;
  bool _ouverture = false;

  Future<void> _ajouter(Variante variante) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final routeur = GoRouter.of(context);
    setState(() => _ajout = true);
    await actionConnectee(context, ref, () async {
      await ref.read(panierProvider.notifier).ajouter(variante.id);
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.panierAjoute),
            action: SnackBarAction(
              label: l10n.panierVoir,
              onPressed: () => routeur.go(Routes.panier),
            ),
          ),
        );
    });
    if (mounted) setState(() => _ajout = false);
  }

  Future<void> _ecrire() async {
    setState(() => _ouverture = true);
    await actionConnectee(
      context,
      ref,
      () => ouvrirDiscussionAvec(context, ref, widget.produit.boutiqueId),
    );
    if (mounted) setState(() => _ouverture = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moi = ref.watch(utilisateurConnecteProvider);
    if (moi?.id == widget.produit.boutiqueId) return const SizedBox.shrink();
    final v = widget.variante;
    final schema = Theme.of(context).colorScheme;

    final String libelle;
    if (widget.produit.variantes.isEmpty || (v != null && !v.enStock)) {
      libelle = l10n.stockRupture;
    } else if (v == null) {
      libelle = l10n.panierChoisirOption;
    } else {
      libelle = l10n.panierAjouter;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: schema.surface,
        border: Border(top: BorderSide(color: schema.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espacements.l,
            Espacements.s,
            Espacements.l,
            Espacements.s,
          ),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: l10n.boutiqueEcrire,
                onPressed: _ouverture ? null : _ecrire,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              const SizedBox(width: Espacements.s),
              Expanded(
                child: FilledButton(
                  onPressed: v != null && v.enStock && !_ajout
                      ? () => _ajouter(v)
                      : null,
                  child: _ajout
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(libelle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton rond blanc posé sur une photo (retour).
class _BoutonRond extends StatelessWidget {
  const _BoutonRond({
    required this.icone,
    required this.libelle,
    required this.surAppui,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: libelle,
      onPressed: surAppui,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: const Color(0xFF151936),
      ),
      icon: Icon(icone),
    );
  }
}
