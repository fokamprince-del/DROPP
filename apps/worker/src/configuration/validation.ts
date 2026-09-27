import Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().integer().default(6379),
  REDIS_PASSWORD: Joi.string().required(),
});
