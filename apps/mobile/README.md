# DROPP — application mobile

Application Flutter (client et vendeur) branchée sur l'API `apps/api`.

## Prérequis

- **Flutter stable récent, Dart ≥ 3.13.5** (contrainte du `pubspec.yaml`).
  Vérifier avec `flutter --version` ; une version plus ancienne échoue dès
  `flutter pub get`. Mettre à jour avec `flutter upgrade`.
- Avant chaque PR : `flutter analyze` (aucun problème toléré) et
  `flutter test`.

## Lancer

```bash
flutter pub get
flutter run                                   # émulateur Android → http://10.0.2.2:3000/v1
flutter run --dart-define=API_URL=http://192.168.1.20:3000/v1   # téléphone sur le Wi-Fi
flutter test
```

L'API doit tourner en local (`pnpm api:dev` à la racine). En debug, Android
autorise le HTTP non chiffré (`android/app/src/debug/AndroidManifest.xml`).

## Organisation

```
lib/
  main.dart
  app/app.dart             MaterialApp (thème, langues, routeur)
  core/                    socle partagé (PR relues)
    api/                   ApiClient, intercepteurs, ApiException, PageResultats
    auth/                  session (Riverpod), stockage sécurisé, Utilisateur
    router/                go_router, routes, règles de redirection
    l10n/                  raccourci context.l10n
    dev/                   écrans de test à supprimer avant la livraison
  features/<module>/       un dossier par module de la roadmap
    data/                  dépôt (appels ApiClient) + modèles
    application/           providers et logique Riverpod
    ui/pages, ui/widgets   écrans et widgets
  shared/
    theme/                 couleurs « Ndop », typographie, rayons, espacements
    widgets/               ListePaginee, Squelette, ImageReseau, EtatVide,
                           VueErreur, AvatarBoutique, LogoDropp, MotifNdop…
    modeles/               modèles communs (BoutiqueResume, MediaContenu)
  utils/                   téléphone, formats (prix, durée, temps relatif)
  l10n/                    textes FR (modèle) et EN
```

## Règles du socle

- **Appels API** : toujours via `ref.read(apiClientProvider)`, chemins avec le
  `/` initial et sans `/v1` : `api.get('/produits')`. Toute erreur est une
  `ApiException` (`type`, `message` prêt à afficher, `details` pour la
  validation).
- **Listes paginées** : `api.page('/route', Modele.fromJson, page: p)` et le
  widget `ListePaginee`. Format de l'API : `{ donnees, pagination }`.
  Passer `squelette:` pour le premier chargement (la maquette préfère les
  squelettes aux spinners) et `auRafraichir:` pour recharger ce qui vit dans
  l'en-tête en même temps que la liste.
- **Jetons** : jamais manipulés par les écrans. Après `/auth/connexion` ou
  `/auth/verifier-telephone`, appeler
  `ref.read(sessionProvider.notifier).ouvrir(Jetons.fromJson(reponse))`.
  Le refresh sur 401 est automatique (un seul à la fois).
- **Idempotency-Key** : ajoutée sur chaque POST. Pour un bouton « Réessayer »
  qui doit garder la même clé, la passer dans `Options(headers: …)`.
- **Navigation** : déclarer la route dans `core/router/app_router.dart` et, si
  elle demande une connexion, un téléphone vérifié ou un compte vendeur, son
  préfixe dans `core/router/routes.dart`. Les règles sont testées dans
  `test/app/router/redirection_test.dart`.
- **Upload de fichiers** : ne pas utiliser `ApiClient` pour le PUT vers l'URL
  signée R2 (il ajouterait le jeton) — service dédié prévu en J3.
- **Textes** : jamais en dur dans un écran. Ajouter la clé dans
  `lib/l10n/app_fr.arb` (modèle) et `app_en.arb`, puis `flutter gen-l10n`
  (lancé aussi par `flutter pub get` / `flutter run`). Les fichiers
  `app_localizations*.dart` générés sont versionnés : les commiter avec les
  `.arb`.
- **Images distantes** : toujours `ImageReseau` (cache disque, squelette,
  repli en cas d'erreur), jamais `Image.network`.
- **Vidéos** : jamais de lecture automatique dans une liste (données mobiles
  coûteuses) ; une vignette (`VignetteVideo`), puis `LecteurVideo` qui ne
  télécharge qu'au premier appui.
- **Couleurs** : passer par le thème. Texte secondaire :
  `colorScheme.onSurfaceVariant` ; fonds secondaires et squelettes :
  `colorScheme.surfaceContainerHighest` ; accent vivant (story non vue,
  onglet actif) : `colorScheme.secondary`.
- **Formats** : `formaterPrix` (`25 000 FCFA` dans toutes les langues),
  `formaterDuree`, `formaterCompteur`, `tempsRelatif` (`utils/format.dart`).

## Fil et stories (`features/fil`, `features/stories`)

| Écran | Route | Appels API |
|---|---|---|
| Accueil : stories + onglets « Pour toi » / « Abonnements » | `/` | `GET /publications`, `GET /publications/fil/abonnements`, `GET /stories`, `GET /stories/abonnements` |
| Détail d'une publication | `/publications/:id` (`extra` : la `Publication` du fil, affichée tout de suite) | `GET /publications/:id` |
| Lecteur de stories plein écran | `/stories` (`extra` : index de la boutique dans la barre) | `POST /stories/:id/vue` |

- **Visiteur** : « Pour toi », le détail et les stories publiques sont
  consultables sans compte ; l'onglet « Abonnements » invite à se connecter.
- **Comptage des vues** : `VuesPublications` envoie `POST /publications/:id/vue`
  quand 60 % de la carte est à l'écran, ou quand elle occupe la moitié de
  l'écran. Une seule fois par publication et par lancement ; nouvel essai au
  prochain affichage si l'envoi échoue. Le serveur dédoublonne aussi sur 24 h.
- **Barre de stories** (`barreStoriesProvider`) : boutiques suivies d'abord
  (ordre du serveur), puis les stories publiques des autres boutiques
  regroupées par boutique ; dans chaque partie, les boutiques non vues passent
  devant (`composerBarre`, testée). Une story vue grise l'anneau tout de
  suite ; le serveur n'est prévenu que si l'utilisateur est connecté. Un
  échec de chargement masque la barre sans bloquer le fil.
- **Lecteur de stories** : 5 s par image, durée réelle pour une vidéo ;
  toucher à gauche / à droite pour reculer / avancer, appui long pour la
  pause, glisser vers le bas pour fermer. Les boutiques s'enchaînent ; la
  lecture reprend à la première story non vue.
- **Pas encore branché** : like, commentaires et partage (compteurs en
  lecture seule), fiche produit (tuiles non cliquables), logo de boutique
  (l'API ne le renvoie pas : initiale sur dégradé indigo).

## Git

Une branche par module depuis `dev` (`feature/mobile-<module>`), PR courte
relue par l'autre dev dans la journée. `core/` ne bouge que par PR.
