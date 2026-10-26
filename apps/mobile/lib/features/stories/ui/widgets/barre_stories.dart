import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../application/barre_stories.dart';
import '../../data/modeles_stories.dart';

/// Rangée de stories en haut du fil. Disparaît s'il n'y en a aucune ou si le
/// chargement échoue : elle ne doit jamais gêner la lecture du fil.
class BarreStories extends ConsumerWidget {
  const BarreStories({super.key});

  static const _hauteur = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(barreStoriesProvider);
    return switch (etat) {
      AsyncData(:final value) when value.isNotEmpty => _Rangee(groupes: value),
      AsyncLoading() when !etat.hasValue => const _RangeeSquelette(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Rangee extends StatelessWidget {
  const _Rangee({required this.groupes});

  final List<GroupeStories> groupes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BarreStories._hauteur,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Espacements.m,
          vertical: Espacements.xs,
        ),
        itemCount: groupes.length,
        separatorBuilder: (_, _) => const SizedBox(width: Espacements.s),
        itemBuilder: (context, i) => _BulleStory(
          groupe: groupes[i],
          surTouche: () =>
              unawaited(context.push<void>(Routes.stories, extra: i)),
        ),
      ),
    );
  }
}

class _BulleStory extends StatelessWidget {
  const _BulleStory({required this.groupe, required this.surTouche});

  final GroupeStories groupe;
  final VoidCallback surTouche;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final nom = groupe.boutique.nom;
    final nonVue = !groupe.toutesVues;

    return Semantics(
      button: true,
      label: nonVue ? l10n.storyNouvelle(nom) : l10n.storyDe(nom),
      excludeSemantics: true,
      child: InkWell(
        onTap: surTouche,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              AnneauStory(
                nonVue: nonVue,
                child: AvatarBoutique(nom: nom, taille: 52),
              ),
              const SizedBox(height: Espacements.xs),
              Text(
                nom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: nonVue ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anneau dégradé hibiscus → kola si une story n'a pas été vue, gris sinon.
class AnneauStory extends StatelessWidget {
  const AnneauStory({super.key, required this.nonVue, required this.child});

  final bool nonVue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nonVue ? null : theme.colorScheme.outline,
        gradient: nonVue
            ? const SweepGradient(
                startAngle: 3.5,
                endAngle: 3.5 + 6.2832,
                colors: [Couleurs.hibiscus, Couleurs.kola, Couleurs.hibiscus],
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.scaffoldBackgroundColor,
        ),
        child: child,
      ),
    );
  }
}

class _RangeeSquelette extends StatelessWidget {
  const _RangeeSquelette();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BarreStories._hauteur,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Espacements.m,
          vertical: Espacements.xs,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: Espacements.s),
        itemBuilder: (_, _) => const SizedBox(
          width: 66,
          child: Column(
            children: [
              Squelette(largeur: 62, hauteur: 62, cercle: true),
              SizedBox(height: Espacements.s),
              Squelette(largeur: 40, hauteur: 8),
            ],
          ),
        ),
      ),
    );
  }
}
