import { Module } from '@nestjs/common';
import { SMS_PROVIDER } from './sms-provider.contract.js';
import { SmsProviderStub } from './sms-provider.stub.js';

@Module({
  providers: [{ provide: SMS_PROVIDER, useClass: SmsProviderStub }],
  exports: [SMS_PROVIDER],
})
export class SmsModule {}
