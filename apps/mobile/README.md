# DROPP — application mobile

Application Flutter (client et vendeur) branchée sur l'API `apps/api`.

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
  app.dart, main.dart
  core/                    socle partagé (Dev A le lundi, puis PR relues)
    api/                   ApiClient, intercepteurs, ApiException, PageResultats
    auth/                  session (Riverpod), stockage sécurisé, Utilisateur
    router/                go_router, règles de redirection, barre d'onglets
    ui/                    composants partagés (ListePaginee, kit de Dev B)
    dev/                   écrans de test à supprimer avant la livraison
  features/<module>/       un dossier par module de la roadmap
    data/                  dépôt (appels ApiClient) + modèles
    providers/             providers Riverpod
    ui/                    écrans et widgets
```

## Règles du socle

- **Appels API** : toujours via `ref.read(apiClientProvider)`, chemins avec le
  `/` initial et sans `/v1` : `api.get('/produits')`. Toute erreur est une
  `ApiException` (`type`, `message` prêt à afficher, `details` pour la
  validation).
- **Listes paginées** : `api.page('/route', Modele.fromJson, page: p)` et le
  widget `ListePaginee`. Format de l'API : `{ donnees, pagination }`.
- **Jetons** : jamais manipulés par les écrans. Après `/auth/connexion` ou
  `/auth/verifier-telephone`, appeler
  `ref.read(sessionProvider.notifier).ouvrir(Jetons.fromJson(reponse))`.
  Le refresh sur 401 est automatique (un seul à la fois).
- **Idempotency-Key** : ajoutée sur chaque POST. Pour un bouton « Réessayer »
  qui doit garder la même clé, la passer dans `Options(headers: …)`.
- **Navigation** : déclarer la route dans `core/router/app_router.dart` et, si
  elle demande une connexion, un téléphone vérifié ou un compte vendeur, son
  préfixe dans `core/router/routes.dart`. Les règles sont testées dans
  `test/core/router/redirection_test.dart`.
- **Upload de fichiers** : ne pas utiliser `ApiClient` pour le PUT vers l'URL
  signée R2 (il ajouterait le jeton) — service dédié prévu en J3.

## Git

Une branche par module depuis `dev` (`feature/mobile-<module>`), PR courte
relue par l'autre dev dans la journée. `core/` ne bouge que par PR.
