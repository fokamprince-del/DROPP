import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_client.dart';
import '../auth/session.dart';
import '../auth/stockage_session.dart';
import '../config/environnement.dart';

/// Événements Socket.IO de l'API (namespace `/temps-reel`).
abstract final class EvenementsTempsReel {
  /// Serveur → app : `Message` complet (tous les appareils des participants,
  /// expéditeur compris).
  static const messageNouveau = 'message:nouveau';

  /// Serveur → app : `{ conversationId, luPar, dateLecture }`, envoyé à
  /// l'autre participant quand quelqu'un lit.
  static const messagesLus = 'message:lus';

  /// Dans les deux sens : `{ conversationId }` envoyé, `{ conversationId,
  /// utilisateurId }` reçu (« en train d'écrire »).
  static const ecrit = 'conversation:ecrit';

  /// Serveur → app : notification enregistrée.
  static const notificationNouvelle = 'notification:nouvelle';

  /// Serveur → app : `{ nonLues }` après une lecture ou une suppression.
  static const notificationsCompteur = 'notification:compteur';
}

/// Événement reçu : son nom et ses données.
typedef EvenementRecu = ({String nom, Map<String, dynamic> donnees});

final tempsReelProvider = Provider<TempsReel>((ref) {
  final tempsReel = TempsReel(
    lireJeton: () async =>
        (await ref.read(stockageSessionProvider).lireJetons())?.accessToken,
    // Un appel authentifié renouvelle le jeton s'il a expiré (intercepteur).
    renouvelerJeton: () => ref.read(apiClientProvider).get<Object?>('/auth/me'),
  );
  ref
    ..listen(
      utilisateurConnecteProvider.select((u) => u?.id),
      (_, id) => id == null ? tempsReel.arreter() : tempsReel.demarrer(),
      fireImmediately: true,
    )
    ..onDispose(tempsReel.fermer);
  return tempsReel;
});

/// Connexion Socket.IO de l'utilisateur connecté.
///
/// - Le jeton d'accès est relu à chaque (re)connexion ; quand le serveur
///   coupe (jeton expiré, refusé), un appel à l'API le renouvelle puis la
///   connexion repart — au plus une fois par minute pour ne pas boucler.
/// - Coupée quand l'app passe en arrière-plan (batterie, données), rouverte
///   au retour.
/// - Les écrans écoutent [evenements] et filtrent par nom ; [connecte] dit
///   s'ils peuvent se passer de relire l'API régulièrement.
class TempsReel {
  TempsReel({required this._lireJeton, required this._renouvelerJeton});

  final Future<String?> Function() _lireJeton;
  final Future<Object?> Function() _renouvelerJeton;

  final _evenements = StreamController<EvenementRecu>.broadcast();
  final connecte = ValueNotifier<bool>(false);

  io.Socket? _socket;
  AppLifecycleListener? _cycleDeVie;
  bool _actif = false;
  DateTime? _dernierRenouvellement;

  Stream<EvenementRecu> get evenements => _evenements.stream;

  /// Événements d'un seul type.
  Stream<Map<String, dynamic>> ecouter(String nom) =>
      evenements.where((e) => e.nom == nom).map((e) => e.donnees);

  void demarrer() {
    if (_actif) return;
    _actif = true;
    _cycleDeVie ??= AppLifecycleListener(
      onPause: () => _socket?.disconnect(),
      onResume: () {
        if (_actif) _socket?.connect();
      },
    );
    final socket = io.io(
      '${Environnement.origineServeur}/temps-reel',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .setAuthFn((rappel) {
            unawaited(
              _lireJeton().then(
                (jeton) => rappel({'token': jeton ?? ''}),
                onError: (Object _) => rappel({'token': ''}),
              ),
            );
          })
          .build(),
    );
    _socket = socket;

    socket
      ..onConnect((_) => connecte.value = true)
      ..onDisconnect((raison) {
        connecte.value = false;
        // Coupure décidée par le serveur (jeton expiré ou refusé) : la
        // bibliothèque ne se reconnecte pas seule dans ce cas.
        if (raison == 'io server disconnect') {
          unawaited(_reconnecterAvecJetonNeuf());
        }
      });
    for (final nom in [
      EvenementsTempsReel.messageNouveau,
      EvenementsTempsReel.messagesLus,
      EvenementsTempsReel.ecrit,
      EvenementsTempsReel.notificationNouvelle,
      EvenementsTempsReel.notificationsCompteur,
    ]) {
      socket.on(nom, (donnees) {
        if (donnees is Map) {
          _evenements.add((
            nom: nom,
            donnees: Map<String, dynamic>.from(donnees),
          ));
        }
      });
    }
    socket.connect();
  }

  Future<void> _reconnecterAvecJetonNeuf() async {
    if (!_actif) return;
    final maintenant = DateTime.now();
    final dernier = _dernierRenouvellement;
    if (dernier != null && maintenant.difference(dernier).inSeconds < 60) {
      return;
    }
    _dernierRenouvellement = maintenant;
    try {
      await _renouvelerJeton();
    } on Exception {
      // Hors connexion : la prochaine reprise de l'app réessaiera.
      return;
    }
    if (_actif) _socket?.connect();
  }

  /// « En train d'écrire » (le serveur limite la fréquence).
  void signalerEcriture(String conversationId) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit(EvenementsTempsReel.ecrit, {'conversationId': conversationId});
  }

  void arreter() {
    _actif = false;
    _socket
      ?..clearListeners()
      ..dispose();
    _socket = null;
    connecte.value = false;
  }

  void fermer() {
    arreter();
    _cycleDeVie?.dispose();
    unawaited(_evenements.close());
    connecte.dispose();
  }

  /// Pour les tests : injecter un événement comme s'il venait du serveur.
  @visibleForTesting
  void simuler(String nom, Map<String, dynamic> donnees) =>
      _evenements.add((nom: nom, donnees: donnees));
}
