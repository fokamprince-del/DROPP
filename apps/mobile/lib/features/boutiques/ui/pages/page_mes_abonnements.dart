import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/widgets/etat_vide.dart';
import '../../../../shared/widgets/liste_paginee.dart';
import '../../data/boutiques_repository.dart';
import '../../data/modeles_boutiques.dart';
import '../widgets/tuile_boutique.dart';

/// Boutiques suivies, les plus récentes d'abord. Se désabonner ici laisse
/// la ligne en place (on peut se réabonner tout de suite).
class PageMesAbonnements extends ConsumerWidget {
  const PageMesAbonnements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final depot = ref.watch(boutiquesRepositoryProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.abonnementsTitre)),
      body: ListePaginee<AbonnementBoutique>(
        charger: depot.mesAbonnements,
        vide: EtatVide(
          icone: IconesDropp.storeFront,
          titre: l10n.abonnementsVideTitre,
          texte: l10n.filAbonnementsVideTexte,
          action: FilledButton(
            onPressed: () => context.go(Routes.recherche),
            child: Text(l10n.filDecouvrirBoutiques),
          ),
        ),
        elementBuilder: (context, a, _) => TuileBoutique(
          boutiqueId: a.boutiqueId,
          nom: a.nom,
          logoUrl: a.logoUrl,
          sousTitre: l10n.abonnementsDepuis(date.format(a.depuis)),
        ),
      ),
    );
  }
}
