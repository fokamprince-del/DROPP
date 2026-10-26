import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @nomApp.
  ///
  /// In fr, this message translates to:
  /// **'DROPP'**
  String get nomApp;

  /// No description provided for @navAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navAccueil;

  /// No description provided for @navDecouvrir.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get navDecouvrir;

  /// No description provided for @navPanier.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get navPanier;

  /// No description provided for @navMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfil;

  /// No description provided for @baselineApp.
  ///
  /// In fr, this message translates to:
  /// **'Le marché camerounais dans ta poche'**
  String get baselineApp;

  /// No description provided for @navPanierArticles.
  ///
  /// In fr, this message translates to:
  /// **'Panier, {count, plural, =1{1 article} other{{count} articles}}'**
  String navPanierArticles(int count);

  /// No description provided for @navMessagesNonLus.
  ///
  /// In fr, this message translates to:
  /// **'Messages, {count, plural, =1{1 non lu} other{{count} non lus}}'**
  String navMessagesNonLus(int count);

  /// No description provided for @champPrenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get champPrenom;

  /// No description provided for @champNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get champNom;

  /// No description provided for @champSexe.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get champSexe;

  /// No description provided for @sexeMasculin.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get sexeMasculin;

  /// No description provided for @sexeFeminin.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get sexeFeminin;

  /// No description provided for @sexeAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get sexeAutre;

  /// No description provided for @champTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get champTelephone;

  /// No description provided for @champEmailFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Email (facultatif)'**
  String get champEmailFacultatif;

  /// No description provided for @champMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get champMotDePasse;

  /// No description provided for @erreurRequis.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get erreurRequis;

  /// No description provided for @erreurTelephoneInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get erreurTelephoneInvalide;

  /// No description provided for @erreurEmailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get erreurEmailInvalide;

  /// No description provided for @erreurMotDePasseCourt.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get erreurMotDePasseCourt;

  /// No description provided for @erreurCodeIncomplet.
  ///
  /// In fr, this message translates to:
  /// **'Saisis les 6 chiffres du code'**
  String get erreurCodeIncomplet;

  /// No description provided for @forceMotDePasse1.
  ///
  /// In fr, this message translates to:
  /// **'Faible. Utilise 8 caractères minimum, avec lettres et chiffres.'**
  String get forceMotDePasse1;

  /// No description provided for @forceMotDePasse2.
  ///
  /// In fr, this message translates to:
  /// **'Moyen. Ajoute des chiffres ou des majuscules.'**
  String get forceMotDePasse2;

  /// No description provided for @forceMotDePasse3.
  ///
  /// In fr, this message translates to:
  /// **'Solide. Ajoute un symbole pour le rendre très solide.'**
  String get forceMotDePasse3;

  /// No description provided for @forceMotDePasse4.
  ///
  /// In fr, this message translates to:
  /// **'Très solide.'**
  String get forceMotDePasse4;

  /// No description provided for @champCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get champCode;

  /// No description provided for @motDePasseAfficher.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get motDePasseAfficher;

  /// No description provided for @motDePasseMasquer.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get motDePasseMasquer;

  /// No description provided for @champIdentifiant.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone ou email'**
  String get champIdentifiant;

  /// No description provided for @champNouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get champNouveauMotDePasse;

  /// No description provided for @erreurIdentifiantInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro ou email invalide'**
  String get erreurIdentifiantInvalide;

  /// No description provided for @erreurReseau.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get erreurReseau;

  /// No description provided for @erreurDelai.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre. Réessaie.'**
  String get erreurDelai;

  /// No description provided for @erreurTropDeTentatives.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patiente une minute avant de réessayer.'**
  String get erreurTropDeTentatives;

  /// No description provided for @erreurServeur.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur rencontre un problème. Réessaie plus tard.'**
  String get erreurServeur;

  /// No description provided for @erreurInterdit.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte ne peut pas être utilisé pour le moment.'**
  String get erreurInterdit;

  /// No description provided for @erreurRequeteInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie les informations saisies.'**
  String get erreurRequeteInvalide;

  /// No description provided for @erreurInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get erreurInconnue;

  /// No description provided for @erreurIdentifiantsIncorrects.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects.'**
  String get erreurIdentifiantsIncorrects;

  /// No description provided for @erreurCompteExistant.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec ce numéro ou cet email.'**
  String get erreurCompteExistant;

  /// No description provided for @erreurCodeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré. Vérifie-le ou demande-en un nouveau.'**
  String get erreurCodeIncorrect;

  /// No description provided for @erreurCodeExpire.
  ///
  /// In fr, this message translates to:
  /// **'Code expiré ou trop d\'essais. Demande un nouveau code.'**
  String get erreurCodeExpire;

  /// No description provided for @erreurVerificationExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Vérification expirée. Recommence depuis le début.'**
  String get erreurVerificationExpiree;

  /// No description provided for @erreurRequeteEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Une demande identique est en cours. Patiente un instant.'**
  String get erreurRequeteEnCours;

  /// No description provided for @sessionExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Reconnecte-toi.'**
  String get sessionExpiree;

  /// No description provided for @inscriptionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get inscriptionTitre;

  /// No description provided for @inscriptionSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Un code d\'activation te sera envoyé par SMS.'**
  String get inscriptionSousTitre;

  /// No description provided for @inscriptionBouton.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code par SMS'**
  String get inscriptionBouton;

  /// No description provided for @inscriptionConditions.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, tu acceptes les conditions d\'utilisation.'**
  String get inscriptionConditions;

  /// No description provided for @jaiDejaUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get jaiDejaUnCompte;

  /// No description provided for @connexionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir'**
  String get connexionTitre;

  /// No description provided for @connexionSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi avec ton numéro ou ton email.'**
  String get connexionSousTitre;

  /// No description provided for @connexionBouton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get connexionBouton;

  /// No description provided for @creerUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerUnCompte;

  /// No description provided for @motDePasseOublieLien.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get motDePasseOublieLien;

  /// No description provided for @codeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Entre le code reçu par SMS'**
  String get codeTitre;

  /// No description provided for @codeEnvoyeA.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé au {numero}. Valable 5 minutes.'**
  String codeEnvoyeA(String numero);

  /// No description provided for @codeEnvoyeAuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Un code vient d\'être envoyé par SMS au numéro de ton compte. Valable 5 minutes.'**
  String get codeEnvoyeAuCompte;

  /// No description provided for @codeVerifier.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get codeVerifier;

  /// No description provided for @renvoyerCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get renvoyerCode;

  /// No description provided for @renvoyerCodeDans.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {duree}'**
  String renvoyerCodeDans(String duree);

  /// No description provided for @oubliTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get oubliTitre;

  /// No description provided for @oubliSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton numéro ou ton email. Si un compte existe, un code te sera envoyé.'**
  String get oubliSousTitre;

  /// No description provided for @oubliSecurite.
  ///
  /// In fr, this message translates to:
  /// **'Par sécurité, toutes tes sessions seront déconnectées après le changement.'**
  String get oubliSecurite;

  /// No description provided for @oubliBouton.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get oubliBouton;

  /// No description provided for @reinitTitre.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get reinitTitre;

  /// No description provided for @reinitSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le code reçu, puis choisis un nouveau mot de passe.'**
  String get reinitSousTitre;

  /// No description provided for @reinitBouton.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get reinitBouton;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @rienAAfficher.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher pour le moment.'**
  String get rienAAfficher;

  /// No description provided for @tempsInstant.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get tempsInstant;

  /// No description provided for @tempsMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} min'**
  String tempsMinutes(int n);

  /// No description provided for @tempsHeures.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} h'**
  String tempsHeures(int n);

  /// No description provided for @tempsJours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} j'**
  String tempsJours(int n);

  /// No description provided for @filPourToi.
  ///
  /// In fr, this message translates to:
  /// **'Pour toi'**
  String get filPourToi;

  /// No description provided for @filAbonnements.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get filAbonnements;

  /// No description provided for @filPourToiVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication pour le moment. Reviens bientôt !'**
  String get filPourToiVide;

  /// No description provided for @filAbonnementsVideTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ton fil est encore vide'**
  String get filAbonnementsVideTitre;

  /// No description provided for @filAbonnementsVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Suis des boutiques pour voir leurs nouveautés ici en premier.'**
  String get filAbonnementsVideTexte;

  /// No description provided for @filDecouvrirBoutiques.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir des boutiques'**
  String get filDecouvrirBoutiques;

  /// No description provided for @filConnexionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour suivre des boutiques'**
  String get filConnexionTitre;

  /// No description provided for @filConnexionTexte.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveautés des boutiques que tu suis apparaîtront ici.'**
  String get filConnexionTexte;

  /// No description provided for @publicationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get publicationTitre;

  /// No description provided for @publicationOuvrir.
  ///
  /// In fr, this message translates to:
  /// **'Voir la publication de {boutique}'**
  String publicationOuvrir(String boutique);

  /// No description provided for @publicationVues.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucune vue} =1{1 vue} other{{count} vues}}'**
  String publicationVues(int count);

  /// No description provided for @publicationLikes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun j\'aime} =1{1 j\'aime} other{{count} j\'aime}}'**
  String publicationLikes(int count);

  /// No description provided for @publicationCommentaires.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun commentaire} =1{1 commentaire} other{{count} commentaires}}'**
  String publicationCommentaires(int count);

  /// No description provided for @publicationAbonnes.
  ///
  /// In fr, this message translates to:
  /// **'Réservée aux abonnés'**
  String get publicationAbonnes;

  /// No description provided for @publicationProduits.
  ///
  /// In fr, this message translates to:
  /// **'Dans cette publication'**
  String get publicationProduits;

  /// No description provided for @mediaVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get mediaVideo;

  /// No description provided for @mediaPosition.
  ///
  /// In fr, this message translates to:
  /// **'{position}/{total}'**
  String mediaPosition(int position, int total);

  /// No description provided for @videoIllisible.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire la vidéo. Touche pour réessayer.'**
  String get videoIllisible;

  /// No description provided for @storyDe.
  ///
  /// In fr, this message translates to:
  /// **'Story de {boutique}'**
  String storyDe(String boutique);

  /// No description provided for @storyNouvelle.
  ///
  /// In fr, this message translates to:
  /// **'{boutique}, nouvelle story'**
  String storyNouvelle(String boutique);

  /// No description provided for @storySuivante.
  ///
  /// In fr, this message translates to:
  /// **'Story suivante'**
  String get storySuivante;

  /// No description provided for @storyPrecedente.
  ///
  /// In fr, this message translates to:
  /// **'Story précédente'**
  String get storyPrecedente;

  /// No description provided for @storyFermer.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get storyFermer;

  /// No description provided for @storyIllisible.
  ///
  /// In fr, this message translates to:
  /// **'Cette story ne peut pas être affichée.'**
  String get storyIllisible;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @erreurActionInterdite.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible avec ce compte. Vérifie ton numéro de téléphone.'**
  String get erreurActionInterdite;

  /// No description provided for @erreurContenuIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu n\'est plus disponible.'**
  String get erreurContenuIntrouvable;

  /// No description provided for @favoriAjouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get favoriAjouter;

  /// No description provided for @favoriRetirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoriRetirer;

  /// No description provided for @partageTitre.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get partageTitre;

  /// No description provided for @partageCopierLien.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get partageCopierLien;

  /// No description provided for @partageLienCopie.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié'**
  String get partageLienCopie;

  /// No description provided for @partageWhatsAppAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir WhatsApp sur cet appareil.'**
  String get partageWhatsAppAbsent;

  /// No description provided for @partageTexte.
  ///
  /// In fr, this message translates to:
  /// **'Découvre {boutique} sur DROPP : {lien}'**
  String partageTexte(String boutique, String lien);

  /// No description provided for @commentairesTitre.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Commentaires} =1{1 commentaire} other{{count} commentaires}}'**
  String commentairesTitre(int count);

  /// No description provided for @commentairesVide.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de commentaire. Sois le premier !'**
  String get commentairesVide;

  /// No description provided for @commentairesVoirReponses.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Voir 1 autre réponse} other{Voir {count} autres réponses}}'**
  String commentairesVoirReponses(int count);

  /// No description provided for @commentairesConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour commenter'**
  String get commentairesConnexion;

  /// No description provided for @commentaireRepondre.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get commentaireRepondre;

  /// No description provided for @commentaireCreateur.
  ///
  /// In fr, this message translates to:
  /// **'Créateur'**
  String get commentaireCreateur;

  /// No description provided for @commentaireReponseA.
  ///
  /// In fr, this message translates to:
  /// **'Réponse à {auteur}'**
  String commentaireReponseA(String auteur);

  /// No description provided for @commentairePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire… (@pseudo pour mentionner)'**
  String get commentairePlaceholder;

  /// No description provided for @commentairePublier.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get commentairePublier;

  /// No description provided for @commentaireSupprimerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce commentaire ?'**
  String get commentaireSupprimerTitre;

  /// No description provided for @commentaireSupprimerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Il disparaîtra pour tout le monde, avec ses réponses.'**
  String get commentaireSupprimerTexte;

  /// No description provided for @rechercheIndice.
  ///
  /// In fr, this message translates to:
  /// **'Robe, téléphone, boutique…'**
  String get rechercheIndice;

  /// No description provided for @rechercheEffacer.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get rechercheEffacer;

  /// No description provided for @decouvrirProduits.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get decouvrirProduits;

  /// No description provided for @decouvrirBoutiques.
  ///
  /// In fr, this message translates to:
  /// **'Boutiques'**
  String get decouvrirBoutiques;

  /// No description provided for @catalogueTout.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get catalogueTout;

  /// No description provided for @catalogueVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit avec ces filtres'**
  String get catalogueVide;

  /// No description provided for @catalogueEffacerFiltres.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get catalogueEffacerFiltres;

  /// No description provided for @boutiquesVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune boutique trouvée'**
  String get boutiquesVide;

  /// No description provided for @triRecents.
  ///
  /// In fr, this message translates to:
  /// **'Plus récents'**
  String get triRecents;

  /// No description provided for @triPrixCroissant.
  ///
  /// In fr, this message translates to:
  /// **'Prix croissant'**
  String get triPrixCroissant;

  /// No description provided for @triPrixDecroissant.
  ///
  /// In fr, this message translates to:
  /// **'Prix décroissant'**
  String get triPrixDecroissant;

  /// No description provided for @triPopulaires.
  ///
  /// In fr, this message translates to:
  /// **'Les plus aimés'**
  String get triPopulaires;

  /// No description provided for @filtresTitre.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtresTitre;

  /// No description provided for @filtresPrix.
  ///
  /// In fr, this message translates to:
  /// **'Prix (FCFA)'**
  String get filtresPrix;

  /// No description provided for @filtresPrixMin.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get filtresPrixMin;

  /// No description provided for @filtresPrixMax.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get filtresPrixMax;

  /// No description provided for @filtresTri.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get filtresTri;

  /// No description provided for @filtresEnStock.
  ///
  /// In fr, this message translates to:
  /// **'En stock uniquement'**
  String get filtresEnStock;

  /// No description provided for @filtresReinitialiser.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get filtresReinitialiser;

  /// No description provided for @filtresAppliquer.
  ///
  /// In fr, this message translates to:
  /// **'Voir les produits'**
  String get filtresAppliquer;

  /// No description provided for @prixMoinsDe.
  ///
  /// In fr, this message translates to:
  /// **'Moins de {montant}'**
  String prixMoinsDe(String montant);

  /// No description provided for @prixPlusDe.
  ///
  /// In fr, this message translates to:
  /// **'Plus de {montant}'**
  String prixPlusDe(String montant);

  /// No description provided for @prixAPartirDe.
  ///
  /// In fr, this message translates to:
  /// **'À partir de {prix}'**
  String prixAPartirDe(String prix);

  /// No description provided for @stockEnStock.
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get stockEnStock;

  /// No description provided for @stockRupture.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get stockRupture;

  /// No description provided for @stockPlusQue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Plus qu\'1 en stock} other{Plus que {count} en stock}}'**
  String stockPlusQue(int count);

  /// No description provided for @varianteNumero.
  ///
  /// In fr, this message translates to:
  /// **'Option {numero}'**
  String varianteNumero(int numero);

  /// No description provided for @avisTitre.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get avisTitre;

  /// No description provided for @avisTitreNombre.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Avis} other{Avis ({count})}}'**
  String avisTitreNombre(int count);

  /// No description provided for @avisNombre.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun avis} =1{1 avis} other{{count} avis}}'**
  String avisNombre(int count);

  /// No description provided for @avisAucun.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'avis sur ce produit.'**
  String get avisAucun;

  /// No description provided for @avisVoirTous.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {count} avis'**
  String avisVoirTous(int count);

  /// No description provided for @avisNote.
  ///
  /// In fr, this message translates to:
  /// **'{note} étoiles sur 5'**
  String avisNote(int note);

  /// No description provided for @avisMoyenne.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne : {note} sur 5'**
  String avisMoyenne(String note);

  /// No description provided for @avisAchatVerifie.
  ///
  /// In fr, this message translates to:
  /// **'Achat vérifié'**
  String get avisAchatVerifie;

  /// No description provided for @boutiqueSuivre.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get boutiqueSuivre;

  /// No description provided for @boutiqueAbonne.
  ///
  /// In fr, this message translates to:
  /// **'Abonné'**
  String get boutiqueAbonne;

  /// No description provided for @boutiqueAbonnes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun abonné} =1{1 abonné} other{{count} abonnés}}'**
  String boutiqueAbonnes(int count);

  /// No description provided for @boutiqueAbonnesLibelle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{abonné} other{abonnés}}'**
  String boutiqueAbonnesLibelle(int count);

  /// No description provided for @boutiqueProduitsLibelle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{produit} other{produits}}'**
  String boutiqueProduitsLibelle(int count);

  /// No description provided for @boutiquePublications.
  ///
  /// In fr, this message translates to:
  /// **'Publications'**
  String get boutiquePublications;

  /// No description provided for @boutiqueAucunProduit.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit en ligne pour le moment.'**
  String get boutiqueAucunProduit;

  /// No description provided for @boutiqueAucunePublication.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication pour le moment.'**
  String get boutiqueAucunePublication;

  /// No description provided for @abonnementsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes abonnements'**
  String get abonnementsTitre;

  /// No description provided for @abonnementsVideTitre.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne suis encore aucune boutique'**
  String get abonnementsVideTitre;

  /// No description provided for @abonnementsDepuis.
  ///
  /// In fr, this message translates to:
  /// **'Abonné depuis le {date}'**
  String abonnementsDepuis(String date);

  /// No description provided for @champEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get champEmail;

  /// No description provided for @erreurEmailUtilisee.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse email est déjà utilisée.'**
  String get erreurEmailUtilisee;

  /// No description provided for @erreurMotDePasseIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get erreurMotDePasseIncorrect;

  /// No description provided for @emailTitre.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ton adresse email'**
  String get emailTitre;

  /// No description provided for @emailSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un code à {email}. Elle servira à récupérer ton compte.'**
  String emailSousTitre(String email);

  /// No description provided for @emailConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get emailConfirmer;

  /// No description provided for @emailConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email confirmée.'**
  String get emailConfirmee;

  /// No description provided for @emailPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get emailPlusTard;

  /// No description provided for @emailChangerLien.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'adresse'**
  String get emailChangerLien;

  /// No description provided for @emailAjouterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton adresse email'**
  String get emailAjouterTitre;

  /// No description provided for @emailChangerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'adresse email'**
  String get emailChangerTitre;

  /// No description provided for @emailChangerSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Un code sera envoyé à la nouvelle adresse. L\'ancienne reste active jusqu\'à la confirmation.'**
  String get emailChangerSousTitre;

  /// No description provided for @emailRecevoirCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get emailRecevoirCode;

  /// No description provided for @emailTitreConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email confirmée'**
  String get emailTitreConfirmee;

  /// No description provided for @emailDejaConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'{email} est confirmée. Tu peux t\'en servir pour récupérer ton compte.'**
  String emailDejaConfirmee(String email);

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @aujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aujourdhui;

  /// No description provided for @hier.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get hier;

  /// No description provided for @mediaGaleriePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de la galerie'**
  String get mediaGaleriePhoto;

  /// No description provided for @mediaPrendrePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get mediaPrendrePhoto;

  /// No description provided for @mediaGalerieVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo de la galerie'**
  String get mediaGalerieVideo;

  /// No description provided for @mediaFilmer.
  ///
  /// In fr, this message translates to:
  /// **'Filmer une vidéo'**
  String get mediaFilmer;

  /// No description provided for @fichierTropGros.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux : {mo} Mo au maximum.'**
  String fichierTropGros(int mo);

  /// No description provided for @fichierFormatRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge. Choisis une photo (JPEG, PNG, WebP) ou une vidéo (MP4, MOV).'**
  String get fichierFormatRefuse;

  /// No description provided for @panierVide.
  ///
  /// In fr, this message translates to:
  /// **'Ton panier est vide'**
  String get panierVide;

  /// No description provided for @panierVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des articles depuis la fiche d\'un produit.'**
  String get panierVideTexte;

  /// No description provided for @panierNombreArticles.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String panierNombreArticles(int count);

  /// No description provided for @panierAjouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get panierAjouter;

  /// No description provided for @panierChoisirOption.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une option'**
  String get panierChoisirOption;

  /// No description provided for @panierAjoute.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get panierAjoute;

  /// No description provided for @panierVoir.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get panierVoir;

  /// No description provided for @panierStockInsuffisant.
  ///
  /// In fr, this message translates to:
  /// **'Stock insuffisant pour cette quantité.'**
  String get panierStockInsuffisant;

  /// No description provided for @panierStockRestant.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Plus qu\'1 en stock : réduis la quantité} other{Plus que {count} en stock : réduis la quantité}}'**
  String panierStockRestant(int count);

  /// No description provided for @panierIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'Plus disponible : retire-le pour commander'**
  String get panierIndisponible;

  /// No description provided for @panierPrixModifie.
  ///
  /// In fr, this message translates to:
  /// **'Prix mis à jour depuis l\'ajout'**
  String get panierPrixModifie;

  /// No description provided for @panierQuantite.
  ///
  /// In fr, this message translates to:
  /// **'Quantité : {count}'**
  String panierQuantite(int count);

  /// No description provided for @panierMoins.
  ///
  /// In fr, this message translates to:
  /// **'Diminuer la quantité'**
  String get panierMoins;

  /// No description provided for @panierPlus.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter la quantité'**
  String get panierPlus;

  /// No description provided for @panierSousTotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get panierSousTotal;

  /// No description provided for @panierLivraison.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get panierLivraison;

  /// No description provided for @panierLivraisonPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Calculée à l\'étape suivante'**
  String get panierLivraisonPlusTard;

  /// No description provided for @panierTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get panierTotal;

  /// No description provided for @panierProtection.
  ///
  /// In fr, this message translates to:
  /// **'Paiement protégé : le vendeur est payé après la livraison.'**
  String get panierProtection;

  /// No description provided for @panierNonCommandable.
  ///
  /// In fr, this message translates to:
  /// **'Retire les articles indisponibles pour commander.'**
  String get panierNonCommandable;

  /// No description provided for @panierCommander.
  ///
  /// In fr, this message translates to:
  /// **'Commander · {prix}'**
  String panierCommander(String prix);

  /// No description provided for @commanderTitre.
  ///
  /// In fr, this message translates to:
  /// **'Passer la commande ?'**
  String get commanderTitre;

  /// No description provided for @commanderTexte.
  ///
  /// In fr, this message translates to:
  /// **'Les articles sont réservés pendant {minutes} minutes, le temps du paiement. Sans paiement, la commande est annulée et le stock rendu.'**
  String commanderTexte(int minutes);

  /// No description provided for @commanderConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get commanderConfirmer;

  /// No description provided for @commanderPanierChange.
  ///
  /// In fr, this message translates to:
  /// **'Ton panier a changé (stock ou prix). Vérifie-le avant de commander.'**
  String get commanderPanierChange;

  /// No description provided for @commandesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get commandesTitre;

  /// No description provided for @commandesVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande pour le moment'**
  String get commandesVide;

  /// No description provided for @commandeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get commandeTitre;

  /// No description provided for @commandeDu.
  ///
  /// In fr, this message translates to:
  /// **'Commande du {date}'**
  String commandeDu(String date);

  /// No description provided for @commandeAPayerAvant.
  ///
  /// In fr, this message translates to:
  /// **'À payer avant l\'annulation automatique'**
  String get commandeAPayerAvant;

  /// No description provided for @commandeDelaiDepasse.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé : la commande va être annulée.'**
  String get commandeDelaiDepasse;

  /// No description provided for @commandePaiementBientot.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement par Mobile Money (MTN MoMo, Orange Money) arrive très bientôt dans l\'application.'**
  String get commandePaiementBientot;

  /// No description provided for @commandeAnnuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get commandeAnnuler;

  /// No description provided for @commandeAnnulerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette commande ?'**
  String get commandeAnnulerTitre;

  /// No description provided for @commandeAnnulerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Les articles seront remis en vente.'**
  String get commandeAnnulerTexte;

  /// No description provided for @commandeGarder.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get commandeGarder;

  /// No description provided for @commandeDejaTraitee.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande a déjà été traitée.'**
  String get commandeDejaTraitee;

  /// No description provided for @statutEnAttentePaiement.
  ///
  /// In fr, this message translates to:
  /// **'En attente de paiement'**
  String get statutEnAttentePaiement;

  /// No description provided for @statutNouvelle.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get statutNouvelle;

  /// No description provided for @statutEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get statutEnCours;

  /// No description provided for @statutExpediee.
  ///
  /// In fr, this message translates to:
  /// **'Expédiée'**
  String get statutExpediee;

  /// No description provided for @statutLivree.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get statutLivree;

  /// No description provided for @statutAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get statutAnnulee;

  /// No description provided for @statutEnLitige.
  ///
  /// In fr, this message translates to:
  /// **'En litige'**
  String get statutEnLitige;

  /// No description provided for @adressesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get adressesTitre;

  /// No description provided for @adressesVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistrée'**
  String get adressesVide;

  /// No description provided for @adressesVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une adresse pour être livré plus vite.'**
  String get adressesVideTexte;

  /// No description provided for @adresseAjouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get adresseAjouter;

  /// No description provided for @adresseModifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get adresseModifier;

  /// No description provided for @adresseSupprimerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette adresse ?'**
  String get adresseSupprimerTitre;

  /// No description provided for @adresseLivraison.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get adresseLivraison;

  /// No description provided for @adresseFacturation.
  ///
  /// In fr, this message translates to:
  /// **'Facturation'**
  String get adresseFacturation;

  /// No description provided for @adresseAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get adresseAutre;

  /// No description provided for @adressePrincipale.
  ///
  /// In fr, this message translates to:
  /// **'Principale'**
  String get adressePrincipale;

  /// No description provided for @adresseLigne1.
  ///
  /// In fr, this message translates to:
  /// **'Quartier, rue, point de repère'**
  String get adresseLigne1;

  /// No description provided for @adresseLigne2.
  ///
  /// In fr, this message translates to:
  /// **'Complément (bâtiment, étage…)'**
  String get adresseLigne2;

  /// No description provided for @adresseVille.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get adresseVille;

  /// No description provided for @adresseRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get adresseRegion;

  /// No description provided for @adressePays.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get adressePays;

  /// No description provided for @adresseCodePostal.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get adresseCodePostal;

  /// No description provided for @adresseDefinirPrincipale.
  ///
  /// In fr, this message translates to:
  /// **'Adresse principale'**
  String get adresseDefinirPrincipale;

  /// No description provided for @avisANoterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Avis à laisser'**
  String get avisANoterTitre;

  /// No description provided for @avisANoterVide.
  ///
  /// In fr, this message translates to:
  /// **'Rien à noter pour le moment'**
  String get avisANoterVide;

  /// No description provided for @avisANoterVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Tes articles livrés apparaîtront ici.'**
  String get avisANoterVideTexte;

  /// No description provided for @avisCommandeLe.
  ///
  /// In fr, this message translates to:
  /// **'commandé le {date}'**
  String avisCommandeLe(String date);

  /// No description provided for @avisNoter.
  ///
  /// In fr, this message translates to:
  /// **'Noter'**
  String get avisNoter;

  /// No description provided for @avisTonAvis.
  ///
  /// In fr, this message translates to:
  /// **'Ton avis'**
  String get avisTonAvis;

  /// No description provided for @avisCommentaireIndice.
  ///
  /// In fr, this message translates to:
  /// **'Qualité, taille, livraison… (facultatif)'**
  String get avisCommentaireIndice;

  /// No description provided for @avisPublier.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'avis'**
  String get avisPublier;

  /// No description provided for @avisModifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon avis'**
  String get avisModifier;

  /// No description provided for @avisSupprimerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ton avis ?'**
  String get avisSupprimerTitre;

  /// No description provided for @avisMesActions.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon avis'**
  String get avisMesActions;

  /// No description provided for @avisNonModifiable.
  ///
  /// In fr, this message translates to:
  /// **'Un avis n\'est plus modifiable après 30 jours.'**
  String get avisNonModifiable;

  /// No description provided for @avisDejaDonne.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà donné ton avis sur cet article.'**
  String get avisDejaDonne;

  /// No description provided for @boutiqueMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get boutiqueMessage;

  /// No description provided for @boutiqueEcrire.
  ///
  /// In fr, this message translates to:
  /// **'Écrire à la boutique'**
  String get boutiqueEcrire;

  /// No description provided for @conversationsVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get conversationsVide;

  /// No description provided for @conversationsVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Écris à une boutique depuis la fiche d\'un produit ou sa page.'**
  String get conversationsVideTexte;

  /// No description provided for @conversationCompteSupprime.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get conversationCompteSupprime;

  /// No description provided for @messageDeMoi.
  ///
  /// In fr, this message translates to:
  /// **'Toi : {texte}'**
  String messageDeMoi(String texte);

  /// No description provided for @messagePhoto.
  ///
  /// In fr, this message translates to:
  /// **'📷 Photo'**
  String get messagePhoto;

  /// No description provided for @messageVideo.
  ///
  /// In fr, this message translates to:
  /// **'🎥 Vidéo'**
  String get messageVideo;

  /// No description provided for @messagePieceJointe.
  ///
  /// In fr, this message translates to:
  /// **'📎 Pièce jointe'**
  String get messagePieceJointe;

  /// No description provided for @messageIndice.
  ///
  /// In fr, this message translates to:
  /// **'Écris un message…'**
  String get messageIndice;

  /// No description provided for @messageEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get messageEnvoyer;

  /// No description provided for @messageJoindre.
  ///
  /// In fr, this message translates to:
  /// **'Joindre une photo ou une vidéo'**
  String get messageJoindre;

  /// No description provided for @messagePiecesMax.
  ///
  /// In fr, this message translates to:
  /// **'{max} fichiers au plus par message.'**
  String messagePiecesMax(int max);

  /// No description provided for @messageFichiers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier} other{{count} fichiers}}'**
  String messageFichiers(int count);

  /// No description provided for @messageEnvoi.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get messageEnvoi;

  /// No description provided for @messageEnvoye.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get messageEnvoye;

  /// No description provided for @messageLu.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get messageLu;

  /// No description provided for @messageEnvoiInterdit.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'écrire dans cette conversation.'**
  String get messageEnvoiInterdit;

  /// No description provided for @discussionDebut.
  ///
  /// In fr, this message translates to:
  /// **'Début de la conversation'**
  String get discussionDebut;

  /// No description provided for @discussionFermee.
  ///
  /// In fr, this message translates to:
  /// **'Cette conversation est fermée.'**
  String get discussionFermee;

  /// No description provided for @plusDOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get plusDOptions;

  /// No description provided for @discussionEcrit.
  ///
  /// In fr, this message translates to:
  /// **'en train d\'écrire…'**
  String get discussionEcrit;

  /// No description provided for @signaler.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get signaler;

  /// No description provided for @signalerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce contenu'**
  String get signalerTitre;

  /// No description provided for @signalementDescriptionObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Explique ce qui ne va pas (obligatoire)'**
  String get signalementDescriptionObligatoire;

  /// No description provided for @signalementDescriptionFacultative.
  ///
  /// In fr, this message translates to:
  /// **'Précisions (facultatif)'**
  String get signalementDescriptionFacultative;

  /// No description provided for @signalementEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get signalementEnvoyer;

  /// No description provided for @signalementAnonyme.
  ///
  /// In fr, this message translates to:
  /// **'La personne signalée ne saura pas que c\'est toi.'**
  String get signalementAnonyme;

  /// No description provided for @signalementEnvoye.
  ///
  /// In fr, this message translates to:
  /// **'Merci. Notre équipe va examiner ce contenu.'**
  String get signalementEnvoye;

  /// No description provided for @signalementDejaFait.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà signalé ce contenu : il est en cours d\'examen.'**
  String get signalementDejaFait;

  /// No description provided for @signalementPropreContenu.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas signaler ton propre contenu.'**
  String get signalementPropreContenu;

  /// No description provided for @signalementsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes signalements'**
  String get signalementsTitre;

  /// No description provided for @signalementsVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement'**
  String get signalementsVide;

  /// No description provided for @signalementOuvert.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get signalementOuvert;

  /// No description provided for @signalementEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En examen'**
  String get signalementEnCours;

  /// No description provided for @signalementTraite.
  ///
  /// In fr, this message translates to:
  /// **'Traité'**
  String get signalementTraite;

  /// No description provided for @signalementRejete.
  ///
  /// In fr, this message translates to:
  /// **'Sans suite'**
  String get signalementRejete;

  /// No description provided for @ciblePublication.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get ciblePublication;

  /// No description provided for @cibleCommentaire.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire'**
  String get cibleCommentaire;

  /// No description provided for @cibleProduit.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get cibleProduit;

  /// No description provided for @cibleBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get cibleBoutique;

  /// No description provided for @cibleMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get cibleMessage;

  /// No description provided for @bloquer.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get bloquer;

  /// No description provided for @debloquer.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get debloquer;

  /// No description provided for @bloquerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {nom} ?'**
  String bloquerTitre(String nom);

  /// No description provided for @bloquerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pourrez plus vous écrire, et cette personne ne pourra plus commenter tes publications ni te suivre. Tu pourras la débloquer depuis ton profil.'**
  String get bloquerTexte;

  /// No description provided for @bloqueConfirme.
  ///
  /// In fr, this message translates to:
  /// **'{nom} est bloqué.'**
  String bloqueConfirme(String nom);

  /// No description provided for @bloquesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs bloqués'**
  String get bloquesTitre;

  /// No description provided for @bloquesVide.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'est bloqué'**
  String get bloquesVide;

  /// No description provided for @bloquesVideTexte.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux bloquer quelqu\'un depuis une conversation ou une page boutique.'**
  String get bloquesVideTexte;

  /// No description provided for @bloqueLe.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué le {date}'**
  String bloqueLe(String date);

  /// No description provided for @notificationsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitre;

  /// No description provided for @notificationsNonLues.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 notification non lue} other{{count} notifications non lues}}'**
  String notificationsNonLues(int count);

  /// No description provided for @notificationsToutLire.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notificationsToutLire;

  /// No description provided for @notificationsPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de notification'**
  String get notificationsPreferences;

  /// No description provided for @notificationsVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsVide;

  /// No description provided for @notificationNonLue.
  ///
  /// In fr, this message translates to:
  /// **'Non lue'**
  String get notificationNonLue;

  /// No description provided for @preferenceMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get preferenceMessages;

  /// No description provided for @preferenceSocial.
  ///
  /// In fr, this message translates to:
  /// **'J\'aime, commentaires, abonnés'**
  String get preferenceSocial;

  /// No description provided for @preferencePromotions.
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get preferencePromotions;

  /// No description provided for @preferencesExplication.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les notifications envoyées sur ton téléphone. Elles restent toutes visibles dans l\'application. Les commandes, paiements et alertes de sécurité sont toujours envoyés.'**
  String get preferencesExplication;

  /// No description provided for @favorisTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get favorisTitre;

  /// No description provided for @favorisProduitsVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit en favori'**
  String get favorisProduitsVide;

  /// No description provided for @favorisPublicationsVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication enregistrée'**
  String get favorisPublicationsVide;

  /// No description provided for @favoriPlusEnVente.
  ///
  /// In fr, this message translates to:
  /// **'plus en vente'**
  String get favoriPlusEnVente;

  /// No description provided for @profilPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get profilPhoto;

  /// No description provided for @profilChangerPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get profilChangerPhoto;

  /// No description provided for @profilRetirerPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get profilRetirerPhoto;

  /// No description provided for @profilModifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profilModifier;

  /// No description provided for @profilSansPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de pseudo'**
  String get profilSansPseudo;

  /// No description provided for @profilEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get profilEmail;

  /// No description provided for @profilEmailAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse email'**
  String get profilEmailAbsent;

  /// No description provided for @profilEmailAConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'{email} · à confirmer'**
  String profilEmailAConfirmer(String email);

  /// No description provided for @profilSectionAchats.
  ///
  /// In fr, this message translates to:
  /// **'ACHATS'**
  String get profilSectionAchats;

  /// No description provided for @profilSectionSocial.
  ///
  /// In fr, this message translates to:
  /// **'SUIVIS ET FAVORIS'**
  String get profilSectionSocial;

  /// No description provided for @profilSectionCompte.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get profilSectionCompte;

  /// No description provided for @profilSectionVendeur.
  ///
  /// In fr, this message translates to:
  /// **'VENDRE SUR DROPP'**
  String get profilSectionVendeur;

  /// No description provided for @profilEspaceVendeur.
  ///
  /// In fr, this message translates to:
  /// **'Espace vendeur'**
  String get profilEspaceVendeur;

  /// No description provided for @profilDevenirVendeur.
  ///
  /// In fr, this message translates to:
  /// **'Devenir vendeur'**
  String get profilDevenirVendeur;

  /// No description provided for @deconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get deconnexion;

  /// No description provided for @deconnexionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter de cet appareil ?'**
  String get deconnexionTitre;

  /// No description provided for @champPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo (@)'**
  String get champPseudo;

  /// No description provided for @pseudoDisponible.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est disponible.'**
  String get pseudoDisponible;

  /// No description provided for @pseudoPris.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est déjà pris.'**
  String get pseudoPris;

  /// No description provided for @pseudoReserve.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est réservé. Choisis-en un autre.'**
  String get pseudoReserve;

  /// No description provided for @pseudoFormat.
  ///
  /// In fr, this message translates to:
  /// **'3 à 30 caractères : lettres minuscules, chiffres, « _ » ou « . ».'**
  String get pseudoFormat;

  /// No description provided for @securiteTitre.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securiteTitre;

  /// No description provided for @securiteIdentifiants.
  ///
  /// In fr, this message translates to:
  /// **'IDENTIFIANTS'**
  String get securiteIdentifiants;

  /// No description provided for @securiteAppareils.
  ///
  /// In fr, this message translates to:
  /// **'APPAREILS CONNECTÉS'**
  String get securiteAppareils;

  /// No description provided for @securiteCompte.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get securiteCompte;

  /// No description provided for @motDePasseChanger.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get motDePasseChanger;

  /// No description provided for @motDePasseChangerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Tes autres appareils seront déconnectés.'**
  String get motDePasseChangerTexte;

  /// No description provided for @champMotDePasseActuel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get champMotDePasseActuel;

  /// No description provided for @motDePasseChange.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé.'**
  String get motDePasseChange;

  /// No description provided for @erreurMotDePasseActuel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect.'**
  String get erreurMotDePasseActuel;

  /// No description provided for @erreurMotDePasseRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Ce mot de passe n\'est pas accepté : il doit être différent de l\'actuel et plus solide.'**
  String get erreurMotDePasseRefuse;

  /// No description provided for @telephoneChanger.
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro'**
  String get telephoneChanger;

  /// No description provided for @telephoneChangerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Un code sera envoyé par SMS au nouveau numéro.'**
  String get telephoneChangerTexte;

  /// No description provided for @telephoneDejaUtilise.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà utilisé par un autre compte.'**
  String get telephoneDejaUtilise;

  /// No description provided for @telephoneChange.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone changé.'**
  String get telephoneChange;

  /// No description provided for @appareilInconnu.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get appareilInconnu;

  /// No description provided for @appareilActuel.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get appareilActuel;

  /// No description provided for @appareilDerniereUtilisation.
  ///
  /// In fr, this message translates to:
  /// **'Dernière activité : {quand}'**
  String appareilDerniereUtilisation(String quand);

  /// No description provided for @deconnecterPartout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les appareils'**
  String get deconnecterPartout;

  /// No description provided for @deconnecterPartoutTitre.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les appareils ?'**
  String get deconnecterPartoutTitre;

  /// No description provided for @deconnecterPartoutTexte.
  ///
  /// In fr, this message translates to:
  /// **'Y compris celui-ci : il faudra te reconnecter partout.'**
  String get deconnecterPartoutTexte;

  /// No description provided for @compteSupprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get compteSupprimer;

  /// No description provided for @compteSupprimerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ton compte ?'**
  String get compteSupprimerTitre;

  /// No description provided for @compteSupprimerTexte.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil, tes favoris, tes messages et ta boutique éventuelle seront supprimés. C\'est définitif. Saisis ton mot de passe pour confirmer.'**
  String get compteSupprimerTexte;

  /// No description provided for @compteSupprimerConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get compteSupprimerConfirmer;

  /// No description provided for @compteSupprime.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte a été supprimé.'**
  String get compteSupprime;

  /// No description provided for @compteCommandesEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Des commandes sont encore en cours : attends leur livraison ou annule-les avant de supprimer ton compte.'**
  String get compteCommandesEnCours;

  /// No description provided for @bienvenue1Titre.
  ///
  /// In fr, this message translates to:
  /// **'Suis les boutiques que tu aimes'**
  String get bienvenue1Titre;

  /// No description provided for @bienvenue1Texte.
  ///
  /// In fr, this message translates to:
  /// **'Découvre leurs nouveautés en vidéo, discute avec le vendeur et achète en Mobile Money.'**
  String get bienvenue1Texte;

  /// No description provided for @bienvenue2Titre.
  ///
  /// In fr, this message translates to:
  /// **'Discute avec le vendeur'**
  String get bienvenue2Titre;

  /// No description provided for @bienvenue2Texte.
  ///
  /// In fr, this message translates to:
  /// **'Pose tes questions, demande une taille ou une couleur avant de commander, directement dans l\'app.'**
  String get bienvenue2Texte;

  /// No description provided for @bienvenue3Titre.
  ///
  /// In fr, this message translates to:
  /// **'Paie en Mobile Money, en confiance'**
  String get bienvenue3Titre;

  /// No description provided for @bienvenue3Texte.
  ///
  /// In fr, this message translates to:
  /// **'MTN MoMo ou Orange Money. Ton argent est bloqué jusqu\'à la réception du colis.'**
  String get bienvenue3Texte;

  /// No description provided for @bienvenuePage.
  ///
  /// In fr, this message translates to:
  /// **'Page {numero} sur {total}'**
  String bienvenuePage(int numero, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
