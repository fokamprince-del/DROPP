import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/modeles/contenu.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../../../utils/format.dart';
import '../../application/vues_publications.dart';
import '../../data/modeles_fil.dart';
import 'medias_publication.dart';

/// Une vue compte quand 60 % de la carte est à l'écran, ou quand elle occupe
/// la moitié de l'écran (carte plus haute que l'écran).
bool estVue(VisibilityInfo info, double hauteurEcran) =>
    info.visibleFraction >= 0.6 ||
    info.visibleBounds.height >= hauteurEcran * 0.5;

/// Publication dans le fil. Toucher le média ou le texte ouvre le détail.
class CartePublication extends ConsumerWidget {
  const CartePublication({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = publication;
    final theme = Theme.of(context);
    final vues = ref.read(vuesPublicationsProvider);
    final hauteurEcran = MediaQuery.sizeOf(context).height;
    void ouvrir() =>
        unawaited(context.push<void>(Routes.publication(p.id), extra: p));

    return VisibilityDetector(
      key: ValueKey('publication-${p.id}'),
      onVisibilityChanged: (info) {
        if (estVue(info, hauteurEcran)) unawaited(vues.signaler(p.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntetePublication(publication: p),
          Semantics(
            button: true,
            label: context.l10n.publicationOuvrir(p.boutique.nom),
            child: GestureDetector(
              onTap: ouvrir,
              child: MediasPublication(
                medias: p.medias,
                produit: p.produits.isEmpty ? null : p.produits.first,
              ),
            ),
          ),
          CompteursPublication(publication: p),
          if (p.contenu != null)
            InkWell(
              onTap: ouvrir,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espacements.m,
                  0,
                  Espacements.m,
                  Espacements.xs,
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${p.boutique.nom} ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: p.contenu),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: Espacements.m),
        ],
      ),
    );
  }
}

/// Boutique, ancienneté, vues, et cadenas si réservée aux abonnés.
class EntetePublication extends StatelessWidget {
  const EntetePublication({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = publication;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacements.m,
        vertical: 10,
      ),
      child: Row(
        children: [
          AvatarBoutique(nom: p.boutique.nom),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.boutique.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${tempsRelatif(l10n, p.dateCreation)} · '
                  '${l10n.publicationVues(p.nombreVues)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (p.visibilite == Visibilite.abonnes)
            Tooltip(
              message: l10n.publicationAbonnes,
              child: Icon(
                Icons.lock_outline,
                size: 18,
                semanticLabel: l10n.publicationAbonnes,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// J'aime et commentaires (lecture seule pour l'instant).
class CompteursPublication extends StatelessWidget {
  const CompteursPublication({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget compteur(IconData icone, int valeur, String libelle) => Semantics(
      label: libelle,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 22),
          const SizedBox(width: 4),
          Text(formaterCompteur(valeur, l10n.localeName), style: style),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacements.m,
        Espacements.s,
        Espacements.m,
        Espacements.s,
      ),
      child: Row(
        children: [
          compteur(
            Icons.favorite_border,
            publication.likes,
            l10n.publicationLikes(publication.likes),
          ),
          const SizedBox(width: Espacements.l),
          compteur(
            Icons.chat_bubble_outline,
            publication.commentaires,
            l10n.publicationCommentaires(publication.commentaires),
          ),
        ],
      ),
    );
  }
}

/// Bande de 8 px entre deux publications, comme dans la maquette.
class SeparateurFil extends StatelessWidget {
  const SeparateurFil({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 8,
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}

/// Deux publications fantômes pendant le premier chargement.
class SqueletteFil extends StatelessWidget {
  const SqueletteFil({super.key});

  @override
  Widget build(BuildContext context) {
    Widget publication() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Espacements.m,
            vertical: 10,
          ),
          child: Row(
            children: [
              Squelette(largeur: 36, hauteur: 36, cercle: true),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Squelette(largeur: 140, hauteur: 10),
                    SizedBox(height: 6),
                    Squelette(largeur: 90, hauteur: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        const AspectRatio(aspectRatio: 4 / 5, child: Squelette(rayon: 0)),
        const SizedBox(height: Espacements.l),
      ],
    );

    return Column(children: [publication(), publication()]);
  }
}
