import '../../../core/router/routes.dart';
import '../data/modeles_kyc.dart';

/// Nombre d'étapes affichées (CNI, informations, selfie, récapitulatif).
/// À passer à 5 si une étape « identité » est ajoutée avant.
const etapesKycTotal = 4;

enum EtapeKyc { cni, informations, selfie, recapitulatif, dossier }

enum StatutEtapeKyc { terminee, aFaire, verrouillee }

bool _documentUtilisable(DossierKyc? dossier, TypeDocumentKyc type) {
  final document = dossier?.document(type);
  return document != null && !document.refuse;
}

/// Où reprendre le parcours, d'après l'état réel du dossier côté serveur.
/// Ne décide d'aucune règle métier : le serveur reste l'autorité.
EtapeKyc etapeSuivante(DossierKyc? dossier) {
  if (dossier != null &&
      (dossier.statut.enVerification ||
          dossier.statut == StatutDossierKyc.valide)) {
    return EtapeKyc.dossier;
  }
  if (!_documentUtilisable(dossier, TypeDocumentKyc.cniRecto) ||
      !_documentUtilisable(dossier, TypeDocumentKyc.cniVerso)) {
    return EtapeKyc.cni;
  }
  if (dossier == null || !dossier.donnees.complet) return EtapeKyc.informations;
  if (!_documentUtilisable(dossier, TypeDocumentKyc.photoFaciale)) {
    return EtapeKyc.selfie;
  }
  return EtapeKyc.recapitulatif;
}

String routePourEtape(EtapeKyc etape) => switch (etape) {
  EtapeKyc.cni => Routes.kycCni,
  EtapeKyc.informations => Routes.kycInformations,
  EtapeKyc.selfie => Routes.kycSelfie,
  EtapeKyc.recapitulatif => Routes.kycRecapitulatif,
  EtapeKyc.dossier => Routes.devenirVendeur,
};

/// État des quatre étapes affichées. Une étape terminée reste modifiable ; une
/// étape n'est ouverte que si les précédentes sont terminées.
Map<EtapeKyc, StatutEtapeKyc> statutDesEtapes(DossierKyc? dossier) {
  final cni =
      _documentUtilisable(dossier, TypeDocumentKyc.cniRecto) &&
      _documentUtilisable(dossier, TypeDocumentKyc.cniVerso);
  final infos = cni && dossier != null && dossier.donnees.complet;
  final selfie = _documentUtilisable(dossier, TypeDocumentKyc.photoFaciale);

  StatutEtapeKyc statut({required bool fait, required bool ouvert}) => fait
      ? StatutEtapeKyc.terminee
      : (ouvert ? StatutEtapeKyc.aFaire : StatutEtapeKyc.verrouillee);

  return {
    EtapeKyc.cni: statut(fait: cni, ouvert: true),
    EtapeKyc.informations: statut(fait: infos, ouvert: cni),
    EtapeKyc.selfie: statut(fait: selfie && infos, ouvert: infos),
    // Jamais « terminé » avant la soumission.
    EtapeKyc.recapitulatif: statut(fait: false, ouvert: cni && infos && selfie),
  };
}
