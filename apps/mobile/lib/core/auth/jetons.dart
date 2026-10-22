/// Jetons émis par `POST /auth/connexion`, `/auth/verifier-telephone` et
/// `/auth/refresh`. `expiresIn` est en secondes.
class Jetons {
  const Jetons({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory Jetons.fromJson(Map<String, dynamic> json) => Jetons(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}
