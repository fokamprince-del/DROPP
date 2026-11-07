import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagination.dart';
import '../../../core/upload/service_upload.dart';
import '../../../shared/modeles/contenu.dart';

/// Taille maximale par type de pièce jointe (Mo), comme l'API.
const tailleMaxImageMessageMo = 10;
const tailleMaxVideoMessageMo = 100;

/// Pièces jointes par message (limite de l'API).
const piecesJointesMax = 10;

/// L'autre personne d'une conversation : un client, ou une boutique.
class Interlocuteur {
  const Interlocuteur({
    required this.id,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.boutiqueId,
    this.boutiqueNom,
    this.boutiqueLogoUrl,
  });

  final String id;
  final String prenom;
  final String nom;
  final String? photoUrl;

  /// Renseignés si l'interlocuteur est un vendeur.
  final String? boutiqueId;
  final String? boutiqueNom;
  final String? boutiqueLogoUrl;

  /// Le nom de la boutique pour un vendeur, sinon « Prénom Nom ».
  String get nomAffiche => boutiqueNom ?? '$prenom $nom'.trim();
  String? get imageUrl => boutiqueLogoUrl ?? photoUrl;

  factory Interlocuteur.fromJson(Map<String, dynamic> json) {
    final boutique = json['boutique'] as Map<String, dynamic>?;
    return Interlocuteur(
      id: json['id'] as String,
      prenom: json['prenom'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      photoUrl: lireUrl(json['photoProfilUrl']),
      boutiqueId: boutique?['id'] as String?,
      boutiqueNom: boutique?['nom'] as String?,
      boutiqueLogoUrl: lireUrl(boutique?['logoUrl']),
    );
  }
}

enum TypeMessage { texte, image, video, fichier }

TypeMessage _typeMessage(Object? v) => switch (v) {
  'IMAGE' => TypeMessage.image,
  'VIDEO' => TypeMessage.video,
  'FICHIER' => TypeMessage.fichier,
  _ => TypeMessage.texte,
};

class PieceJointe {
  const PieceJointe({
    required this.id,
    required this.url,
    required this.estVideo,
    this.largeur,
    this.hauteur,
    this.duree,
  });

  final String id;

  /// URL signée valable 1 h : recharger la conversation au-delà.
  final String url;
  final bool estVideo;
  final int? largeur;
  final int? hauteur;
  final Duration? duree;

  double? get ratio {
    final l = largeur;
    final h = hauteur;
    return l == null || h == null || l <= 0 || h <= 0 ? null : l / h;
  }

  MediaContenu get media => MediaContenu(
    id: id,
    type: estVideo ? TypeMedia.video : TypeMedia.image,
    url: url,
    largeur: largeur,
    hauteur: hauteur,
    duree: duree,
  );

  factory PieceJointe.fromJson(Map<String, dynamic> json) {
    final duree = (json['duree'] as num?)?.toInt();
    return PieceJointe(
      id: json['id'] as String,
      url: json['url'] as String,
      estVideo: json['type'] == 'VIDEO',
      largeur: (json['largeur'] as num?)?.toInt(),
      hauteur: (json['hauteur'] as num?)?.toInt(),
      duree: duree == null ? null : Duration(seconds: duree),
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.dateCreation,
    this.contenu,
    this.type = TypeMessage.texte,
    this.lu = false,
    this.piecesJointes = const [],
  });

  final String id;
  final String conversationId;
  final String expediteurId;
  final String? contenu;
  final TypeMessage type;

  /// Lu par le destinataire (accusé de lecture).
  final bool lu;
  final DateTime dateCreation;
  final List<PieceJointe> piecesJointes;

  /// Copie marquée « lue » (accusé de lecture reçu en temps réel).
  Message copierLu() => Message(
    id: id,
    conversationId: conversationId,
    expediteurId: expediteurId,
    dateCreation: dateCreation,
    contenu: contenu,
    type: type,
    lu: true,
    piecesJointes: piecesJointes,
  );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String? ?? '',
    expediteurId: json['expediteurId'] as String,
    contenu: json['contenu'] as String?,
    type: _typeMessage(json['type']),
    lu: json['statut'] == 'LU',
    dateCreation: dateDepuis(json['dateCreation']),
    piecesJointes: (json['piecesJointes'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PieceJointe.fromJson)
        .toList(),
  );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.dateDerniereActivite,
    this.interlocuteur,
    this.dernierMessage,
    this.nonLus = 0,
    this.peutEcrire = true,
  });

  final String id;

  /// `null` si l'autre compte a été supprimé.
  final Interlocuteur? interlocuteur;
  final Message? dernierMessage;
  final int nonLus;

  /// Faux si la conversation a été fermée (modération).
  final bool peutEcrire;
  final DateTime dateDerniereActivite;

  /// Après un blocage : plus d'écriture possible depuis cet écran.
  Conversation fermee() => Conversation(
    id: id,
    dateDerniereActivite: dateDerniereActivite,
    interlocuteur: interlocuteur,
    dernierMessage: dernierMessage,
    nonLus: nonLus,
    peutEcrire: false,
  );

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final interlocuteur = json['interlocuteur'] as Map<String, dynamic>?;
    final dernier = json['dernierMessage'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as String,
      interlocuteur: interlocuteur == null
          ? null
          : Interlocuteur.fromJson(interlocuteur),
      dernierMessage: dernier == null
          ? null
          : Message.fromJson({...dernier, 'conversationId': json['id']}),
      nonLus: (json['nonLus'] as num? ?? 0).toInt(),
      peutEcrire: json['peutEcrire'] as bool? ?? true,
      dateDerniereActivite: dateDepuis(json['dateDerniereActivite']),
    );
  }
}

