import { Module } from '@nestjs/common';

import { AuthentificationModule } from '../auth/auth.module.js';
import { PrismaModule } from '../../infrastructure/database/prisma.module.js';
import { UsersController } from './users.controller.js';
import { UsersService } from './users.service.js';

@Module({
  imports: [PrismaModule, AuthentificationModule],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}