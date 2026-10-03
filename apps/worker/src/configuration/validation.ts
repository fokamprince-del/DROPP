import Joi from 'joi';

export const validationSchema = Joi.object({
  APP_NAME: Joi.string().default('DROPP WORKERS'),
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().integer().default(6379),
  REDIS_PASSWORD: Joi.string().required(),

  // Resend (emails). Vide = stub en dev.
  RESEND_API_KEY: Joi.string()
    .allow('')
    .pattern(/^re_/)
    .message('RESEND_API_KEY doit commencer par "re_".')
    .default(''),
  // Doit utiliser un domaine vérifié dans Resend (sinon erreur 403).
  EMAIL_EXPEDITEUR: Joi.string().default('DROPP <no-reply@dropp.cm>'),
  EMAIL_REPONDRE_A: Joi.string().email().allow('').default(''),

  // Firebase Cloud Messaging (push). Vide = stub en dev.
  // Console Firebase → Paramètres du projet → Comptes de service → Générer une clé privée.
  FIREBASE_PROJECT_ID: Joi.string().allow('').default(''),
  FIREBASE_CLIENT_EMAIL: Joi.string().allow('').when('FIREBASE_PROJECT_ID', {
    is: Joi.string().min(1),
    then: Joi.string().email().required(),
  }),
  FIREBASE_PRIVATE_KEY: Joi.string().allow('').when('FIREBASE_PROJECT_ID', {
    is: Joi.string().min(1),
    then: Joi.string().min(100).required(),
  }),

  // STOCKAGE_DRIVER: Joi.string().valid('stub', 'r2').default('stub'),
  // R2_ACCESS_KEY_ID: Joi.string().allow('').when('STOCKAGE_DRIVER', {
  //   is: 'r2',
  //   then: Joi.string().required(),
  // }),
  // R2_SECRET_ACCESS_KEY: Joi.string().allow('').when('STOCKAGE_DRIVER', {
  //   is: 'r2',
  //   then: Joi.string().required(),
  // }),
  // R2_BUCKET: Joi.string().allow('').when('STOCKAGE_DRIVER', {
  //   is: 'r2',
  //   then: Joi.string().required(),
  // }),
  // // Bucket SANS accès public pour la messagerie (lu par URL signée).
  // R2_BUCKET_PRIVE: Joi.string().allow('').default(''),
  // R2_ENDPOINT: Joi.string().allow('').when('STOCKAGE_DRIVER', {
  //   is: 'r2',
  //   then: Joi.string().uri({ scheme: ['https'] }).required(),
  // }),

  DATABASE_URL: Joi.string().required(),
  DATABASE_POOL_MAX: Joi.number().default(5)
});
