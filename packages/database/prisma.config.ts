import { defineConfig } from 'prisma/config';
import { resolve } from 'node:path';
import dotenv from 'dotenv';

dotenv.config({ path: resolve(import.meta.dirname, '../../.env') });

// DATABASE_URL n'est requise que pour les commandes qui parlent à la base
// (migrate, studio…). `prisma generate` doit marcher sans .env, sur un clone
// neuf ou en CI : on ne déclare la datasource que si l'URL est définie.
const url = process.env.DATABASE_URL;

export default defineConfig({
  schema: 'prisma',

  migrations: {
    path: 'prisma/migrations',
  },

  ...(url && { datasource: { url } }),
});
