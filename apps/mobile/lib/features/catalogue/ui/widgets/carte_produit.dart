import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/image_reseau.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../../../utils/format.dart';
import '../../../interactions/application/interactions.dart';
import '../../../interactions/ui/actions_connectees.dart';
import '../../data/modeles_catalogue.dart';

const _rayonImage = 14.0;

/// Grille du catalogue : 2 colonnes sur téléphone, 3 au-delà de 600 dp.
/// La hauteur suit la largeur de l'image carrée et la taille du texte.
SliverGridDelegate grilleProduits(BuildContext context, double largeur) {
  final colonnes = largeur >= 600 ? 3 : 2;
  const marge = Espacements.m;
  const espace = 10.0;
  final carre = (largeur - 2 * marge - (colonnes - 1) * espace) / colonnes;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: colonnes,
    crossAxisSpacing: espace,
    mainAxisSpacing: Espacements.l,
    mainAxisExtent: carre + MediaQuery.textScalerOf(context).scale(62),
  );
}

/// Image carrée (cœur favori dessus), nom sur deux lignes et prix.
class CarteProduit extends ConsumerWidget {
  const CarteProduit({super.key, required this.produit});

  final ProduitResume produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final image = produit.imageUrl;
    final favori = ref.watch(
      interactionsProvider.select(
        (e) => e.favorisProduits.contains(produit.id),
      ),
    );

    return Semantics(
      button: true,
      label: '${produit.nom}, ${formaterPrix(produit.prixMin)}',
      child: InkWell(
        onTap: () => unawaited(context.push<void>(Routes.produit(produit.id))),
        borderRadius: BorderRadius.circular(_rayonImage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_rayonImage),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image == null)
                      ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: FaIcon(
                          IconesDropp.shoppingBasket,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ImageReseau(url: image),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: BoutonFavoriProduit(
                        produitId: produit.id,
                        favori: favori,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Text(
                produit.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(height: 1.25),
              ),
            ),
            ExcludeSemantics(
              child: Text(
                formaterPrix(produit.prixMin),
                maxLines: 1,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: Typographie.titre,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cœur rond sur fond blanc, posé sur une image.
class BoutonFavoriProduit extends ConsumerWidget {
  const BoutonFavoriProduit({
    super.key,
    required this.produitId,
    required this.favori,
  });

  final String produitId;
  final bool favori;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      toggled: favori,
      label: favori ? l10n.favoriRetirer : l10n.favoriAjouter,
      excludeSemantics: true,
      child: InkResponse(
        radius: 22,
        onTap: () => actionConnectee(
          context,
          ref,
          () => ref
              .read(interactionsProvider.notifier)
              .basculerFavoriProduit(produitId),
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                favori ? IconesDropp.solidFavorite : IconesDropp.favorite,
                size: 18,
                color: favori ? Couleurs.hibiscus : Couleurs.encre,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quatre cartes fantômes pendant le premier chargement.
class SqueletteGrille extends StatelessWidget {
  const SqueletteGrille({super.key});

  @override
  Widget build(BuildContext context) {
    Widget carte() => const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1, child: Squelette(rayon: _rayonImage)),
          SizedBox(height: 8),
          Squelette(hauteur: 10),
          SizedBox(height: 6),
          Squelette(largeur: 70, hauteur: 12),
        ],
      ),
    );
    Widget rangee() =>
        Row(children: [carte(), const SizedBox(width: 10), carte()]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espacements.m),
      child: Column(
        children: [
          rangee(),
          const SizedBox(height: Espacements.l),
          rangee(),
        ],
      ),
    );
  }
}
