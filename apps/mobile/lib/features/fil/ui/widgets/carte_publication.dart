import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/modeles/contenu.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../../../utils/format.dart';
import '../../../commentaires/ui/feuille_commentaires.dart';
import '../../../interactions/application/interactions.dart';
import '../../../interactions/ui/actions_connectees.dart';
import '../../../interactions/ui/feuille_partage.dart';
import '../../../moderation/data/moderation.dart';
import '../../../moderation/ui/moderation_ui.dart';
import '../../application/vues_publications.dart';
import '../../data/modeles_fil.dart';
import 'medias_publication.dart';

/// Une vue compte quand 60 % de la carte est à l'écran, ou quand elle occupe
/// la moitié de l'écran (carte plus haute que l'écran).
bool estVue(VisibilityInfo info, double hauteurEcran) =>
    info.visibleFraction >= 0.6 ||
    info.visibleBounds.height >= hauteurEcran * 0.5;

/// Publication dans le fil. Toucher le média ou le texte ouvre le détail ;
/// un double appui sur le média l'aime.
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
            child: MediaAimable(
              publication: p,
              surAppui: ouvrir,
              child: MediasPublication(
                medias: p.medias,
                produit: p.produits.isEmpty ? null : p.produits.first,
              ),
            ),
          ),
          ActionsPublication(publication: p),
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

/// Média qui s'ouvre au toucher et s'aime au double appui, avec un cœur
/// qui apparaît puis s'efface.
class MediaAimable extends ConsumerStatefulWidget {
  const MediaAimable({
    super.key,
    required this.publication,
    required this.child,
    this.surAppui,
  });

  final Publication publication;
  final Widget child;
  final VoidCallback? surAppui;

  @override
  ConsumerState<MediaAimable> createState() => _MediaAimableState();
}

class _MediaAimableState extends ConsumerState<MediaAimable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coeur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  late final Animation<double> _echelle = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.15), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 30),
    TweenSequenceItem(tween: ConstantTween(1), weight: 40),
  ]).animate(_coeur);

  late final Animation<double> _opacite = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
  ]).animate(_coeur);

  @override
  void dispose() {
    _coeur.dispose();
    super.dispose();
  }

  void _doubleAppui() {
    final p = widget.publication;
    final etats = ref.read(interactionsProvider);
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(_coeur.forward(from: 0));
    }
    // Le double appui aime seulement : il ne retire jamais un j'aime.
    if (etats.likesPublications.contains(p.id)) return;
    unawaited(
      actionConnectee(
        context,
        ref,
        () => ref
            .read(interactionsProvider.notifier)
            .basculerLikePublication(
              p.id,
              etats.likesPublication(p.id, p.likes),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.surAppui,
      onDoubleTap: _doubleAppui,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          IgnorePointer(
            child: FadeTransition(
              opacity: _opacite,
              child: ScaleTransition(
                scale: _echelle,
                child: FaIcon(
                  IconesDropp.solidFavorite,
                  size: 96,
                  color: Theme.of(context).colorScheme.secondary,
                  shadows: const [
                    Shadow(blurRadius: 14, color: Color(0x59000000)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutique (vers sa page), ancienneté, vues, et cadenas si réservée aux
/// abonnés.
class EntetePublication extends ConsumerWidget {
  const EntetePublication({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = publication;
    final moi = ref.watch(utilisateurConnecteProvider)?.id;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacements.s,
        vertical: Espacements.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  unawaited(context.push<void>(Routes.boutique(p.boutique.id))),
              child: Padding(
                padding: const EdgeInsets.all(Espacements.xs),
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
                  ],
                ),
              ),
            ),
          ),
          if (moi != p.boutique.id)
            PopupMenuButton<void>(
              tooltip: l10n.plusDOptions,
              icon: const FaIcon(IconesDropp.ellips),
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: () => unawaited(
                    ouvrirSignalement(
                      context,
                      ref,
                      typeCible: TypeCible.publication,
                      cibleId: p.id,
                    ),
                  ),
                  child: Text(l10n.signaler),
                ),
              ],
            ),
          if (p.visibilite == Visibilite.abonnes)
            Padding(
              padding: const EdgeInsets.only(right: Espacements.xs),
              child: Tooltip(
                message: l10n.publicationAbonnes,
                child: FaIcon(
                  IconesDropp.userLock,
                  size: 18,
                  semanticLabel: l10n.publicationAbonnes,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// J'aime, commentaires, partage et favori, comme dans la maquette.
class ActionsPublication extends ConsumerWidget {
  const ActionsPublication({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schema = Theme.of(context).colorScheme;
    final p = publication;
    final etats = ref.watch(interactionsProvider);
    final aime = etats.likesPublications.contains(p.id);
    final favori = etats.favorisPublications.contains(p.id);
    final likes = etats.likesPublication(p.id, p.likes);
    final commentaires = etats.commentaires(p.id, p.commentaires);
    final notifier = ref.read(interactionsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espacements.xs),
      child: Row(
        children: [
          _BoutonAction(
            icone: aime ? IconesDropp.solidFavorite : IconesDropp.favorite,
            couleur: aime ? schema.secondary : null,
            valeur: likes,
            libelle: l10n.publicationLikes(likes),
            actif: aime,
            surAppui: () => actionConnectee(
              context,
              ref,
              () => notifier.basculerLikePublication(p.id, likes),
            ),
          ),
          _BoutonAction(
            icone: IconesDropp.commentaire,
            valeur: commentaires,
            libelle: l10n.publicationCommentaires(commentaires),
            surAppui: () => unawaited(ouvrirCommentaires(context, p)),
          ),
          _BoutonAction(
            icone: IconesDropp.share,
            libelle: l10n.partageTitre,
            surAppui: () => unawaited(ouvrirPartage(context, ref, p)),
          ),
          const Spacer(),
          _BoutonAction(
            icone: favori ? IconesDropp.solidBookmark : IconesDropp.bookmark,
            couleur: favori ? schema.primary : null,
            libelle: favori ? l10n.favoriRetirer : l10n.favoriAjouter,
            actif: favori,
            surAppui: () => actionConnectee(
              context,
              ref,
              () => notifier.basculerFavoriPublication(p.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.icone,
    required this.libelle,
    required this.surAppui,
    this.valeur,
    this.couleur,
    this.actif,
  });

  final FaIconData icone;
  final String libelle;
  final VoidCallback surAppui;

  /// Compteur affiché à côté de l'icône.
  final int? valeur;
  final Color? couleur;

  /// État d'un bouton bascule (j'aime, favori), pour les lecteurs d'écran.
  final bool? actif;

  @override
  Widget build(BuildContext context) {
    final valeur = this.valeur;
    return Semantics(
      button: true,
      toggled: actif,
      label: libelle,
      excludeSemantics: true,
      child: InkWell(
        onTap: surAppui,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espacements.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(icone, size: 24, color: couleur),
                if (valeur != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    formaterCompteur(valeur, context.l10n.localeName),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ),
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
    Widget publication() => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
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
        AspectRatio(aspectRatio: 4 / 5, child: Squelette(rayon: 0)),
        SizedBox(height: Espacements.l),
      ],
    );

    return Column(children: [publication(), publication()]);
  }
}
