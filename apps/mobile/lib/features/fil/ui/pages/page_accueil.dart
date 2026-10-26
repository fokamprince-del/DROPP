import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/etat_vide.dart';
import '../../../../shared/widgets/liste_paginee.dart';
import '../../../../shared/widgets/logo_dropp.dart';
import '../../../stories/application/barre_stories.dart';
import '../../../stories/ui/widgets/barre_stories.dart';
import '../../data/fil_repository.dart';
import '../../data/modeles_fil.dart';
import '../widgets/carte_publication.dart';

/// Onglet Accueil : stories en haut, puis le fil « Pour toi » (public) ou
/// « Abonnements » (boutiques suivies).
class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

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
                  0,
                ),
                child: Row(
                  children: [
                    Semantics(
                      header: true,
                      child: LogoDropp(
                        taille: 26,
                        anime: false,
                        couleur: schema.onSurface,
                      ),
                    ),
                  ],
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
                  Tab(text: l10n.filPourToi),
                  Tab(text: l10n.filAbonnements),
                ],
              ),
              const Expanded(
                child: TabBarView(children: [_FilPourToi(), _FilAbonnements()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recharge la barre de stories avec le fil ; une erreur ne bloque pas le
/// rafraîchissement du fil.
Future<void> _rafraichirStories(WidgetRef ref) async {
  try {
    ref.invalidate(barreStoriesProvider);
    await ref.read(barreStoriesProvider.future);
  } on ApiException {
    // La barre se masque d'elle-même.
  }
}

class _FilPourToi extends ConsumerStatefulWidget {
  const _FilPourToi();

  @override
  ConsumerState<_FilPourToi> createState() => _FilPourToiState();
}

class _FilPourToiState extends ConsumerState<_FilPourToi>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final depot = ref.watch(filRepositoryProvider);
    // Nouvelle session : on repart de zéro.
    final utilisateur = ref.watch(utilisateurConnecteProvider);

    return ListePaginee<Publication>(
      key: ValueKey('pour-toi-${utilisateur?.id}'),
      charger: depot.pourToi,
      enTete: const BarreStories(),
      auRafraichir: () => _rafraichirStories(ref),
      separateur: const SeparateurFil(),
      squelette: const SqueletteFil(),
      vide: EtatVide(
        icone: Icons.dynamic_feed_outlined,
        titre: l10n.filPourToiVide,
      ),
      elementBuilder: (context, publication, _) =>
          CartePublication(publication: publication),
    );
  }
}

class _FilAbonnements extends ConsumerStatefulWidget {
  const _FilAbonnements();

  @override
  ConsumerState<_FilAbonnements> createState() => _FilAbonnementsState();
}

class _FilAbonnementsState extends ConsumerState<_FilAbonnements>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final utilisateur = ref.watch(utilisateurConnecteProvider);

    if (utilisateur == null) {
      return ListView(
        children: [
          EtatVide(
            icone: Icons.storefront_outlined,
            titre: l10n.filConnexionTitre,
            texte: l10n.filConnexionTexte,
            action: FilledButton(
              onPressed: () => unawaited(context.push<void>(Routes.connexion)),
              child: Text(l10n.connexionBouton),
            ),
          ),
        ],
      );
    }

    return ListePaginee<Publication>(
      key: ValueKey('abonnements-${utilisateur.id}'),
      charger: ref.watch(filRepositoryProvider).abonnements,
      enTete: const BarreStories(),
      auRafraichir: () => _rafraichirStories(ref),
      separateur: const SeparateurFil(),
      squelette: const SqueletteFil(),
      vide: EtatVide(
        icone: Icons.storefront_outlined,
        titre: l10n.filAbonnementsVideTitre,
        texte: l10n.filAbonnementsVideTexte,
        action: FilledButton(
          onPressed: () => context.go(Routes.recherche),
          child: Text(l10n.filDecouvrirBoutiques),
        ),
      ),
      elementBuilder: (context, publication, _) =>
          CartePublication(publication: publication),
    );
  }
}
