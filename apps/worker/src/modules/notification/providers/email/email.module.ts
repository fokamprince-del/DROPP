import { Module } from '@nestjs/common';
import { EMAIL_PROVIDER } from './email.contract.js';
import { EmailProviderStub } from './email.stub.js';

@Module({
  providers: [{ provide: EMAIL_PROVIDER, useClass: EmailProviderStub }],
  exports: [EMAIL_PROVIDER],
})
export class EmailModule {}
