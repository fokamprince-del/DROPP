import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/theme/rayons.dart';
import '../../../shared/theme/typographie.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../../utils/format.dart';
import '../data/commandes.dart';

final commandeProvider = FutureProvider.autoDispose.family<Commande, String>(
  (ref, id) => ref.watch(commandesRepositoryProvider).obtenir(id),
);

String libelleStatut(AppLocalizations l10n, StatutCommande statut) =>
    switch (statut) {
      StatutCommande.enAttentePaiement => l10n.statutEnAttentePaiement,
      StatutCommande.nouvelle => l10n.statutNouvelle,
      StatutCommande.enCours => l10n.statutEnCours,
      StatutCommande.expediee => l10n.statutExpediee,
      StatutCommande.livree => l10n.statutLivree,
      StatutCommande.annulee => l10n.statutAnnulee,
      StatutCommande.enLitige => l10n.statutEnLitige,
    };

/// Pastille de statut : attente (kola), réussite (plantain), erreur
/// (piment), en cours (indigo).
class PastilleStatut extends StatelessWidget {
  const PastilleStatut({super.key, required this.statut});

  final StatutCommande statut;

  @override
  Widget build(BuildContext context) {
    final metier = context.couleursMetier;
    final schema = Theme.of(context).colorScheme;
    final (couleur, fond) = switch (statut) {
      StatutCommande.enAttentePaiement => (metier.attente, metier.attenteFond),
      StatutCommande.livree => (metier.succes, metier.succesFond),
      StatutCommande.annulee ||
      StatutCommande.enLitige => (metier.erreur, metier.erreurFond),
      _ => (schema.primary, schema.surfaceContainerHighest),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          libelleStatut(context.l10n, statut),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: couleur, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Mes commandes, les plus récentes d'abord.
class PageCommandes extends ConsumerWidget {
  const PageCommandes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    final depot = ref.watch(commandesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandesTitre)),
      body: ListePaginee<Commande>(
        charger: depot.lister,
        padding: const EdgeInsets.all(Espacements.l),
        separateur: const SizedBox(height: Espacements.s),
        vide: EtatVide(
          icone: IconesDropp.receipt,
          titre: l10n.commandesVide,
          action: FilledButton(
            onPressed: () => context.go(Routes.recherche),
            child: Text(l10n.navDecouvrir),
          ),
        ),
        elementBuilder: (context, c, _) {
          final boutiques = c.sousCommandes
              .map((s) => s.boutiqueNom)
              .whereType<String>()
              .join(', ');
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: Rayons.borduresCarte,
            child: InkWell(
              borderRadius: Rayons.borduresCarte,
              onTap: () => unawaited(
                context.push<void>(Routes.commande(c.id), extra: c),
              ),
              child: Container(
                padding: const EdgeInsets.all(Espacements.m),
                decoration: BoxDecoration(
                  borderRadius: Rayons.borduresCarte,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            date.format(c.dateCreation),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        PastilleStatut(statut: c.statut),
                      ],
                    ),
                    const SizedBox(height: Espacements.s),
                    Text(
                      boutiques,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.panierNombreArticles(c.nombreArticles),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          formaterPrix(c.montantTotal),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFamily: Typographie.titre,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Détail d'une commande : statut, minuteur de paiement, articles par
/// boutique, total, annulation.
class PageCommande extends ConsumerStatefulWidget {
  const PageCommande({super.key, required this.id, this.initiale});

  final String id;

  /// Commande venue de la liste ou tout juste passée : affichée tout de suite.
  final Commande? initiale;

  @override
  ConsumerState<PageCommande> createState() => _PageCommandeState();
}

class _PageCommandeState extends ConsumerState<PageCommande> {
  Commande? _apresAnnulation;
  bool _annulation = false;

  Future<void> _annuler() async {
    final l10n = context.l10n;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commandeAnnulerTitre),
        content: Text(l10n.commandeAnnulerTexte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commandeGarder),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commandeAnnuler),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final messager = ScaffoldMessenger.of(context);
    setState(() => _annulation = true);
    try {
      final commande = await ref
          .read(commandesRepositoryProvider)
          .annuler(widget.id);
      if (mounted) setState(() => _apresAnnulation = commande);
    } on ApiException catch (e) {
      // Déjà traitée (payée ou expirée entre-temps) : on relit.
      ref.invalidate(commandeProvider(widget.id));
      messager.showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {TypeErreurApi.conflit: l10n.commandeDejaTraitee},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _annulation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final etat = ref.watch(commandeProvider(widget.id));
    final commande = _apresAnnulation ?? etat.value ?? widget.initiale;

    final Widget corps;
    if (commande != null) {
      corps = _Detail(
        commande: commande,
        annulation: _annulation,
        surAnnuler: _annuler,
        surExpiree: () => ref.invalidate(commandeProvider(widget.id)),
      );
    } else if (etat.hasError) {
      corps = Center(
        child: VueErreur(
          erreur: ApiException.depuis(etat.error!),
          reessayer: () => ref.invalidate(commandeProvider(widget.id)),
        ),
      );
    } else {
      corps = ListView(
        padding: const EdgeInsets.all(Espacements.l),
        children: const [
          Squelette(hauteur: 80, rayon: 16),
          SizedBox(height: Espacements.m),
          Squelette(hauteur: 160, rayon: 16),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commandeTitre)),
      body: corps,
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.commande,
    required this.annulation,
    required this.surAnnuler,
    required this.surExpiree,
  });

  final Commande commande;
  final bool annulation;
  final VoidCallback surAnnuler;
  final VoidCallback surExpiree;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final c = commande;
    final date = DateFormat.yMMMd(l10n.localeName).add_Hm();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Espacements.l,
        Espacements.s,
        Espacements.l,
        MediaQuery.paddingOf(context).bottom + Espacements.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.commandeDu(date.format(c.dateCreation)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: schema.onSurfaceVariant,
                ),
              ),
            ),
            PastilleStatut(statut: c.statut),
          ],
        ),
        if (c.statut == StatutCommande.enAttentePaiement) ...[
          const SizedBox(height: Espacements.m),
          _Minuteur(echeance: c.echeancePaiement, surFin: surExpiree),
          const SizedBox(height: Espacements.s),
          Container(
            padding: const EdgeInsets.all(Espacements.m),
            decoration: BoxDecoration(
              color: schema.surfaceContainerHighest,
              borderRadius: Rayons.borduresCarte,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(IconesDropp.phoneScreen, color: schema.primary),
                const SizedBox(width: Espacements.s),
                Expanded(
                  child: Text(
                    l10n.commandePaiementBientot,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Espacements.l),
        for (final sc in c.sousCommandes) ...[
          Container(
            padding: const EdgeInsets.all(Espacements.m),
            decoration: BoxDecoration(
              color: schema.surface,
              borderRadius: Rayons.borduresCarte,
              border: Border.all(color: schema.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => unawaited(
                    context.push<void>(Routes.boutique(sc.boutiqueId)),
                  ),
                  child: Text(
                    sc.boutiqueNom ?? '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: Espacements.s),
                for (final l in sc.lignes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l.quantite} × ${l.nom}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (l.variante != null)
                                Text(
                                  l.variante!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: schema.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formaterPrix(l.total),
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Espacements.s),
        ],
        const SizedBox(height: Espacements.s),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.panierTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              formaterPrix(c.montantTotal),
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: Typographie.titre,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Text(
          l10n.panierLivraisonPlusTard,
          style: theme.textTheme.bodySmall?.copyWith(
            color: schema.onSurfaceVariant,
          ),
        ),
        if (c.annulable) ...[
          const SizedBox(height: Espacements.xl),
          OutlinedButton(
            onPressed: annulation ? null : surAnnuler,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.couleursMetier.erreur,
            ),
            child: Text(l10n.commandeAnnuler),
          ),
        ],
      ],
    );
  }
}

/// Temps restant pour payer ; à zéro, relit la commande (annulée par le
/// serveur).
class _Minuteur extends StatefulWidget {
  const _Minuteur({required this.echeance, required this.surFin});

  final DateTime echeance;
  final VoidCallback surFin;

  @override
  State<_Minuteur> createState() => _MinuteurState();
}

class _MinuteurState extends State<_Minuteur> {
  Timer? _minuteur;
  late Duration _restant = _calculer();
  bool _finSignalee = false;

  Duration _calculer() {
    final r = widget.echeance.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _restant = _calculer());
      if (_restant == Duration.zero && !_finSignalee) {
        _finSignalee = true;
        // Le serveur annule à l'échéance : laisser un peu de marge.
        Timer(const Duration(seconds: 5), () {
          if (mounted) widget.surFin();
        });
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metier = context.couleursMetier;
    final fini = _restant == Duration.zero;
    return Semantics(
      liveRegion: false,
      child: Container(
        padding: const EdgeInsets.all(Espacements.m),
        decoration: BoxDecoration(
          color: metier.attenteFond,
          borderRadius: Rayons.borduresCarte,
        ),
        child: Row(
          children: [
            FaIcon(IconesDropp.timer, color: metier.attente),
            const SizedBox(width: Espacements.s),
            Expanded(
              child: Text(
                fini ? l10n.commandeDelaiDepasse : l10n.commandeAPayerAvant,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: metier.attente,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!fini)
              Text(
                formaterDuree(_restant),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: metier.attente,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
