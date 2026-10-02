import { Injectable, Logger } from '@nestjs/common';
import type { MessagePush, PushProvider } from './push.contract.js';

@Injectable()
export class PushProviderStub implements PushProvider {
  private readonly logger = new Logger(PushProviderStub.name);

  async envoyer(message: MessagePush): Promise<{ tokensInvalides: string[] }> {
    this.logger.debug(
      `[PUSH STUB] → ${message.tokens.length} appareil(s) : "${message.titre}" — ${message.corps}`,
    );
    return { tokensInvalides: [] };
  }
}
