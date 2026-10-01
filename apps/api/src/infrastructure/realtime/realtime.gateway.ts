import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  type OnGatewayConnection,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';

import type { PayloadJwt } from '../../modules/auth/services/jeton.service.js';
import { PrismaService } from '../database/prisma.service.js';
import { EVENEMENT, roomUtilisateur } from './evenements.js';

const STATUTS_AUTORISES = new Set(['ACTIF', 'EN_ATTENTE_VERIFICATION']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface DonneesSocket {
  utilisateurId: string;
}

/**
 * Connexion : io(`${API}/temps-reel`, { auth: { token: accessToken } }).
 * Chaque socket rejoint la room de son utilisateur : tous ses appareils
 * reçoivent les événements. Le JWT n'est vérifié qu'à la connexion ;
 * l'app se reconnecte avec le nouveau token après un refresh.
 */
@WebSocketGateway({ namespace: '/temps-reel', cors: { origin: true } })
export class RealtimeGateway implements OnGatewayConnection {
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(socket: Socket): Promise<void> {
    try {
      const token = this.extraireToken(socket);
      if (!token) throw new Error('token absent');

      const payload = await this.jwt.verifyAsync<PayloadJwt>(token);
      if (!STATUTS_AUTORISES.has(payload.statutCompte)) {
        throw new Error('compte indisponible');
      }

      (socket.data as DonneesSocket).utilisateurId = payload.sub;
      await socket.join(roomUtilisateur(payload.sub));
    } catch (erreur) {
      this.logger.debug(`Connexion refusée : ${String(erreur)}`);
      socket.emit('erreur', { message: 'Authentification requise.' });
      socket.disconnect(true);
    }
  }

  /** Indicateur « en train d'écrire », relayé aux autres participants. */
  @SubscribeMessage(EVENEMENT.ECRIT)
  async ecrit(
    @ConnectedSocket() socket: Socket,
    @MessageBody() corps: { conversationId?: unknown },
  ): Promise<void> {
    const utilisateurId = (socket.data as DonneesSocket).utilisateurId;
    const conversationId = corps?.conversationId;
    if (!utilisateurId || typeof conversationId !== 'string') return;
    if (!UUID.test(conversationId)) return;

    const participants = await this.prisma.participantConversation.findMany({
      where: { conversationId },
      select: { utilisateurId: true },
    });
    if (!participants.some((p) => p.utilisateurId === utilisateurId)) return;

    for (const p of participants) {
      if (p.utilisateurId === utilisateurId) continue;
      this.server
        .to(roomUtilisateur(p.utilisateurId))
        .emit(EVENEMENT.CONVERSATION_ECRIT, { conversationId, utilisateurId });
    }
  }

  private extraireToken(socket: Socket): string | undefined {
    const auth = socket.handshake.auth as { token?: unknown } | undefined;
    if (typeof auth?.token === 'string') return auth.token;

    const entete = socket.handshake.headers.authorization;
    if (entete?.startsWith('Bearer ')) return entete.slice(7);
    return undefined;
  }
}
