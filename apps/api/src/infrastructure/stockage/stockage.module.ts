import { Module } from '@nestjs/common';

import { STOCKAGE_PROVIDER } from './stockage-provider.contract.js';
import { StockageProviderStub } from './stockage-provider.stub.js';

@Module({
  providers: [{ provide: STOCKAGE_PROVIDER, useClass: StockageProviderStub }],
  exports: [STOCKAGE_PROVIDER],
})
export class StockageModule {}