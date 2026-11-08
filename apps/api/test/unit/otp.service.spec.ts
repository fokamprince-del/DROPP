import { BadRequestException, GoneException, HttpException } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';

import { OtpService } from '../../src/modules/auth/services/otp.service.js';
import { RedisMemoire } from '../utils/redis-memoire.js';

const CONFIG: Record<string, unknown> = {
  'auth.otpPepper': 'pepper-de-test-suffisamment-long-pour-hmac',
  'redis.otpTtl': 300,
  'redis.otpCooldown': 60,
  'redis.otpMaxTentatives': 5,
  'redis.otpMaxEnvoisHeure': 5,
};
const config = { getOrThrow: (cle: string) => CONFIG[cle] } as ConfigService;
const DESTINATION = '+237650000001';

function nouveau() {
  const redis = new RedisMemoire();
  return { redis, otp: new OtpService(redis.commeRedis(), config) };
}

const generer = (otp: OtpService) =>
  otp.generer({ destination: DESTINATION, canal: 'SMS', type: 'INSCRIPTION', utilisateurId: 'u1' });
const verifier = (otp: OtpService, code: string) =>
  otp.verifier({ destination: DESTINATION, type: 'INSCRIPTION', codeSoumis: code });
const mauvais = (code: string) => String((Number(code) + 1) % 1_000_000).padStart(6, '0');

describe('OtpService', () => {
  it('génère un code à 6 chiffres et le valide une seule fois', async () => {
    const { otp } = nouveau();
    const { code } = await generer(otp);
    expect(code).toMatch(/^\d{6}$/);

    await expect(verifier(otp, code)).resolves.toEqual({ utilisateurId: 'u1' });
    await expect(verifier(otp, code)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('applique le délai entre deux envois', async () => {
    const { otp } = nouveau();
    await generer(otp);
    await expect(generer(otp)).rejects.toBeInstanceOf(HttpException);
  });

  it('limite le nombre de tentatives, même en parallèle', async () => {
    const { otp } = nouveau();
    const { code } = await generer(otp);

    const essais = await Promise.allSettled(
      Array.from({ length: 20 }, () => verifier(otp, mauvais(code))),
    );
    expect(essais.every((e) => e.status === 'rejected')).toBe(true);
    const epuises = essais.filter(
      (e) => e.status === 'rejected' && e.reason instanceof GoneException,
    );
    expect(epuises.length).toBeGreaterThan(0);

    // Le bon code ne passe plus : le code a été invalidé.
    await expect(verifier(otp, code)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('un code correct après quelques erreurs reste accepté', async () => {
    const { otp } = nouveau();
    const { code } = await generer(otp);
    await expect(verifier(otp, mauvais(code))).rejects.toThrow('4 tentative(s)');
    await expect(verifier(otp, code)).resolves.toEqual({ utilisateurId: 'u1' });
  });

  it('un seul gagnant si le bon code est soumis deux fois en même temps', async () => {
    const { otp } = nouveau();
    const { code } = await generer(otp);
    const [a, b] = await Promise.allSettled([verifier(otp, code), verifier(otp, code)]);
    const succes = [a, b].filter((r) => r.status === 'fulfilled');
    expect(succes).toHaveLength(1);
  });

  describe('mode test (code fixe)', () => {
    const avecModeTest = (code: string, destinations: string[]) => {
      const cfg = { ...CONFIG, 'auth.otpTestCode': code, 'auth.otpTestDestinations': destinations };
      const redis = new RedisMemoire();
      return new OtpService(redis.commeRedis(), {
        getOrThrow: (cle: string) => cfg[cle],
      } as ConfigService);
    };

    it('donne le code fixe aux destinations listées, et il se valide', async () => {
      const otp = avecModeTest('123456', [DESTINATION]);
      const { code } = await generer(otp);
      expect(code).toBe('123456');
      await expect(verifier(otp, '123456')).resolves.toEqual({ utilisateurId: 'u1' });
    });

    it("n'accepte pas le code fixe pour une destination non listée", async () => {
      const otp = avecModeTest('123456', ['+237699999999']);
      const { code } = await generer(otp);
      // Code aléatoire : le code fixe ne passe pas (sauf coïncidence 1/10^6).
      if (code !== '123456') {
        await expect(verifier(otp, '123456')).rejects.toBeInstanceOf(BadRequestException);
      }
      await expect(verifier(otp, code)).resolves.toEqual({ utilisateurId: 'u1' });
    });

    it('reste désactivé sans code, même avec des destinations', async () => {
      const otp = avecModeTest('', [DESTINATION]);
      const { code } = await generer(otp);
      expect(code).toMatch(/^\d{6}$/);
    });
  });
});
