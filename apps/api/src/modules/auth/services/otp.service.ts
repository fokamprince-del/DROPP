import { Injectable } from '@nestjs/common';
import { randomInt } from 'node:crypto';

@Injectable()
export class OtpService {
  generer(): string {
    return randomInt(0, 1_000_000)
      .toString()
      .padStart(6, '0');
  }
}