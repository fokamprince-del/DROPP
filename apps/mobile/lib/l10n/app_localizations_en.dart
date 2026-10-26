// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get nomApp => 'DROPP';

  @override
  String get navAccueil => 'Home';

  @override
  String get navDecouvrir => 'Discover';

  @override
  String get navPanier => 'Cart';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfil => 'Profile';

  @override
  String get baselineApp => 'Cameroon\'s marketplace in your pocket';

  @override
  String navPanierArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Cart, $_temp0';
  }

  @override
  String navMessagesNonLus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return 'Messages, $_temp0';
  }

  @override
  String get champPrenom => 'First name';

  @override
  String get champNom => 'Last name';

  @override
  String get champSexe => 'Gender';

  @override
  String get sexeMasculin => 'Male';

  @override
  String get sexeFeminin => 'Female';

  @override
  String get sexeAutre => 'Other';

  @override
  String get champTelephone => 'Phone';

  @override
  String get champEmailFacultatif => 'Email (optional)';

  @override
  String get champMotDePasse => 'Password';

  @override
  String get erreurRequis => 'This field is required';

  @override
  String get erreurTelephoneInvalide => 'Invalid phone number';

  @override
  String get erreurEmailInvalide => 'Invalid email address';

  @override
  String get erreurMotDePasseCourt => 'At least 8 characters';

  @override
  String get erreurCodeIncomplet => 'Enter the 6 digits of the code';

  @override
  String get forceMotDePasse1 =>
      'Weak. Use at least 8 characters, with letters and numbers.';

  @override
  String get forceMotDePasse2 => 'Fair. Add numbers or capital letters.';

  @override
  String get forceMotDePasse3 => 'Strong. Add a symbol to make it very strong.';

  @override
  String get forceMotDePasse4 => 'Very strong.';

  @override
  String get champCode => 'Verification code';

  @override
  String get motDePasseAfficher => 'Show password';

  @override
  String get motDePasseMasquer => 'Hide password';

  @override
  String get champIdentifiant => 'Phone or email';

  @override
  String get champNouveauMotDePasse => 'New password';

  @override
  String get erreurIdentifiantInvalide => 'Invalid number or email';

  @override
  String get erreurReseau => 'No internet connection.';

  @override
  String get erreurDelai =>
      'The server is taking too long to respond. Try again.';

  @override
  String get erreurTropDeTentatives =>
      'Too many attempts. Wait a minute before trying again.';

  @override
  String get erreurServeur =>
      'The server is having a problem. Try again later.';

  @override
  String get erreurInterdit => 'This account can\'t be used right now.';

  @override
  String get erreurRequeteInvalide => 'Check the information you entered.';

  @override
  String get erreurInconnue => 'Something went wrong. Try again.';

  @override
  String get erreurIdentifiantsIncorrects => 'Incorrect credentials.';

  @override
  String get erreurCompteExistant =>
      'An account already exists with this number or email.';

  @override
  String get erreurCodeIncorrect =>
      'Incorrect or expired code. Check it or request a new one.';

  @override
  String get erreurCodeExpire =>
      'Code expired or too many attempts. Request a new code.';

  @override
  String get erreurVerificationExpiree => 'Verification expired. Start over.';

  @override
  String get erreurRequeteEnCours =>
      'An identical request is in progress. Please wait.';

  @override
  String get sessionExpiree => 'Your session has expired. Sign in again.';

  @override
  String get inscriptionTitre => 'Create your account';

  @override
  String get inscriptionSousTitre =>
      'An activation code will be sent to you by SMS.';

  @override
  String get inscriptionBouton => 'Get the code by SMS';

  @override
  String get inscriptionConditions =>
      'By continuing, you accept the terms of use.';

  @override
  String get jaiDejaUnCompte => 'I already have an account';

  @override
  String get connexionTitre => 'Welcome back';

  @override
  String get connexionSousTitre => 'Sign in with your number or email.';

  @override
  String get connexionBouton => 'Sign in';

  @override
  String get creerUnCompte => 'Create an account';

  @override
  String get motDePasseOublieLien => 'Forgot password?';

  @override
  String get codeTitre => 'Enter the code received by SMS';

  @override
  String codeEnvoyeA(String numero) {
    return 'Sent to $numero. Valid for 5 minutes.';
  }

  @override
  String get codeEnvoyeAuCompte =>
      'A code has just been sent by SMS to your account\'s number. Valid for 5 minutes.';

  @override
  String get codeVerifier => 'Verify';

  @override
  String get renvoyerCode => 'Resend code';

  @override
  String renvoyerCodeDans(String duree) {
    return 'Resend code in $duree';
  }

  @override
  String get oubliTitre => 'Forgot password';

  @override
  String get oubliSousTitre =>
      'Enter your number or email. If an account exists, a code will be sent.';

  @override
  String get oubliSecurite =>
      'For security, all your sessions will be signed out after the change.';

  @override
  String get oubliBouton => 'Get a code';

  @override
  String get reinitTitre => 'New password';

  @override
  String get reinitSousTitre =>
      'Enter the code you received, then choose a new password.';

  @override
  String get reinitBouton => 'Change password';

  @override
  String get reessayer => 'Retry';

  @override
  String get rienAAfficher => 'Nothing to show yet.';

  @override
  String get tempsInstant => 'just now';

  @override
  String tempsMinutes(int n) {
    return '$n min ago';
  }

  @override
  String tempsHeures(int n) {
    return '$n h ago';
  }

  @override
  String tempsJours(int n) {
    return '$n d ago';
  }

  @override
  String get filPourToi => 'For you';

  @override
  String get filAbonnements => 'Following';

  @override
  String get filPourToiVide => 'No posts yet. Check back soon!';

  @override
  String get filAbonnementsVideTitre => 'Your feed is still empty';

  @override
  String get filAbonnementsVideTexte =>
      'Follow shops to see their latest items here first.';

  @override
  String get filDecouvrirBoutiques => 'Discover shops';

  @override
  String get filConnexionTitre => 'Log in to follow shops';

  @override
  String get filConnexionTexte =>
      'New posts from the shops you follow will show up here.';

  @override
  String get publicationTitre => 'Post';

  @override
  String publicationOuvrir(String boutique) {
    return 'Open $boutique\'s post';
  }

  @override
  String publicationVues(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString views',
      one: '1 view',
      zero: 'no views',
    );
    return '$_temp0';
  }

  @override
  String publicationLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes',
    );
    return '$_temp0';
  }

  @override
  String publicationCommentaires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'No comments',
    );
    return '$_temp0';
  }

  @override
  String get publicationAbonnes => 'Followers only';

  @override
  String get publicationProduits => 'In this post';

  @override
  String get mediaVideo => 'Video';

  @override
  String mediaPosition(int position, int total) {
    return '$position/$total';
  }

  @override
  String get videoIllisible => 'Couldn\'t play the video. Tap to try again.';

  @override
  String storyDe(String boutique) {
    return '$boutique\'s story';
  }

  @override
  String storyNouvelle(String boutique) {
    return '$boutique, new story';
  }

  @override
  String get storySuivante => 'Next story';

  @override
  String get storyPrecedente => 'Previous story';

  @override
  String get storyFermer => 'Close';

  @override
  String get storyIllisible => 'This story can\'t be displayed.';

  @override
  String get annuler => 'Cancel';

  @override
  String get supprimer => 'Delete';

  @override
  String get erreurActionInterdite =>
      'This account can\'t do that. Check your phone number is verified.';

  @override
  String get erreurContenuIntrouvable => 'This content is no longer available.';

  @override
  String get favoriAjouter => 'Add to favorites';

  @override
  String get favoriRetirer => 'Remove from favorites';

  @override
  String get partageTitre => 'Share';

  @override
  String get partageCopierLien => 'Copy link';

  @override
  String get partageLienCopie => 'Link copied';

  @override
  String get partageWhatsAppAbsent => 'Couldn\'t open WhatsApp on this device.';

  @override
  String partageTexte(String boutique, String lien) {
    return 'Check out $boutique on DROPP: $lien';
  }

  @override
  String commentairesTitre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'Comments',
    );
    return '$_temp0';
  }

  @override
  String get commentairesVide => 'No comments yet. Be the first!';

  @override
  String commentairesVoirReponses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View $count more replies',
      one: 'View 1 more reply',
    );
    return '$_temp0';
  }

  @override
  String get commentairesConnexion => 'Log in to comment';

  @override
  String get commentaireRepondre => 'Reply';

  @override
  String get commentaireCreateur => 'Creator';

  @override
  String commentaireReponseA(String auteur) {
    return 'Replying to $auteur';
  }

  @override
  String get commentairePlaceholder => 'Add a comment… (@username to mention)';

  @override
  String get commentairePublier => 'Post';

  @override
  String get commentaireSupprimerTitre => 'Delete this comment?';

  @override
  String get commentaireSupprimerTexte =>
      'It will disappear for everyone, along with its replies.';

  @override
  String get rechercheIndice => 'Dress, phone, shop…';

  @override
  String get rechercheEffacer => 'Clear search';

  @override
  String get decouvrirProduits => 'Products';

  @override
  String get decouvrirBoutiques => 'Shops';

  @override
  String get catalogueTout => 'All';

  @override
  String get catalogueVide => 'No products match these filters';

  @override
  String get catalogueEffacerFiltres => 'Clear filters';

  @override
  String get boutiquesVide => 'No shops found';

  @override
  String get triRecents => 'Newest';

  @override
  String get triPrixCroissant => 'Price: low to high';

  @override
  String get triPrixDecroissant => 'Price: high to low';

  @override
  String get triPopulaires => 'Most liked';

  @override
  String get filtresTitre => 'Filters';

  @override
  String get filtresPrix => 'Price (FCFA)';

  @override
  String get filtresPrixMin => 'Min';

  @override
  String get filtresPrixMax => 'Max';

  @override
  String get filtresTri => 'Sort by';

  @override
  String get filtresEnStock => 'In stock only';

  @override
  String get filtresReinitialiser => 'Reset';

  @override
  String get filtresAppliquer => 'Show products';

  @override
  String prixMoinsDe(String montant) {
    return 'Under $montant';
  }

  @override
  String prixPlusDe(String montant) {
    return 'Over $montant';
  }

  @override
  String prixAPartirDe(String prix) {
    return 'From $prix';
  }

  @override
  String get stockEnStock => 'In stock';

  @override
  String get stockRupture => 'Out of stock';

  @override
  String stockPlusQue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count left',
      one: 'Only 1 left',
    );
    return '$_temp0';
  }

  @override
  String varianteNumero(int numero) {
    return 'Option $numero';
  }

  @override
  String get avisTitre => 'Reviews';

  @override
  String avisTitreNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reviews ($count)',
      zero: 'Reviews',
    );
    return '$_temp0';
  }

  @override
  String avisNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: 'no reviews',
    );
    return '$_temp0';
  }

  @override
  String get avisAucun => 'No reviews for this product yet.';

  @override
  String avisVoirTous(int count) {
    return 'See all $count reviews';
  }

  @override
  String avisNote(int note) {
    return '$note out of 5 stars';
  }

  @override
  String avisMoyenne(String note) {
    return 'Average rating: $note out of 5';
  }

  @override
  String get avisAchatVerifie => 'Verified purchase';

  @override
  String get boutiqueSuivre => 'Follow';

  @override
  String get boutiqueAbonne => 'Following';

  @override
  String boutiqueAbonnes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString followers',
      one: '1 follower',
      zero: 'no followers',
    );
    return '$_temp0';
  }

  @override
  String boutiqueAbonnesLibelle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'followers',
      one: 'follower',
    );
    return '$_temp0';
  }

  @override
  String boutiqueProduitsLibelle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'products',
      one: 'product',
    );
    return '$_temp0';
  }

  @override
  String get boutiquePublications => 'Posts';

  @override
  String get boutiqueAucunProduit => 'No products online yet.';

  @override
  String get boutiqueAucunePublication => 'No posts yet.';

  @override
  String get abonnementsTitre => 'Following';

  @override
  String get abonnementsVideTitre => 'You don\'t follow any shops yet';

  @override
  String abonnementsDepuis(String date) {
    return 'Following since $date';
  }

  @override
  String get champEmail => 'Email address';

  @override
  String get erreurEmailUtilisee => 'This email address is already in use.';

  @override
  String get erreurMotDePasseIncorrect => 'Incorrect password.';

  @override
  String get emailTitre => 'Confirm your email address';

  @override
  String emailSousTitre(String email) {
    return 'We sent a code to $email. You\'ll use it to recover your account.';
  }

  @override
  String get emailConfirmer => 'Confirm';

  @override
  String get emailConfirmee => 'Email address confirmed.';

  @override
  String get emailPlusTard => 'Later';

  @override
  String get emailChangerLien => 'Change address';

  @override
  String get emailAjouterTitre => 'Add your email address';

  @override
  String get emailChangerTitre => 'Change email address';

  @override
  String get emailChangerSousTitre =>
      'A code will be sent to the new address. The old one stays active until you confirm.';

  @override
  String get emailRecevoirCode => 'Get the code';

  @override
  String get emailTitreConfirmee => 'Email address confirmed';

  @override
  String emailDejaConfirmee(String email) {
    return '$email is confirmed. You can use it to recover your account.';
  }

  @override
  String get enregistrer => 'Save';

  @override
  String get aujourdhui => 'Today';

  @override
  String get hier => 'Yesterday';

  @override
  String get mediaGaleriePhoto => 'Photo from gallery';

  @override
  String get mediaPrendrePhoto => 'Take a photo';

  @override
  String get mediaGalerieVideo => 'Video from gallery';

  @override
  String get mediaFilmer => 'Record a video';

  @override
  String fichierTropGros(int mo) {
    return 'File too large: $mo MB maximum.';
  }

  @override
  String get fichierFormatRefuse =>
      'Unsupported format. Choose a photo (JPEG, PNG, WebP) or a video (MP4, MOV).';

  @override
  String get panierVide => 'Your cart is empty';

  @override
  String get panierVideTexte => 'Add items from a product page.';

  @override
  String panierNombreArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get panierAjouter => 'Add to cart';

  @override
  String get panierChoisirOption => 'Choose an option';

  @override
  String get panierAjoute => 'Added to cart';

  @override
  String get panierVoir => 'View';

  @override
  String get panierStockInsuffisant => 'Not enough stock for this quantity.';

  @override
  String panierStockRestant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count left: lower the quantity',
      one: 'Only 1 left: lower the quantity',
    );
    return '$_temp0';
  }

  @override
  String get panierIndisponible => 'No longer available: remove it to order';

  @override
  String get panierPrixModifie => 'Price updated since you added it';

  @override
  String panierQuantite(int count) {
    return 'Quantity: $count';
  }

  @override
  String get panierMoins => 'Decrease quantity';

  @override
  String get panierPlus => 'Increase quantity';

  @override
  String get panierSousTotal => 'Subtotal';

  @override
  String get panierLivraison => 'Delivery';

  @override
  String get panierLivraisonPlusTard => 'Calculated at the next step';

  @override
  String get panierTotal => 'Total';

  @override
  String get panierProtection =>
      'Protected payment: the seller is paid after delivery.';

  @override
  String get panierNonCommandable =>
      'Remove unavailable items to place your order.';

  @override
  String panierCommander(String prix) {
    return 'Order · $prix';
  }

  @override
  String get commanderTitre => 'Place the order?';

  @override
  String commanderTexte(int minutes) {
    return 'Items are reserved for $minutes minutes while you pay. Without payment, the order is cancelled and the stock released.';
  }

  @override
  String get commanderConfirmer => 'Order';

  @override
  String get commanderPanierChange =>
      'Your cart has changed (stock or price). Check it before ordering.';

  @override
  String get commandesTitre => 'My orders';

  @override
  String get commandesVide => 'No orders yet';

  @override
  String get commandeTitre => 'Order';

  @override
  String commandeDu(String date) {
    return 'Order of $date';
  }

  @override
  String get commandeAPayerAvant => 'To pay before automatic cancellation';

  @override
  String get commandeDelaiDepasse =>
      'Time is up: the order is being cancelled.';

  @override
  String get commandePaiementBientot =>
      'Mobile Money payment (MTN MoMo, Orange Money) is coming to the app very soon.';

  @override
  String get commandeAnnuler => 'Cancel order';

  @override
  String get commandeAnnulerTitre => 'Cancel this order?';

  @override
  String get commandeAnnulerTexte => 'The items will be put back on sale.';

  @override
  String get commandeGarder => 'Keep';

  @override
  String get commandeDejaTraitee => 'This order has already been processed.';

  @override
  String get statutEnAttentePaiement => 'Awaiting payment';

  @override
  String get statutNouvelle => 'Paid';

  @override
  String get statutEnCours => 'Being prepared';

  @override
  String get statutExpediee => 'Shipped';

  @override
  String get statutLivree => 'Delivered';

  @override
  String get statutAnnulee => 'Cancelled';

  @override
  String get statutEnLitige => 'In dispute';

  @override
  String get adressesTitre => 'My addresses';

  @override
  String get adressesVide => 'No saved address';

  @override
  String get adressesVideTexte => 'Add an address to get your orders faster.';

  @override
  String get adresseAjouter => 'Add an address';

  @override
  String get adresseModifier => 'Edit address';

  @override
  String get adresseSupprimerTitre => 'Delete this address?';

  @override
  String get adresseLivraison => 'Delivery';

  @override
  String get adresseFacturation => 'Billing';

  @override
  String get adresseAutre => 'Other';

  @override
  String get adressePrincipale => 'Default';

  @override
  String get adresseLigne1 => 'Neighbourhood, street, landmark';

  @override
  String get adresseLigne2 => 'Additional info (building, floor…)';

  @override
  String get adresseVille => 'City';

  @override
  String get adresseRegion => 'Region';

  @override
  String get adressePays => 'Country';

  @override
  String get adresseCodePostal => 'Postal code';

  @override
  String get adresseDefinirPrincipale => 'Default address';

  @override
  String get avisANoterTitre => 'Reviews to write';

  @override
  String get avisANoterVide => 'Nothing to review yet';

  @override
  String get avisANoterVideTexte => 'Your delivered items will show up here.';

  @override
  String avisCommandeLe(String date) {
    return 'ordered on $date';
  }

  @override
  String get avisNoter => 'Rate';

  @override
  String get avisTonAvis => 'Your review';

  @override
  String get avisCommentaireIndice => 'Quality, size, delivery… (optional)';

  @override
  String get avisPublier => 'Post review';

  @override
  String get avisModifier => 'Edit my review';

  @override
  String get avisSupprimerTitre => 'Delete your review?';

  @override
  String get avisMesActions => 'Manage my review';

  @override
  String get avisNonModifiable =>
      'A review can no longer be changed after 30 days.';

  @override
  String get avisDejaDonne => 'You\'ve already reviewed this item.';

  @override
  String get boutiqueMessage => 'Message';

  @override
  String get boutiqueEcrire => 'Message the shop';

  @override
  String get conversationsVide => 'No conversations';

  @override
  String get conversationsVideTexte =>
      'Message a shop from a product page or its shop page.';

  @override
  String get conversationCompteSupprime => 'Deleted account';

  @override
  String messageDeMoi(String texte) {
    return 'You: $texte';
  }

  @override
  String get messagePhoto => '📷 Photo';

  @override
  String get messageVideo => '🎥 Video';

  @override
  String get messagePieceJointe => '📎 Attachment';

  @override
  String get messageIndice => 'Write a message…';

  @override
  String get messageEnvoyer => 'Send';

  @override
  String get messageJoindre => 'Attach a photo or video';

  @override
  String messagePiecesMax(int max) {
    return '$max files maximum per message.';
  }

  @override
  String messageFichiers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get messageEnvoi => 'Sending…';

  @override
  String get messageEnvoye => 'Sent';

  @override
  String get messageLu => 'Read';

  @override
  String get messageEnvoiInterdit => 'You can\'t write in this conversation.';

  @override
  String get discussionDebut => 'Start of the conversation';

  @override
  String get discussionFermee => 'This conversation is closed.';

  @override
  String get plusDOptions => 'More options';

  @override
  String get discussionEcrit => 'typing…';

  @override
  String get signaler => 'Report';

  @override
  String get signalerTitre => 'Report this content';

  @override
  String get signalementDescriptionObligatoire =>
      'Explain what\'s wrong (required)';

  @override
  String get signalementDescriptionFacultative => 'Details (optional)';

  @override
  String get signalementEnvoyer => 'Send report';

  @override
  String get signalementAnonyme =>
      'The person you report won\'t know it was you.';

  @override
  String get signalementEnvoye => 'Thanks. Our team will review this content.';

  @override
  String get signalementDejaFait =>
      'You\'ve already reported this content: it\'s being reviewed.';

  @override
  String get signalementPropreContenu => 'You can\'t report your own content.';

  @override
  String get signalementsTitre => 'My reports';

  @override
  String get signalementsVide => 'No reports';

  @override
  String get signalementOuvert => 'Received';

  @override
  String get signalementEnCours => 'Under review';

  @override
  String get signalementTraite => 'Resolved';

  @override
  String get signalementRejete => 'No action';

  @override
  String get ciblePublication => 'Post';

  @override
  String get cibleCommentaire => 'Comment';

  @override
  String get cibleProduit => 'Product';

  @override
  String get cibleBoutique => 'Shop';

  @override
  String get cibleMessage => 'Message';

  @override
  String get bloquer => 'Block';

  @override
  String get debloquer => 'Unblock';

  @override
  String bloquerTitre(String nom) {
    return 'Block $nom?';
  }

  @override
  String get bloquerTexte =>
      'You won\'t be able to message each other, and they won\'t be able to comment on your posts or follow you. You can unblock them from your profile.';

  @override
  String bloqueConfirme(String nom) {
    return '$nom is blocked.';
  }

  @override
  String get bloquesTitre => 'Blocked users';

  @override
  String get bloquesVide => 'Nobody is blocked';

  @override
  String get bloquesVideTexte =>
      'You can block someone from a conversation or a shop page.';

  @override
  String bloqueLe(String date) {
    return 'Blocked on $date';
  }

  @override
  String get notificationsTitre => 'Notifications';

  @override
  String notificationsNonLues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get notificationsToutLire => 'Mark all as read';

  @override
  String get notificationsPreferences => 'Notification settings';

  @override
  String get notificationsVide => 'No notifications';

  @override
  String get notificationNonLue => 'Unread';

  @override
  String get preferenceMessages => 'Messages';

  @override
  String get preferenceSocial => 'Likes, comments, followers';

  @override
  String get preferencePromotions => 'Promotions';

  @override
  String get preferencesExplication =>
      'Choose which notifications are sent to your phone. They all stay visible in the app. Orders, payments and security alerts are always sent.';

  @override
  String get favorisTitre => 'My favorites';

  @override
  String get favorisProduitsVide => 'No favorite products';

  @override
  String get favorisPublicationsVide => 'No saved posts';

  @override
  String get favoriPlusEnVente => 'no longer on sale';

  @override
  String get profilPhoto => 'Profile photo';

  @override
  String get profilChangerPhoto => 'Change photo';

  @override
  String get profilRetirerPhoto => 'Remove photo';

  @override
  String get profilModifier => 'Edit profile';

  @override
  String get profilSansPseudo => 'No username yet';

  @override
  String get profilEmail => 'Email address';

  @override
  String get profilEmailAbsent => 'No email address';

  @override
  String profilEmailAConfirmer(String email) {
    return '$email · to confirm';
  }

  @override
  String get profilSectionAchats => 'PURCHASES';

  @override
  String get profilSectionSocial => 'FOLLOWING AND FAVORITES';

  @override
  String get profilSectionCompte => 'ACCOUNT';

  @override
  String get profilSectionVendeur => 'SELL ON DROPP';

  @override
  String get profilEspaceVendeur => 'Seller space';

  @override
  String get profilDevenirVendeur => 'Become a seller';

  @override
  String get deconnexion => 'Log out';

  @override
  String get deconnexionTitre => 'Log out of this device?';

  @override
  String get champPseudo => 'Username (@)';

  @override
  String get pseudoDisponible => 'This username is available.';

  @override
  String get pseudoPris => 'This username is already taken.';

  @override
  String get pseudoReserve => 'This username is reserved. Choose another one.';

  @override
  String get pseudoFormat =>
      '3 to 30 characters: lowercase letters, digits, \"_\" or \".\".';

  @override
  String get securiteTitre => 'Security';

  @override
  String get securiteIdentifiants => 'SIGN-IN DETAILS';

  @override
  String get securiteAppareils => 'CONNECTED DEVICES';

  @override
  String get securiteCompte => 'ACCOUNT';

  @override
  String get motDePasseChanger => 'Change password';

  @override
  String get motDePasseChangerTexte => 'Your other devices will be logged out.';

  @override
  String get champMotDePasseActuel => 'Current password';

  @override
  String get motDePasseChange => 'Password changed.';

  @override
  String get erreurMotDePasseActuel => 'Current password is incorrect.';

  @override
  String get erreurMotDePasseRefuse =>
      'This password isn\'t accepted: it must differ from the current one and be stronger.';

  @override
  String get telephoneChanger => 'Change phone number';

  @override
  String get telephoneChangerTexte =>
      'A code will be texted to the new number.';

  @override
  String get telephoneDejaUtilise =>
      'This number is already used by another account.';

  @override
  String get telephoneChange => 'Phone number changed.';

  @override
  String get appareilInconnu => 'Device';

  @override
  String get appareilActuel => 'This device';

  @override
  String appareilDerniereUtilisation(String quand) {
    return 'Last active: $quand';
  }

  @override
  String get deconnecterPartout => 'Log out of all devices';

  @override
  String get deconnecterPartoutTitre => 'Log out of all devices?';

  @override
  String get deconnecterPartoutTexte =>
      'Including this one: you\'ll have to log in again everywhere.';

  @override
  String get compteSupprimer => 'Delete my account';

  @override
  String get compteSupprimerTitre => 'Delete your account?';

  @override
  String get compteSupprimerTexte =>
      'Your profile, favorites, messages and any shop will be deleted. This is permanent. Enter your password to confirm.';

  @override
  String get compteSupprimerConfirmer => 'Delete permanently';

  @override
  String get compteSupprime => 'Your account has been deleted.';

  @override
  String get compteCommandesEnCours =>
      'Some orders are still in progress: wait for delivery or cancel them before deleting your account.';
}
