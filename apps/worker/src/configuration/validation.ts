import Joi from 'joi';

export const validationSchema = Joi.object({
  APP_NAME: Joi.string().default('DROPP WORKERS'),
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().integer().default(6379),
  REDIS_PASSWORD: Joi.string().required(),

  DATABASE_URL: Joi.string().required(),
  DATABASE_POOL_MAX: Joi.number().default(5)
});
