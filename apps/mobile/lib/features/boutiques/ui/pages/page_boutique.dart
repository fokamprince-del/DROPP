import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/typographie.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/etat_vide.dart';
import '../../../../shared/widgets/image_reseau.dart';
import '../../../../shared/widgets/liste_paginee.dart';
import '../../../../shared/widgets/motif_ndop.dart';
import '../../../../shared/widgets/squelette.dart';
import '../../../../shared/widgets/vue_erreur.dart';
import '../../../../utils/format.dart';
import '../../../catalogue/data/catalogue_repository.dart';
import '../../../catalogue/data/modeles_catalogue.dart';
import '../../../catalogue/ui/widgets/carte_produit.dart';
import '../../../fil/data/fil_repository.dart';
import '../../../fil/data/modeles_fil.dart';
import '../../../fil/ui/widgets/carte_publication.dart';
import '../../../interactions/application/interactions.dart';
import '../../../interactions/ui/actions_connectees.dart';
import '../../../interactions/ui/bouton_suivre.dart';
import '../../../messagerie/ui/page_discussion.dart';
import '../../../moderation/data/moderation.dart';
import '../../../moderation/ui/moderation_ui.dart';
import '../../application/boutiques_providers.dart';
import '../../data/modeles_boutiques.dart';

/// Page d'une boutique : bannière, logo, statistiques, Suivre, puis ses
/// produits et ses publications. L'en-tête se replie au défilement.
class PageBoutique extends ConsumerWidget {
  const PageBoutique({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // À chaque chargement de la page, son état d'abonnement fait foi s'il
    // diffère du cache local (abonnement pris sur un autre appareil).
    ref.listen(boutiqueProvider(id), (_, suivant) {
      if (suivant.value case final b?) {
        ref
            .read(interactionsProvider.notifier)
            .synchroniserAbonnement(b.id, suivie: b.estAbonne);
      }
    });
    final etat = ref.watch(boutiqueProvider(id));
    final boutique = etat.value;

    if (boutique == null) {
      return Scaffold(
        appBar: AppBar(),
        body: etat.hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(Espacements.xl),
                  child: VueErreur(
                    erreur: ApiException.depuis(etat.error!),
                    reessayer: () => ref.invalidate(boutiqueProvider(id)),
                  ),
                ),
              )
            : const _SqueletteBoutique(),
      );
    }

