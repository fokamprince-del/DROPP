import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../utils/format.dart';
import '../application/interactions.dart';
import '../data/favoris.dart';
import 'actions_connectees.dart';

/// Mes favoris : produits et publications enregistrés. Retirer un favori
/// l'enlève de la liste tout de suite.
class PageFavoris extends ConsumerStatefulWidget {
  const PageFavoris({super.key});

  @override
  ConsumerState<PageFavoris> createState() => _PageFavorisState();
}

class _PageFavorisState extends ConsumerState<PageFavoris> {
  final _produits = GlobalKey<ListePagineeState<FavoriProduit>>();
  final _publications = GlobalKey<ListePagineeState<FavoriPublication>>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final depot = ref.watch(favorisRepositoryProvider);
    final notifier = ref.read(interactionsProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.favorisTitre),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.decouvrirProduits),
              Tab(text: l10n.boutiquePublications),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListePaginee<FavoriProduit>(
              key: _produits,
              charger: depot.produits,
              separateur: const Divider(height: 1),
              vide: EtatVide(
                icone: Icons.favorite_border,
                titre: l10n.favorisProduitsVide,
              ),
              elementBuilder: (context, f, _) => ListTile(
                onTap: () =>
                    unawaited(context.push<void>(Routes.produit(f.produitId))),
                title: Text(f.nom),
                subtitle: Text(
                  [
                    formaterPrix(f.prix),
                    ?f.boutiqueNom,
                    if (!f.enVente) l10n.favoriPlusEnVente,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  tooltip: l10n.favoriRetirer,
                  icon: Icon(
                    Icons.favorite,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () => actionConnectee(context, ref, () async {
                    await notifier.basculerFavoriProduit(
                      f.produitId,
                      estFavori: true,
                    );
                    _produits.currentState?.retirer(
                      (x) => x.produitId == f.produitId,
                    );
                  }),
                ),
              ),
            ),
            ListePaginee<FavoriPublication>(
              key: _publications,
              charger: depot.publications,
              separateur: const Divider(height: 1),
              vide: EtatVide(
                icone: Icons.bookmark_border,
                titre: l10n.favorisPublicationsVide,
              ),
              elementBuilder: (context, f, _) => ListTile(
                onTap: () => unawaited(
                  context.push<void>(Routes.publication(f.publicationId)),
                ),
                title: Text(f.boutiqueNom ?? '—'),
                subtitle: Text(
                  f.contenu ?? tempsRelatif(l10n, f.dateCreation),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: l10n.favoriRetirer,
                  icon: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                  onPressed: () => actionConnectee(context, ref, () async {
                    await notifier.basculerFavoriPublication(
                      f.publicationId,
                      estFavori: true,
                    );
                    _publications.currentState?.retirer(
                      (x) => x.publicationId == f.publicationId,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
