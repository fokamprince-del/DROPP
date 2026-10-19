/// Chemins de l'app. Un écran se déclare dans `app_router.dart` et, s'il
/// demande une condition (connexion, vendeur…), dans les ensembles ci-dessous.
abstract final class Routes {
  static const demarrage = '/demarrage';

  // Auth (Dev B)
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const verificationTelephone = '/verification-telephone';
  static const motDePasseOublie = '/mot-de-passe-oublie';

  // Onglets
  static const accueil = '/';
  static const recherche = '/recherche';
  static const panier = '/panier';
  static const messages = '/messages';
  static const profil = '/profil';

  static const securite = '/profil/securite';

  // Vendeur
  static const devenirVendeur = '/devenir-vendeur';
  static const espaceVendeur = '/vendeur';

  /// Paramètre de requête qui ramène à la page demandée après connexion.
  static const parametreRetour = 'de';
}

/// Pages réservées aux visiteurs : un utilisateur connecté en est redirigé.
const pagesVisiteur = {
  Routes.connexion,
  Routes.inscription,
  Routes.verificationTelephone,
  Routes.motDePasseOublie,
};

/// Préfixes qui demandent d'être connecté. Le reste (fil, catalogue, fiches
/// produit et boutique) est consultable sans compte.
const prefixesConnexion = [
  Routes.panier,
  Routes.messages,
  Routes.profil,
  Routes.devenirVendeur,
  Routes.espaceVendeur,
  '/commandes',
  '/notifications',
];

/// Préfixes qui demandent un téléphone vérifié (même règle que l'API).
const prefixesTelephone = [
  Routes.messages,
  Routes.devenirVendeur,
  Routes.espaceVendeur,
];

/// Préfixes réservés aux vendeurs.
const prefixesVendeur = [Routes.espaceVendeur];

bool commencePar(String chemin, Iterable<String> prefixes) => prefixes.any(
      (p) => p == Routes.accueil
          ? chemin == p
          : chemin == p || chemin.startsWith('$p/'),
    );
