import { randomBytes, randomUUID } from 'node:crypto';

import { DeleteObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import type { PrismaClient, TypePublication } from '@dropp/database';
import * as argon2 from 'argon2';

/**
 * Contenu de démonstration pour le fil d'actualité : boutiques fictives,
 * produits (avec variantes et photos), publications image / carrousel et
 * reels vidéo, plus quelques likes, commentaires et abonnements.
 *
 * Les fichiers sont téléchargés depuis des sources libres (DummyJSON pour
 * les photos produits, test-videos.co.uk / samplelib pour les vidéos) puis
 * envoyés dans le bucket R2 public, comme le ferait l'app.
 *
 * Idempotent : une boutique de démo déjà présente est laissée telle quelle ;
 * une boutique dont la création échoue en cours de route est supprimée pour
 * être retentée proprement au lancement suivant.
 *
 * Lancé automatiquement au démarrage de l'API si SEED_DEMO=true
 * (ComptesTestService), ou à la main via seed-demo.ts.
 */

interface Contexte {
  prisma: PrismaClient;
  s3: S3Client | null;
  bucket: string | undefined;
  log: (message: string) => void;
}

function contexte(prisma: PrismaClient, env: NodeJS.ProcessEnv, log: (m: string) => void): Contexte {
  const bucket = env.R2_BUCKET;
  const s3 =
    env.STOCKAGE_DRIVER === 'r2' && bucket
      ? new S3Client({
          region: 'auto',
          endpoint: env.R2_ENDPOINT!,
          credentials: {
            accessKeyId: env.R2_ACCESS_KEY_ID!,
            secretAccessKey: env.R2_SECRET_ACCESS_KEY!,
          },
          requestChecksumCalculation: 'WHEN_REQUIRED',
          responseChecksumValidation: 'WHEN_REQUIRED',
        })
      : null;
  return { prisma, s3, bucket, log };
}

// ─── Stockage R2 ────────────────────────────────────────────────────────────

const EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'video/mp4': 'mp4',
};

/** Fichiers déjà téléchargés pendant ce lancement (une même vidéo sert plusieurs fois). */
const cacheTelechargements = new Map<string, { corps: Buffer; typeMime: string }>();

async function telecharger(url: string) {
  const enCache = cacheTelechargements.get(url);
  if (enCache) return enCache;
  const reponse = await fetch(url, { signal: AbortSignal.timeout(60_000) });
  if (!reponse.ok) throw new Error(`Téléchargement ${url} : HTTP ${reponse.status}`);
  const typeMime = (reponse.headers.get('content-type') ?? '').split(';')[0].trim();
  if (!EXTENSIONS[typeMime]) throw new Error(`Type non pris en charge (${typeMime}) : ${url}`);
  const fichier = { corps: Buffer.from(await reponse.arrayBuffer()), typeMime };
  cacheTelechargements.set(url, fichier);
  return fichier;
}

/** Télécharge un fichier et l'envoie dans R2 ; renvoie la ligne Media à créer. */
async function envoyer(ctx: Contexte, url: string, repertoire: string, duree?: number) {
  const { corps, typeMime } = await telecharger(url);
  const cleStockage = `${repertoire}/${randomUUID()}.${EXTENSIONS[typeMime]}`;
  await ctx.s3!.send(
    new PutObjectCommand({
      Bucket: ctx.bucket,
      Key: cleStockage,
      Body: corps,
      ContentType: typeMime,
      CacheControl: 'public, max-age=31536000, immutable',
    }),
  );
  return {
    typeMedia: typeMime.startsWith('video/') ? ('VIDEO' as const) : ('IMAGE' as const),
    cleStockage,
    typeMime,
    taille: BigInt(corps.length),
    duree: duree ?? null,
    statutTraitement: 'PRET' as const,
  };
}

// ─── Données fictives ───────────────────────────────────────────────────────

const IMG = 'https://cdn.dummyjson.com/product-images';
const photos = (chemin: string, n: number) =>
  Array.from({ length: n }, (_, i) => `${IMG}/${chemin}/${i + 1}.webp`);

