/// Utilisateur connecté, tel que renvoyé par `GET /auth/me`.
class Utilisateur {
  const Utilisateur({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.emailVerifie,
    required this.telephone,
    required this.telephoneVerifie,
    required this.statutCompte,
    required this.estClient,
    required this.estVendeur,
    required this.statutVendeur,
  });

  final String id;
  final String prenom;
  final String nom;
  final String? email;
  final bool emailVerifie;
  final String? telephone;
  final bool telephoneVerifie;

  /// `ACTIF`, `EN_ATTENTE_VERIFICATION`…
  final String statutCompte;
  final bool estClient;
  final bool estVendeur;
  final String? statutVendeur;

  String get nomComplet => '$prenom $nom'.trim();

  factory Utilisateur.fromJson(Map<String, dynamic> json) => Utilisateur(
    id: json['id'] as String,
    prenom: json['prenom'] as String? ?? '',
    nom: json['nom'] as String? ?? '',
    email: json['email'] as String?,
    emailVerifie: json['emailVerifie'] as bool? ?? false,
    telephone: json['telephone'] as String?,
    telephoneVerifie: json['telephoneVerifie'] as bool? ?? false,
    statutCompte: json['statutCompte'] as String,
    estClient: json['estClient'] as bool? ?? false,
    estVendeur: json['estVendeur'] as bool? ?? false,
    statutVendeur: json['statutVendeur'] as String?,
  );
}
