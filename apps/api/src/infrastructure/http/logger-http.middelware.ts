import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class LoggerHttpMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction): void {
    const debut = Date.now();

    this.logger.log(`--> ${req.method} ${req.originalUrl}`);

    res.on('finish', () => {
      const duree = Date.now() - debut;

      this.logger.log(
        `<-- ${req.method} ${req.originalUrl} ${res.statusCode} ${duree}ms`,
      );
    });

    next();
  }
}
