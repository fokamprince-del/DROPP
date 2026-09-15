export default () => ({
  app: {
    name: process.env.APP_NAME ?? 'DROPP API',
    environment: process.env.NODE_ENV ?? 'development',
    port: Number(process.env.PORT ?? 3000),
  },
});