import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/etat_vide.dart';
import '../../../../shared/widgets/liste_paginee.dart';
import '../../../../utils/format.dart';
import '../../../boutiques/data/boutiques_repository.dart';
import '../../../boutiques/data/modeles_boutiques.dart';
import '../../../boutiques/ui/widgets/tuile_boutique.dart';
import '../../application/catalogue_providers.dart';
import '../../data/catalogue_repository.dart';
import '../../data/modeles_catalogue.dart';
import '../widgets/carte_produit.dart';
import '../widgets/feuille_filtres.dart';

/// Onglet Découvrir : recherche commune, puis produits (catégories, filtres,
/// tri) ou boutiques.
class PageDecouvrir extends StatefulWidget {
  const PageDecouvrir({super.key});

  @override
  State<PageDecouvrir> createState() => _PageDecouvrirState();
}

class _PageDecouvrirState extends State<PageDecouvrir> {
  static const _delaiRecherche = Duration(milliseconds: 400);

  final _recherche = TextEditingController();
  Timer? _minuteur;
  FiltresCatalogue _filtres = const FiltresCatalogue();

  @override
  void dispose() {
    _minuteur?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  /// On attend une courte pause dans la frappe avant d'interroger l'API.
  void _surSaisie(String texte) {
    setState(() {});
    _minuteur?.cancel();
    _minuteur = Timer(_delaiRecherche, () {
      final q = texte.trim();
      if (q == (_filtres.q ?? '')) return;
      setState(() => _filtres = _filtres.avec(q: q.isEmpty ? null : q));
    });
  }

  void _effacerRecherche() {
    _recherche.clear();
    _minuteur?.cancel();
    setState(() => _filtres = _filtres.avec(q: null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espacements.l,
                  Espacements.s,
                  Espacements.l,
                  Espacements.s,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.navDecouvrir,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: Typographie.titre,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espacements.m),
                child: TextField(
                  controller: _recherche,
                  onChanged: _surSaisie,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.rechercheIndice,
                    prefixIcon:const Center(child: FaIcon(IconesDropp.decouvrir)),
                    suffixIcon: _recherche.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.rechercheEffacer,
                            icon: const FaIcon(IconesDropp.close),
                            onPressed: _effacerRecherche,
                          ),
                  ),
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: Espacements.xs),
                dividerColor: Colors.transparent,
                labelColor: schema.onSurface,
                unselectedLabelColor: schema.onSurfaceVariant,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: schema.secondary, width: 3),
                  borderRadius: BorderRadius.circular(3),
                ),
                tabs: [
                  Tab(text: l10n.decouvrirProduits),
                  Tab(text: l10n.decouvrirBoutiques),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OngletProduits(
                      filtres: _filtres,
                      surFiltres: (f) => setState(() => _filtres = f),
                    ),
                    _OngletBoutiques(q: _filtres.q),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OngletProduits extends ConsumerStatefulWidget {
  const _OngletProduits({required this.filtres, required this.surFiltres});

  final FiltresCatalogue filtres;
  final ValueChanged<FiltresCatalogue> surFiltres;

  @override
  ConsumerState<_OngletProduits> createState() => _OngletProduitsState();
}

class _OngletProduitsState extends ConsumerState<_OngletProduits>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _ouvrirFiltres() async {
    final nouveaux = await ouvrirFiltres(context, widget.filtres);
    if (nouveaux != null) widget.surFiltres(nouveaux);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final filtres = widget.filtres;
    final depot = ref.watch(catalogueRepositoryProvider);

    return LayoutBuilder(
      builder: (context, contraintes) => ListePaginee<ProduitResume>(
        // Nouveaux filtres : on repart de la première page.
        key: ValueKey(filtres),
        charger: (page) => depot.produits(filtres, page),
        grille: grilleProduits(context, contraintes.maxWidth),
        padding: const EdgeInsets.fromLTRB(
          Espacements.m,
          0,
          Espacements.m,
          Espacements.l,
        ),
        auRafraichir: () async {
          ref.invalidate(categoriesProvider);
        },
        enTete: _EnTeteProduits(
          filtres: filtres,
          surFiltres: widget.surFiltres,
          surOuvrirFiltres: _ouvrirFiltres,
        ),
        squelette: const SqueletteGrille(),
        vide: EtatVide(
          icone: IconesDropp.searchChart,
          titre: l10n.catalogueVide,
          action: filtres.nombreActifs > 0 || filtres.categorieId != null
              ? TextButton(
                  onPressed: () =>
                      widget.surFiltres(FiltresCatalogue(q: filtres.q)),
                  child: Text(l10n.catalogueEffacerFiltres),
                )
              : null,
        ),
        elementBuilder: (context, produit, _) => CarteProduit(produit: produit),
      ),
    );
  }
}

