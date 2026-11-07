import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiExtension } from '@nestjs/swagger';

export const CLE_PUBLIC = 'est_public';

/** Marque une route comme publique : le JwtAuthGuard global la laisse passer. */
export const Public = () => applyDecorators(SetMetadata(CLE_PUBLIC, true), ApiExtension('x-public', true));
