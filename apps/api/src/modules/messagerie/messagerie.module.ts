import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { StockageModule } from '../../infrastructure/stockage/stockage.module.js';
import { BlocagesService } from './blocages.service.js';
import { ConversationsService } from './conversations.service.js';
import { MessagerieController } from './messagerie.controller.js';
import { MessagesService } from './messages.service.js';

@Module({
  imports: [PrismaModule, StockageModule],
  controllers: [MessagerieController],
  providers: [BlocagesService, ConversationsService, MessagesService],
  exports: [BlocagesService],
})
export class MessagerieModule {}
