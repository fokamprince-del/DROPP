export default () => ({
  app: {
    name: process.env.APP_NAME ?? 'DROPP WORKERS',
    environement: process.env.NODE_ENV ?? 'development',
  },
  redis: {
    host: process.env.REDIS_HOST ?? 'localhost',
    port: process.env.REDIS_PORT ?? '6379',
    password: process.env.REDIS_PASSWORD!,
  },
  email: {
    resendApiKey: process.env.RESEND_API_KEY || undefined,
    expediteur: process.env.EMAIL_EXPEDITEUR ?? 'DROPP <no-reply@dropp.cm>',
    repondreA: process.env.EMAIL_REPONDRE_A || undefined,
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || undefined,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || undefined,
    // Les retours à la ligne de la clé sont échappés dans le .env.
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  },
  database: {
    url: process.env.DATABASE_URL!,
    poolMax: process.env.DATABASE_POOL_MAX ?? 5
  },
  // stockage: {
  //   driver: process.env.STOCKAGE_DRIVER ?? 'stub',
  //   r2: {
  //     accessKeyId: process.env.R2_ACCESS_KEY_ID,
  //     secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  //     bucket: process.env.R2_BUCKET,
  //     bucketPrive: process.env.R2_BUCKET_PRIVE!,
  //     endpoint: process.env.R2_ENDPOINT
  //   }
  // }
});
