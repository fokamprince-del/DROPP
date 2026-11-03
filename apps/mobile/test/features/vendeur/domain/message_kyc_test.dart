import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/features/vendeur/domain/messages_kyc.dart';
import 'package:dropp/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

ApiException _refus(String message) => ApiException(
  type: TypeErreurApi.requeteInvalide,
  message: message,
  statusCode: 400,
  details: [message],
);

void main() {
  final l10n = AppLocalizationsFr();
  String m(String serveur) => messageConfirmationCni(l10n, _refus(serveur));

  test('traduit les refus du serveur', () {
    expect(
      m('Votre carte d’identité est expirée.'),
      'Ta carte d\'identité est expirée. Utilise une carte en cours de validité.',
    );
    expect(
      m('Dates de la carte d’identité incohérentes.'),
      contains('dates de ta carte'),
    );
    expect(m('Date de naissance incohérente.'), contains('incohérente'));
    expect(
      m('Vous devez avoir au moins 18 ans pour vendre sur DROPP.'),
      'Tu dois avoir au moins 18 ans pour vendre sur DROPP.',
    );
  });

  test('un refus inconnu donne le message général, jamais le texte brut', () {
    final texte = m('quelque chose de technique');
    expect(texte, contains('pas été acceptées'));
    expect(texte, isNot(contains('technique')));
  });

  test('une erreur réseau garde son message', () {
    const reseau = ApiException(type: TypeErreurApi.reseau, message: 'x');
    expect(messageConfirmationCni(l10n, reseau), 'Pas de connexion internet.');
  });
}
