/** Format d'un @pseudo : minuscules, chiffres, « _ » et « . », 3 à 30 caractères. */
export const FORMAT_PSEUDO = /^[a-z0-9_.]{3,30}$/;

/** Mentions dans un texte : « @pseudo » (insensible à la casse). */
export const REGEX_MENTION = /(?<![\w.@])@([a-zA-Z0-9_.]{3,30})/g;

const RESERVES = new Set([
  'admin',
  'administrateur',
  'dropp',
  'support',
  'aide',
  'help',
  'moderateur',
  'moderation',
  'securite',
  'officiel',
  'system',
  'systeme',
  'root',
  'api',
]);

export function normaliserPseudo(brut: string): string {
  return brut.trim().replace(/^@/, '').toLowerCase();
}

export function estPseudoReserve(pseudo: string): boolean {
  return RESERVES.has(pseudo) || pseudo.startsWith('dropp');
}

/** Pseudos distincts mentionnés dans un texte (au plus `max`). */
export function extraireMentions(texte: string, max = 10): string[] {
  const pseudos = new Set<string>();
  for (const m of texte.matchAll(REGEX_MENTION)) {
    const p = m[1].toLowerCase().replace(/\.+$/, '');
    if (FORMAT_PSEUDO.test(p)) pseudos.add(p);
    if (pseudos.size >= max) break;
  }
  return [...pseudos];
}