/// Une page d'historique, du plus récent au plus ancien.
class PageMessages {
  const PageMessages({required this.messages, this.curseurSuivant});

  final List<Message> messages;

  /// À passer en `avant` pour charger les messages plus anciens ; `null` :
  /// début de la conversation atteint.
  final String? curseurSuivant;
}

final messagerieRepositoryProvider = Provider<MessagerieRepository>(
  (ref) => MessagerieRepository(ref.watch(apiClientProvider)),
);

/// Messagerie : session et **téléphone vérifié** exigés sur toutes les
/// routes. Toute erreur est une `ApiException`.
class MessagerieRepository {
  MessagerieRepository(this._api);

  final ApiClient _api;

  /// `POST /conversations` : retrouve ou crée la conversation avec
  /// [destinataireId] (pour une boutique : son id). On peut toujours écrire
  /// à une boutique active ; un vendeur ne peut écrire qu'à ses clients
  /// (403 sinon). 403 aussi s'il y a un blocage, 400 si c'est soi-même.
  Future<Conversation> ouvrir(String destinataireId) async =>
      Conversation.fromJson(
        await _api.post<Map<String, dynamic>>(
          '/conversations',
          data: {'destinataireId': destinataireId},
        ),
      );

  /// `GET /conversations` : celles qui ont au moins un message, les plus
  /// actives d'abord, avec le dernier message et le nombre de non-lus.
  Future<PageResultats<Conversation>> lister(int page) =>
      _api.page('/conversations', Conversation.fromJson, page: page);

  /// `GET /conversations/non-lus` : total des messages reçus non lus.
  Future<int> nonLus() async {
    final json = await _api.get<Map<String, dynamic>>('/conversations/non-lus');
    return (json['nonLus'] as num? ?? 0).toInt();
  }

  /// `GET /conversations/:id` : 404 si l'utilisateur n'y participe pas.
  Future<Conversation> detail(String id) async => Conversation.fromJson(
    await _api.get<Map<String, dynamic>>('/conversations/$id'),
  );

  /// `GET /conversations/:id/messages` : pagination par **curseur**.
  /// Sans [avant] : les plus récents ; avec : ceux d'avant ce message.
  Future<PageMessages> messages(
    String conversationId, {
    String? avant,
    int limite = 30,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      query: {'avant': avant, 'limite': limite},
    );
    return PageMessages(
      messages: (json['donnees'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Message.fromJson)
          .toList(),
      curseurSuivant: json['curseurSuivant'] as String?,
    );
  }

  /// `POST /conversations/:id/messages` : texte (4 000 caractères) et/ou
  /// jusqu'à [piecesJointesMax] fichiers déjà envoyés dans R2 par
  /// l'expéditeur. 400 si vide, 403 si la conversation est fermée ou s'il y
  /// a un blocage. 60 messages par minute au plus.
  Future<Message> envoyer(
    String conversationId, {
    String? contenu,
    List<FichierEnvoye> piecesJointes = const [],
  }) async => Message.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: {
        if (contenu != null && contenu.trim().isNotEmpty)
          'contenu': contenu.trim(),
        if (piecesJointes.isNotEmpty)
          'piecesJointes': [for (final p in piecesJointes) p.toJson()],
      },
    ),
  );

  /// `POST /conversations/:id/pieces-jointes/signature` : URL d'envoi d'une
  /// pièce jointe (images 10 Mo, vidéos 100 Mo ; 30 par minute au plus).
  Future<SignatureUpload> signaturePieceJointe(
    String conversationId,
    String typeMime,
    int taille,
  ) async => SignatureUpload.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/conversations/$conversationId/pieces-jointes/signature',
      data: {'typeMime': typeMime, 'taille': taille},
    ),
  );

  /// `POST /conversations/:id/lu` : tous les messages reçus passent « lu ».
  Future<void> marquerLu(String conversationId) =>
      _api.post<Object?>('/conversations/$conversationId/lu');
}
