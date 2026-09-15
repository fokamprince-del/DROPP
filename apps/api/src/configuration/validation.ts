import Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),

  APP_NAME: Joi.string()
    .trim()
    .min(1)
    .default('DROPP API'),

  PORT: Joi.number()
    .integer()
    .min(1)
    .max(65535)
    .default(3000),
  DATABASE_URL: Joi.string()
    .uri({
      scheme: ['postgresql'],
    })
    .required(),
});