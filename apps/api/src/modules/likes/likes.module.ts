import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { LikesController } from './likes.controller.js';
import { LikesService } from './likes.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [LikesController],
  providers: [LikesService],
})
export class LikesModule {}