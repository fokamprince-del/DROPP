/** Noms des événements Socket.IO échangés avec les apps (namespace /temps-reel). */
export const EVENEMENT = {
  // Serveur → client
  MESSAGE_NOUVEAU: 'message:nouveau',
  MESSAGES_LUS: 'message:lus',
  CONVERSATION_ECRIT: 'conversation:ecrit',
  NOTIFICATION_NOUVELLE: 'notification:nouvelle',
  NOTIFICATIONS_COMPTEUR: 'notification:compteur',

  // Client → serveur
  ECRIT: 'conversation:ecrit',
} as const;

export const roomUtilisateur = (utilisateurId: string) =>
  `utilisateur:${utilisateurId}`;
