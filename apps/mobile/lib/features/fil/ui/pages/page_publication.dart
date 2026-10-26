import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/image_reseau.dart';
import '../../../../shared/widgets/vue_erreur.dart';
import '../../../../utils/format.dart';
import '../../application/vues_publications.dart';
import '../../data/fil_repository.dart';
import '../../data/modeles_fil.dart';
import '../widgets/carte_publication.dart';
import '../widgets/medias_publication.dart';

final publicationProvider = FutureProvider.autoDispose
    .family<Publication, String>(
      (ref, id) => ref.watch(filRepositoryProvider).obtenir(id),
    );

/// Détail d'une publication : médias en grand (vidéo lisible), texte complet,
/// compteurs et produits liés.
class PagePublication extends ConsumerStatefulWidget {
  const PagePublication({super.key, required this.id, this.initiale});

  final String id;

  /// Publication venue du fil : affichée tout de suite, puis rafraîchie.
  final Publication? initiale;

  @override
  ConsumerState<PagePublication> createState() => _PagePublicationState();
}

class _PagePublicationState extends ConsumerState<PagePublication> {
  @override
  void initState() {
    super.initState();
    // Ouverte par un lien partagé, elle n'est pas passée par le fil.
    unawaited(ref.read(vuesPublicationsProvider).signaler(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final etat = ref.watch(publicationProvider(widget.id));
    final publication = etat.value ?? widget.initiale;

    final Widget corps;
    if (publication != null) {
      corps = _Detail(publication: publication);
    } else if (etat.hasError) {
      corps = Center(
        child: Padding(
          padding: const EdgeInsets.all(Espacements.xl),
          child: VueErreur(
            erreur: ApiException.depuis(etat.error!),
            reessayer: () => ref.invalidate(publicationProvider(widget.id)),
          ),
        ),
      );
    } else {
      corps = const SingleChildScrollView(child: SqueletteFil());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.publicationTitre)),
      body: corps,
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = publication;
    final ratio = p.medias.isEmpty ? null : p.medias.first.ratio;

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + Espacements.xl,
      ),
      children: [
        EntetePublication(publication: p),
        MediaAimable(
          publication: p,
          child: MediasPublication(
            medias: p.medias,
            // Format d'origine, borné entre le portrait 4:5 et le paysage
            // 1,91:1.
            ratio: (ratio ?? 4 / 5).clamp(0.8, 1.91),
            lecture: true,
          ),
        ),
        ActionsPublication(publication: p),
        if (p.contenu != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espacements.m),
            child: Text(p.contenu!, style: theme.textTheme.bodyMedium),
          ),
        if (p.produits.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacements.m,
              Espacements.xl,
              Espacements.m,
              Espacements.s,
            ),
            child: Text(
              l10n.publicationProduits,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: Typographie.titre,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final produit in p.produits)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacements.m,
                0,
                Espacements.m,
                Espacements.s,
              ),
              child: _TuileProduit(produit: produit),
            ),
        ],
      ],
    );
  }
}

/// Produit lié : ouvre sa fiche.
class _TuileProduit extends StatelessWidget {
  const _TuileProduit({required this.produit});

  final ProduitLie produit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final image = produit.imageUrl;
    return Material(
      color: schema.surface,
      borderRadius: Rayons.borduresCarte,
      child: InkWell(
        borderRadius: Rayons.borduresCarte,
        onTap: () => unawaited(context.push<void>(Routes.produit(produit.id))),
        child: _contenu(theme, schema, image),
      ),
    );
  }

  Widget _contenu(ThemeData theme, ColorScheme schema, String? image) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: Rayons.borduresCarte,
        border: Border.all(color: schema.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.square(
              dimension: 64,
              child: image == null
                  ? ColoredBox(
                      color: schema.surfaceContainerHighest,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: schema.onSurfaceVariant,
                      ),
                    )
                  : ImageReseau(url: image),
            ),
          ),
          const SizedBox(width: Espacements.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Espacements.xs),
                Text(
                  formaterPrix(produit.prix),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: Typographie.titre,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
