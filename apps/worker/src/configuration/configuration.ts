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
});
