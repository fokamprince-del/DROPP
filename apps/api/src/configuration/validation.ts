import Joi from 'joi';

const DUREE = /^[1-9]\d*[smhd]$/;

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),

  APP_NAME: Joi.string().trim().min(1).default('DROPP API'),

  PORT: Joi.number().integer().min(1).max(65535).default(3000),

  // Nombre exact de reverse proxys devant l'API.
  // 0 = pas de proxy, 1 = un load balancer, etc.
  // Trop haut = IP falsifiable via X-Forwarded-For.
  TRUST_PROXY: Joi.number().integer().min(0).max(10).default(0),

  // Origines CORS autorisées, séparées par des virgules.
  // Chaque élément doit être une origine exacte (schéma + hôte + port).
  // Exemple : https://admin.dropp.cm,https://www.dropp.cm
  // Vide = CORS désactivé (apps mobiles, pas de navigateur).
  CORS_ORIGINS: Joi.string()
    .allow('')
    .default('')
    .custom((valeur: string, aide) => {
      for (const brut of valeur.split(',')) {
        const origine = brut.trim();
        if (origine === '') continue;
        try {
          if (new URL(origine).origin !== origine) {
            return aide.error('any.invalid');
          }
        } catch {
          return aide.error('any.invalid');
        }
      }
      return valeur;
    }, 'liste origines CORS'),

  DATABASE_URL: Joi.string()
    .uri({ scheme: ['postgresql', 'postgres'] })
    .required(),

  DATABASE_POOL_MAX: Joi.number().integer().min(1).max(100).default(10),

  // Minimum 32 caractères (256 bits).
  // Générer : openssl rand -base64 48
  JWT_ACCESS_SECRET: Joi.string().min(32).required(),

  JWT_ACCESS_TTL: Joi.string().pattern(DUREE).default('15m'),

  REFRESH_TOKEN_TTL: Joi.string().pattern(DUREE).default('30d'),

  // Pepper mot de passe : hachage argon2id côté serveur.
  // Générer : openssl rand -base64 48
  AUTH_PASSWORD_PEPPER: Joi.string().min(32).required(),

  // Pepper OTP : HMAC-SHA256 du code + destination.
  // Générer : openssl rand -base64 48
  AUTH_OTP_PEPPER: Joi.string().min(32).required(),

  // app sheme de l'application
  APP_DEEP_LINK_SCHEME: Joi.string().default('dropp'),

  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().integer().min(1).max(65535).default(6379),
  REDIS_PASSWORD: Joi.string().required(),
  REDIS_MAX_MEMORY: Joi.string().default('256mb'),
  REDIS_OTP_TTL: Joi.number().integer().min(60).max(3600).default(300),
  REDIS_OTP_COOLDOWN: Joi.number().integer().min(30).max(300).default(60),
  REDIS_OTP_MAX_TENTATIVES: Joi.number().integer().min(3).max(10).default(5),
  REDIS_OTP_MAX_ENVOIS_HEURE: Joi.number().integer().min(3).max(20).default(5),
  REDIS_IDEMPOTENCE_TTL: Joi.number()
    .integer()
    .min(3600)
    .max(604800)
    .default(86400),
  AUTH_VERIFICATION_SECRET: Joi.string().min(32).required(),
  AUTH_VERIFICATION_TTL: Joi.string().pattern(DUREE).default('15m'),

  // Délai de paiement d'une commande avant annulation auto (stock libéré).
  COMMANDE_DELAI_PAIEMENT_MINUTES: Joi.number()
    .integer()
    .min(5)
    .max(1440)
    .default(30),

  // Stockage : "stub" en dev, "r2" = Cloudflare R2 (clés R2_* obligatoires).
  STOCKAGE_DRIVER: Joi.string().valid('stub', 'r2').default('stub'),
  R2_ACCOUNT_ID: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().required(),
  }),
  R2_ACCESS_KEY_ID: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().required(),
  }),
  R2_SECRET_ACCESS_KEY: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().required(),
  }),
  R2_BUCKET: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().required(),
  }),
  // Bucket SANS accès public : pièces d'identité KYC, messagerie, contenus
  // réservés aux abonnés (lus par URL signée). Obligatoire en production.
  R2_BUCKET_PRIVE: Joi.string()
    .allow('')
    .default('')
    .when('STOCKAGE_DRIVER', {
      is: 'r2',
      then: Joi.when('NODE_ENV', {
        is: 'production',
        then: Joi.string().required().invalid(Joi.ref('R2_BUCKET')),
      }),
    }),
  R2_ENDPOINT: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().uri({ scheme: ['https'] }).required(),
  }),
  R2_PUBLIC_URL: Joi.string().allow('').when('STOCKAGE_DRIVER', {
    is: 'r2',
    then: Joi.string().uri({ scheme: ['https'] }).required(),
  }),
  R2_UPLOAD_URL_TTL: Joi.number().integer().min(60).max(3600).default(600),
  // true uniquement avec un domaine perso + Transformations activées (pas r2.dev).
  R2_TRANSFORMATIONS_IMAGES: Joi.boolean().default(false),
});
