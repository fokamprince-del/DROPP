import 'package:dio/dio.dart';

enum TypeErreurApi {
  reseau,
  delaiDepasse,
  requeteInvalide, // 400 (validation comprise)
  nonAuthentifie, // 401
  interdit, // 403
  introuvable, // 404
  conflit, // 409
  expire, // 410
  tropDeRequetes, // 429
  serveur, // 5xx
  inconnu,
}

/// Erreur unique remontée par la couche API. L'API renvoie
/// `{ statusCode, message }`, où `message` est un texte ou, pour les erreurs
/// de validation, une liste de textes.
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details = const [],
  });

  final TypeErreurApi type;

  /// Message prêt à afficher à l'utilisateur.
  final String message;
  final int? statusCode;

  /// Tous les messages de validation (champ par champ) quand il y en a plusieurs.
  final List<String> details;

  factory ApiException.depuis(Object erreur) {
    if (erreur is ApiException) return erreur;
    if (erreur is DioException) {
      if (erreur.error is ApiException) return erreur.error! as ApiException;
      return _depuisDio(erreur);
    }
    return const ApiException(
      type: TypeErreurApi.inconnu,
      message: 'Une erreur inattendue est survenue.',
    );
  }

  static ApiException _depuisDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: TypeErreurApi.delaiDepasse,
          message: 'Le serveur met trop de temps à répondre. Réessayez.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: TypeErreurApi.reseau,
          message: 'Pas de connexion internet.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: TypeErreurApi.inconnu,
          message: 'Requête annulée.',
        );
      default:
        break;
    }

    final statut = e.response?.statusCode;
    if (statut == null) {
      return const ApiException(
        type: TypeErreurApi.reseau,
        message: 'Impossible de joindre le serveur.',
      );
    }

    final details = _messages(e.response?.data);
    final type = _typePourStatut(statut);
    return ApiException(
      type: type,
      statusCode: statut,
      details: details,
      message: switch (type) {
        // Le throttler renvoie un message technique en anglais.
        TypeErreurApi.tropDeRequetes =>
          'Trop de tentatives. Patientez une minute avant de réessayer.',
        TypeErreurApi.serveur =>
          'Le serveur rencontre un problème. Réessayez plus tard.',
        _ => details.isNotEmpty ? details.first : 'Une erreur est survenue.',
      },
    );
  }

  static List<String> _messages(Object? corps) {
    if (corps is! Map) return const [];
    final message = corps['message'];
    if (message is String) return [message];
    if (message is List) return message.map((m) => m.toString()).toList();
    return const [];
  }

  static TypeErreurApi _typePourStatut(int statut) => switch (statut) {
    400 || 422 => TypeErreurApi.requeteInvalide,
    401 => TypeErreurApi.nonAuthentifie,
    403 => TypeErreurApi.interdit,
    404 => TypeErreurApi.introuvable,
    409 => TypeErreurApi.conflit,
    410 => TypeErreurApi.expire,
    429 => TypeErreurApi.tropDeRequetes,
    >= 500 => TypeErreurApi.serveur,
    _ => TypeErreurApi.inconnu,
  };

  @override
  String toString() => 'ApiException($statusCode, $type): $message';
}
