import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/messages_erreurs.dart';

/// Message traduit pour un code d'erreur KYC. Le `switch` est exhaustif : si
/// un code est ajouté à l'énumération, la compilation échoue tant qu'il n'a
/// pas de message.
String messageErreurKyc(AppLocalizations l10n, ApiException erreur,{ Map<TypeErreurApi, String> specifiques = const {}}){

  final code = erreur.code;
  if (code == null) {
    return messageErreurApi(l10n, erreur, specifiques: specifiques);
  }
  return switch (code) {
    'PROFILE_NOT_FOUND' => l10n.kycErrProfilIntrouvable,
    'OCR_UNAVAILABLE' => l10n.kycErrOcrIndisponible,
    'KYC_DOSSIER_NOT_FOUND' => l10n.kycErrDossierIntrouvable,
    'KYC_DOSSIER_NOT_EDITABLE' => l10n.kycErrDossierNonModifiable,
    'KYC_ALREADY_VERIFIED' => l10n.kycErrDejaVerifie,
    'KYC_UNDER_REVIEW' => l10n.kycErrEnCoursDeRevue,
    'KYC_ALREADY_SUBMITTED' => l10n.kycErrDejaSoumis,
    'CNI_RECTO_NOT_UPLOADED' => l10n.kycErrCniRectoManquant,
    'CNI_IMAGE_NOT_FOUND' => l10n.kycLectureIntrouvable,
    'INVALID_CNI_NUMBER' => l10n.kycErrNumeroCniInvalide,
    'INVALID_BIRTH_DATE' => l10n.kycErrNaissanceInvalide,
    'INVALID_ISSUE_DATE' => l10n.kycErrDelivranceInvalide,
    'INVALID_EXPIRATION_DATE' => l10n.kycErrExpirationInvalide,
    'IDENTITY_CARD_EXPIRED' => l10n.kycServeurCarteExpiree,
    'INCONSISTENT_CNI_DATES' => l10n.kycServeurDatesIncoherentes,
    'INCONSISTENT_BIRTH_DATE' =>
      l10n.kycServeurNaissanceIncoherente,
    'MINIMUM_AGE_NOT_MET' => l10n.kycErrAgeMinimum,
    'INCOMPLETE_CNI_DATA' => l10n.kycErrDonneesIncompletes,
    'REQUIRED_DOCUMENTS_MISSING' => l10n.kycErrDocumentsManquants,
    'CONSENT_REQUIRED' => l10n.kycErrConsentementRequis,
    _ => l10n.erreurInconnue,
  };

}
