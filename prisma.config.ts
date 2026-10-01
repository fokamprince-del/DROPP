import 'dotenv/config';
import { defineConfig } from 'prisma/config';

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
