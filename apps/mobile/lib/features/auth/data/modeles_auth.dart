import '../../../core/auth/jetons.dart';

enum Sexe {
  masculin('MASCULIN'),
  feminin('FEMININ'),
  autre('AUTRE');

  const Sexe(this.valeurApi);

  final String valeurApi;
}

/// Formulaire d'inscription (`POST /auth/inscription`).
class DonneesInscription {
  const DonneesInscription({
    required this.prenom,
    required this.nom,
    required this.sexe,
    required this.telephone,
    required this.motDePasse,
    this.email,
  });

  final String prenom;
  final String nom;
  final Sexe sexe;
  final String telephone;
  final String motDePasse;
  final String? email;

  Map<String, dynamic> toJson() {
    final courriel = email?.trim();
    return {
      'prenom': prenom.trim(),
      'nom': nom.trim(),
      'sexe': sexe.valeurApi,
      'telephone': telephone,
      // Le mot de passe n'est jamais « trimé » : les espaces comptent.
      'motDePasse': motDePasse,
      // Facultatif : une chaîne vide serait rejetée (format email).
      if (courriel != null && courriel.isNotEmpty) 'email': courriel,
    };
  }
}

sealed class ResultatConnexion {
  const ResultatConnexion();
}

final class ConnexionReussie extends ResultatConnexion {
  const ConnexionReussie(this.jetons);

  final Jetons jetons;
}

/// Compte non vérifié : un code vient d'être envoyé par SMS.
final class VerificationRequise extends ResultatConnexion {
  const VerificationRequise(this.verificationToken);

  final String verificationToken;
}
