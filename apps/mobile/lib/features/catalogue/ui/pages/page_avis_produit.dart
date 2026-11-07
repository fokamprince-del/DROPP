import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/liste_paginee.dart';
import '../../data/catalogue_repository.dart';
import '../../data/modeles_catalogue.dart';
import '../widgets/avis.dart';

/// Tous les avis d'un produit, sous leur résumé.
class PageAvisProduit extends ConsumerStatefulWidget {
  const PageAvisProduit({super.key, required this.produitId});

  final String produitId;

  @override
  ConsumerState<PageAvisProduit> createState() => _PageAvisProduitState();
}

class _PageAvisProduitState extends ConsumerState<PageAvisProduit> {
  /// Arrive avec la première page.
  ResumeAvis? _resume;
  final _liste = GlobalKey<ListePagineeState<Avis>>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final depot = ref.watch(catalogueRepositoryProvider);
    final resume = _resume;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.avisTitre)),
      body: ListePaginee<Avis>(
        key: _liste,
        charger: (page) async {
          final resultat = await depot.avis(widget.produitId, page);
          if (page == 1 && mounted) {
            setState(() => _resume = resumeDe(resultat));
          }
          return resultat;
        },
        enTete: resume == null ? null : ResumeAvisVue(resume: resume),
        padding: const EdgeInsets.only(bottom: Espacements.xl),
        separateur: const SizedBox(height: Espacements.s),
        vide: Center(child: Text(l10n.avisAucun)),
        elementBuilder: (context, avis, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espacements.l),
          child: CarteAvis(
            avis: avis,
            surChangement: () => _liste.currentState?.recharger(),
          ),
        ),
      ),
    );
  }
}
