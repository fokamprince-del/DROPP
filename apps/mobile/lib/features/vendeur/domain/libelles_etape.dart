import '../../../l10n/app_localizations.dart';
import '../domain/etape_kyc.dart';

String titreEtape(AppLocalizations l10n, EtapeKyc etape) => switch (etape) {
  EtapeKyc.cni => l10n.kycEtapeCniTitre,
  EtapeKyc.informations => l10n.kycEtapeInfosTitre,
  EtapeKyc.selfie => l10n.kycEtapeSelfieTitre,
  EtapeKyc.recapitulatif => l10n.kycEtapeRecapTitre,
  EtapeKyc.dossier => '',
};
