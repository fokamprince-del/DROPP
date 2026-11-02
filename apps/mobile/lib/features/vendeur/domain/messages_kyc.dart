import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/messages_erreurs.dart';

/// Traduit les refus métier de `POST /kyc/cni/confirmer`. Le serveur répond en
/// français : on reconnaît ses messages par mots-clés (fragile : à remplacer
/// par un code d'erreur stable dès qu'il existe). Tout le reste donne un
/// message général, jamais le texte brut du serveur.
String messageConfirmationCni(AppLocalizations l10n, ApiException erreur) {
  if (erreur.type != TypeErreurApi.requeteInvalide) {
    return messageErreurApi(l10n, erreur);
  }
  final texte = erreur.details.join(' ').toLowerCase();
  if (texte.contains('expir')) return l10n.kycServeurCarteExpiree;
  if (texte.contains('dates de la carte')) {
    return l10n.kycServeurDatesIncoherentes;
  }
  if (texte.contains('naissance incoh')) {
    return l10n.kycServeurNaissanceIncoherente;
  }
  final age = RegExp(r'(\d+)\s*ans').firstMatch(texte);
  if (texte.contains('au moins') && age != null) {
    return l10n.kycServeurAgeMinimum(int.parse(age[1]!));
  }
  return l10n.kycInfosRefusees;
}
