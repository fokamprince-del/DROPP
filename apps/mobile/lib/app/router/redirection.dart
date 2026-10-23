import '../../core/auth/session.dart';
import 'routes.dart';

/// Règles de navigation, sans dépendance à Flutter : testées dans
/// `test/core/router/redirection_test.dart`. Renvoie `null` pour laisser
/// passer, sinon le chemin où aller.
String? redirection(
  EtatSession session,
  Uri demande, {
  bool demarrageTermine = true,
  bool bienvenueVue = true,
}) {
  final chemin = demande.path;
  final retour = demande.queryParameters[Routes.parametreRetour];

  // Tant que la session n'est pas lue ou que le démarrage n'est pas terminé,
  // on reste sur l'écran de démarrage.
  if (session is SessionInconnue || !demarrageTermine) {
    if (chemin == Routes.demarrage) return null;
    return _avecRetour(Routes.demarrage, demande);
  }
  if (chemin == Routes.demarrage) {
    if (session is SessionAnonyme && !bienvenueVue) return Routes.bienvenue;
    return _retourSur(retour) ?? Routes.accueil;
  }
  switch (session) {
    case SessionInconnue():
      return null;
    case SessionAnonyme():
      if (commencePar(chemin, prefixesConnexion)) {
        return _avecRetour(Routes.connexion, demande);
      }
      return null;
    case SessionConnectee(:final utilisateur):
      if (pagesVisiteur.contains(chemin)) {
        return _retourSur(retour) ?? Routes.accueil;
      }
      // Ne devrait pas arriver (le serveur n'ouvre de session qu'après
      // vérification du téléphone) : l'écran sécurité permet de le refaire.
      if (!utilisateur.telephoneVerifie &&
          commencePar(chemin, prefixesTelephone)) {
        return Routes.securite;
      }
      if (!utilisateur.estVendeur && commencePar(chemin, prefixesVendeur)) {
        return Routes.devenirVendeur;
      }
      if (utilisateur.estVendeur && chemin == Routes.devenirVendeur) {
        return Routes.espaceVendeur;
      }
      return null;
  }
}

String _avecRetour(String cible, Uri demande) {
  final origine = demande.toString();
  if (origine == Routes.accueil || origine.isEmpty) return cible;
  return Uri(
    path: cible,
    queryParameters: {Routes.parametreRetour: origine},
  ).toString();
}

/// N'accepte qu'un chemin interne (pas d'URL externe dans `?de=`).
String? _retourSur(String? retour) {
  if (retour == null || !retour.startsWith('/') || retour.startsWith('//')) {
    return null;
  }
  if (pagesVisiteur.contains(Uri.parse(retour).path)) return null;
  return retour;
}
