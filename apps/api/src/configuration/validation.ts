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
  JWT_ACCESS_SECRET: Joi.string()
    .min(32)
    .required(),
  JWT_ACCESS_TTL: Joi.string()
    .pattern(/^\d+[smhd]$/)
    .default('15m'),
  JWT_REFRESH_TTL: Joi.string()
    .pattern(/^\d+[smhd]$/)
    .default('30d'),
});