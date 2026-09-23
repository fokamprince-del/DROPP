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
});
