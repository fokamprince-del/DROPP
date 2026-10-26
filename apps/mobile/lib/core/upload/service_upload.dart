import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';

/// Fichier choisi sur l'appareil (photo, vidéo), prêt à être envoyé.
class FichierLocal {
  const FichierLocal({
    required this.fichier,
    required this.typeMime,
    required this.taille,
    this.largeur,
    this.hauteur,
  });

  final XFile fichier;

  /// Un des types acceptés par l'API (`image/jpeg`, `video/mp4`…).
  final String typeMime;

  /// En octets.
  final int taille;
  final int? largeur;
  final int? hauteur;

  bool get estVideo => typeMime.startsWith('video/');
}

/// Réponse des routes `…/signature` de l'API.
class SignatureUpload {
  const SignatureUpload({
    required this.uploadUrl,
    required this.cleStockage,
    this.enTetes = const {},
  });

  /// URL R2 présignée, valable quelques minutes, pour un seul `PUT`.
  final String uploadUrl;

  /// Identifiant du fichier à renvoyer à l'API pour la confirmation.
  final String cleStockage;

  /// En-têtes **signés** (au moins `Content-Type`) : à renvoyer tels quels,
  /// sinon R2 refuse l'envoi (403).
  final Map<String, String> enTetes;

  factory SignatureUpload.fromJson(Map<String, dynamic> json) =>
      SignatureUpload(
        uploadUrl: json['uploadUrl'] as String,
        cleStockage: json['cleStockage'] as String,
        enTetes: {
          for (final e
              in (json['enTetes'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: '${e.value}',
        },
      );
}

/// Fichier arrivé dans R2, à confirmer auprès de l'API.
class FichierEnvoye {
  const FichierEnvoye({
    required this.cleStockage,
    required this.typeMime,
    required this.taille,
    this.largeur,
    this.hauteur,
  });

  final String cleStockage;
  final String typeMime;
  final int taille;
  final int? largeur;
  final int? hauteur;

  /// Champs attendus par les routes de confirmation (et les pièces jointes
  /// de la messagerie).
  Map<String, dynamic> toJson() => {
    'cleStockage': cleStockage,
    'typeMime': typeMime,
    'taille': taille,
    'largeur': ?largeur,
    'hauteur': ?hauteur,
  };
}

final serviceUploadProvider = Provider<ServiceUpload>((ref) {
  // Client sans intercepteurs : l'URL signée porte déjà l'autorisation, et
  // le jeton de l'API ne doit jamais partir vers R2.
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  ref.onDispose(dio.close);
  return ServiceUpload(dio);
});

/// Envoi de fichiers en trois temps, commun à tous les modules (pièces
/// jointes, photo de profil, KYC, médias des produits) :
///
/// 1. **signature** : le module demande une URL présignée à sa route
///    (`POST …/signature` avec `{ typeMime, taille }`) ;
/// 2. **envoi** : `PUT` du fichier directement vers R2, en flux depuis le
///    disque (pas de copie en mémoire), avec suivi de progression ;
/// 3. **confirmation** : le module déclare le fichier à sa route
///    (`…/confirmer`, `…/media`, ou l'envoi du message), qui vérifie sa
///    taille et son type réels.
///
/// Toute erreur est une [ApiException].
class ServiceUpload {
  ServiceUpload(this._dio);

  final Dio _dio;

  /// Étapes 1 et 2. [demanderSignature] reçoit le type et la taille du
  /// fichier ; [surProgression] reçoit une valeur de 0 à 1.
  Future<FichierEnvoye> televerser(
    FichierLocal fichier, {
    required Future<SignatureUpload> Function(String typeMime, int taille)
    demanderSignature,
    void Function(double progression)? surProgression,
    CancelToken? annulation,
  }) async {
    final signature = await demanderSignature(fichier.typeMime, fichier.taille);
    try {
      await _dio.put<void>(
        signature.uploadUrl,
        data: fichier.fichier.openRead(),
        options: Options(
          headers: {
            ...signature.enTetes,
            Headers.contentLengthHeader: fichier.taille,
          },
        ),
        onSendProgress: (envoye, total) {
          if (total > 0) surProgression?.call(envoye / total);
        },
        cancelToken: annulation,
      );
    } catch (e) {
      throw ApiException.depuis(e);
    }
    return FichierEnvoye(
      cleStockage: signature.cleStockage,
      typeMime: fichier.typeMime,
      taille: fichier.taille,
      largeur: fichier.largeur,
      hauteur: fichier.hauteur,
    );
  }

  /// Les trois étapes d'un coup : [confirmer] reçoit le fichier envoyé et
  /// appelle la route de confirmation du module.
  Future<T> envoyer<T>(
    FichierLocal fichier, {
    required Future<SignatureUpload> Function(String typeMime, int taille)
    demanderSignature,
    required Future<T> Function(FichierEnvoye envoye) confirmer,
    void Function(double progression)? surProgression,
    CancelToken? annulation,
  }) async {
    final envoye = await televerser(
      fichier,
      demanderSignature: demanderSignature,
      surProgression: surProgression,
      annulation: annulation,
    );
    return confirmer(envoye);
  }
}
