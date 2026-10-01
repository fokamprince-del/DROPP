import { BadRequestException, Injectable } from '@nestjs/common';
import {
  isValidPhoneNumber,
  parsePhoneNumberWithError,
} from 'libphonenumber-js';

const REGION_DEFAUT = 'CM' as const;

@Injectable()
export class TelephoneService {
  /**
   * Normalise en E.164 (+237650000001) et valide.
   * @throws BadRequestException si invalide.
   */
  normaliser(numero: string): string {
    const brut = numero.trim();
    if (!isValidPhoneNumber(brut, REGION_DEFAUT)) {
      throw new BadRequestException('Numéro de téléphone invalide.');
    }
    return parsePhoneNumberWithError(brut, REGION_DEFAUT).format('E.164');
  }

  /**
   * Pour les recherches (connexion, mot de passe oublié) : E.164 si le numéro
   * est valide, sinon la saisie brute — sans lever, pour garder une réponse
   * identique à « compte inconnu » (anti-énumération).
   */
  normaliserOuBrut(numero: string): string {
    try {
      return this.normaliser(numero);
    } catch {
      return numero.trim();
    }
  }

  estValide(numero: string): boolean {
    try {
      this.normaliser(numero);
      return true;
    } catch {
      return false;
    }
  }
}
