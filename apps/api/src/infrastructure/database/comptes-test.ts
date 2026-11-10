import type { PrismaClient } from '@dropp/database';
import * as argon2 from 'argon2';

/**
 * Comptes de test déjà activés (téléphone vérifié), pour la bêta fermée sans
 * OTP. Chaque compte n'est créé que si ses deux variables (téléphone + mot
 * de passe) sont définies ; un compte dont le téléphone existe déjà est
 * laissé tel quel (idempotent, aucune mise à jour).
 *  - CLIENT  : client simple ;
 *  - VENDEUR : client + vendeur validé (KYC VALIDE) + boutique ACTIVE ;
 *  - DEV     : idem vendeur, compte du développeur.
 */
interface CompteTest {
  libelle: string;
  prefixeEnv: string;
  prenom: string;
  nom: string;
  pseudo: string;
  sexe: 'MASCULIN' | 'FEMININ';
  boutique?: string;
}

const COMPTES: CompteTest[] = [
  {
    libelle: 'Client',
    prefixeEnv: 'SEED_CLIENT',
    prenom: 'Client',
    nom: 'Test',
    pseudo: 'client_test',
    sexe: 'MASCULIN',
  },
  {
    libelle: 'Vendeur',
    prefixeEnv: 'SEED_VENDEUR',
    prenom: 'Vendeur',
    nom: 'Test',
    pseudo: 'vendeur_test',
    sexe: 'FEMININ',
    boutique: 'Boutique Test',
  },
  {
    libelle: 'Dev',
    prefixeEnv: 'SEED_DEV',
    prenom: 'Dev',
    nom: 'DROPP',
    pseudo: 'dev_dropp',
    sexe: 'MASCULIN',
    boutique: 'Boutique Dev',
  },
];

// Mêmes paramètres que MotDePasseService : le login vérifiera ce hash.
const ARGON2_OPTIONS = {
  type: argon2.argon2id as 0 | 1 | 2,
  memoryCost: 65_536,
  timeCost: 3,
  parallelism: 4,
};

export async function creerComptesTest(
  prisma: PrismaClient,
  env: NodeJS.ProcessEnv = process.env,
  log: (message: string) => void = console.log,
): Promise<void> {
  const pepper = env.AUTH_PASSWORD_PEPPER;
  if (!pepper) {
    log('Comptes de test ignorés : AUTH_PASSWORD_PEPPER manquant.');
    return;
  }

  for (const compte of COMPTES) {
    const telephone = env[`${compte.prefixeEnv}_TELEPHONE`]?.trim();
    const motDePasse = env[`${compte.prefixeEnv}_MOT_DE_PASSE`];
    if (!telephone || !motDePasse) continue;

    const existant = await prisma.utilisateur.findUnique({
      where: { telephone },
      select: { id: true },
    });
    if (existant) {
      log(`${compte.libelle} déjà présent : ${telephone}`);
      continue;
    }

    // Pseudo déjà pris (compte supprimé, autre seed…) : on s'en passe.
    const pseudoPris =
      (await prisma.utilisateur.findUnique({
        where: { pseudo: compte.pseudo },
        select: { id: true },
      })) !== null;

    const maintenant = new Date();
    const cree = await prisma.utilisateur.create({
      data: {
        prenom: compte.prenom,
        nom: compte.nom,
        pseudo: pseudoPris ? null : compte.pseudo,
        telephone,
        motDePasseHash: await argon2.hash(
          `${pepper}:${motDePasse}`,
          ARGON2_OPTIONS,
        ),
        statutCompte: 'ACTIF',
        sexe: compte.sexe,
        telephoneVerifieLe: maintenant,
        client: { create: {} },
        ...(compte.boutique && {
          vendeur: {
            create: {
              statutVendeur: 'ACTIF',
              biographie: `Compte ${compte.libelle.toLowerCase()} de test.`,
              dossiersKyc: {
                create: {
                  statut: 'VALIDE',
                  dateValidation: maintenant,
                  consentementLe: maintenant,
                },
              },
              boutique: {
                create: {
                  nom: compte.boutique,
                  description: 'Boutique de démonstration pour la bêta.',
                  ville: 'Douala',
                  statut: 'ACTIVE',
                },
              },
            },
          },
        }),
      },
      select: { id: true },
    });
    log(`${compte.libelle} créé : ${telephone} (id: ${cree.id})`);
  }
}
