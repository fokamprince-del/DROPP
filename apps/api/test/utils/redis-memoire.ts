import type { Redis } from 'ioredis';

interface Entree {
  valeur: string;
  expireA?: number;
}

/**
 * Redis en mémoire pour les tests unitaires : sous-ensemble des commandes
 * utilisées par l'API (get/set EX NX, del, incr, expire NX, ttl, mget,
 * pipeline). Chaque commande est atomique, comme dans Redis.
 */
export class RedisMemoire {
  private readonly donnees = new Map<string, Entree>();

  private lire(cle: string): Entree | undefined {
    const e = this.donnees.get(cle);
    if (e?.expireA !== undefined && e.expireA <= Date.now()) {
      this.donnees.delete(cle);
      return undefined;
    }
    return e;
  }

  async get(cle: string) {
    return this.lire(cle)?.valeur ?? null;
  }

  async mget(...cles: string[]) {
    return cles.map((c) => this.lire(c)?.valeur ?? null);
  }

  async set(cle: string, valeur: string, ...options: (string | number)[]) {
    const nx = options.includes('NX');
    if (nx && this.lire(cle)) return null;
    const ex = options.indexOf('EX');
    this.donnees.set(cle, {
      valeur,
      expireA: ex >= 0 ? Date.now() + Number(options[ex + 1]) * 1000 : undefined,
    });
    return 'OK';
  }

  async del(...cles: string[]) {
    let n = 0;
    for (const c of cles) if (this.lire(c) && this.donnees.delete(c)) n++;
    return n;
  }

  async incr(cle: string) {
    const e = this.lire(cle);
    const valeur = Number(e?.valeur ?? 0) + 1;
    this.donnees.set(cle, { valeur: String(valeur), expireA: e?.expireA });
    return valeur;
  }

  async expire(cle: string, secondes: number, mode?: 'NX') {
    const e = this.lire(cle);
    if (!e || (mode === 'NX' && e.expireA !== undefined)) return 0;
    e.expireA = Date.now() + secondes * 1000;
    return 1;
  }

  async ttl(cle: string) {
    const e = this.lire(cle);
    if (!e) return -2;
    if (e.expireA === undefined) return -1;
    return Math.ceil((e.expireA - Date.now()) / 1000);
  }

  pipeline() {
    const commandes: (() => Promise<unknown>)[] = [];
    const chaine = new Proxy(
      {},
      {
        get: (_cible, nom: string) => {
          if (nom === 'exec') {
            return async () => {
              const resultats: [null, unknown][] = [];
              for (const c of commandes) resultats.push([null, await c()]);
              return resultats;
            };
          }
          return (...args: unknown[]) => {
            const methode = (this as unknown as Record<string, (...a: unknown[]) => Promise<unknown>>)[nom];
            commandes.push(() => methode.apply(this, args));
            return chaine;
          };
        },
      },
    );
    return chaine;
  }

  /** Pour l'injection : typé comme un client ioredis. */
  commeRedis(): Redis {
    return this as unknown as Redis;
  }
}
