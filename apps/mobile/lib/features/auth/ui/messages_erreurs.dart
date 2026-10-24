import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';

/// Texte traduit pour une erreur d'API. [specifiques] prime sur le texte
/// générique du type. Le message du serveur n'est jamais affiché.
String messageErreurApi(
  AppLocalizations l10n,
  ApiException erreur, {
  Map<TypeErreurApi, String> specifiques = const {},
}) {
  final specifique = specifiques[erreur.type];
  if (specifique != null) return specifique;
  return switch (erreur.type) {
    TypeErreurApi.reseau => l10n.erreurReseau,
    TypeErreurApi.delaiDepasse => l10n.erreurDelai,
    TypeErreurApi.tropDeRequetes => l10n.erreurTropDeTentatives,
    TypeErreurApi.serveur => l10n.erreurServeur,
    TypeErreurApi.interdit => l10n.erreurInterdit,
    TypeErreurApi.requeteInvalide => l10n.erreurRequeteInvalide,
    _ => l10n.erreurInconnue,
  };
}
