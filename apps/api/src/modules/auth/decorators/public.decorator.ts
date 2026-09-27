import { SetMetadata } from '@nestjs/common';

export const CLE_PUBLIC = 'est_public';

/** Marque une route comme publique : le JwtAuthGuard global la laisse passer. */
export const Public = () => SetMetadata(CLE_PUBLIC, true);
