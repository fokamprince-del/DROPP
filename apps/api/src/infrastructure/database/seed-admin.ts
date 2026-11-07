import 'dotenv/config';
import { PrismaClient } from '@dropp/database';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';

const prisma = new PrismaClient({
  adapter: new PrismaPg({
    connectionString: process.env.DATABASE_URL!,
  }),
});

async function seedAdmin() {
  const telephone = process.env.SEED_ADMIN_TELEPHONE;
  const motDePasse = process.env.SEED_ADMIN_MOT_DE_PASSE;
  const pepper = process.env.AUTH_PASSWORD_PEPPER;

  if (!telephone || !motDePasse || !pepper) {
    console.error(
      'Variables manquantes : SEED_ADMIN_TELEPHONE, SEED_ADMIN_MOT_DE_PASSE, AUTH_PASSWORD_PEPPER',
    );
    process.exit(1);
  }

  const superAdminRole = await prisma.role.findUnique({
    where: { nom: 'SUPER_ADMIN' },
    select: { id: true },
  });

  if (!superAdminRole) {
    console.error(
      'Rôle SUPER_ADMIN introuvable. Assurez-vous que les migrations sont appliquées.',
    );
    process.exit(1);
  }

  const existant = await prisma.utilisateur.findUnique({
    where: { telephone },
    select: { id: true },
  });

  if (existant) {
    console.log(`Un compte avec ce téléphone existe déjà : ${telephone}`);
    process.exit(0);
  }

  const motDePasseHash = await argon2.hash(`${pepper}:${motDePasse}`, {
    type: argon2.argon2id,
    memoryCost: 65_536,
    timeCost: 3,
    parallelism: 4,
  });

  const admin = await prisma.utilisateur.create({
    data: {
      prenom: 'Super',
      nom: 'Admin',
      telephone,
      motDePasseHash,
      statutCompte: 'ACTIF',
      sexe: 'MASCULIN',
      telephoneVerifieLe: new Date(),
      roles: {
        create: { roleId: superAdminRole.id },
      },
    },
    select: { id: true, telephone: true },
  });

  console.log(`Super admin créé : ${admin.telephone} (id: ${admin.id})`);
}

await seedAdmin()
  .catch(console.error)
  .finally(() => prisma.$disconnect());