import { Injectable } from '@nestjs/common';
import { JetonService, type JetonsEmis } from '../services/jeton.service.js';

@Injectable()
export class RefreshTokenService {
  constructor(private readonly jetonService: JetonService) {}

  async executer(refreshToken: string): Promise<JetonsEmis> {
    return this.jetonService.rafraichir(refreshToken);
  }
}
