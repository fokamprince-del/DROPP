import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/rayons.dart';
import '../../../shared/theme/typographie.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../../utils/format.dart';
import '../../commandes/data/commandes.dart';
import '../application/panier.dart';
import '../data/panier.dart';

/// Onglet Panier : articles par boutique, quantités, total, « Commander ».
class PagePanier extends ConsumerWidget {
  const PagePanier({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final etat = ref.watch(panierProvider);
    final panier = etat.value;

    final Widget corps;
    if (panier == null && etat.hasError) {
      corps = Center(
        child: VueErreur(
          erreur: ApiException.depuis(etat.error!),
          reessayer: () => ref.invalidate(panierProvider),
        ),
      );
    } else if (panier == null) {
      corps = const _SquelettePanier();
    } else if (panier.articles.isEmpty) {
      corps = ListView(
        children: [
          EtatVide(
            icone: Icons.shopping_bag_outlined,
            titre: l10n.panierVide,
            texte: l10n.panierVideTexte,
            action: FilledButton(
              onPressed: () => context.go(Routes.recherche),
              child: Text(l10n.navDecouvrir),
            ),
          ),
        ],
      );
    } else {
      corps = _Contenu(panier: panier);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacements.l,
                Espacements.s,
                Espacements.l,
                Espacements.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.navPanier,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: Typographie.titre,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (panier != null && panier.articles.isNotEmpty)
                    Text(
                      l10n.panierNombreArticles(panier.nombreArticles),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(panierProvider);
                  await ref
                      .read(panierProvider.future)
                      .catchError((Object _) => Panier.vide);
                },
                child: corps,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenu extends ConsumerStatefulWidget {
  const _Contenu({required this.panier});

  final Panier panier;

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  bool _commande = false;

  /// Lance une action du panier ; l'erreur s'affiche en bas de l'écran.
  Future<void> _action(Future<void> Function() action) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    try {
      await action();
    } on ApiException catch (e) {
      messager.showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {
                TypeErreurApi.requeteInvalide: l10n.panierStockInsuffisant,
              },
            ),
          ),
        ),
      );
    }
  }

  Future<void> _commander() async {
    final l10n = context.l10n;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commanderTitre),
        content: Text(l10n.commanderTexte(delaiPaiementCommande.inMinutes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commanderConfirmer),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final routeur = GoRouter.of(context);
    final messager = ScaffoldMessenger.of(context);
    setState(() => _commande = true);
    try {
      final commande = await ref.read(commandesRepositoryProvider).passer();
      ref.read(panierProvider.notifier).recharger();
      unawaited(
        routeur.push<void>(Routes.commande(commande.id), extra: commande),
      );
    } on ApiException catch (e) {
      // Panier modifié entre-temps (stock, produit retiré) : on le relit.
      ref.read(panierProvider.notifier).recharger();
      messager.showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {
                TypeErreurApi.requeteInvalide: l10n.commanderPanierChange,
              },
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _commande = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final panier = widget.panier;
    final notifier = ref.read(panierProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Espacements.l,
              0,
              Espacements.l,
              Espacements.l,
            ),
            children: [
              for (final articles in panier.parBoutique.values) ...[
                _EnTeteBoutique(article: articles.first),
                for (final article in articles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espacements.s),
                    child: _CarteArticle(
                      article: article,
                      surQuantite: (q) => _action(
                        () => notifier.modifierQuantite(article.id, q),
                      ),
                      surSupprimer: () =>
                          _action(() => notifier.supprimer(article.id)),
                    ),
                  ),
                const SizedBox(height: Espacements.s),
              ],
              _Recapitulatif(panier: panier),
              const SizedBox(height: Espacements.m),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: context.couleursMetier.succes,
                  ),
                  const SizedBox(width: Espacements.s),
                  Expanded(
                    child: Text(
                      l10n.panierProtection,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacements.l,
              Espacements.s,
              Espacements.l,
              Espacements.m,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!panier.commandable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espacements.s),
                    child: Text(
                      l10n.panierNonCommandable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.couleursMetier.erreur,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: panier.commandable && !_commande
                      ? _commander
                      : null,
                  child: _commande
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.panierCommander(formaterPrix(panier.sousTotal)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EnTeteBoutique extends StatelessWidget {
  const _EnTeteBoutique({required this.article});

  final ArticlePanier article;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          unawaited(context.push<void>(Routes.boutique(article.boutiqueId))),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacements.s),
        child: Row(
          children: [
            AvatarBoutique(nom: article.boutiqueNom, taille: 24),
            const SizedBox(width: Espacements.s),
            Expanded(
              child: Text(
                article.boutiqueNom,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteArticle extends StatelessWidget {
  const _CarteArticle({
    required this.article,
    required this.surQuantite,
    required this.surSupprimer,
  });

  final ArticlePanier article;
  final ValueChanged<int> surQuantite;
  final VoidCallback surSupprimer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final metier = context.couleursMetier;
    final a = article;
    final variante = a.descriptionVariante;

    String? alerte;
    if (!a.disponible) {
      alerte = a.stockDisponible > 0 && a.stockDisponible < a.quantite
          ? l10n.panierStockRestant(a.stockDisponible)
          : l10n.panierIndisponible;
    } else if (a.prixModifie) {
      alerte = l10n.panierPrixModifie;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: schema.surface,
        borderRadius: Rayons.borduresCarte,
        border: Border.all(
          color: a.disponible ? schema.outline : metier.erreur,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                unawaited(context.push<void>(Routes.produit(a.produitId))),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: schema.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: schema.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Espacements.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.produitNom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.supprimer,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: surSupprimer,
                    ),
                  ],
                ),
                if (variante != null)
                  Text(
                    variante,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: schema.onSurfaceVariant,
                    ),
                  ),
                if (alerte != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      alerte,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: a.disponible ? metier.attente : metier.erreur,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: Espacements.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formaterPrix(a.prixUnitaire),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: Typographie.titre,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _Quantite(
                      valeur: a.quantite,
                      // Au-delà du stock, l'article deviendrait indisponible.
                      maximum: a.stockDisponible > 0
                          ? a.stockDisponible
                          : a.quantite,
                      surChangement: surQuantite,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Quantite extends StatelessWidget {
  const _Quantite({
    required this.valeur,
    required this.maximum,
    required this.surChangement,
  });

  final int valeur;
  final int maximum;
  final ValueChanged<int> surChangement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schema = Theme.of(context).colorScheme;
    return Semantics(
      label: l10n.panierQuantite(valeur),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: schema.outline, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.panierMoins,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, size: 18),
              onPressed: valeur > 1 ? () => surChangement(valeur - 1) : null,
            ),
            ExcludeSemantics(
              child: Text(
                '$valeur',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: l10n.panierPlus,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 18),
              onPressed: valeur < maximum
                  ? () => surChangement(valeur + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Recapitulatif extends StatelessWidget {
  const _Recapitulatif({required this.panier});

  final Panier panier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    Widget ligne(String libelle, String valeur, {bool total = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text(
                libelle,
                style: total
                    ? theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )
                    : theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: Espacements.m),
              // La valeur passe à la ligne sur un écran étroit (360 dp).
              Expanded(
                child: Text(
                  valeur,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: total ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(Espacements.m),
      decoration: BoxDecoration(
        color: schema.surface,
        borderRadius: Rayons.borduresCarte,
        border: Border.all(color: schema.outline),
      ),
      child: Column(
        children: [
          ligne(l10n.panierSousTotal, formaterPrix(panier.sousTotal)),
          ligne(l10n.panierLivraison, l10n.panierLivraisonPlusTard),
          const Divider(),
          ligne(l10n.panierTotal, formaterPrix(panier.sousTotal), total: true),
        ],
      ),
    );
  }
}

class _SquelettePanier extends StatelessWidget {
  const _SquelettePanier();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Espacements.l),
      children: [
        for (var i = 0; i < 3; i++) ...[
          const Squelette(hauteur: 86, rayon: 16),
          const SizedBox(height: Espacements.s),
        ],
      ],
    );
  }
}
