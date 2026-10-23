import 'package:dropp/app/router/redirection.dart';
import 'package:dropp/app/router/routes.dart';
import 'package:dropp/core/auth/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const anonyme = SessionAnonyme();

  test('session inconnue : reste sur le démarrage', () {
    expect(
      redirection(const SessionInconnue(), Uri.parse(Routes.accueil)),
      Routes.demarrage,
    );
  });

  test(
    'démarrage pas terminé : reste sur le démarrage même si la session est lue',
    () {
      expect(
        redirection(
          anonyme,
          Uri.parse(Routes.accueil),
          demarrageTermine: false,
        ),
        Routes.demarrage,
      );
    },
  );

  test('première ouverture : mène à la bienvenue', () {
    expect(
      redirection(anonyme, Uri.parse(Routes.demarrage), bienvenueVue: false),
      Routes.bienvenue,
    );
  });

  test('bienvenue déjà vue : mène à l’accueil', () {
    expect(redirection(anonyme, Uri.parse(Routes.demarrage)), Routes.accueil);
  });

  test('bienvenue déjà vue : respecte la page demandée', () {
    expect(
      redirection(anonyme, Uri.parse('${Routes.demarrage}?de=/produits/42')),
      '/produits/42',
    );
  });

  test('la bienvenue reste accessible à un visiteur', () {
    expect(
      redirection(anonyme, Uri.parse(Routes.bienvenue), bienvenueVue: false),
      isNull,
    );
  });
}
