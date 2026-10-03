# Contribuer à DROPP

Bienvenue sur **DROPP**, une plateforme de social commerce et marketplace.

Ce document explique comment préparer l'environnement de développement et travailler sur le projet.

---

## 1. Prérequis

Avant de commencer, installer :

* **Git**
* **Node.js 24.x**
* **pnpm 12.4.1**
* **Docker Desktop**

Vérifier les versions :

```bash
git --version
node --version
pnpm --version
docker --version
```

Le projet utilise **pnpm**. N'utilisez pas `npm install` ou `yarn install` pour installer les dépendances du projet.

---

## 2. Cloner le projet

```bash
git clone <URL_DU_REPOSITORY>
cd DROPP
```

---

## 3. Installer les dépendances

À la racine du projet :

```bash
pnpm install
```

`pnpm install` lance ensuite automatiquement `pnpm generer`, qui produit les fichiers générés non versionnés dans git :

- le client Prisma et le package `@dropp/database` (`packages/database/src/generated/prisma` et `packages/database/dist`) ;
- les contrats partagés compilés (`packages/contrats/dist`).

Sans eux, la compilation échoue avec des centaines d'erreurs (module `@dropp/database` ou `@dropp/contrats` introuvable, propriétés Prisma inconnues). Après chaque `git pull` qui modifie `packages/database` ou `packages/contrats`, relancez :

```bash
pnpm generer
```

Aucun fichier `.env` n'est nécessaire pour cette étape.

Si pnpm demande l'autorisation d'exécuter certains scripts de dépendances, n'autorisez que les paquets nécessaires et connus.

Ne désactivez pas globalement les protections de pnpm.

---

## 4. Configuration de l'environnement

Copier le fichier d'exemple :

```bash
copy .env.example .env
```

Sur Linux/macOS :

```bash
cp .env.example .env
```

Le fichier `.env` contient les variables locales nécessaires à l'environnement de développement.

**Ne jamais commit un fichier `.env` contenant des secrets.**

Les fichiers `.env` sont ignorés par Git.

---

## 5. Démarrer PostgreSQL + PostGIS

DROPP utilise PostgreSQL avec PostGIS.

Démarrer la base :

```bash
pnpm db:up
```

Vérifier son état :

```bash
pnpm db:status
```

Voir les logs :

```bash
pnpm db:logs
```

Arrêter PostgreSQL sans supprimer les données :

```bash
pnpm db:down
```

### Attention

Ne pas utiliser :

```bash
docker compose down -v
```

sans savoir ce que vous faites.

L'option `-v` supprime les volumes Docker et peut donc supprimer les données locales de PostgreSQL.

---

## 6. Prisma

Prisma est utilisé comme couche d'accès à PostgreSQL.

Le projet utilise actuellement **Prisma 7.10.0**.

Après une modification du schéma Prisma (le client est déjà généré par `pnpm install`) :

```bash
pnpm prisma:generate
```

Après un `git pull` qui apporte de nouvelles migrations, appliquez-les à votre base locale :

```bash
pnpm prisma:migrate:dev
```

Vérifier le schéma :

```bash
pnpm prisma:validate
```

Formater le schéma Prisma :

```bash
pnpm prisma:format
```

> Les migrations métier ne doivent pas être créées ou modifiées sans validation de l'équipe.

---

## 7. Lancer l'API

Lancer l'API en mode développement :

```bash
pnpm api:dev
```

L'API utilise NestJS et fonctionne actuellement sur :

```text
http://localhost:3000
```

Pour construire l'API :

```bash
pnpm api:build
```

---

## 8. Vérifications du code

Avant de pousser une modification, exécuter :

```bash
pnpm format
pnpm lint
pnpm typecheck
pnpm test
```

### Formatage

```bash
pnpm format
```

Corrige automatiquement le formatage du code avec Prettier.

Pour vérifier le formatage sans modifier les fichiers :

```bash
pnpm format:check
```

### Lint

```bash
pnpm lint
```

Recherche les problèmes de qualité et de syntaxe détectables par l'outil de linting.

### TypeScript

```bash
pnpm typecheck
```

Vérifie les erreurs de typage TypeScript.

### Tests

```bash
pnpm test
```

Exécute les tests du monorepo.

Pour les tests de l'API uniquement :

```bash
pnpm api:test
```

Tests end-to-end :

```bash
pnpm api:test:e2e
```

---

## 9. Commandes principales

