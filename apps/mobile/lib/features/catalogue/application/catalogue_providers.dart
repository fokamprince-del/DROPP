import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/pagination.dart';
import '../data/catalogue_repository.dart';
import '../data/modeles_catalogue.dart';

/// Arbre des catégories (change rarement : gardé pendant la session).
final categoriesProvider = FutureProvider<List<Categorie>>(
  (ref) => ref.watch(catalogueRepositoryProvider).categories(),
);

final produitProvider = FutureProvider.autoDispose
    .family<ProduitDetail, String>(
      (ref, id) => ref.watch(catalogueRepositoryProvider).produit(id),
    );

/// Trois derniers avis et le résumé, pour la fiche produit.
final apercuAvisProvider = FutureProvider.autoDispose
    .family<PageResultats<Avis>, String>(
      (ref, id) =>
          ref.watch(catalogueRepositoryProvider).avis(id, 1, limite: 3),
    );
