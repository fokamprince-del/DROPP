/// Chemins de l'app. Un écran se déclare dans `app_router.dart` et, s'il
/// demande une condition (connexion, vendeur…), dans les ensembles ci-dessous.
abstract final class Routes {
  static const demarrage = '/demarrage';
  static const bienvenue = '/bienvenue';

  // Auth (Dev B)
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const verificationTelephone = '/verification-telephone';
  static const motDePasseOublie = '/mot-de-passe-oublie';
  static const reinitialiserMotDePasse = '/reinitialiser-mot-de-passe';

  // Onglets
  static const accueil = '/';
  static const recherche = '/recherche';
  static const panier = '/panier';
  static const messages = '/messages';
  static const profil = '/profil';

  static const securite = '/profil/securite';

  // Fil et stories (consultables sans compte)
  static const publications = '/publications';
  static String publication(String id) => '$publications/$id';
  static const stories = '/stories';

  // Catalogue et boutiques (consultables sans compte)
  static const produits = '/produits';
  static String produit(String id) => '$produits/$id';
  static String avisProduit(String id) => '$produits/$id/avis';
  static const boutiques = '/boutiques';
  static String boutique(String id) => '$boutiques/$id';

  static const mesAbonnements = '/profil/abonnements';

  /// Confirmation ou changement de l'adresse email (connexion requise).
  static const confirmerEmail = '/profil/email';
  static const adresses = '/profil/adresses';
  static const nouvelleAdresse = '/profil/adresses/nouvelle';
  static String adresse(String id) => '$adresses/$id';
  static const avisANoter = '/profil/avis';
  static const modifierProfil = '/profil/modifier';
  static const motDePasse = '/profil/securite/mot-de-passe';
  static const changerTelephone = '/profil/securite/telephone';
  static const bloques = '/profil/bloques';
  static const mesSignalements = '/profil/signalements';
  static const mesFavoris = '/profil/favoris';

  // Notifications (connexion requise)
  static const notifications = '/notifications';
  static const preferencesNotifications = '/notifications/preferences';

  // Achat (connexion requise)
  static const commandes = '/commandes';
  static String commande(String id) => '$commandes/$id';

  // Messagerie (connexion et téléphone vérifié)
  static const conversations = '/conversations';
  static String conversation(String id) => '$conversations/$id';

  // Vendeur
  static const devenirVendeur = '/devenir-vendeur';
  static const espaceVendeur = '/vendeur';

  /// Paramètre de requête qui ramène à la page demandée après connexion.
  static const parametreRetour = 'de';
}

/// Pages réservées aux visiteurs : un utilisateur connecté en est redirigé.
const pagesVisiteur = {
  Routes.bienvenue,
  Routes.connexion,
  Routes.inscription,
  Routes.verificationTelephone,
  Routes.motDePasseOublie,
  Routes.reinitialiserMotDePasse,
};

/// Préfixes qui demandent d'être connecté. Le reste (fil, catalogue, fiches
/// produit et boutique) est consultable sans compte.
const prefixesConnexion = [
  Routes.panier,
  Routes.messages,
  Routes.profil,
  Routes.devenirVendeur,
  Routes.espaceVendeur,
  Routes.commandes,
  Routes.conversations,
  Routes.notifications,
];

/// Préfixes qui demandent un téléphone vérifié (même règle que l'API).
const prefixesTelephone = [
  Routes.messages,
  Routes.conversations,
  Routes.devenirVendeur,
  Routes.espaceVendeur,
];

/// Préfixes réservés aux vendeurs.
const prefixesVendeur = [Routes.espaceVendeur];

/// Pages du parcours « devenir vendeur » : fermées aux vendeurs actifs.
const prefixesDevenirVendeur = [Routes.devenirVendeur];

bool commencePar(String chemin, Iterable<String> prefixes) => prefixes.any(
  (p) => p == Routes.accueil
      ? chemin == p
      : chemin == p || chemin.startsWith('$p/'),
);
