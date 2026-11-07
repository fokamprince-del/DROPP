import 'package:dropp/core/api/api_exception.dart';
import 'package:dropp/features/vendeur/domain/messages_kyc.dart';
import 'package:dropp/l10n/app_localizations_en.dart';
import 'package:dropp/l10n/app_localizations_fr.dart';
import 'package:dropp/shared/widgets/messages_erreurs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Copie de `KYC_ERRORS` côté API : si le serveur ajoute un code, ce test
/// échoue tant que l'application ne le connaît pas.
const _codesServeur = [
  'PROFILE_NOT_FOUND',
  'OCR_UNAVAILABLE',
  'KYC_DOSSIER_NOT_FOUND',
  'KYC_DOSSIER_NOT_EDITABLE',
  'KYC_ALREADY_VERIFIED',
  'KYC_UNDER_REVIEW',
  'KYC_ALREADY_SUBMITTED',
  'KYC_NOT_PENDING_ADMIN_REVIEW',
  'KYC_DECISION_ALREADY_MADE',
  'CNI_RECTO_NOT_UPLOADED',
  'CNI_IMAGE_NOT_FOUND',
  'INVALID_CNI_NUMBER',
  'INVALID_BIRTH_DATE',
  'INVALID_ISSUE_DATE',
  'INVALID_EXPIRATION_DATE',
  'IDENTITY_CARD_EXPIRED',
  'INCONSISTENT_CNI_DATES',
  'INCONSISTENT_BIRTH_DATE',
  'MINIMUM_AGE_NOT_MET',
  'INCOMPLETE_CNI_DATA',
  'REQUIRED_DOCUMENTS_MISSING',
  'CONSENT_REQUIRED',
  'REJECTION_REASON_REQUIRED',
];

ApiException _erreur({String? code, List<String> details = const []}) =>
    ApiException(
      type: TypeErreurApi.requeteInvalide,
      message: 'x',
      statusCode: 400,
      code: code,
      details: details,
    );

void main() {
  test('chaque code a un message, en français et en anglais, sans code brut',
      () {
    for (final code in _codesServeur) {
      for (final message in [
        messageErreurKyc(AppLocalizationsFr(), _erreur(code: code)),
        messageErreurKyc(AppLocalizationsEn(), _erreur(code: code)),
      ]) {
        expect(message, isNotEmpty, reason: code);
        expect(message, isNot(contains(code)), reason: code);
      }
    }
  });

  test('sans code connu laisse la main au message général', () {
    expect(
      messageErreurKyc(AppLocalizationsFr(), _erreur(details: ['autre'])),
      messageErreurApi(AppLocalizationsFr(), _erreur(details: ['autre'])),
    );
    expect(
      messageErreurKyc(
        AppLocalizationsFr(),
        _erreur(code: 'KYC_ALREADY_VERIFIED'),
      ),
      'Ton identité est déjà vérifiée.',
    );
  });
}