    return _Contenu(boutique: boutique);
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.boutique});

  final Boutique boutique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final b = boutique;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _EnTete(boutique: b)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _OngletsFixes(
                couleur: theme.scaffoldBackgroundColor,
                onglets: TabBar(
                  labelColor: schema.onSurface,
                  unselectedLabelColor: schema.onSurfaceVariant,
                  labelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(color: schema.secondary, width: 3),
                  ),
                  dividerColor: schema.outline,
                  tabs: [
                    Tab(text: l10n.decouvrirProduits),
                    Tab(text: l10n.boutiquePublications),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ProduitsBoutique(boutiqueId: b.id),
              _PublicationsBoutique(boutiqueId: b.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnTete extends ConsumerWidget {
  const _EnTete({required this.boutique});

  final Boutique boutique;

  static const _hauteurBanniere = 140.0;
  static const _tailleLogo = 80.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final b = boutique;
    final abonnes = ref.watch(
      interactionsProvider.select((e) => e.abonnes(b.id, b.abonnes)),
    );
    final resume = ref.watch(resumeAvisBoutiqueProvider(b.id)).value;
    final banniere = b.banniereUrl;
    final moyenne = resume?.moyenne;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _hauteurBanniere + _tailleLogo / 2,
          child: Stack(
            children: [
              SizedBox(
                height: _hauteurBanniere,
                width: double.infinity,
                child: banniere != null
                    ? ImageReseau(url: banniere)
                    : const _BanniereNdop(),
              ),
              Positioned(
                left: Espacements.l,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: AvatarBoutique(
                    nom: b.nom,
                    logoUrl: b.logoUrl,
                    taille: _tailleLogo,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Espacements.xs),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: Couleurs.encre,
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
              if (!b.estMaBoutique)
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(Espacements.xs),
                      child: PopupMenuButton<bool>(
                        tooltip: l10n.plusDOptions,
                        icon: const CircleAvatar(
                          backgroundColor: Color(0xEBFFFFFF),
                          foregroundColor: Couleurs.encre,
                          child: Icon(Icons.more_vert),
                        ),
                        onSelected: (signaler) => unawaited(
                          signaler
                              ? ouvrirSignalement(
                                  context,
                                  ref,
                                  typeCible: TypeCible.boutique,
                                  cibleId: b.id,
                                )
                              : confirmerBlocage(
                                  context,
                                  ref,
                                  utilisateurId: b.id,
                                  nom: b.nom,
                                ),
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: true,
                            child: Text(l10n.signaler),
                          ),
                          PopupMenuItem(
                            value: false,
                            child: Text(l10n.bloquer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Espacements.l,
            Espacements.s,
            Espacements.l,
            Espacements.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                b.nom,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: Typographie.titre,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (b.lieu != null || b.description != null)
                Text(
                  [?b.lieu, ?b.description].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: schema.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: Espacements.m),
              Row(
                children: [
                  _Statistique(
                    valeur: formaterCompteur(abonnes, l10n.localeName),
                    libelle: l10n.boutiqueAbonnesLibelle(abonnes),
                  ),
                  _Statistique(
                    valeur: formaterCompteur(b.produits ?? 0, l10n.localeName),
                    libelle: l10n.boutiqueProduitsLibelle(b.produits ?? 0),
                  ),
                  _Statistique(
                    valeur: moyenne == null
                        ? '—'
                        : '${formaterNote(moyenne, l10n.localeName)} ★',
                    libelle: l10n.avisNombre(resume?.total ?? 0),
                  ),
                ],
              ),
              if (!b.estMaBoutique) ...[
                const SizedBox(height: Espacements.m),
                Row(
                  children: [
                    Expanded(
                      child: BoutonSuivre(
                        boutiqueId: b.id,
                        abonnesRecus: b.abonnes,
                        largeurPleine: true,
                      ),
                    ),
                    const SizedBox(width: Espacements.s),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => actionConnectee(
                          context,
                          ref,
                          () => ouvrirDiscussionAvec(context, ref, b.id),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(l10n.boutiqueMessage),
                      ),
                    ),
                  ],
                ),
              ],
              if (b.biographie != null) ...[
                const SizedBox(height: Espacements.m),
                Text(b.biographie!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Statistique extends StatelessWidget {
  const _Statistique({required this.valeur, required this.libelle});

  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '$valeur $libelle',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              valeur,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: Typographie.titre,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              libelle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière par défaut : dégradé indigo → hibiscus, bande ndop en bas.
class _BanniereNdop extends StatelessWidget {
  const _BanniereNdop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Couleurs.indigo, Couleurs.hibiscus],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: 0.55,
          child: MotifNdop(
            hauteur: 12,
            tailleCase: 12,
            couleurFonce: Couleurs.blanc,
            couleurClair: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _OngletsFixes extends SliverPersistentHeaderDelegate {
  const _OngletsFixes({required this.onglets, required this.couleur});

  final TabBar onglets;
  final Color couleur;

  @override
  double get minExtent => onglets.preferredSize.height;

  @override
  double get maxExtent => onglets.preferredSize.height;

  @override
  Widget build(BuildContext context, double decalage, bool chevauche) =>
      ColoredBox(color: couleur, child: onglets);

  @override
  bool shouldRebuild(_OngletsFixes ancien) =>
      ancien.onglets != onglets || ancien.couleur != couleur;
}

class _ProduitsBoutique extends ConsumerWidget {
  const _ProduitsBoutique({required this.boutiqueId});

  final String boutiqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final depot = ref.watch(catalogueRepositoryProvider);
    return LayoutBuilder(
      builder: (context, contraintes) => ListePaginee<ProduitResume>(
        defilementPrincipal: true,
        charger: (page) => depot.produits(
          const FiltresCatalogue(),
          page,
          boutiqueId: boutiqueId,
        ),
        grille: grilleProduits(context, contraintes.maxWidth),
        padding: const EdgeInsets.all(Espacements.m),
        squelette: const Padding(
          padding: EdgeInsets.only(top: Espacements.m),
          child: SqueletteGrille(),
        ),
        vide: EtatVide(
          icone: Icons.shopping_bag_outlined,
          titre: l10n.boutiqueAucunProduit,
        ),
        elementBuilder: (context, produit, _) => CarteProduit(produit: produit),
      ),
    );
  }
}

class _PublicationsBoutique extends ConsumerWidget {
  const _PublicationsBoutique({required this.boutiqueId});

  final String boutiqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final depot = ref.watch(filRepositoryProvider);
    return ListePaginee<Publication>(
      defilementPrincipal: true,
      charger: (page) => depot.deBoutique(boutiqueId, page),
      separateur: const SeparateurFil(),
      squelette: const SqueletteFil(),
      vide: EtatVide(
        icone: Icons.dynamic_feed_outlined,
        titre: l10n.boutiqueAucunePublication,
      ),
      elementBuilder: (context, publication, _) =>
          CartePublication(publication: publication),
    );
  }
}

class _SqueletteBoutique extends StatelessWidget {
  const _SqueletteBoutique();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Squelette(hauteur: 120, rayon: 0),
        Padding(
          padding: EdgeInsets.all(Espacements.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Squelette(largeur: 80, hauteur: 80, cercle: true),
              SizedBox(height: Espacements.m),
              Squelette(largeur: 180, hauteur: 16),
              SizedBox(height: Espacements.s),
              Squelette(largeur: 120, hauteur: 10),
            ],
          ),
        ),
      ],
    );
  }
}