/// Puces de catégories (et sous-catégories), bouton Filtres et tri.
class _EnTeteProduits extends ConsumerWidget {
  const _EnTeteProduits({
    required this.filtres,
    required this.surFiltres,
    required this.surOuvrirFiltres,
  });

  final FiltresCatalogue filtres;
  final ValueChanged<FiltresCatalogue> surFiltres;
  final VoidCallback surOuvrirFiltres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final categories = ref.watch(categoriesProvider).value ?? const [];

    // Catégorie parente active : celle choisie, ou la mère de la
    // sous-catégorie choisie.
    Categorie? parent;
    for (final c in categories) {
      if (c.id == filtres.categorieId ||
          c.enfants.any((e) => e.id == filtres.categorieId)) {
        parent = c;
      }
    }
    final total = categories.fold(0, (s, c) => s + c.nombreProduits);

    Widget puce(String libelle, int? nombre, bool choisie, String? id) =>
        Padding(
          padding: const EdgeInsets.only(right: Espacements.s),
          child: ChoiceChip(
            label: Text(
              nombre == null
                  ? libelle
                  : '$libelle  ${formaterCompteur(nombre, l10n.localeName)}',
            ),
            selected: choisie,
            showCheckmark: false,
            onSelected: (_) => surFiltres(filtres.avec(categorieId: id)),
          ),
        );

    final nombreFiltres = filtres.nombreActifs;
    return Padding(
      padding: const EdgeInsets.only(top: Espacements.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  puce(
                    l10n.catalogueTout,
                    total,
                    filtres.categorieId == null,
                    null,
                  ),
                  for (final c in categories)
                    puce(c.nom, c.nombreProduits, parent?.id == c.id, c.id),
                ],
              ),
            ),
          if (parent != null && parent.enfants.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in parent.enfants)
                    puce(
                      e.nom,
                      e.nombreProduits,
                      filtres.categorieId == e.id,
                      filtres.categorieId == e.id ? parent.id : e.id,
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Badge(
                isLabelVisible: nombreFiltres > 0,
                label: Text('$nombreFiltres'),
                backgroundColor: schema.secondary,
                child: OutlinedButton.icon(
                  onPressed: surOuvrirFiltres,
                  icon: const FaIcon(IconesDropp.slider, size: 18),
                  label: Text(l10n.filtresTitre),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: nombreFiltres > 0 ? schema.primary : null,
                    side: BorderSide(
                      color: nombreFiltres > 0
                          ? schema.primary
                          : schema.outline,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: surOuvrirFiltres,
                icon: const FaIcon(IconesDropp.swatVert, size: 18),
                label: Text(libelleTri(l10n, filtres.tri)),
              ),
            ],
          ),
          const SizedBox(height: Espacements.s),
        ],
      ),
    );
  }
}

class _OngletBoutiques extends ConsumerStatefulWidget {
  const _OngletBoutiques({required this.q});

  final String? q;

  @override
  ConsumerState<_OngletBoutiques> createState() => _OngletBoutiquesState();
}

class _OngletBoutiquesState extends ConsumerState<_OngletBoutiques>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final depot = ref.watch(boutiquesRepositoryProvider);
    return ListePaginee<Boutique>(
      key: ValueKey('boutiques-${widget.q}'),
      charger: (page) => depot.rechercher(widget.q, page),
      vide: EtatVide(icone: IconesDropp.shopOff, titre: l10n.boutiquesVide),
      elementBuilder: (context, b, _) => TuileBoutique(
        boutiqueId: b.id,
        nom: b.nom,
        logoUrl: b.logoUrl,
        abonnes: b.abonnes,
        sousTitre: [?b.lieu, l10n.boutiqueAbonnes(b.abonnes)].join(' · '),
      ),
    );
  }
}
