# DROPP — application mobile

Application Flutter (client et vendeur) branchée sur l'API `apps/api`.

Fonctionnement détaillé (réseau, session, providers, modules, tests, écarts
avec l'API, dépannage) : [docs/technique.md](docs/technique.md).

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
- **Upload de fichiers** : toujours `ref.read(serviceUploadProvider)`
  (`core/upload/service_upload.dart`) : signature par la route du module, PUT
  en flux vers R2 sans le jeton de l'API, puis confirmation. Choix d'une
  photo ou d'une vidéo : `choisirMedia()`. Jamais `ApiClient` pour le PUT.
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
  `formaterDuree`, `formaterCompteur`, `formaterNote`, `tempsRelatif`
  (`utils/format.dart`).
- **Montants** : les prix `Decimal` de Prisma arrivent en **chaînes**
  (`"25000"`) ; les lire avec `lireMontant`, jamais `as num`.
- **Actions d'un utilisateur connecté** : passer par
  `actionConnectee(context, ref, () => …)` (envoie un visiteur vers la
  connexion avec retour sur la page, affiche l'erreur de l'API). Pour une
  liste verticale dans un `NestedScrollView`, `ListePaginee(defilementPrincipal:
  true)` ; pour une grille, `grille:`.

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
- **Logo de boutique** : absent des publications et des stories (l'API ne
  le renvoie pas) : initiale sur dégradé indigo.

## Interactions (`features/interactions`, `features/commentaires`)

| Action | Appels API |
|---|---|
| J'aime (bouton ou double appui sur le média) | `POST`/`DELETE /publications/:id/like` |
| Favori publication / produit | `POST`/`DELETE /publications/:id/favori`, `/produits/:id/favori` |
| Partage (WhatsApp ou copie du lien) | `POST /publications/:id/partager` → lien profond |
| Suivre / ne plus suivre une boutique | `POST`/`DELETE /vendeurs/:id/suivre` (id boutique = id vendeur) |
| États de l'utilisateur, chargés à la connexion | `GET /moi/etats` |
| Commentaires, réponses, like, suppression | `GET`/`POST /publications/:id/commentaires`, `GET /commentaires/:id/reponses`, `POST`/`DELETE /commentaires/:id/like`, `DELETE /commentaires/:id` |

- **Une seule source de vérité** : `interactionsProvider` garde ce que
  l'utilisateur a aimé, mis en favori et suivi, plus les compteurs modifiés
  depuis le lancement. Tous les écrans le lisent : un j'aime donné dans le
  détail s'affiche aussi dans le fil.
- **Mise à jour optimiste** : l'écran change tout de suite, puis prend le
  total renvoyé par le serveur. Un refus annule le changement et affiche
  l'erreur. Un 409 (« déjà aimé ») ou un 404 au retrait (« déjà retiré »)
  garde l'affichage : le serveur est déjà dans l'état voulu. Un double appui
  pendant la requête est ignoré.
- **Pendant le chargement de `/moi/etats`**, les actions sont rejouées sur
  les états reçus : rien n'est perdu (testé).
- **Commentaires** (feuille à 85 % de l'écran) : les plus récents d'abord,
  trois réponses en aperçu puis « Voir N autres réponses » ; on répond
  toujours au commentaire racine (un seul niveau, règle du serveur). Les
  `@pseudo` ressortent en couleur, badge « Créateur » pour la boutique.
  Supprimer : son propre commentaire, ou n'importe lequel sur ses
  publications (boutique).

## Catalogue et boutiques (`features/catalogue`, `features/boutiques`)

| Écran | Route | Appels API |
|---|---|---|
| Découvrir : recherche, onglets Produits / Boutiques | `/recherche` | `GET /produits`, `GET /categories`, `GET /boutiques` |
| Fiche produit | `/produits/:id` | `GET /produits/:id`, `GET /produits/:id/avis` (3 + résumé), `GET /boutiques/:id` |
| Tous les avis | `/produits/:id/avis` | `GET /produits/:id/avis` |
| Page boutique : produits et publications | `/boutiques/:id` | `GET /boutiques/:id`, `GET /boutiques/:id/avis/resume`, `GET /produits?boutiqueId=`, `GET /publications?boutiqueId=` |
| Mes abonnements | `/profil/abonnements` (connexion) | `GET /moi/abonnements` |

- **Recherche** : une seule saisie pour les deux onglets, envoyée après
  400 ms sans frappe. Les filtres (catégorie et sous-catégorie, prix min /
  max et fourchettes de la maquette, tri, en stock) relancent la liste
  depuis la première page.
- **Fiche produit** : la première variante en stock est présélectionnée ;
  une valeur sans stock reste choisissable mais apparaît barrée. Le prix
  suit la variante (« À partir de » tant qu'aucune n'est choisie et que les
  prix diffèrent) ; badge de stock « En stock » / « Plus que N » /
  « Rupture ».
- **Fiche produit et page boutique** sont au-dessus des onglets : on y
  arrive aussi bien depuis le fil (étiquette produit, en-tête de
  publication) que depuis Découvrir.
- La fiche produit a la barre d'achat de la maquette (« Écrire à la
  boutique », « Ajouter au panier ») ; la page boutique, « Message ».

## Achat et avis (`features/panier`, `commandes`, `adresses`, `avis`)

| Écran | Route | Appels API |
|---|---|---|
| Panier (onglet 3) | `/panier` | `GET /panier`, `POST /panier/articles`, `PATCH` / `DELETE /panier/articles/:id` |
| Mes commandes, détail | `/commandes`, `/commandes/:id` | `POST /commandes`, `GET /commandes`, `GET /commandes/:id`, `POST /commandes/:id/annuler` |
| Mes adresses, formulaire | `/profil/adresses`, `/nouvelle`, `/:id` | `GET /clients/me`, `POST` / `PATCH` / `DELETE /clients/me/adresses/:id` |
| Avis à laisser | `/profil/avis` | `GET /moi/avis/a-noter`, `POST /avis` ; `PATCH` / `DELETE /avis/:id` depuis la fiche produit |

- Le panier affiché est **toujours celui renvoyé par le serveur** (prix et
  disponibilités recalculés à chaque action) ; un article indisponible bloque
  « Commander ».
- Commander transforme tout le panier en commande **« en attente de
  paiement »** : minuteur de 30 min puis annulation automatique (stock
  rendu). Paiement Mobile Money et livraison ne sont pas encore branchés.

## Messagerie (`features/messagerie`)

| Écran | Route | Appels API |
|---|---|---|
| Conversations (onglet 4) | `/messages` | `GET /conversations`, `GET /conversations/non-lus` |
| Discussion | `/conversations/:id` | `POST /conversations`, `GET` / `POST /conversations/:id/messages`, `POST /conversations/:id/pieces-jointes/signature`, `POST /conversations/:id/lu` |

- Historique par curseur, chargé en remontant ; photos et vidéos jointes via
  le service d'upload, avec progression et « Réessayer ».
- **Temps réel** (Socket.IO, `core/temps_reel`) : messages, accusés de
  lecture, « en train d'écrire… », notifications. Coupé en arrière-plan ;
  relecture toutes les 15 s seulement si la connexion est coupée.

## Compte (`features/profil`, `notifications`, `moderation`)

| Écran | Route | Appels API |
|---|---|---|
| Profil, modifier | `/profil`, `/profil/modifier` | `GET` / `PATCH /users/me`, `GET /users/pseudo-disponible`, `POST /users/me/photo/signature`, `PUT` / `DELETE /users/me/photo` |
| Sécurité | `/profil/securite` (+ `/mot-de-passe`, `/telephone`) | `GET` / `DELETE /auth/sessions`, `POST /auth/deconnecter-partout`, `/auth/mot-de-passe/changer`, `/auth/telephone/changer` puis `/confirmer`, `/auth/compte/supprimer` |
| Notifications | `/notifications` (+ `/preferences`) | `GET /notifications`, `/compteur`, `PATCH /:id/lue`, `POST /tout-lire`, `DELETE /:id`, `GET` / `PUT /preferences` |
| Favoris, bloqués, signalements | `/profil/favoris`, `/profil/bloques`, `/profil/signalements` | `GET /moi/favoris/produits`, `/publications`, `GET /moi/bloques`, `POST` / `DELETE /utilisateurs/:id/bloquer`, `GET /signalements/motifs`, `POST /signalements`, `GET /moi/signalements` |

- Signaler : menu des publications, commentaires, fiche produit, page
  boutique, discussion (feuille commune, anonyme).

## Git

Une branche par module depuis `dev` (`feature/mobile-<module>`), PR courte
relue par l'autre dev dans la journée. `core/` ne bouge que par PR.
