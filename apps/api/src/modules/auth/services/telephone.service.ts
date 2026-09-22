import { BadRequestException, Injectable } from '@nestjs/common';
import { isValidPhoneNumber, parsePhoneNumber } from 'libphonenumber-js';

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
    return parsePhoneNumber(brut, REGION_DEFAUT).format('E.164');
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