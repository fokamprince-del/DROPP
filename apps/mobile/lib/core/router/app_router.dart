import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/pages/page_connexion.dart';
import '../../features/auth/ui/pages/page_mot_de_passe_oublie.dart';
import '../../features/auth/ui/pages/page_reinitialisation.dart';
import '../../features/auth/ui/pages/pages_inscription.dart';
import '../../features/auth/ui/pages/verification_telephone.dart';
import '../../features/demarrage/demarrage.dart';
import '../../features/demarrage/page_demarrage.dart';
import '../../features/fil/data/modeles_fil.dart';
import '../../features/fil/ui/pages/page_accueil.dart';
import '../../features/fil/ui/pages/page_publication.dart';
import '../../features/navigation/navigation_principale.dart';
import '../../features/stories/ui/pages/lecteur_stories.dart';
import '../../shared/widgets/page_provisoire.dart';
import '../auth/session.dart';
import 'redirection.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Le routeur réévalue `redirect` à chaque changement de session.
  final session = ValueNotifier<EtatSession>(ref.read(sessionProvider));
  final demarrage = ValueNotifier<EtatDemarrage>(ref.read(demarrageProvider));

  ref.listen(sessionProvider, (_, suivant) => session.value = suivant);
  ref.listen(demarrageProvider, (_, suivant) => demarrage.value = suivant);

  final router = GoRouter(
    initialLocation: Routes.accueil,
    refreshListenable: Listenable.merge([session, demarrage]),
    redirect: (context, state) => redirection(
      session.value,
      state.uri,
      demarrageTermine: demarrage.value.termine,
      bienvenueVue: demarrage.value.bienvenueVue,
    ),
    routes: [
      GoRoute(
        path: Routes.demarrage,
        builder: (context, state) => const PageDemarrage(),
      ),

      GoRoute(
        path: Routes.bienvenue,
        builder: (context, state) => const _BienvenueProvisoire(),
      ),

      // ── Auth (Dev B : remplacer les pages provisoires) ──
      GoRoute(
        path: Routes.connexion,
        builder: (context, state) => const PageConnexion(),
      ),
      GoRoute(
        path: Routes.inscription,
        builder: (context, state) => const PageInscription(),
      ),
      GoRoute(
        path: Routes.verificationTelephone,
        builder: (context, state) => const PageVerificationTelephone(),
      ),
      GoRoute(
        path: Routes.motDePasseOublie,
        builder: (context, state) => const PageMotDePasseOublie(),
      ),
      GoRoute(
        path: Routes.reinitialiserMotDePasse,
        builder: (context, state) => const PageReinitialisation(),
      ),

      // ── Onglets ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, coquille) =>
            NavigationPrincipale(coquille: coquille),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.accueil,
                builder: (context, state) => const PageAccueil(),
                routes: [
                  GoRoute(
                    path: 'publications/:id',
                    builder: (context, state) => PagePublication(
                      id: state.pathParameters['id']!,
                      initiale: state.extra as Publication?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.recherche,
                builder: (context, state) => const PageProvisoire('Rechercher'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.panier,
                builder: (context, state) => const PageProvisoire('Panier'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.messages,
                builder: (context, state) => const PageProvisoire('Messages'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profil,
                builder: (context, state) => const _ProfilProvisoire(),
                routes: [
                  GoRoute(
                    path: 'securite',
                    builder: (context, state) =>
                        const PageProvisoire('Sécurité'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Stories (plein écran, sans la barre d'onglets) ──
      GoRoute(
        path: Routes.stories,
        pageBuilder: (context, state) => MaterialPage<void>(
          fullscreenDialog: true,
          child: LecteurStories(indexInitial: state.extra as int? ?? 0),
        ),
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
    demarrage.dispose();
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

/// En attendant le vrai écran « Bienvenue » (3 écrans de présentation).
class _BienvenueProvisoire extends ConsumerWidget {
  const _BienvenueProvisoire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageProvisoire(
      'Bienvenue',
      actions: [
        FilledButton(
          onPressed: () async {
            await ref.read(demarrageProvider.notifier).marquerBienvenueVue();
            if (context.mounted) context.go(Routes.accueil);
          },
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}
