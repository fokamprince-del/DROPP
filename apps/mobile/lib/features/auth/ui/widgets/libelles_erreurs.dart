import '../../../../../../l10n/app_localizations.dart';
import '../../domain/validateurs.dart';

extension LibelleErreurChamp on ErreurChamp {
  String libelle(AppLocalizations l10n) => switch (this) {
    ErreurChamp.requis => l10n.erreurRequis,
    ErreurChamp.telephoneInvalide => l10n.erreurTelephoneInvalide,
    ErreurChamp.emailInvalide => l10n.erreurEmailInvalide,
    ErreurChamp.motDePasseTropCourt => l10n.erreurMotDePasseCourt,
    ErreurChamp.codeIncomplet => l10n.erreurCodeIncomplet,
    ErreurChamp.identifiantInvalide => l10n.erreurIdentifiantInvalide,
  };
}
