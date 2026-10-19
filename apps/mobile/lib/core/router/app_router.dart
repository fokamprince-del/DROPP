import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart';
import '../dev/connexion_dev_page.dart';
import '../ui/page_demarrage.dart';
import '../ui/page_provisoire.dart';
import 'navigation_principale.dart';
import 'redirection.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Le routeur réévalue `redirect` à chaque changement de session.
  final session = ValueNotifier<EtatSession>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, suivant) => session.value = suivant);

  final router = GoRouter(
    initialLocation: Routes.accueil,
    refreshListenable: session,
    redirect: (context, state) => redirection(session.value, state.uri),
    routes: [
      GoRoute(
        path: Routes.demarrage,
        builder: (context, state) => const PageDemarrage(),
      ),

      // ── Auth (Dev B : remplacer les pages provisoires) ──
      GoRoute(
        path: Routes.connexion,
        builder: (context, state) => const ConnexionDevPage(),
      ),
      GoRoute(
        path: Routes.inscription,
        builder: (context, state) => const PageProvisoire('Inscription'),
      ),
      GoRoute(
        path: Routes.verificationTelephone,
        builder: (context, state) => const PageProvisoire('Vérification du téléphone'),
      ),
      GoRoute(
        path: Routes.motDePasseOublie,
        builder: (context, state) => const PageProvisoire('Mot de passe oublié'),
      ),

      // ── Onglets ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, coquille) =>
            NavigationPrincipale(coquille: coquille),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.accueil,
              builder: (context, state) => const PageProvisoire('Accueil'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.recherche,
              builder: (context, state) => const PageProvisoire('Rechercher'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.panier,
              builder: (context, state) => const PageProvisoire('Panier'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.messages,
              builder: (context, state) => const PageProvisoire('Messages'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profil,
              builder: (context, state) => const _ProfilProvisoire(),
              routes: [
                GoRoute(
                  path: 'securite',
                  builder: (context, state) => const PageProvisoire('Sécurité'),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ── Vendeur ──
      GoRoute(
        path: Routes.devenirVendeur,
        builder: (context, state) => const PageProvisoire('Devenir vendeur'),
      ),
      GoRoute(
        path: Routes.espaceVendeur,
        builder: (context, state) => const PageProvisoire('Espace vendeur'),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});

/// En attendant le vrai profil (Dev B, J4) : de quoi tester la session.
class _ProfilProvisoire extends ConsumerWidget {
  const _ProfilProvisoire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    return PageProvisoire(
      'Profil',
      actions: [
        if (utilisateur != null) Text(utilisateur.nomComplet),
        OutlinedButton(
          onPressed: () => context.push(Routes.espaceVendeur),
          child: const Text('Espace vendeur'),
        ),
        FilledButton(
          onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
          child: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}
