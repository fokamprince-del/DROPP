import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import configuration from './configuration/configuration.js';
import { validationSchema } from './configuration/validation.js';
import { BullModule } from '@nestjs/bullmq';
import { QUEUE_KYC, QUEUE_NOTIFICATION } from '@dropp/contrats';
import { NotificationModule } from './modules/notification/notification.module.js';
import { KycModule } from './modules/kyc/kyc.module.js';
import { PrismaModule } from './infrastructure/database/database/prisma.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      envFilePath: '.env',
      load: [configuration],
      validationSchema,
    }),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.getOrThrow<string>('redis.host'),
          port: Number(config.getOrThrow<string>('redis.port')),
          password: config.getOrThrow<string>('redis.password'),
          // Exigé par BullMQ pour les workers (commandes bloquantes).
          maxRetriesPerRequest: null,
        },
        defaultJobOptions: {
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 1000,
          },
          removeOnComplete: { count: 100 },
          removeOnFail: { count: 500 },
        },
      }),
    }),
    BullModule.registerQueue(
      { name: QUEUE_NOTIFICATION },
      { name: QUEUE_KYC }
    ),
    PrismaModule,
    NotificationModule,
    KycModule,
  ],
})
export class AppModule {}
