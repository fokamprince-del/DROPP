import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/auth/utilisateur.dart';
import 'package:dropp/core/router/redirection.dart';
import 'package:dropp/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

Utilisateur _utilisateur({
  bool vendeur = false,
  bool telephoneVerifie = true,
}) => Utilisateur(
  id: 'u1',
  prenom: 'Awa',
  nom: 'Ngo',
  email: null,
  emailVerifie: false,
  telephone: '+237690000000',
  telephoneVerifie: telephoneVerifie,
  statutCompte: 'ACTIF',
  estClient: true,
  estVendeur: vendeur,
  statutVendeur: vendeur ? 'ACTIF' : null,
);

String? _aller(EtatSession session, String lien) =>
    redirection(session, Uri.parse(lien));

void main() {
  const anonyme = SessionAnonyme();
  final client = SessionConnectee(_utilisateur());
  final vendeur = SessionConnectee(_utilisateur(vendeur: true));

  group('démarrage', () {
    test('attend la session sur l\'écran de démarrage en gardant la cible', () {
      expect(
        _aller(const SessionInconnue(), '/panier'),
        '/demarrage?de=%2Fpanier',
      );
      expect(_aller(const SessionInconnue(), '/'), Routes.demarrage);
      expect(_aller(const SessionInconnue(), Routes.demarrage), isNull);
    });

    test('repart vers la cible une fois la session connue', () {
      expect(_aller(client, '/demarrage?de=%2Fpanier'), '/panier');
      expect(_aller(anonyme, Routes.demarrage), Routes.accueil);
    });
  });

  group('visiteur', () {
    test('consulte le contenu public', () {
      expect(_aller(anonyme, Routes.accueil), isNull);
      expect(_aller(anonyme, Routes.recherche), isNull);
      expect(_aller(anonyme, '/produits/abc'), isNull);
    });

    test('est envoyé à la connexion pour les pages privées', () {
      expect(_aller(anonyme, '/panier'), '/connexion?de=%2Fpanier');
      expect(
        _aller(anonyme, '/profil/securite'),
        '/connexion?de=%2Fprofil%2Fsecurite',
      );
      expect(_aller(anonyme, '/vendeur'), '/connexion?de=%2Fvendeur');
    });

    test('ne confond pas un préfixe avec un mot plus long', () {
      expect(_aller(anonyme, '/paniers-partages'), isNull);
    });
  });

  group('connecté', () {
    test('quitte les pages visiteur vers la cible demandée', () {
      expect(_aller(client, '/connexion?de=%2Fpanier'), '/panier');
      expect(_aller(client, Routes.inscription), Routes.accueil);
    });

    test('refuse un retour vers une URL externe', () {
      expect(
        _aller(client, '/connexion?de=https%3A%2F%2Fpirate.example'),
        Routes.accueil,
      );
      expect(
        _aller(client, '/connexion?de=%2F%2Fpirate.example'),
        Routes.accueil,
      );
    });

    test('un client sans boutique va vers « devenir vendeur »', () {
      expect(_aller(client, '/vendeur'), Routes.devenirVendeur);
      expect(_aller(client, Routes.devenirVendeur), isNull);
    });

    test('un vendeur accède à son espace et saute « devenir vendeur »', () {
      expect(_aller(vendeur, '/vendeur'), isNull);
      expect(_aller(vendeur, Routes.devenirVendeur), Routes.espaceVendeur);
    });

    test('téléphone non vérifié : messagerie renvoyée vers la sécurité', () {
      final nonVerifie = SessionConnectee(
        _utilisateur(telephoneVerifie: false),
      );
      expect(_aller(nonVerifie, '/messages'), Routes.securite);
      expect(_aller(nonVerifie, '/panier'), isNull);
    });
  });
}
