import { defineConfig, env } from 'prisma/config';
import { resolve } from 'node:path'
import dotenv from 'dotenv';

dotenv.config({ path: resolve(import.meta.dirname, '../../.env') });


export default defineConfig({
  schema: 'prisma',

  migrations: {
    path: 'prisma/migrations',
  },

  datasource: {
    url: env('DATABASE_URL'),
  },
});