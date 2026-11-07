# Mise en production de DROPP

Checklist à suivre dans l'ordre le jour où le domaine est disponible. Dans
ce document, `mondomaine` est à remplacer par le vrai domaine.

Chaque service refuse de démarrer en production s'il manque une clé
obligatoire (validation Joi au lancement) : une erreur au démarrage indique
la variable à renseigner.

---

## 1. Sous-domaines à prévoir

| Sous-domaine | Usage |
|---|---|
| `api.mondomaine` | API (HTTPS obligatoire : l'app mobile refuse `http` en release). |
| `medias.mondomaine` | Domaine personnalisé du bucket R2 public (images, vidéos). |
| `mail.mondomaine` | Envoi des emails par Resend (sous-domaine dédié : la réputation d'envoi reste séparée du domaine principal). |
| `mondomaine` (plus tard) | Site et liens de partage `https://mondomaine/p/<id>` (voir § 9). |

## 2. Emails (Resend) — service : worker

1. resend.com → **Domains** → *Add domain* → `mail.mondomaine`.
2. Créer chez l'hébergeur DNS les enregistrements affichés par Resend :
   - **MX** et **TXT (SPF)** sur `send.mail.mondomaine` ;
   - **TXT (DKIM)** sur `resend._domainkey.mail.mondomaine`.
3. Ajouter un **DMARC** sur le domaine : TXT `_dmarc.mondomaine` =
   `v=DMARC1; p=none; rua=mailto:dmarc@mondomaine` (passer à
   `p=quarantine` après quelques semaines sans problème).
4. Attendre le statut **Verified** dans Resend.
5. **API Keys** → *Create API Key* → permission **Sending access**,
   limitée au domaine `mail.mondomaine`.
6. Dans l'environnement du **worker** (pas de l'API) :

   ```
   RESEND_API_KEY=re_...
   EMAIL_EXPEDITEUR=DROPP <no-reply@mail.mondomaine>
   EMAIL_REPONDRE_A=support@mondomaine
   ```

   ⚠️ L'expéditeur doit appartenir au domaine vérifié, sinon chaque envoi
   est refusé (403, sans nouvel essai). La valeur par défaut
   (`no-reply@dropp.cm`) ne convient que si `dropp.cm` est ce domaine.

Ce que Resend envoie : code de confirmation de l'adresse email (après
l'activation du compte, puis depuis le profil), code « mot de passe
oublié » si l'adresse est confirmée, alerte « quelqu'un a tenté de créer
un compte avec votre email », messages de décision KYC.

Test : créer un compte avec un email → après le code SMS, l'écran
« Confirme ton adresse email » s'ouvre et le code arrive par email.

## 3. SMS (Twilio) — service : worker

```
SMS_DRIVER=twilio
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_EXPEDITEUR=DROPP
```

- Obligatoire en production : sans SMS, personne ne peut activer son compte.
- **Vérifier auprès de Twilio** que l'expéditeur alphanumérique « DROPP »
  est autorisé pour le Cameroun (enregistrement préalable souvent exigé) ;
  sinon utiliser un numéro Twilio au format E.164.
- Prévoir du crédit : chaque inscription, connexion d'un compte non vérifié
  et « mot de passe oublié » par SMS envoie un message.

## 4. Vérification faciale KYC (Face++) — service : worker

```
FACEPP_API_KEY=...
FACEPP_API_SECRET=...
```

Obligatoires en production (sinon la comparaison serait simulée).

## 5. Notifications push (Firebase) — service : worker

```
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...@....iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Console Firebase → Paramètres du projet → Comptes de service → *Générer une
nouvelle clé privée*. Sans ces clés, le worker démarre mais écrit une
**erreur** au lancement : aucun push n'est envoyé.

⚠️ Côté mobile, les push ne sont **pas encore branchés** (paquet
`firebase_messaging`, `google-services.json`, appel de
`POST /notifications/appareils`) : à faire avant d'annoncer les
notifications.

## 6. Stockage des médias (Cloudflare R2) — service : API

1. Créer deux buckets : **public** (`dropp-medias`) et **privé**
   (`dropp-prive`, sans accès public : pièces d'identité KYC, messagerie,
   contenus réservés aux abonnés).
2. Bucket public → *Settings* → **Custom domain** → `medias.mondomaine`.
3. Optionnel : activer **Images → Transformations** sur ce domaine (images
   redimensionnées à la volée, moins de données mobiles).
4. *Manage API tokens* → jeton **Object Read & Write** limité aux deux
   buckets.

```
STOCKAGE_DRIVER=r2
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET=dropp-medias
R2_BUCKET_PRIVE=dropp-prive        # obligatoire en production, différent de R2_BUCKET
R2_ENDPOINT=https://<R2_ACCOUNT_ID>.r2.cloudflarestorage.com
R2_PUBLIC_URL=https://medias.mondomaine
R2_TRANSFORMATIONS_IMAGES=true     # seulement si l'étape 3 est faite
```

5. **CORS du bucket public** : autoriser `PUT` depuis l'app (envoi direct
   des fichiers par URL signée).

## 7. API — service : api

```
NODE_ENV=production
PORT=3000
TRUST_PROXY=1                      # nombre exact de proxys devant l'API
CORS_ORIGINS=                      # vide tant qu'il n'y a pas de site web
DATABASE_URL=postgresql://...
REDIS_HOST=... REDIS_PORT=... REDIS_PASSWORD=...
APP_DEEP_LINK_SCHEME=dropp
```

**Secrets : nouvelles valeurs pour la production**, jamais celles de
développement. Générer chacune avec `openssl rand -base64 48` :

```
JWT_ACCESS_SECRET=
AUTH_PASSWORD_PEPPER=
AUTH_OTP_PEPPER=
AUTH_VERIFICATION_SECRET=
```

⚠️ `AUTH_PASSWORD_PEPPER` ne doit **plus jamais changer** une fois des
comptes créés : changer le pepper rend tous les mots de passe invalides.
Le conserver dans un coffre (gestionnaire de secrets de l'hébergeur).

Le worker utilise la même `DATABASE_URL` et le même Redis que l'API.

## 8. Déploiement

Ordre au premier lancement :

```bash
pnpm install --frozen-lockfile            # génère aussi Prisma et les contrats
pnpm --filter @dropp/database migrate:deploy
pnpm api:build && pnpm worker:build
pnpm --filter api seed:admin              # premier administrateur (SEED_ADMIN_*)
pnpm api:start                            # node dist/main
pnpm worker:start
```

- Postgres **avec PostGIS** (image `postgis/postgis:17-3.5` en local) et
  Redis 7 avec mot de passe.
- Santé de l'API : `GET https://api.mondomaine/sante` (sans le préfixe `/v1`).
- Une seule instance du worker suffit au lancement ; l'API peut en avoir
  plusieurs (temps réel partagé par l'adaptateur Redis).
- Il n'existe **pas encore de Dockerfile ni de pipeline CI** : à écrire selon
  l'hébergeur choisi (attention aux modules natifs `argon2` et
  `tesseract.js`).

## 9. Application mobile

1. **Clé de signature Android** (une seule fois, à sauvegarder hors du
   dépôt : la perdre empêche toute mise à jour sur le Play Store) :

   ```bash
   keytool -genkey -v -keystore dropp-upload.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

   puis créer `apps/mobile/android/key.properties` (ignoré par git) :

   ```
   storeFile=../../chemin/vers/dropp-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   `storeFile` est relatif à `apps/mobile/android/app`. Sans ce fichier, la
   release est signée avec la clé de debug (refusée par le Play Store).

2. **Build** :

   ```bash
   flutter build appbundle --release \
     --dart-define=API_URL=https://api.mondomaine/v1
   ```

3. **Liens de partage** : l'API renvoie aujourd'hui `dropp://publications/<id>`,
   non cliquable dans WhatsApp et non géré par l'app. Avec le domaine :
   - servir `https://mondomaine/.well-known/assetlinks.json` (empreinte
     SHA-256 de la clé de signature, package `cm.dropp.app`) et
     `https://mondomaine/.well-known/apple-app-site-association` ;
   - faire renvoyer par l'API un lien `https://mondomaine/p/<id>` ;
   - déclarer ce domaine dans l'app (intent-filter `autoVerify` Android,
     Associated Domains iOS) et router `/p/<id>` vers la publication.

## 10. Vérifications finales

- [ ] `GET /sante` répond 200.
- [ ] Inscription → SMS reçu → compte activé.
- [ ] Email donné à l'inscription → code reçu → adresse confirmée.
- [ ] « Mot de passe oublié » avec l'email confirmé → code reçu par email.
- [ ] Publication d'une image par un vendeur → visible dans le fil (R2).
- [ ] Logs du worker : ni `stub` ni erreur `FIREBASE_*` au démarrage.
- [ ] Sauvegardes automatiques de la base activées.
