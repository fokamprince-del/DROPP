import { Global, Module } from '@nestjs/common';
import { IdempotenceInterceptor } from './idempotence.interceptor.js';
import { IdempotenceService } from './idempotence.service.js';

@Global()
@Module({
  providers: [IdempotenceService, IdempotenceInterceptor],
  exports: [IdempotenceService, IdempotenceInterceptor],
})
export class IdempotenceModule {}
