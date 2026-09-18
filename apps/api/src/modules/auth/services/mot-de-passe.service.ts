import { Injectable } from '@nestjs/common';
import * as argon2 from 'argon2';

@Injectable()
export class MotDePasseService {
  async hacher(motDePasse: string): Promise<string> {
    return argon2.hash(motDePasse, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });
  }

  async verifier(
    hash: string,
    motDePasse: string,
  ): Promise<boolean> {
    try {
      return await argon2.verify(hash, motDePasse);
    } catch {
      return false;
    }
  }
}