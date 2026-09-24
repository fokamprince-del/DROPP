import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ZxcvbnFactory } from '@zxcvbn-ts/core';
import { adjacencyGraphs, dictionary } from '@zxcvbn-ts/language-common';
import * as argon2 from 'argon2';
import { dictionary as dic2 } from '@zxcvbn-ts/language-fr';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const frDictionary = dic2 as Record<string, string[]>;

const LONGUEUR_MIN = 8;
const LONGUEUR_MAX = 128;
const SCORE_MIN = 2;

const ARGON2_OPTIONS = {
  type: argon2.argon2id as 0 | 1 | 2,
  memoryCost: 65_536,
  timeCost: 3,
  parallelism: 4,
};

@Injectable()
export class MotDePasseService {
  private readonly zxcvbn: ZxcvbnFactory;
  private readonly pepper: string;

  constructor(config: ConfigService) {
    this.pepper = config.getOrThrow<string>('auth.passwordPepper');
    this.zxcvbn = new ZxcvbnFactory({
      graphs: adjacencyGraphs,
      dictionary: { ...dictionary, ...frDictionary },
    });
  }

  async hacher(mdpBrut: string): Promise<string> {
    this.valider(mdpBrut);
    return argon2.hash(`${this.pepper}:${mdpBrut}`, ARGON2_OPTIONS);
  }

  async verifier(
    mdpBrut: string,
    hashStocke: string,
  ): Promise<{ valide: boolean; nouveauHash: string | null }> {
    const valide = await argon2.verify(hashStocke, `${this.pepper}:${mdpBrut}`);
    if (!valide) return { valide: false, nouveauHash: null };

    const nouveauHash = argon2.needsRehash(hashStocke, ARGON2_OPTIONS)
      ? await argon2.hash(`${this.pepper}:${mdpBrut}`, ARGON2_OPTIONS)
      : null;

    return { valide: true, nouveauHash };
  }

  valider(mdpBrut: string): void {
    if (mdpBrut.length < LONGUEUR_MIN) {
      throw new BadRequestException(
        `Le mot de passe doit contenir au moins ${LONGUEUR_MIN} caractères.`,
      );
    }
    if (mdpBrut.length > LONGUEUR_MAX) {
      throw new BadRequestException(
        `Le mot de passe ne peut pas dépasser ${LONGUEUR_MAX} caractères.`,
      );
    }
    const result = this.zxcvbn.check(mdpBrut);
    if (result.score < SCORE_MIN) {
      const conseil =
        result.feedback?.suggestions?.[0] ?? 'Essayez une phrase de passe.';
      throw new BadRequestException(`Mot de passe trop faible. ${conseil}`);
    }
  }
}
