export default () => ({
  app: {
    name: process.env.APP_NAME ?? 'DROPP API',
    environment: process.env.NODE_ENV ?? 'development',
    port: Number(process.env.PORT ?? 3000),
    trustProxy: Number(process.env.TRUST_PROXY ?? 0),
    corsOrigins: liste(process.env.CORS_ORIGINS),
    deepLinkScheme: process.env.APP_DEEP_LINK_SCHEME ?? 'dropp',
  },

  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET!,
  },

  auth: {
    accessTokenTtlSeconds: dureeEnSecondes(process.env.JWT_ACCESS_TTL ?? '15m'),
    refreshTokenTtlSeconds: dureeEnSecondes(
      process.env.REFRESH_TOKEN_TTL ?? '30d',
    ),
    passwordPepper: process.env.AUTH_PASSWORD_PEPPER!,
    otpPepper: process.env.AUTH_OTP_PEPPER!,
    verificationSecret: process.env.AUTH_VERIFICATION_SECRET!,
    verificationTtlSeconds: dureeEnSecondes(
      process.env.AUTH_VERIFICATION_TTL ?? '15m',
    ),
  },

  database: {
    url: process.env.DATABASE_URL,
    poolMax: Number(process.env.DATABASE_POOL_MAX ?? 10),
  },

  redis: {
    host: process.env.REDIS_HOST ?? 'localhost',
    port: Number(process.env.REDIS_PORT ?? 6379),
    password: process.env.REDIS_PASSWORD!,
    otpTtl: Number(process.env.REDIS_OTP_TTL ?? 300),
    otpCooldown: Number(process.env.REDIS_OTP_COOLDOWN ?? 60),
    otpMaxTentatives: Number(process.env.REDIS_OTP_MAX_TENTATIVES ?? 5),
    otpMaxEnvoisHeure: Number(process.env.REDIS_OTP_MAX_ENVOIS_HEURE ?? 5),
    idempotenceTtl: Number(process.env.REDIS_IDEMPOTENCE_TTL ?? 86400),
  },
});

const SECONDES_PAR_UNITE = { s: 1, m: 60, h: 3_600, d: 86_400 } as const;
type Unite = keyof typeof SECONDES_PAR_UNITE;

function dureeEnSecondes(valeur: string): number {
  const m = /^([1-9]\d*)([smhd])$/.exec(valeur);
  if (!m) throw new Error(`Durée invalide : "${valeur}"`);
  return Number(m[1]) * SECONDES_PAR_UNITE[m[2] as Unite];
}

function liste(valeur: string | undefined): string[] {
  return (valeur ?? '')
    .split(',')
    .map((v) => v.trim())
    .filter((v) => v.length > 0);
}
