import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/adresses/data/adresses.dart';
import '../../features/adresses/ui/pages_adresses.dart';
import '../../features/auth/ui/pages/page_confirmation_email.dart';
import '../../features/auth/ui/pages/page_connexion.dart';
import '../../features/auth/ui/pages/page_mot_de_passe_oublie.dart';
import '../../features/auth/ui/pages/page_reinitialisation.dart';
import '../../features/auth/ui/pages/pages_inscription.dart';
import '../../features/auth/ui/pages/verification_telephone.dart';
import '../../features/avis/ui/avis_ui.dart';
import '../../features/boutiques/ui/pages/page_boutique.dart';
import '../../features/boutiques/ui/pages/page_mes_abonnements.dart';
import '../../features/catalogue/ui/pages/page_avis_produit.dart';
import '../../features/catalogue/ui/pages/page_decouvrir.dart';
import '../../features/catalogue/ui/pages/page_produit.dart';
import '../../features/commandes/data/commandes.dart';
import '../../features/commandes/ui/commandes_ui.dart';
import '../../features/demarrage/demarrage.dart';
import '../../features/demarrage/page_bienvenue.dart';
import '../../features/demarrage/page_demarrage.dart';
import '../../features/fil/data/modeles_fil.dart';
import '../../features/fil/ui/pages/page_accueil.dart';
import '../../features/fil/ui/pages/page_publication.dart';
import '../../features/interactions/ui/page_favoris.dart';
import '../../features/messagerie/data/messagerie.dart';
import '../../features/messagerie/ui/page_conversations.dart';
import '../../features/messagerie/ui/page_discussion.dart';
import '../../features/moderation/ui/moderation_ui.dart';
import '../../features/navigation/navigation_principale.dart';
import '../../features/notifications/ui/notifications_ui.dart';
import '../../features/panier/ui/page_panier.dart';
import '../../features/profil/ui/page_modifier_profil.dart';
import '../../features/profil/ui/page_profil.dart';
import '../../features/profil/ui/pages_securite.dart';
import '../../features/stories/ui/pages/lecteur_stories.dart';
import '../../features/vendeur/ui/pages/page_devenir_vendeur.dart';
import '../../features/vendeur/ui/pages/page_kyc_cni.dart';
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
        builder: (context, state) => const PageBienvenue(),
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
                builder: (context, state) => const PageDecouvrir(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.panier,
                builder: (context, state) => const PagePanier(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.messages,
                builder: (context, state) => const PageConversations(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profil,
                builder: (context, state) => const PageProfil(),
                routes: [
                  GoRoute(
                    path: 'modifier',
                    builder: (context, state) => const PageModifierProfil(),
                  ),
                  GoRoute(
                    path: 'securite',
                    builder: (context, state) => const PageSecurite(),
                    routes: [
                      GoRoute(
                        path: 'mot-de-passe',
                        builder: (context, state) =>
                            const PageChangerMotDePasse(),
                      ),
                      GoRoute(
                        path: 'telephone',
                        builder: (context, state) =>
                            const PageChangerTelephone(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'favoris',
                    builder: (context, state) => const PageFavoris(),
                  ),
                  GoRoute(
                    path: 'bloques',
                    builder: (context, state) => const PageBloques(),
                  ),
                  GoRoute(
                    path: 'signalements',
                    builder: (context, state) => const PageMesSignalements(),
                  ),
                  GoRoute(
                    path: 'abonnements',
                    builder: (context, state) => const PageMesAbonnements(),
                  ),
                  GoRoute(
                    path: 'adresses',
                    builder: (context, state) => const PageAdresses(),
                    routes: [
                      // Avant « :id », sinon « nouvelle » serait pris pour un id.
                      GoRoute(
                        path: 'nouvelle',
                        builder: (context, state) =>
                            const PageFormulaireAdresse(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PageFormulaireAdresse(
                          adresse: state.extra as Adresse?,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'avis',
                    builder: (context, state) => const PageAvisANoter(),
                  ),
                  GoRoute(
                    path: 'email',
                    builder: (context, state) {
                      final p = state.uri.queryParameters;
                      return PageConfirmationEmail(
                        codeDejaEnvoye:
                            p[PageConfirmationEmail.parametreEnvoye] == '1',
                        changement:
                            p[PageConfirmationEmail.parametreChanger] == '1',
                      );
                    },
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

      // ── Catalogue et boutiques (au-dessus des onglets : on y arrive depuis
      // le fil comme depuis Découvrir) ──
      GoRoute(
        path: '${Routes.produits}/:id',
        builder: (context, state) =>
            PageProduit(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'avis',
            builder: (context, state) =>
                PageAvisProduit(produitId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '${Routes.boutiques}/:id',
        builder: (context, state) =>
            PageBoutique(id: state.pathParameters['id']!),
      ),

      // ── Notifications (au-dessus des onglets) ──
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const PageNotifications(),
        routes: [
          GoRoute(
            path: 'preferences',
            builder: (context, state) => const PagePreferencesNotifications(),
          ),
        ],
      ),

      // ── Commandes et discussions (au-dessus des onglets) ──
      GoRoute(
        path: Routes.commandes,
        builder: (context, state) => const PageCommandes(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => PageCommande(
              id: state.pathParameters['id']!,
              initiale: state.extra as Commande?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '${Routes.conversations}/:id',
        builder: (context, state) => PageDiscussion(
          id: state.pathParameters['id']!,
          initiale: state.extra as Conversation?,
        ),
      ),

      // ── Vendeur ──
      GoRoute(
        path: Routes.devenirVendeur,
        builder: (context, state) => const PageDevenirVendeur(),
      ),
            GoRoute(
        path: Routes.kycCni,
        builder: (context, state) => const PageKycCni(),
      ),
      GoRoute(
        path: Routes.kycInformations,
        builder: (context, state) => const PageProvisoire('Informations de la CNI'),
      ),
      GoRoute(
        path: Routes.kycSelfie,
        builder: (context, state) => const PageProvisoire('Selfie'),
      ),
      GoRoute(
        path: Routes.kycRecapitulatif,
        builder: (context, state) => const PageProvisoire('Récapitulatif'),
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
