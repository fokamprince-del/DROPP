# DROPP mobile — documentation technique

Référence pour développer sur l'application Flutter. Pour le déploiement
(domaine, Resend, Twilio, R2, signature) :
[docs/mise-en-production.md](../../../docs/mise-en-production.md). Le [README](../README.md)
donne l'essentiel pour démarrer ; ce document explique comment l'app
fonctionne, pourquoi elle est construite ainsi, et ce qu'il faut savoir avant
de toucher à un module.

Sommaire :

1. [Pile technique](#1-pile-technique)
2. [Configuration et lancement](#2-configuration-et-lancement)
3. [Architecture](#3-architecture)
4. [Réseau](#4-réseau)
5. [Session et navigation](#5-session-et-navigation)
6. [État partagé (providers)](#6-état-partagé-providers)
7. [Modules](#7-modules)
8. [Interface](#8-interface)
9. [Textes et langues](#9-textes-et-langues)
10. [Tests](#10-tests)
11. [Écarts connus avec l'API](#11-écarts-connus-avec-lapi)
12. [Reste à faire](#12-reste-à-faire)
13. [Dépannage](#13-dépannage)

---

## 1. Pile technique

| Besoin | Paquet | Remarque |
|---|---|---|
| SDK | Flutter stable, **Dart ≥ 3.13.5** | Le code utilise les éléments nuls `?x` dans les collections et les motifs Dart 3. |
| État | `flutter_riverpod` 3 | `Notifier`, `AsyncNotifier`, `FutureProvider.family`. Pas de génération de code. |
| Navigation | `go_router` 18 | `StatefulShellRoute` pour les onglets, `redirect` pour les règles d'accès. |
| HTTP | `dio` 5 | Toujours via `ApiClient`, jamais directement. |
| Clés d'idempotence | `uuid` | Une par POST. |
| Jetons | `flutter_secure_storage` | Keystore Android / Keychain iOS. |
| Préférences | `shared_preferences` | Drapeau « bienvenue vue ». |
| Téléphone | `phone_numbers_parser` | Normalisation `+237…`. |
| Images | `cached_network_image` | Cache disque : revoir le fil ne retélécharge rien. |
| Vidéo | `video_player` | Lecture à la demande (détail, stories). |
| Visibilité | `visibility_detector` | Comptage des vues du fil. |
| Liens externes | `url_launcher` | Partage WhatsApp (`https://wa.me/?text=`). |
| Langues | `flutter_localizations`, `intl` | Fichiers `.arb`, génération par `flutter gen-l10n`. |

`freezed` et `json_serializable` sont déclarés mais **pas utilisés** : les
modèles sont écrits à la main (`fromJson` explicite), ce qui garde le contrôle
sur les formats particuliers de l'API (montants en chaînes, dates).

## 2. Configuration et lancement

- **URL de l'API** : constante de compilation `API_URL`
  (`lib/core/config/environnement.dart`). Par défaut
  `http://10.0.2.2:3000/v1` (l'API locale vue depuis l'émulateur Android).
  Sur un téléphone : `--dart-define=API_URL=http://<IP du PC>:3000/v1`.
- **Release** : `Environnement.verifier()` refuse au démarrage une URL qui
  n'est pas en `https`.
- **HTTP en clair** : autorisé uniquement en debug
  (`android/app/src/debug/AndroidManifest.xml`).
- **Signature release** : `android/key.properties` (ignoré par git) pointe vers
  la clé de production ; sans ce fichier, la release est signée avec la clé
  de debug (refusée par le Play Store). Détails :
  [docs/mise-en-production.md](../../../docs/mise-en-production.md), § 9.
- **Permissions Android** (`android/app/src/main/AndroidManifest.xml`) :
  `INTERNET`, et une déclaration `<queries>` pour ouvrir des liens `https`
  (exigée par Android 11+ pour `url_launcher`).

Vérifications avant chaque PR :

```bash
flutter analyze   # aucun problème toléré (règles strictes, voir analysis_options.yaml)
flutter test
```

`analysis_options.yaml` active `strict-casts`, `strict-inference`,
`strict-raw-types` : tout `dynamic` venant du JSON doit être converti
explicitement (`json['x'] as String`).

## 3. Architecture

```
lib/
  main.dart                 vérifie la config, lance DroppApp
  app/app.dart              MaterialApp.router : thème, langues, routeur
  core/                     socle commun, modifié uniquement par PR relue
    api/                    ApiClient, intercepteurs, ApiException, pagination
    auth/                   session, stockage des jetons, Utilisateur
    router/                 routes, règles de redirection, routeur
    l10n/                   raccourci context.l10n
  features/<module>/
    data/                   modèles + dépôt (appels ApiClient)
    application/            providers et notifiers Riverpod
    ui/pages, ui/widgets    écrans et composants du module
  shared/
    theme/                  jetons de design (couleurs, typo, rayons, espacements)
    widgets/                composants réutilisés par plusieurs modules
    modeles/                modèles communs (BoutiqueResume, MediaContenu)
  utils/                    fonctions pures (téléphone, formats)
  l10n/                     .arb + code généré (versionné)
```

Règles :

- **Le code est en français** (noms, commentaires), comme l'API.
- **Un écran ne parle jamais à `ApiClient`** : il passe par un dépôt
  (`features/*/data/*_repository.dart`), en général à travers un provider.
- **Un module peut importer un autre module** quand il en affiche les objets
  (la page boutique affiche des `CartePublication`), mais jamais son état
  interne privé.
- **Les fonctions pures sont testées sans Flutter** : règles de redirection,
  composition de la barre de stories, filtres du catalogue, formats.

## 4. Réseau

### ApiClient

`ref.read(apiClientProvider)` ; chemins relatifs à `/v1`, avec le `/`
initial : `api.get('/produits')`.

| Méthode | Usage |
|---|---|
| `get<T>(chemin, query:)` | Les paramètres `null` sont retirés de `query`. |
| `post`, `patch`, `put`, `delete` | `data:` pour le corps JSON, `options:` pour des en-têtes. |
| `page<T>(chemin, fromJson, page:, limite:, query:)` | Liste paginée → `PageResultats<T>`. |

### Intercepteurs (dans l'ordre)

1. **`IntercepteurIdempotence`** : ajoute `Idempotency-Key` (UUID v4) à chaque
   POST qui n'en a pas. Un bouton « Réessayer » qui doit rejouer la même
   opération passe sa propre clé (exemple : réinitialisation du mot de
   passe).
2. **`IntercepteurAuth`** : ajoute `Authorization: Bearer`. Sur un 401, fait
   **un seul** `/auth/refresh` à la fois puis rejoue les requêtes en
   attente : le serveur fait tourner le refresh token, et présenter un ancien
   jeton deux fois ferme toutes les sessions de l'appareil. Si le refresh est
   refusé, `sessionProvider` passe en `SessionAnonyme(expiree: true)`.
3. **`IntercepteurErreurs`** : toute erreur devient une `ApiException`.

### ApiException

| `type` | Statut | Cas typique |
|---|---|---|
| `reseau` | — | Pas de connexion, serveur injoignable. |
| `delaiDepasse` | — | 15 s de connexion / 20 s de réception dépassées. |
| `requeteInvalide` | 400, 422 | Validation (`details` contient tous les messages). |
| `nonAuthentifie` | 401 | Après échec du refresh, ou identifiants faux sur `/auth/*`. |
| `interdit` | 403 | Profil client inactif, téléphone non vérifié, blocage. |
| `introuvable` | 404 | Contenu supprimé, réservé aux abonnés, boutique suspendue. |
| `conflit` | 409 | Déjà aimé / suivi / en favori, requête identique en cours. |
| `expire` | 410 | Code de vérification expiré. |
| `tropDeRequetes` | 429 | Limitation de débit. |
| `serveur` | 5xx | — |

Dans l'interface, le texte affiché vient de `messageErreurApi(l10n, e)`
(`features/auth/ui/messages_erreurs.dart`), jamais du message brut du
serveur (non traduit).

### Formats de l'API à connaître

- **Pagination** : `{ donnees: [...], pagination: { total, page, limite,
  pages } }`. Des champs annexes peuvent s'ajouter à côté (le `resume` des
  avis) : ils restent lisibles dans `PageResultats.brut`.
- **Montants** : les `Decimal` Prisma sont sérialisés en **chaînes**
  (`"25000"`, `"4500.50"`) sur les produits, et en nombres sur les produits
  liés aux publications. Toujours lire avec `lireMontant()`
  (`shared/modeles/contenu.dart`).
- **Dates** : ISO 8601 en UTC ; converties en heure locale par
  `dateDepuis()`.
- **Identifiants** : UUID. Une **boutique, son vendeur et le compte du
  vendeur ont le même identifiant** (`/vendeurs/:id/suivre` prend l'id de la
  boutique ; `estMaBoutique` compare l'id de la boutique à celui de
  l'utilisateur).
- **Médias** : `url` publique, ou **signée et à durée limitée** pour un
  contenu réservé aux abonnés. Ne pas stocker ces URL au-delà de la
  session.

## 5. Session et navigation

### États de session (`sessionProvider`)

`SessionInconnue` (lecture du stockage au lancement) → `SessionAnonyme`
(visiteur, éventuellement `expiree`) ou `SessionConnectee(utilisateur)`.
Raccourci pour les écrans : `utilisateurConnecteProvider` (`Utilisateur?`).

Tout provider qui dépend de l'utilisateur **surveille**
`utilisateurConnecteProvider` : il se recharge seul à la connexion et à la
déconnexion (barre de stories, interactions, page boutique).

### Routes

| Chemin | Écran | Accès |
|---|---|---|
| `/demarrage` | Démarrage (logo, durée minimale) | — |
| `/bienvenue` | Bienvenue (provisoire) | visiteur, première ouverture |
| `/connexion`, `/inscription`, `/verification-telephone`, `/mot-de-passe-oublie`, `/reinitialiser-mot-de-passe` | Accès | visiteur seulement |
| `/` (onglet 1) | Accueil : stories + fil | public |
| `/publications/:id` | Détail d'une publication | public |
| `/recherche` (onglet 2) | Découvrir | public |
| `/panier` (onglet 3) | Panier | connexion |
| `/messages` (onglet 4) | Conversations | connexion + téléphone vérifié |
| `/conversations/:id` (`extra` : la `Conversation`) | Discussion (plein écran) | connexion + téléphone vérifié |
| `/commandes`, `/commandes/:id` (`extra` : la `Commande`) | Mes commandes, détail | connexion |
| `/profil` (onglet 5), `/profil/modifier` | Profil (photo, identité, accès au compte), modification | connexion |
| `/profil/securite`, `/mot-de-passe`, `/telephone` | Sécurité : appareils, mot de passe, numéro, suppression du compte | connexion |
| `/profil/abonnements`, `/profil/favoris`, `/profil/bloques`, `/profil/signalements` | Abonnements, favoris, bloqués, signalements | connexion |
| `/notifications`, `/notifications/preferences` | Notifications, préférences des push | connexion |
| `/profil/email` (`?envoye=1` après l'activation, `?changer=1`) | Confirmer, ajouter ou changer l'adresse email | connexion |
| `/profil/adresses`, `/profil/adresses/nouvelle`, `/profil/adresses/:id` (`extra` : l'`Adresse`) | Carnet d'adresses, formulaire | connexion |
| `/profil/avis` | Avis à laisser | connexion |
| `/stories` | Lecteur de stories (plein écran) | public |
| `/produits/:id`, `/produits/:id/avis` | Fiche produit, tous les avis | public |
| `/boutiques/:id` | Page boutique | public |
| `/devenir-vendeur`, `/vendeur` | Vendeur (provisoire) | connexion + téléphone ; `/vendeur` réservé aux vendeurs |

- Les routes des onglets gardent chacune leur pile ; les routes déclarées
  **au-dessus des onglets** (stories, produit, boutique) s'ouvrent en plein
  écran, d'où qu'on vienne.
- Les règles d'accès sont dans `core/router/redirection.dart` (fonction pure,
  testée) et les ensembles de préfixes dans `core/router/routes.dart`. Une
  nouvelle route protégée = ajouter son préfixe, pas une condition dans
  l'écran.
- **Retour après connexion** : un visiteur envoyé vers `/connexion` emporte
  `?de=<page demandée>` ; après connexion, la redirection l'y ramène
  (chemins internes seulement). Pour une action d'un écran public (j'aime,
  suivre…), utiliser `exigerConnexion` / `actionConnectee`
  (`features/interactions/ui/actions_connectees.dart`), qui construisent ce
  paramètre.
- `extra` sert à afficher tout de suite ce qu'on a déjà (la `Publication`
  venue du fil, l'index de la boutique dans la barre de stories). La page
  doit toujours fonctionner sans `extra` (lien profond, redémarrage).

## 6. État partagé (providers)

| Provider | Type | Contenu | Rechargé quand |
|---|---|---|---|
| `sessionProvider` | `Notifier` | État de session | connexion, déconnexion, refresh refusé |
| `utilisateurConnecteProvider` | `Provider` | `Utilisateur?` | suit la session |
| `demarrageProvider` | `Notifier` | Démarrage terminé, bienvenue vue | lancement |
| `routerProvider` | `Provider` | `GoRouter` | jamais (écoute session et démarrage) |
| `interactionsProvider` | `Notifier` | J'aime, favoris, abonnements, compteurs modifiés | changement d'utilisateur |
| `barreStoriesProvider` | `AsyncNotifier` | Groupes de stories de la barre | changement d'utilisateur, tirer pour rafraîchir |
| `vuesPublicationsProvider` | `Provider` | Vues déjà signalées | jamais (vit pendant le lancement) |
| `categoriesProvider` | `FutureProvider` | Arbre des catégories | tirer pour rafraîchir dans Découvrir |
| `produitProvider(id)` | `FutureProvider.autoDispose.family` | Fiche produit | à chaque ouverture |
| `apercuAvisProvider(id)` | idem | 3 avis + résumé | à chaque ouverture |
| `publicationProvider(id)` | idem | Détail d'une publication | à chaque ouverture |
| `boutiqueProvider(id)` | idem | Page boutique | ouverture, changement d'utilisateur |
| `resumeAvisBoutiqueProvider(id)` | idem | Note de la boutique | à chaque ouverture |
| `panierProvider` | `AsyncNotifier` | Panier (vide pour un visiteur) | changement d'utilisateur, après chaque action, après une commande |
| `nombreArticlesPanierProvider` | `Provider` | Pastille de l'onglet Panier | suit le panier |
| `nonLusProvider` / `nombreMessagesNonLusProvider` | `AsyncNotifier` / `Provider` | Messages reçus non lus (pastille) | connexion, liste des conversations, sortie d'une discussion |
| `commandeProvider(id)` | `FutureProvider.autoDispose.family` | Détail d'une commande | ouverture, échéance du paiement |
| `adressesProvider` | `FutureProvider.autoDispose` | Carnet d'adresses | ouverture, après un enregistrement |
| `articlesANoterProvider` | `FutureProvider.autoDispose` | Articles livrés à noter | ouverture, après un avis |
| `serviceUploadProvider` | `Provider` | Service d'upload (client sans jeton) | jamais |
| `tempsReelProvider` | `Provider` | Connexion Socket.IO | connexion / déconnexion (suit l'utilisateur) |
| `compteurNotificationsProvider` | `AsyncNotifier` | Notifications non lues (cloche) | connexion, puis temps réel |
| `profilProvider` | `FutureProvider.autoDispose` | Profil complet (`/users/me`) | ouverture, après une modification |
| `sessionsProvider` | `FutureProvider.autoDispose` | Appareils connectés | ouverture, après une déconnexion d'appareil |
| `motifsSignalementProvider` | `FutureProvider` | Motifs de signalement | une fois par lancement |
| `bloquesProvider` | `FutureProvider.autoDispose` | Utilisateurs bloqués | ouverture, après un déblocage |

Les listes paginées ne sont pas dans des providers : `ListePaginee` garde
ses éléments, et une `ValueKey` construite à partir des filtres ou de
l'utilisateur la remet à zéro quand ils changent.

### `interactionsProvider` en détail

C'est la source de vérité de « ai-je aimé / suivi / mis en favori ». Les
publications et produits reçus de l'API ne portent pas cette information (ou
l'app l'ignore) : un écran lit toujours l'état ici.

- **Chargement** : `GET /moi/etats` à l'ouverture de session. Échec : tout
  s'affiche « non aimé », les actions restent possibles.
- **Compteurs** : `likesPublication(id, recu)`, `abonnes(id, recu)`… rendent
  la valeur modifiée depuis le lancement si elle existe, sinon `recu` (celle
  de l'objet affiché). Ainsi, une liste en cache affiche le bon total après
  une action faite ailleurs.
- **Action** (`basculerLikePublication`, `basculerFavoriProduit`,
  `basculerAbonnement`…) :
  1. changement appliqué tout de suite (optimiste) ;
  2. requête ; le total renvoyé par le serveur remplace l'estimation ;
  3. refus : changement annulé, `ApiException` relancée (l'écran l'affiche
     via `actionConnectee`) ;
  4. 409 en ajout ou 404 en retrait : le serveur est déjà dans l'état voulu,
     l'affichage est gardé ;
  5. une seconde action sur le même élément pendant la requête est ignorée.
- **Actions pendant le chargement de `/moi/etats`** : enregistrées puis
  rejouées sur les états reçus, pour ne pas effacer un j'aime donné entre
  temps.
- `synchroniserAbonnement` aligne l'état sans requête quand une page boutique
  dit autre chose (abonnement pris sur un autre appareil).
- `noterCommentaire(id, ±1)` ajuste le compteur de commentaires d'une
  publication après une publication ou une suppression locale.

## 7. Modules

### Accès et email (`features/auth`)

- Inscription (téléphone obligatoire, email facultatif) → code SMS →
  session ouverte. Si un email a été donné, **le serveur y envoie aussitôt un
  code** : l'app ouvre alors `/profil/email?envoye=1` (« Plus tard » mène à
  l'accueil).
- `PageConfirmationEmail` a trois étapes : saisie d'une adresse (ajout ou
  changement, mot de passe exigé), code à 6 chiffres (renvoi après 60 s),
  adresse déjà confirmée. Depuis le profil, le code est demandé à
  l'ouverture ; un 409 « déjà vérifiée » met le profil à jour.
- Une adresse confirmée permet de recevoir le code « mot de passe oublié »
  par email (sinon il part par SMS). Les emails sont envoyés par le worker
  via Resend.

### Fil (`features/fil`)

- **Accueil** : deux onglets (« Pour toi » public, « Abonnements » connecté),
  gardés en vie (`AutomaticKeepAliveClientMixin`) pour ne pas perdre la
  position en changeant d'onglet. La barre de stories est l'en-tête des deux
  listes ; tirer pour rafraîchir recharge aussi la barre.
- **Pages de 10** publications (chaque carte charge des médias).
- **Vues** : une `VisibilityDetector` par carte ; une vue compte quand 60 %
  de la carte est visible **ou** qu'elle couvre la moitié de l'écran (sinon
  une carte plus haute que l'écran ne serait jamais comptée).
  `VuesPublications` n'envoie qu'une fois par publication et par lancement,
  et réessaie au prochain affichage après un échec.
- **Médias** : image unique, vidéo unique ou carrousel (2 à 10). Dans le fil,
  une vidéo est une **vignette** (fond nuit, durée) : rien n'est téléchargé.
  Dans le détail, `LecteurVideo` télécharge au premier appui, en boucle,
  avec une barre de progression déplaçable.
- **Carte** : toucher le média ou le texte ouvre le détail (avec la
  publication en `extra`) ; double appui sur le média = j'aime (jamais de
  retrait) avec un cœur animé ; l'en-tête ouvre la boutique ; l'étiquette
  produit ouvre la fiche produit.
- **Détail** : ratio d'origine du premier média, borné entre 4:5 et 1,91:1 ;
  la vue est signalée aussi à l'ouverture (lien partagé).

### Stories (`features/stories`)

- **Barre** : connecté, `GET /stories/abonnements` (déjà groupé) puis
  `GET /stories` (à plat) ; visiteur, `GET /stories` seul. `composerBarre`
  regroupe les stories publiques par boutique, écarte les boutiques déjà
  présentes et place les boutiques non vues devant dans chaque partie. Un
  échec masque la barre (ne bloque jamais le fil).
- **Vues** : grisées tout de suite (`_vuesLocales`) ; envoyées au serveur
  uniquement avec une session (la route exige la connexion).
- **Lecteur** : copie figée des groupes à l'ouverture (marquer une story vue
  réordonne la barre, pas le lecteur). 5 s par image, durée réelle d'une
  vidéo (repli : durée fournie par le vendeur, puis 15 s). Média illisible :
  message 3 s puis story suivante. Seul le groupe affiché joue ; les voisins
  sont en pause. Lecture reprise à la première story non vue.

### Interactions et commentaires (`features/interactions`, `features/commentaires`)

- Toutes les routes d'action exigent un **profil client actif et un
  téléphone vérifié** : un compte qui ne remplit pas ces conditions reçoit
  403, affiché par `actionConnectee` avec un texte dédié.
- **Partage** : `POST /publications/:id/partager` renvoie un lien profond
  (`dropp://publications/:id`). WhatsApp s'ouvre sur
  `https://wa.me/?text=…` ; « Copier le lien » copie le lien profond.
- **Commentaires** : feuille modale à 85 % de la hauteur, avec son propre
  `ScaffoldMessenger` (les erreurs s'affichent dans la feuille, pas derrière).
  Racines les plus récentes d'abord, 3 réponses en aperçu, « Voir N autres
  réponses » charge jusqu'à 5 pages de 20. Répondre vise toujours la racine
  (le serveur refuse les réponses à une réponse). Un commentaire publié est
  inséré en tête sans recharger la liste.

### Catalogue (`features/catalogue`)

- **Découvrir** : une saisie commune aux onglets Produits et Boutiques,
  envoyée après 400 ms sans frappe. `FiltresCatalogue` est immuable et
  comparable : sa valeur sert de clé à la liste, qui repart de la page 1 à
  chaque changement.
- **Filtres** : catégorie (puces, avec une seconde rangée de
  sous-catégories ; toucher la sous-catégorie choisie revient à la
  catégorie parente), prix min / max (inversés automatiquement s'ils sont
  dans le désordre), fourchettes de la maquette, tri, en stock. La pastille
  du bouton compte prix, stock et tri (la catégorie a ses puces).
  `FiltresCatalogue.avec()` distingue « effacer » (`null`) de « ne pas
  toucher » (`Garder`).
- **Grille** : 2 colonnes (3 au-delà de 600 dp) ; hauteur calculée à partir
  de la largeur et de la taille du texte de l'utilisateur.
- **Fiche produit** : variantes décrites par des attributs (`{taille,
  couleur}`), au plus 10 par variante. Les noms d'attributs sont pris dans
  l'ordre d'apparition ; une variante est choisie quand toutes ses valeurs
  le sont. Sans attributs, une puce par variante (son nom, ou « Option N »).
  Prix d'une variante = son prix, sinon le prix de base ; « À partir de »
  tant qu'aucune n'est choisie et que les prix diffèrent. Badge : rupture
  (0), « Plus que N » (≤ 3), « En stock ».

### Boutiques (`features/boutiques`)

- **Page boutique** : `NestedScrollView` (l'en-tête se replie, les onglets
  restent fixés). Les listes des onglets utilisent
  `ListePaginee(defilementPrincipal: true)` pour partager le défilement
  principal. Bannière par défaut : dégradé indigo → hibiscus avec bande
  ndop.
- L'état d'abonnement renvoyé par la page est réappliqué à
  `interactionsProvider` à chaque chargement (`ref.listen`), jamais à chaque
  reconstruction (sinon un appui sur Suivre serait écrasé).
- **Mes abonnements** : se désabonner laisse la ligne en place, pour pouvoir
  se réabonner d'un appui.

### Upload de fichiers (`core/upload`)

Un seul service pour tous les envois (pièces jointes aujourd'hui ; photo de
profil, KYC et médias des produits ensuite) :

1. **signature** : le module appelle sa route `…/signature` avec
   `{ typeMime, taille }` → `SignatureUpload { uploadUrl, cleStockage,
   enTetes }` ;
2. **envoi** : `PUT` direct vers R2, **en flux depuis le disque** (une vidéo
   de 100 Mo n'est jamais chargée en mémoire), avec les en-têtes signés
   renvoyés à l'identique (sinon 403) et la progression ;
3. **confirmation** : le module déclare `FichierEnvoye.toJson()` à sa route
   (`…/confirmer`, `…/media`, ou l'envoi du message).

`ServiceUpload` a son **propre client dio, sans intercepteurs** : le jeton
de l'API ne doit jamais partir vers R2. `choisirMedia()` propose galerie ou
appareil photo, recompresse les photos en JPEG (2 048 px, qualité 85 : moins
de données, et le HEIC de l'iPhone devient accepté), vérifie format et
taille (`FichierRefuse`) et lit les dimensions des images. Permissions iOS
déclarées dans `Info.plist` (photos, appareil photo, micro).

### Panier et commandes (`features/panier`, `features/commandes`)

- Le serveur renvoie **le panier complet après chaque action**, prix et
  disponibilités recalculés : `PanierNotifier` remplace son état par cette
  réponse (pas d'estimation locale). Un refus (stock insuffisant) laisse le
  panier affiché et affiche l'erreur.
- Un article peut devenir **indisponible** (produit retiré, stock
  insuffisant) ou **changer de prix** depuis l'ajout : il est signalé, et
  « Commander » reste grisé tant qu'un article est indisponible
  (`commandable`). Le bouton « + » s'arrête au stock disponible.
- Ajout depuis la fiche produit (barre « Écrire à la boutique » / « Ajouter
  au panier », masquée sur ses propres produits) ; la variante doit être
  choisie et en stock.
- **Commander** = `POST /commandes` **sans corps** : tout le panier devient
  une commande (une sous-commande par boutique), le stock est réservé et le
  panier vidé. Ni adresse ni paiement : ces modules ne sont pas branchés
  côté serveur. Un 400 (panier changé entre-temps) recharge le panier.
- Une commande reste **« en attente de paiement »** puis est annulée
  automatiquement : le détail affiche un minuteur basé sur
  `delaiPaiementCommande` (30 min, à aligner sur
  `COMMANDE_DELAI_PAIEMENT_MINUTES` ; l'API ne renvoie pas l'échéance) et
  relit la commande à zéro. Annulation possible tant qu'elle n'est pas payée
  (409 sinon : relue).

### Adresses (`features/adresses`)

Carnet (`GET /clients/me`), ajout, modification, suppression. La première
adresse devient principale ; en marquer une autre principale retire ce
statut à l'ancienne. Les champs facultatifs vides sont envoyés vides pour
pouvoir être effacés. Les commandes ne prennent pas encore d'adresse.

### Avis (`features/avis`)

- « Avis à laisser » : articles **livrés** sans avis
  (`GET /moi/avis/a-noter`) ; feuille de notation (1 à 5 étoiles,
  commentaire facultatif).
- Il n'existe pas de route « mes avis » : un avis déjà donné se reconnaît sur
  la fiche produit à `Avis.auteurId`, avec un menu Modifier / Supprimer
  (30 jours ; 403 ensuite, message dédié).

### Messagerie (`features/messagerie`)

- **Conversations** : celles qui ont au moins un message, les plus actives
  d'abord, aperçu du dernier message (« Toi : … », « 📷 Photo »), pastille de
  non-lus. Une boutique s'affiche sous son nom et son logo.
- **Démarrer** : « Écrire à la boutique » (fiche produit) ou « Message »
  (page boutique) → `POST /conversations` (retrouve la conversation si elle
  existe) → discussion. Un vendeur ne peut écrire qu'à ses clients.
- **Discussion** : liste à l'envers, historique chargé **en remontant** par
  curseur (`avant` = plus ancien message affiché) ; séparateurs de jour ;
  bulles indigo à droite pour soi, avec ✓ (envoyé) / ✓✓ (lu).
- **Envoi** : texte et jusqu'à 10 photos ou vidéos (10 Mo / 100 Mo). La
  bulle apparaît tout de suite avec la progression ; en cas d'échec,
  « Réessayer » ne renvoie pas les fichiers déjà arrivés dans R2.
- **Lu** : `POST /conversations/:id/lu` à l'ouverture et à chaque nouveau
  message reçu ; la pastille est relue en quittant l'écran.
- **Temps réel** : nouveaux messages, accusés de lecture (✓✓) et « en train
  d'écrire… » arrivent par Socket.IO. La relecture toutes les 15 s ne sert
  plus que si la connexion temps réel est coupée.
- **Menu** de la discussion : Signaler (le dernier message reçu) et
  Bloquer ; après un blocage, la saisie est fermée.
- Les URL des pièces jointes sont signées pour 1 h : rouvrir la discussion
  au-delà.

### Temps réel (`core/temps_reel`)

- Socket.IO sur `<origine de l'API>/temps-reel`, transport WebSocket.
  Ouvert tant qu'un utilisateur est connecté (`tempsReelProvider`, démarré
  par `DroppApp`), **coupé quand l'app passe en arrière-plan** et rouvert
  au retour (batterie, données).
- **Jeton** : relu à chaque (re)connexion (`setAuthFn`). Quand le serveur
  coupe (jeton expiré ou refusé), un appel à `/auth/me` fait renouveler le
  jeton par l'intercepteur, puis la connexion repart — au plus une fois par
  minute. Les coupures réseau sont reprises par la bibliothèque (2 s à
  30 s entre deux essais).
- **Événements** (`EvenementsTempsReel`) : `message:nouveau`,
  `message:lus`, `conversation:ecrit` (dans les deux sens),
  `notification:nouvelle`, `notification:compteur`. Les écrans écoutent
  `tempsReel.ecouter(nom)` et filtrent (conversation affichée…).
- Qui écoute quoi : pastille Messages (+1 par message reçu), liste des
  conversations (rechargée, 1 s de regroupement), discussion (message,
  lecture, écriture), cloche et liste des notifications.
- **Tests** : `TempsReel(lireJeton: …, renouvelerJeton: …)` sans
  `demarrer()`, puis `simuler(nom, données)`.

### Notifications (`features/notifications`)

- Cloche avec pastille dans l'en-tête de l'accueil. Liste des plus
  récentes ; toucher une notification la marque lue et ouvre le contenu lié
  (`commandeId`, `conversationId`, `publicationId`, `produitId`) ;
  glisser la supprime ; « Tout lire » dans la barre.
- **Préférences** : messages, activité sociale, promotions. Elles coupent
  le **push**, pas la notification dans l'app ; commandes, paiements et
  sécurité sont toujours envoyés.

### Profil et sécurité (`features/profil`)

- **Profil** (onglet 5) : photo (via le service d'upload, 5 Mo, images
  seulement), nom, `@pseudo`, téléphone, puis l'accès à tout le compte
  (achats, favoris, abonnements, email, sécurité, préférences, bloqués,
  signalements, espace vendeur), et la déconnexion.
- **Modifier** : prénom, nom, sexe, pseudo (3 à 30 caractères minuscules,
  chiffres, « _ », « . » ; disponibilité vérifiée 400 ms après la frappe ;
  409 pris, 400 réservé). Seuls les champs changés sont envoyés ; la
  session est relue pour le nom affiché.
- **Sécurité** : appareils connectés (celui-ci signalé), déconnexion d'un
  appareil ou de **tous** (y compris celui-ci : session locale fermée),
  changement de mot de passe (le serveur révoque tout et renvoie de
  nouveaux jetons, ouverts aussitôt), de numéro (code SMS au nouveau
  numéro) et d'email (écran email existant), suppression du compte (mot de
  passe ; 409 s'il reste des commandes en cours).
- `SessionNotifier.fermerLocalement()` efface la session sans appeler
  l'API, quand le serveur a déjà tout révoqué.

### Modération (`features/moderation`) et favoris

- **Signaler** (feuille commune) : motifs fournis par l'API, description
  obligatoire pour « Autre », anonyme pour la personne signalée. Points
  d'entrée : menu « ⋯ » des publications, lien sous les commentaires des
  autres, drapeau de la fiche produit, menu de la page boutique, menu de la
  discussion. 409 si déjà signalé, 400 sur son propre contenu.
- **Bloquer** : depuis la discussion ou la page boutique ; liste des
  bloqués dans le profil avec « Débloquer ».
- **Mes favoris** : produits et publications ; retirer passe par
  `interactionsProvider` avec `estFavori: true` (l'élément est forcément
  en favori, même si `/moi/etats` n'est pas encore chargé).

## 8. Interface

### Jetons de design (direction « Ndop »)

| Rôle | Clair | Sombre | Accès dans le code |
|---|---|---|---|
| Marque, boutons | Indigo `#23307A` | `#8C9BFF` | `colorScheme.primary` |
| Accent vivant (like, story non vue, onglet actif) | Hibiscus `#D6336C` | `#FF5C93` | `colorScheme.secondary` |
| Fond | Coton `#F5F6FA` | Nuit `#0B1029` | `scaffoldBackgroundColor` |
| Surfaces | `#FFFFFF` | `#141A3D` | `colorScheme.surface` |
| Fonds secondaires, squelettes | `#ECEEF6` | `#1C2350` | `colorScheme.surfaceContainerHighest` |
| Texte secondaire | `#4A5078` | `#B3B8DA` | `colorScheme.onSurfaceVariant` |
| Bordures | `#D9DCE8` | `#2A3160` | `colorScheme.outline` |
| Succès / attente / erreur | plantain / kola / piment | variantes claires | `context.couleursMetier` |

Polices : **Bricolage Grotesque** (titres, prix) et **Figtree** (texte),
embarquées dans `assets/fonts`. Rayons : `Rayons` ; espacements : grille de
4 (`Espacements`).

### Composants partagés (`shared/widgets`)

| Composant | Usage |
|---|---|
| `ListePaginee<T>` | Défilement infini, tirer pour rafraîchir, vide / erreur / Réessayer ; options `grille`, `squelette`, `enTete`, `auRafraichir`, `defilementPrincipal` ; méthodes `recharger`, `inserer`, `mettreAJour`, `retirer` via une `GlobalKey`. |
| `ImageReseau` | Toute image distante (cache disque, squelette, repli). |
| `Squelette` | Bloc de chargement animé (fixe si l'utilisateur réduit les animations). |
| `EtatVide` | Médaillon ndop, titre, texte, action. |
| `VueErreur` | Message d'une `ApiException` + Réessayer. |
| `AvatarBoutique` | Logo rond, ou initiale sur dégradé indigo. |
| `Etoiles` | Note sur 5 (demi-étoiles). |
| `LogoDropp`, `MotifNdop` | Identité (logo provisoire). |

### Règles d'ergonomie (maquette, section 5)

- **Données mobiles** : pas de lecture vidéo automatique dans une liste,
  images en cache, petites pages.
- **Appareils d'entrée de gamme** : tout tient en 360 dp ; zones tactiles
  d'au moins 44–48 dp ; squelettes plutôt que spinners.
- **Hors-ligne** : « Réessayer » partout ; une erreur secondaire (barre de
  stories, note d'une boutique) masque l'élément au lieu de bloquer l'écran.
- **Accessibilité** : chaque bouton à icône a un libellé (`Semantics` ou
  `tooltip`) ; les boutons bascule exposent `toggled` ; les éléments
  décoratifs sont exclus (`ExcludeSemantics`).

## 9. Textes et langues

- Modèle : `lib/l10n/app_fr.arb` ; traduction : `app_en.arb`. Toute clé doit
  exister dans les deux.
- Génération : `flutter gen-l10n` (aussi lancé par `flutter pub get` et
  `flutter run`). Les fichiers `app_localizations*.dart` générés sont
  **versionnés** : les commiter avec les `.arb`.
- Pluriels ICU : `{count, plural, =0{…} =1{…} other{…}}`. Pour un nombre
  abrégé (`1,2 k vues`), déclarer `"format": "compact"` sur le paramètre.
- Langue de l'appareil inconnue : français.
- Formats (`utils/format.dart`) : `formaterPrix` (`25 000 FCFA` dans toutes
  les langues), `formaterCompteur`, `formaterDuree`, `formaterNote`
  (`4,8`), `tempsRelatif` (« il y a 5 min », puis la date au-delà d'une
  semaine).

## 10. Tests

`flutter test` : 181 tests au moment de cette version.

| Dossier | Ce qui est couvert |
|---|---|
| `test/app/router` | Règles de redirection, démarrage. |
| `test/core` | `ApiException`, intercepteur d'authentification, session, configuration, textes. |
| `test/features/auth` | Dépôt, validateurs, écran de connexion, champs. |
| `test/features/fil` | Lecture des publications, routes, comptage des vues, écran d'accueil visiteur. |
| `test/features/stories` | Composition de la barre, lecture de la réponse groupée. |
| `test/features/interactions` | Mise à jour optimiste, annulation, 409, double appui, actions pendant le chargement des états. |
| `test/features/catalogue` | Produits (prix en chaînes, variantes), filtres, avis, boutiques, commentaires, partage, écran de la fiche produit. |
| `test/core/upload` | Envoi vers R2 (en-têtes signés, pas de jeton, progression, refus), types acceptés. |
| `test/features/achat` | Panier (lecture, actions, remplacement par la réponse, refus), commandes, adresses, avis ; écran du panier sur 400 dp. |
| `test/features/messagerie` | Conversations, interlocuteur boutique / client, curseur, envoi avec pièces jointes, signature, lecture. |
| `test/features/compte` | Temps réel simulé (non-lus, compteur de notifications), notifications, modération, profil, sessions, mot de passe, favoris ; écrans Profil et Notifications. |
| `test/utils`, `test/shared` | Formats, contrastes du thème, logo et motif. |

Recettes :

- **Faux serveur** : sous-classer `ApiClient` (`super(Dio())`) et surcharger
  `get` / `post`, puis `apiClientProvider.overrideWithValue(...)`.
- **Utilisateur** : `utilisateurConnecteProvider.overrideWithValue(null)`
  pour un visiteur (évite la lecture du stockage sécurisé).
- **Logique Riverpod sans écran** : `ProviderContainer(overrides: …)` et
  `addTearDown(c.dispose)`.
- **Écrans** : donner une taille de téléphone
  (`tester.view.physicalSize = const Size(400, 2000)`), sinon un `ListView`
  ne construit pas ce qui sort de l'écran de test (800 × 600) ; ne pas
  mettre d'URL d'image dans les données (le cache d'images exige un plugin
  absent des tests) ; avec `VisibilityDetector`, régler
  `VisibilityDetectorController.instance.updateInterval = Duration.zero`.
- **Séparateur de milliers** : `intl` utilise une espace fine insécable ;
  comparer après `replaceAll(RegExp(r'\s'), ' ')`.

## 11. Écarts connus avec l'API

À traiter côté serveur ; l'app les contourne en attendant.

| Constat | Effet / contournement |
|---|---|
| Prix `Decimal` envoyés en chaînes sur `/produits`, en nombres sur les publications. | `lireMontant()` accepte les deux. |
| `GET /produits/:id` ne donne ni le nom de la boutique ni l'état favori. | Boutique chargée à part (`boutiqueProvider`), favori depuis `/moi/etats`. |
| `GET /produits` ne donne ni stock ni nom de boutique. | Pas de badge « Plus que N » ni de nom de boutique sur la grille (prévus par la maquette). |
| Publications et stories sans logo de boutique. | Initiale sur dégradé. |
| Like, favori, abonnement non idempotents (409 / 404). | Traités comme des réussites par `InteractionsNotifier`. |
| `_count.commentaires` d'une publication compte aussi les commentaires supprimés. | Compteur un peu trop élevé après une suppression. |
| Pas de miniature pour les vidéos. | Vignette unie (fond nuit) dans le fil. |
| Lien de partage en schéma `dropp://`, non cliquable dans WhatsApp. | À remplacer par un lien `https` (App Links / Universal Links). |
| Le panier ne renvoie pas l'image des produits. | Pictogramme à la place de la photo. |
| `POST /commandes` ne prend pas d'adresse ; la commande ne renvoie pas son échéance de paiement. | Adresses gérées à part ; échéance estimée côté app (30 min). |
| Pas de route « mes avis ». | Son avis se retrouve sur la fiche produit (`auteurId`). |
| Supprimer l'adresse principale n'en désigne pas d'autre. | L'utilisateur choisit une nouvelle principale. |
| Les listes de favoris ne renvoient ni image ni prix des variantes. | Liste textuelle (nom, prix de base, boutique). |
| Pas de route pour connaître l'état de blocage d'une conversation. | Après un blocage depuis l'app, la saisie est fermée localement ; sinon, l'envoi renvoie 403 (message dédié). |

## 12. Reste à faire

- Écrans encore provisoires : Bienvenue, espace vendeur.
- Paiement Mobile Money et livraison (partenaires en discussion).
- Notifications push (Firebase côté app, `POST /notifications/appareils`).
- Liens profonds entrants (`dropp://publications/:id`) vers les routes.
- Mode « Économie de données » de la maquette (réglage utilisateur).
- Barre de navigation : la maquette met « + Publier » au centre et le panier
  en haut de l'accueil ; l'app a le panier au centre (décision à prendre).
- Logo définitif.

## 13. Dépannage

| Symptôme | Cause / solution |
|---|---|
| Accents abîmés (`Ã©`) ou BOM en tête de fichier après une modification | Fichier relu en ANSI par `Get-Content` / `Set-Content` de PowerShell 5.1 : ne pas modifier les sources avec ces commandes (ou forcer `-Encoding utf8` en lecture **et** en écriture). |
| `flutter pub get` refuse la version du SDK | Flutter trop ancien (Dart < 3.13.5) : `flutter upgrade`. |
| `dart.exe` introuvable dans `bin/cache/dart-sdk` | Fichier supprimé (souvent l'antivirus) : supprimer `bin/cache/dart-sdk` et relancer `flutter --version` pour le retélécharger ; ajouter le dossier Flutter aux exclusions de l'antivirus. |
| `git pull` refuse d'avancer dans le dossier Flutter | La branche stable de Flutter a été réécrite : utiliser `flutter upgrade`, pas `git pull`. |
| « Because l10n.yaml exists, the options defined there will be used » | Message normal de `flutter gen-l10n`. |
| Avertissements `LF will be replaced by CRLF` | `core.autocrlf=true` sous Windows ; le dépôt reste en LF. |
| L'app ne joint pas l'API sur un téléphone | Passer l'IP du PC : `--dart-define=API_URL=http://192.168.x.x:3000/v1`, même réseau Wi-Fi. |
| Erreur au démarrage en release « API_URL doit être en https » | Voulu : fournir une URL `https`. |
