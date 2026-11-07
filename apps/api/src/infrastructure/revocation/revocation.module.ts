import { Global, Module } from '@nestjs/common';

import { RevocationService } from './revocation.service.js';

/** Global : utilisé par l'authentification et l'administration. */
@Global()
@Module({
  providers: [RevocationService],
  exports: [RevocationService],
})
export class RevocationModule {}
