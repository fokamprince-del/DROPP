import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../data/panier.dart';

final panierProvider = AsyncNotifierProvider<PanierNotifier, Panier>(
  PanierNotifier.new,
);

/// Nombre d'articles (quantités cumulées) pour la pastille de l'onglet.
final nombreArticlesPanierProvider = Provider<int>(
  (ref) => ref.watch(panierProvider).value?.nombreArticles ?? 0,
);

/// Panier de l'utilisateur connecté (vide pour un visiteur). Chaque action
/// remplace le panier par celui renvoyé par le serveur ; une erreur laisse
/// le panier affiché tel quel et remonte à l'écran.
class PanierNotifier extends AsyncNotifier<Panier> {
  PanierRepository get _depot => ref.read(panierRepositoryProvider);

  @override
  Future<Panier> build() async {
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    if (utilisateur == null) return Panier.vide;
    return ref.watch(panierRepositoryProvider).obtenir();
  }

  Future<void> ajouter(String varianteId, {int quantite = 1}) =>
      _remplacer(_depot.ajouter(varianteId, quantite: quantite));

  Future<void> modifierQuantite(String articleId, int quantite) =>
      _remplacer(_depot.modifierQuantite(articleId, quantite));

  Future<void> supprimer(String articleId) =>
      _remplacer(_depot.supprimer(articleId));

  /// Après une commande : le panier a été converti, on relit le nouveau.
  void recharger() => ref.invalidateSelf();

  Future<void> _remplacer(Future<Panier> requete) async {
    final panier = await requete;
    if (ref.mounted) state = AsyncData(panier);
  }
}