const VIDEOS = {
  lapin: { url: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4', duree: 10 },
  meduses: { url: 'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4', duree: 10 },
  sintel: { url: 'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4', duree: 10 },
  court: { url: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4', duree: 5 },
} as const;

interface ProduitDemo {
  nom: string;
  description: string;
  categorie: string;
  prix: number;
  photos: string[];
  /** Attributs de chaque variante ; prix optionnel (sinon prix de base). */
  variantes: Array<{ attributs: Record<string, string>; prix?: number; stock: number }>;
}

interface PublicationDemo {
  type: TypePublication;
  contenu: string;
  /** Index des produits de la boutique identifiés dans la publication. */
  produits: number[];
  /** Images : URL ; vidéo : clé de VIDEOS. */
  medias: string[];
  video?: keyof typeof VIDEOS;
  ilYaHeures: number;
  vues: number;
}

interface BoutiqueDemo {
  pseudo: string;
  telephone: string;
  prenom: string;
  nom: string;
  sexe: 'MASCULIN' | 'FEMININ';
  boutique: string;
  description: string;
  biographie: string;
  ville: string;
  quartier: string;
  logo: string;
  produits: ProduitDemo[];
  publications: PublicationDemo[];
}

const tailles = (stock: number, ...t: string[]) => t.map((taille) => ({ attributs: { taille }, stock }));

const BOUTIQUES: BoutiqueDemo[] = [
  {
    pseudo: 'demo_kmer_style',
    telephone: '+237699000001',
    prenom: 'Aïcha',
    nom: 'Ngo Bassa',
    sexe: 'FEMININ',
    boutique: 'Kmer Style',
    description: 'Mode urbaine et tenues de soirée, livrées partout à Douala.',
    biographie: 'Styliste passionnée, je sélectionne des pièces tendance à petits prix ✨',
    ville: 'Douala',
    quartier: 'Akwa',
    logo: `${IMG}/womens-dresses/dress-pea/1.webp`,
    produits: [
      {
        nom: 'Robe longue de soirée noire',
        description: 'Robe fluide et élégante, idéale pour mariages et soirées. Tissu léger qui ne froisse pas.',
        categorie: 'Robes',
        prix: 25_000,
        photos: photos("womens-dresses/black-women's-gown", 4),
        variantes: tailles(5, 'S', 'M', 'L', 'XL'),
      },
      {
        nom: 'Chemise à carreaux homme',
        description: 'Chemise en coton à carreaux, coupe ajustée. Parfaite pour le bureau comme pour le week-end.',
        categorie: 'Chemises',
        prix: 9_500,
        photos: photos('mens-shirts/man-plaid-shirt', 4),
        variantes: tailles(8, 'M', 'L', 'XL'),
      },
      {
        nom: 'Baskets montantes rouge et noir',
        description: 'Baskets montantes confortables, semelle antidérapante. Le classique qui va avec tout.',
        categorie: 'Chaussures',
        prix: 32_000,
        photos: photos('mens-shoes/nike-air-jordan-1-red-and-black', 4),
        variantes: ['40', '41', '42', '43', '44'].map((pointure) => ({ attributs: { pointure }, stock: 3 })),
      },
      {
        nom: 'Sac à main en cuir bleu',
        description: 'Sac à main en simili-cuir, deux compartiments et bandoulière amovible.',
        categorie: 'Sacs',
        prix: 18_000,
        photos: photos("womens-bags/blue-women's-handbag", 3),
        variantes: [{ attributs: { couleur: 'Bleu' }, stock: 6 }],
      },
    ],
    publications: [
      {
        type: 'CARROUSEL',
        contenu: 'Nouvelle collection soirée 🖤 Disponible du S au XL. Livraison à Douala en 24 h !',
        produits: [0],
        medias: photos("womens-dresses/black-women's-gown", 4),
        ilYaHeures: 3,
        vues: 842,
      },
      {
        type: 'VIDEO',
        contenu: 'Essayage en direct de nos baskets 🔥 Qui veut la paire ? #sneakers #douala',
        produits: [2],
        medias: [],
        video: 'lapin',
        ilYaHeures: 9,
        vues: 2310,
      },
      {
        type: 'IMAGE',
        contenu: 'Le sac bleu est de retour en stock 💙 Premières arrivées, premières servies.',
        produits: [3],
        medias: [`${IMG}/womens-bags/blue-women's-handbag/2.webp`],
        ilYaHeures: 30,
        vues: 415,
      },
      {
        type: 'CARROUSEL',
        contenu: 'Look du week-end pour ces messieurs : chemise à carreaux + baskets 👌',
        produits: [1, 2],
        medias: [...photos('mens-shirts/man-plaid-shirt', 2), `${IMG}/mens-shoes/nike-air-jordan-1-red-and-black/2.webp`],
        ilYaHeures: 52,
        vues: 678,
      },
    ],
  },
  {
    pseudo: 'demo_belle_ebene',
    telephone: '+237699000002',
    prenom: 'Laure',
    nom: 'Mbarga',
    sexe: 'FEMININ',
    boutique: 'Belle Ébène Cosmétiques',
    description: 'Soins du corps, maquillage et parfums pour sublimer toutes les peaux.',
    biographie: 'Esthéticienne diplômée. Conseils beauté gratuits en message privé 💄',
    ville: 'Yaoundé',
    quartier: 'Bastos',
    logo: `${IMG}/beauty/red-lipstick/1.webp`,
    produits: [
      {
        nom: 'Rouge à lèvres mat longue tenue',
        description: 'Rouge à lèvres mat qui tient jusqu’à 12 h, sans dessécher les lèvres.',
        categorie: 'Maquillage',
        prix: 4_500,
        photos: photos('beauty/red-lipstick', 1),
        variantes: [
          { attributs: { teinte: 'Rouge passion' }, stock: 20 },
          { attributs: { teinte: 'Bordeaux' }, stock: 12 },
        ],
      },
      {
        nom: 'Palette de fards à paupières',
        description: '12 teintes mates et nacrées avec miroir intégré. Pigmentation intense.',
        categorie: 'Maquillage',
        prix: 8_000,
        photos: photos('beauty/eyeshadow-palette-with-mirror', 1),
        variantes: [{ attributs: { format: 'Standard' }, stock: 15 }],
      },
      {
        nom: 'Gel douche au beurre de karité',
        description: 'Nourrit et adoucit la peau grâce au beurre de karité. Flacon de 500 ml.',
        categorie: 'Soins',
        prix: 3_500,
        photos: photos('skin-care/olay-ultra-moisture-shea-butter-body-wash', 3),
        variantes: [
          { attributs: { contenance: '500 ml' }, stock: 30 },
          { attributs: { contenance: '1 L' }, prix: 6_000, stock: 10 },
        ],
      },
      {
        nom: 'Eau de parfum florale',
        description: 'Notes de jasmin et de rose, sillage doux et durable. Flacon de 50 ml.',
        categorie: 'Parfums',
        prix: 22_000,
        photos: photos('fragrances/gucci-bloom-eau-de', 3),
        variantes: [{ attributs: { contenance: '50 ml' }, stock: 7 }],
      },
    ],
    publications: [
      {
        type: 'VIDEO',
        contenu: 'Tuto maquillage soirée en 30 secondes ✨ Tous les produits sont en boutique.',
        produits: [0, 1],
        medias: [],
        video: 'meduses',
        ilYaHeures: 2,
        vues: 3120,
      },
      {
        type: 'IMAGE',
        contenu: 'Notre best-seller : le rouge mat qui tient toute la journée 💋',
        produits: [0],
        medias: [`${IMG}/beauty/red-lipstick/1.webp`],
        ilYaHeures: 14,
        vues: 960,
      },
      {
        type: 'CARROUSEL',
        contenu: 'Routine douceur pour les peaux sèches 🌿 Le karité, notre meilleur allié.',
        produits: [2],
        medias: photos('skin-care/olay-ultra-moisture-shea-butter-body-wash', 3),
        ilYaHeures: 40,
        vues: 512,
      },
      {
        type: 'IMAGE',
        contenu: 'Arrivage parfums 🌸 Stock limité, réservez le vôtre en message.',
        produits: [3],
        medias: [`${IMG}/fragrances/gucci-bloom-eau-de/2.webp`],
        ilYaHeures: 70,
        vues: 388,
      },
    ],
  },
  {
    pseudo: 'demo_techzone',
    telephone: '+237699000003',
    prenom: 'Junior',
    nom: 'Fotso',
    sexe: 'MASCULIN',
    boutique: 'TechZone 237',
    description: 'Smartphones, écouteurs et accessoires garantis 6 mois.',
    biographie: 'Tech addict. Produits testés avant chaque livraison 📱🎧',
    ville: 'Douala',
    quartier: 'Bonapriso',
    logo: `${IMG}/mobile-accessories/apple-airpods/1.webp`,
    produits: [
      {
        nom: 'Écouteurs sans fil Bluetooth',
        description: 'Écouteurs sans fil avec boîtier de charge, 20 h d’autonomie, appels mains libres.',
        categorie: 'Audio',
        prix: 15_000,
        photos: photos('mobile-accessories/apple-airpods', 3),
        variantes: [{ attributs: { couleur: 'Blanc' }, stock: 25 }],
      },
      {
        nom: 'Smartphone 128 Go reconditionné',
        description: 'Smartphone reconditionné grade A, batterie neuve, garanti 6 mois.',
        categorie: 'Smartphones',
        prix: 145_000,
        photos: photos('smartphones/iphone-13-pro', 3),
        variantes: [
          { attributs: { stockage: '128 Go', couleur: 'Graphite' }, stock: 2 },
          { attributs: { stockage: '256 Go', couleur: 'Graphite' }, prix: 175_000, stock: 1 },
        ],
      },
      {
        nom: 'Chargeur rapide USB-C',
        description: 'Chargeur 20 W avec câble USB-C de 1 m. Recharge 50 % en 30 minutes.',
        categorie: 'Accessoires',
        prix: 5_000,
        photos: photos('mobile-accessories/apple-iphone-charger', 2),
        variantes: [{ attributs: { puissance: '20 W' }, stock: 40 }],
      },
      {
        nom: 'Montre bracelet cuir marron',
        description: 'Montre analogique, bracelet en cuir véritable, étanche 3 ATM.',
        categorie: 'Montres',
        prix: 19_500,
        photos: photos('mens-watches/brown-leather-belt-watch', 3),
        variantes: [{ attributs: { couleur: 'Marron' }, stock: 9 }],
      },
    ],
    publications: [
      {
        type: 'VIDEO',
        contenu: 'Unboxing du jour 📦 Smartphone reconditionné grade A, comme neuf !',
        produits: [1],
        medias: [],
        video: 'sintel',
        ilYaHeures: 5,
        vues: 1875,
      },
      {
        type: 'CARROUSEL',
        contenu: 'Pack mobilité : écouteurs + chargeur rapide 🔌 -10 % si vous prenez les deux.',
        produits: [0, 2],
        medias: [...photos('mobile-accessories/apple-airpods', 2), `${IMG}/mobile-accessories/apple-iphone-charger/1.webp`],
        ilYaHeures: 20,
        vues: 744,
      },
      {
        type: 'IMAGE',
        contenu: 'L’élégance au poignet ⌚ Bracelet en cuir véritable.',
        produits: [3],
        medias: [`${IMG}/mens-watches/brown-leather-belt-watch/2.webp`],
        ilYaHeures: 60,
        vues: 302,
      },
      {
        type: 'VIDEO',
        contenu: 'Test d’autonomie des écouteurs : verdict en 5 secondes 😅',
        produits: [0],
        medias: [],
        video: 'court',
        ilYaHeures: 96,
        vues: 1290,
      },
    ],
  },
  {
    pseudo: 'demo_maison_deco',
    telephone: '+237699000004',
    prenom: 'Paul',
    nom: 'Tchoumi',
    sexe: 'MASCULIN',
    boutique: 'Maison & Déco Bafoussam',
    description: 'Décoration, plantes et accessoires pour un intérieur chaleureux.',
    biographie: 'On rend votre maison plus belle, un objet à la fois 🪴',
    ville: 'Bafoussam',
    quartier: 'Tamdja',
    logo: `${IMG}/home-decoration/plant-pot/1.webp`,
    produits: [
      {
        nom: 'Pot de fleurs en céramique',
        description: 'Pot en céramique émaillée avec soucoupe, diamètre 20 cm.',
        categorie: 'Décoration',
        prix: 7_500,
        photos: photos('home-decoration/plant-pot', 4),
        variantes: [
          { attributs: { couleur: 'Blanc' }, stock: 10 },
          { attributs: { couleur: 'Terracotta' }, stock: 8 },
        ],
      },
      {
        nom: 'Lampe de chevet design',
        description: 'Lampe de table à abat-jour en tissu, ampoule LED fournie.',
        categorie: 'Décoration',
        prix: 12_000,
        photos: photos('home-decoration/table-lamp', 1),
        variantes: [{ attributs: { couleur: 'Beige' }, stock: 6 }],
      },
      {
        nom: 'Plante décorative artificielle',
        description: 'Plante artificielle réaliste en pot, aucun entretien. Hauteur 45 cm.',
        categorie: 'Décoration',
        prix: 9_000,
        photos: photos('home-decoration/house-showpiece-plant', 3),
        variantes: [{ attributs: { hauteur: '45 cm' }, stock: 12 }],
      },
      {
        nom: 'Lunettes de soleil classiques',
        description: 'Lunettes de soleil unisexes, verres polarisés UV400.',
        categorie: 'Accessoires',
        prix: 6_500,
        photos: photos('sunglasses/classic-sun-glasses', 3),
        variantes: [{ attributs: { couleur: 'Noir' }, stock: 15 }],
      },
    ],
    publications: [
      {
        type: 'CARROUSEL',
        contenu: 'Coin lecture cosy 🛋️ Lampe + plante = ambiance garantie.',
        produits: [1, 2],
        medias: [`${IMG}/home-decoration/table-lamp/1.webp`, ...photos('home-decoration/house-showpiece-plant', 2)],
        ilYaHeures: 7,
        vues: 530,
      },
      {
        type: 'IMAGE',
        contenu: 'Nos pots en céramique existent en blanc et terracotta 🪴',
        produits: [0],
        medias: [`${IMG}/home-decoration/plant-pot/2.webp`],
        ilYaHeures: 26,
        vues: 290,
      },
      {
        type: 'VIDEO',
        contenu: 'Avant / après : on transforme un salon en 10 secondes ✨',
        produits: [0, 1, 2],
        medias: [],
        video: 'lapin',
        ilYaHeures: 48,
        vues: 1650,
      },
    ],
  },
];

const CATEGORIES: Record<string, string[]> = {
  Mode: ['Robes', 'Chemises', 'Chaussures', 'Sacs', 'Montres', 'Accessoires'],
  Beauté: ['Maquillage', 'Soins', 'Parfums'],
  Électronique: ['Smartphones', 'Audio'],
  Maison: ['Décoration'],
};

const COMMENTAIRES = [
  'Trop beau 😍',
  'C’est combien la livraison à Yaoundé ?',
  'Disponible en d’autres couleurs ?',
  'J’ai commandé la semaine dernière, très satisfaite 👌',
  'Je prends ! Je vous écris en privé.',
  'La qualité est vraiment top 🔥',
  'Vous livrez le dimanche ?',
  'Magnifique, bravo 👏',
];

// ─── Logique ────────────────────────────────────────────────────────────────

/** Sous-catégorie → id, créées si absentes (parent compris). */
async function preparerCategories({ prisma }: Contexte) {
  const ids = new Map<string, string>();
  for (const [parent, enfants] of Object.entries(CATEGORIES)) {
    const p =
      (await prisma.categorie.findFirst({ where: { nom: parent, parentId: null } })) ??
      (await prisma.categorie.create({ data: { nom: parent } }));
    for (const nom of enfants) {
      // « Accessoires » est sous Mode ; on réutilise toute catégorie existante du même nom.
      const c =
        (await prisma.categorie.findFirst({ where: { nom } })) ??
        (await prisma.categorie.create({ data: { nom, parentId: p.id } }));
      ids.set(nom, c.id);
    }
  }
  return ids;
}

async function supprimerBoutiques({ prisma, s3, bucket, log }: Contexte, pseudos: string[]) {
  const utilisateurs = await prisma.utilisateur.findMany({
    where: { pseudo: { in: pseudos } },
    select: { id: true, pseudo: true, photoProfilCle: true, vendeur: { select: { boutique: { select: { logoCle: true } } } } },
  });
  for (const u of utilisateurs) {
    const medias = await prisma.media.findMany({
      where: {
        OR: [
          { mediaProduits: { some: { produit: { boutiqueId: u.id } } } },
          { mediaPublications: { some: { publication: { boutiqueId: u.id } } } },
        ],
      },
      select: { id: true, cleStockage: true },
    });
    const cles = [...medias.map((m) => m.cleStockage), u.vendeur?.boutique?.logoCle].filter(
      (c): c is string => !!c,
    );
    await prisma.$transaction([
      prisma.publication.deleteMany({ where: { boutiqueId: u.id } }),
      prisma.articlePanier.deleteMany({ where: { varianteProduit: { produit: { boutiqueId: u.id } } } }),
      prisma.produit.deleteMany({ where: { boutiqueId: u.id } }),
      prisma.media.deleteMany({ where: { id: { in: medias.map((m) => m.id) } } }),
      prisma.dossierKyc.deleteMany({ where: { vendeurId: u.id } }),
      prisma.utilisateur.delete({ where: { id: u.id } }),
    ]);
    if (s3) {
      for (const cle of cles) {
        await s3.send(new DeleteObjectCommand({ Bucket: bucket, Key: cle })).catch(() => undefined);
      }
    }
    log(`Supprimé : ${u.pseudo} (${cles.length} fichiers)`);
  }
}

async function creerBoutique(ctx: Contexte, b: BoutiqueDemo, categories: Map<string, string>, hash: string) {
  const { prisma } = ctx;
  const maintenant = new Date();
  const { id } = await prisma.utilisateur.create({
    data: {
      prenom: b.prenom,
      nom: b.nom,
      pseudo: b.pseudo,
      telephone: b.telephone,
      motDePasseHash: hash,
      statutCompte: 'ACTIF',
      sexe: b.sexe,
      telephoneVerifieLe: maintenant,
      client: { create: {} },
      vendeur: {
        create: {
          statutVendeur: 'ACTIF',
          biographie: b.biographie,
          dossiersKyc: {
            create: { statut: 'VALIDE', dateValidation: maintenant, consentementLe: maintenant },
          },
          boutique: {
            create: {
              nom: b.boutique,
              description: b.description,
              biographie: b.biographie,
              ville: b.ville,
              quartier: b.quartier,
              statut: 'ACTIVE',
            },
          },
        },
      },
    },
    select: { id: true },
  });

  const logo = await envoyer(ctx, b.logo, `boutiques/${id}/logo`);
  await prisma.boutique.update({ where: { id }, data: { logoCle: logo.cleStockage } });

  const produitIds: string[] = [];
  for (const [i, p] of b.produits.entries()) {
    const produitId = randomUUID();
    const medias = [];
    for (const url of p.photos) {
      medias.push(await envoyer(ctx, url, `boutiques/${id}/produits/${produitId}/images`));
    }
    await prisma.produit.create({
      data: {
        id: produitId,
        boutiqueId: id,
        categorieId: categories.get(p.categorie)!,
        nom: p.nom,
        description: p.description,
        statut: 'PUBLIE',
        prixBase: p.prix,
        dateCreation: new Date(Date.now() - (i + 1) * 86_400_000),
        variantes: {
          create: p.variantes.map((v, j) => ({
            sku: `DEMO-${b.pseudo.slice(5, 9).toUpperCase()}-${i + 1}-${j + 1}-${randomBytes(2).toString('hex')}`,
            nom: Object.values(v.attributs).join(' / '),
            attributs: v.attributs,
            prix: v.prix ?? null,
            stockDisponible: v.stock,
          })),
        },
        medias: { create: medias.map((media, ordre) => ({ ordre, media: { create: media } })) },
      },
    });
    produitIds.push(produitId);
  }

  const publicationIds: string[] = [];
  for (const pub of b.publications) {
    const publicationId = randomUUID();
    const dossier = `boutiques/${id}/publications/${publicationId}`;
    const medias = pub.video
      ? [await envoyer(ctx, VIDEOS[pub.video].url, `${dossier}/videos`, VIDEOS[pub.video].duree)]
      : await Promise.all(pub.medias.map((url) => envoyer(ctx, url, `${dossier}/images`)));
    await prisma.publication.create({
      data: {
        id: publicationId,
        boutiqueId: id,
        contenu: pub.contenu,
        type: pub.type,
        statut: 'PUBLIEE',
        nombreVues: pub.vues,
        dateCreation: new Date(Date.now() - pub.ilYaHeures * 3_600_000),
        medias: { create: medias.map((media, ordre) => ({ ordre, media: { create: media } })) },
        produits: { create: pub.produits.map((k, ordre) => ({ ordre, produitId: produitIds[k] })) },
      },
    });
    publicationIds.push(publicationId);
  }

  ctx.log(`Créé : ${b.boutique} — ${produitIds.length} produits, ${publicationIds.length} publications`);
  return { id, publicationIds };
}

/** Likes, commentaires et abonnements croisés entre comptes de démo et de test. */
async function animer({ prisma }: Contexte, boutiques: Array<{ id: string; publicationIds: string[] }>) {
  const fans = await prisma.utilisateur.findMany({
    where: {
      pseudo: { in: [...BOUTIQUES.map((b) => b.pseudo), 'client_test', 'vendeur_test', 'dev_dropp'] },
    },
    select: { id: true },
  });
  let n = 0;
  for (const boutique of boutiques) {
    for (const fan of fans) {
      if (fan.id === boutique.id) continue;
      await prisma.abonnement.upsert({
        where: { utilisateurId_vendeurId: { utilisateurId: fan.id, vendeurId: boutique.id } },
        create: { utilisateurId: fan.id, vendeurId: boutique.id },
        update: {},
      });
    }
    for (const publicationId of boutique.publicationIds) {
      for (const fan of fans) {
        if (fan.id === boutique.id || Math.random() < 0.3) continue;
        await prisma.aime.create({ data: { utilisateurId: fan.id, publicationId } });
        if (Math.random() < 0.4) {
          await prisma.commentaire.create({
            data: {
              utilisateurId: fan.id,
              publicationId,
              contenu: COMMENTAIRES[n++ % COMMENTAIRES.length],
            },
          });
        }
      }
    }
  }
}


// ─── Points d'entrée ────────────────────────────────────────────────────────

const PSEUDOS = BOUTIQUES.map((b) => b.pseudo);

/** Supprime toutes les boutiques de démo (données + fichiers R2). */
export async function supprimerDemo(
  prisma: PrismaClient,
  env: NodeJS.ProcessEnv = process.env,
  log: (message: string) => void = console.log,
): Promise<void> {
  await supprimerBoutiques(contexte(prisma, env, log), PSEUDOS);
}

/** Crée les boutiques de démo manquantes. Lève une erreur si R2 n'est pas configuré. */
export async function creerDemo(
  prisma: PrismaClient,
  env: NodeJS.ProcessEnv = process.env,
  log: (message: string) => void = console.log,
): Promise<void> {
  const ctx = contexte(prisma, env, log);
  if (!ctx.s3) {
    throw new Error('Seed démo : STOCKAGE_DRIVER=r2 et les variables R2_* sont requis (les médias doivent être lisibles).');
  }

  const manquantes = [];
  for (const b of BOUTIQUES) {
    const existe = await prisma.utilisateur.findFirst({
      where: { OR: [{ pseudo: b.pseudo }, { telephone: b.telephone }] },
      select: { id: true },
    });
    if (!existe) manquantes.push(b);
  }
  if (!manquantes.length) {
    log('Seed démo : toutes les boutiques sont déjà présentes.');
    return;
  }

  const categories = await preparerCategories(ctx);
  // Comptes vitrines : mot de passe aléatoire jeté, personne ne s'y connecte.
  const hash = await argon2.hash(randomBytes(32).toString('hex'), { type: argon2.argon2id });

  const creees = [];
  for (const b of manquantes) {
    try {
      creees.push(await creerBoutique(ctx, b, categories, hash));
    } catch (erreur: unknown) {
      // Création partielle : on nettoie pour retenter proprement au prochain lancement.
      log(`Échec : ${b.boutique} (${erreur instanceof Error ? erreur.message : String(erreur)}), nettoyage…`);
      await supprimerBoutiques(ctx, [b.pseudo]).catch(() => undefined);
    }
  }
  if (creees.length) await animer(ctx, creees);
  log(`Seed démo terminé : ${creees.length}/${manquantes.length} boutique(s) créée(s).`);
}