| Commande               | Utilisation                                |
| ---------------------- | ------------------------------------------ |
| `pnpm dev`             | Démarrer les applications en développement |
| `pnpm build`           | Construire les applications                |
| `pnpm format`          | Formater le code                           |
| `pnpm format:check`    | Vérifier le formatage                      |
| `pnpm lint`            | Vérifier le code                           |
| `pnpm typecheck`       | Vérifier les types TypeScript              |
| `pnpm test`            | Exécuter les tests                         |
| `pnpm api:dev`         | Démarrer l'API                             |
| `pnpm api:build`       | Construire l'API                           |
| `pnpm db:up`           | Démarrer PostgreSQL                        |
| `pnpm db:down`         | Arrêter PostgreSQL                         |
| `pnpm db:status`       | Vérifier PostgreSQL                        |
| `pnpm db:logs`         | Voir les logs PostgreSQL                   |
| `pnpm prisma:generate` | Générer le client Prisma                   |
| `pnpm prisma:validate` | Valider le schéma Prisma                   |
| `pnpm prisma:format`   | Formater le schéma Prisma                  |
| `pnpm prisma:studio`   | Ouvrir Prisma Studio                       |

---

## 10. Structure du projet

```text
DROPP/
├── apps/
│   ├── api/                  # Backend NestJS
│   ├── worker/               # Traitements asynchrones
│   ├── admin/                # Interface d'administration
│   └── mobile/               # Application Flutter
│
├── packages/
│   ├── contrats/             # Contrats partagés
│   └── outils/               # Utilitaires réellement partagés
│
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed/
│
├── infrastructure/
│   ├── docker/
│   └── nginx/
│
├── docs/
│   ├── architecture/
│   ├── adr/
│   ├── mcd/
│   ├── mld/
│   ├── api/
│   ├── securite/
│   └── deployment/
│
├── scripts/
├── .github/
├── docker-compose.yml
├── package.json
├── pnpm-workspace.yaml
├── turbo.json
└── prisma.config.ts
```

Certains répertoires peuvent être encore incomplets ou absents pendant les premières phases du projet.

---

## 11. Règles importantes

### Ne pas modifier directement les fichiers générés

Le client Prisma généré dans :

```text
packages/database/src/generated/prisma/
```

est généré automatiquement.

Ne pas modifier ces fichiers manuellement.

Après une modification du schéma :

```bash
pnpm prisma:generate
```

---

### Ne pas accéder directement à PostgreSQL depuis les applications clientes

L'architecture est :

```text
Mobile / Admin
      ↓
     API
      ↓
 PostgreSQL
```

Les applications clientes ne doivent jamais accéder directement à PostgreSQL.

---

### PostgreSQL est la source de vérité

Redis, les index de recherche et les autres systèmes auxiliaires ne doivent pas devenir une source de vérité pour les données métier critiques.

---

### Ne pas ajouter une dépendance sans raison

Avant d'ajouter une librairie :

1. vérifier qu'elle est réellement nécessaire ;
2. vérifier qu'une fonctionnalité existante ne répond pas déjà au besoin ;
3. vérifier son impact sécurité et maintenance ;
4. vérifier son impact sur la taille et les ressources du projet.

---

## 12. Workflow Git recommandé

Avant de commencer :

```bash
git pull
```

Créer une branche dédiée :

```bash
git checkout -b feat/nom-de-la-fonctionnalite
```

ou :

```bash
git checkout -b fix/nom-du-probleme
```

Après modification :

```bash
pnpm format
pnpm lint
pnpm typecheck
pnpm test
```

Vérifier les changements :

```bash
git status
git diff
```

Puis commit :

```bash
git add .
git commit -m "feat: description courte"
```

Enfin :

```bash
git push -u origin feat/nom-de-la-fonctionnalite
```

---

## 13. En cas de problème

Avant de demander de l'aide, fournir :

* la commande exécutée ;
* le message d'erreur complet ;
* la version de Node.js ;
* la version de pnpm ;
* le contexte de la modification.

Ne jamais partager :

* mots de passe ;
* clés API ;
* tokens ;
* secrets présents dans `.env`.

---

## 14. Architecture en évolution

DROPP est actuellement construit progressivement.

Certaines parties de l'architecture sont volontairement préparées mais ne sont pas encore implémentées.

Ne créez pas de modules, services ou abstractions uniquement parce qu'un dossier existe dans l'architecture cible.

**On privilégie une architecture simple, explicite et justifiée plutôt qu'une architecture anticipée inutilement.**

Les décisions architecturales importantes doivent être documentées dans :

```text
docs/adr/
```

Toute modification importante du modèle de données doit être précédée d'une validation fonctionnelle et architecturale.
