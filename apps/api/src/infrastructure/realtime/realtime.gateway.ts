import { Inject, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  type OnGatewayConnection,
  type OnGatewayDisconnect,
} from '@nestjs/websockets';
import type { Redis } from 'ioredis';
import type { Server, Socket } from 'socket.io';

import type { PayloadJwt } from '../../modules/auth/services/jeton.service.js';
import { PrismaService } from '../database/prisma.service.js';
import { REDIS_CLIENT } from '../redis/redis.provider.js';
import { jetonRevoque } from '../revocation/revocation.js';
import { EVENEMENT, roomUtilisateur } from './evenements.js';

const STATUTS_AUTORISES = new Set(['ACTIF', 'EN_ATTENTE_VERIFICATION']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** « En train d'écrire » : au plus un relais par conversation toutes les 3 s. */
const INTERVALLE_ECRIT_MS = 3_000;

interface DonneesSocket {
  utilisateurId: string;
  dernierEcrit: Map<string, number>;
  minuterieExpiration?: NodeJS.Timeout;
}

/**
 * Connexion : io(`${API}/temps-reel`, { auth: { token: accessToken } }).
 * Chaque socket rejoint la room de son utilisateur : tous ses appareils
 * reçoivent les événements. Le socket est fermé à l'expiration du jeton
 * (l'app se reconnecte avec le jeton rafraîchi) et dès qu'il est révoqué.
 * CORS : configuré par RedisIoAdapter (CORS_ORIGINS).
 */
@WebSocketGateway({ namespace: '/temps-reel' })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async handleConnection(socket: Socket): Promise<void> {
    try {
      const token = this.extraireToken(socket);
      if (!token) throw new Error('token absent');

      const payload = await this.jwt.verifyAsync<
        PayloadJwt & { iat?: number; exp?: number }
      >(token);
      if (!STATUTS_AUTORISES.has(payload.statutCompte)) {
        throw new Error('compte indisponible');
      }
      if (await jetonRevoque(this.redis, payload)) {
        throw new Error('jeton révoqué');
      }

      const donnees = socket.data as DonneesSocket;
      donnees.utilisateurId = payload.sub;
      donnees.dernierEcrit = new Map();
      if (payload.exp) {
        const restant = payload.exp * 1000 - Date.now();
        donnees.minuterieExpiration = setTimeout(
          () => socket.disconnect(true),
          Math.max(restant, 0),
        );
      }
      await socket.join(roomUtilisateur(payload.sub));
    } catch (erreur) {
      this.logger.debug(`Connexion refusée : ${String(erreur)}`);
      socket.emit('erreur', { message: 'Authentification requise.' });
      socket.disconnect(true);
    }
  }

  handleDisconnect(socket: Socket): void {
    const minuterie = (socket.data as Partial<DonneesSocket>).minuterieExpiration;
    if (minuterie) clearTimeout(minuterie);
  }

  /** Indicateur « en train d'écrire », relayé aux autres participants. */
  @SubscribeMessage(EVENEMENT.ECRIT)
  async ecrit(
    @ConnectedSocket() socket: Socket,
    @MessageBody() corps: { conversationId?: unknown },
  ): Promise<void> {
    const donnees = socket.data as Partial<DonneesSocket>;
    const utilisateurId = donnees.utilisateurId;
    const conversationId = corps?.conversationId;
    if (!utilisateurId || !donnees.dernierEcrit) return;
    if (typeof conversationId !== 'string' || !UUID.test(conversationId)) return;

    const maintenant = Date.now();
    const dernier = donnees.dernierEcrit.get(conversationId) ?? 0;
    if (maintenant - dernier < INTERVALLE_ECRIT_MS) return;
    donnees.dernierEcrit.set(conversationId, maintenant);
    if (donnees.dernierEcrit.size > 100) donnees.dernierEcrit.clear();

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
