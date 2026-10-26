import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/messagerie/data/messagerie.dart';
import 'package:flutter_test/flutter_test.dart';

import '../achat/achat_test.dart' show FauxApi;

/// Forme de `ConversationsService.presenter` côté API.
Map<String, dynamic> conversationJson() => {
  'id': 'cv1',
  'statut': 'ACTIVE',
  'peutEcrire': true,
  'dateDerniereActivite': '2026-10-26T10:42:00.000Z',
  'interlocuteur': {
    'id': 'b1',
    'prenom': 'Awa',
    'nom': 'Ngo',
    'pseudo': null,
    'photoProfilUrl': null,
    'boutique': {'id': 'b1', 'nom': 'Awa Wax', 'logoUrl': 'https://cdn/l.png'},
  },
  'dernierMessage': {
    'id': 'm9',
    'expediteurId': 'b1',
    'contenu': null,
    'type': 'IMAGE',
    'statut': 'ENVOYE',
    'dateCreation': '2026-10-26T10:42:00.000Z',
  },
  'nonLus': 2,
};

Map<String, dynamic> messageJson(String id, {String statut = 'ENVOYE'}) => {
  'id': id,
  'conversationId': 'cv1',
  'expediteurId': 'u1',
  'contenu': 'Bonjour',
  'type': 'IMAGE',
  'statut': statut,
  'dateCreation': '2026-10-26T10:40:00.000Z',
  'piecesJointes': [
    {
      'id': 'pj1',
      'type': 'IMAGE',
      'url': 'https://signee/pj1.jpg',
      'typeMime': 'image/jpeg',
      'taille': 1000,
      'largeur': 800,
      'hauteur': 600,
      'duree': null,
    },
  ],
};

void main() {
  test('une conversation avec une boutique affiche la boutique', () {
    final c = Conversation.fromJson(conversationJson());
    expect(c.interlocuteur!.nomAffiche, 'Awa Wax');
    expect(c.interlocuteur!.imageUrl, 'https://cdn/l.png');
    expect(c.interlocuteur!.boutiqueId, 'b1');
    expect(c.dernierMessage!.type, TypeMessage.image);
    expect(c.dernierMessage!.conversationId, 'cv1');
    expect(c.nonLus, 2);
  });

  test('un client affiche « Prénom Nom »', () {
    final i = Interlocuteur.fromJson({
      'id': 'u2',
      'prenom': 'Paul',
      'nom': 'Etoa',
      'photoProfilUrl': 'https://cdn/p.jpg',
      'boutique': null,
    });
    expect(i.nomAffiche, 'Paul Etoa');
    expect(i.imageUrl, 'https://cdn/p.jpg');
  });

  test('historique par curseur', () async {
    final api = FauxApi(
      (_, _) => {
        'donnees': [messageJson('m2', statut: 'LU'), messageJson('m1')],
        'curseurSuivant': 'm1',
      },
    );
    final page = await MessagerieRepository(api)
        .messages('cv1', avant: 'm3', limite: 2);

    expect(api.appels, ['GET /conversations/cv1/messages']);
    expect(api.derniereQuery, {'avant': 'm3', 'limite': 2});
    expect(page.curseurSuivant, 'm1');
    expect(page.messages.first.lu, isTrue);
    expect(page.messages.first.piecesJointes.single.ratio, closeTo(1.33, 0.01));
  });

  test('envoi d’un message avec pièce jointe déjà dans R2', () async {
    final api = FauxApi((_, _) => messageJson('m3'));
    await MessagerieRepository(api).envoyer(
      'cv1',
      contenu: '  Voici la photo  ',
      piecesJointes: const [
        FichierEnvoye(
          cleStockage: 'conversations/cv1/u1/a.jpg',
          typeMime: 'image/jpeg',
          taille: 1000,
        ),
      ],
    );
    expect(api.appels, ['POST /conversations/cv1/messages']);
    expect(api.dernierCorps, {
      'contenu': 'Voici la photo',
      'piecesJointes': [
        {
          'cleStockage': 'conversations/cv1/u1/a.jpg',
          'typeMime': 'image/jpeg',
          'taille': 1000,
        },
      ],
    });
  });

  test('ouvrir, non-lus, signature et lecture', () async {
    final api = FauxApi(
      (_, chemin) => switch (chemin) {
        '/conversations' => conversationJson(),
        '/conversations/non-lus' => {'nonLus': 7},
        '/conversations/cv1/pieces-jointes/signature' => {
          'uploadUrl': 'https://u',
          'cleStockage': 'k',
          'enTetes': {'Content-Type': 'video/mp4'},
        },
        _ => null,
      },
    );
    final depot = MessagerieRepository(api);

    await depot.ouvrir('b1');
    expect(api.dernierCorps, {'destinataireId': 'b1'});
    expect(await depot.nonLus(), 7);
    final s = await depot.signaturePieceJointe('cv1', 'video/mp4', 5000);
    expect(api.dernierCorps, {'typeMime': 'video/mp4', 'taille': 5000});
    expect(s.cleStockage, 'k');
    await depot.marquerLu('cv1');
    expect(api.appels.last, 'POST /conversations/cv1/lu');
  });
}
