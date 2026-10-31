import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/upload/service_upload.dart';
import 'modeles_kyc.dart';

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => KycRepository(
    ref.watch(apiClientProvider),
    ref.watch(serviceUploadProvider),
  ),
);

class KycRepository {
  KycRepository(this._api, this._uploader);

  final ApiClient _api;
  final ServiceUpload _uploader;

  static const _enteteIdempotence = 'Idempotency-Key';

  /// `null` quand aucun dossier n'existe encore (404).
  Future<DossierKyc?> monDossier() async {
    try {
      final json = await _api.get<Map<String, dynamic>>('/kyc/mon-dossier');
      return DossierKyc.depuisJson(json);
    } on ApiException catch (e) {
      if (e.type == TypeErreurApi.introuvable) return null;
      rethrow;
    }
  }

  Future<SignatureUpload> _signatureDocument(
    TypeDocumentKyc type,
    int taille,
    String typeMime,
  ) async => SignatureUpload.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/kyc/documents/signature',
      data: {
        'typeMime': typeMime,
        'taille': taille,
        'typeDocument': type.valeurApi,
      },
    ),
  );

  Future<DocumentKyc?> _confirmerDocument(
    FichierEnvoye envoye,
    String typeMime,
    int taille,
    TypeDocumentKyc type,
  ) async => DocumentKyc.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/kyc/documents/confirmer',
      data: {
        'cleStockage': envoye.cleStockage,
        'typeMime': typeMime,
        'taille': taille,
        'typeDocument': type.valeurApi,
      },
    ),
  );

  /// Signature, envoi vers le stockage, puis confirmation.
  Future<DocumentKyc> envoyerDocument({
    required TypeDocumentKyc type,
    required FichierLocal fichier,
    void Function(double)? onProgress,
  }) async {
    final doc = await _uploader.envoyer(
      fichier,
      demanderSignature: (typeMime, taille) =>
          _signatureDocument(type, taille, typeMime),
      confirmer: (envoye) =>
          _confirmerDocument(envoye, fichier.typeMime, fichier.taille, type),
      surProgression: onProgress,
    );
    if (doc == null) {
      throw const ApiException(
        type: TypeErreurApi.inconnu,
        message: 'Réponse inattendue du serveur.',
      );
    }
    return doc;
  }

  Future<ResultatExtractionCni> extraireCni() async {
    final json = await _api.post<Map<String, dynamic>>('/kyc/cni/extraire');
    return ResultatExtractionCni.depuisJson(json);
  }

  Future<void> confirmerCni(DonneesCni donnees) async {
    await _api.post<Map<String, dynamic>>(
      '/kyc/cni/confirmer',
      data: donnees.versJsonConfirmation(),
    );
  }

  /// [cleIdempotence] : un UUID par action, réutilisé à chaque nouvel essai.
  Future<StatutDossierKyc> soumettre({
    required bool consentement,
    required String cleIdempotence,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/kyc/soumettre',
      data: {'consentement': consentement},
      options: Options(headers: {_enteteIdempotence: cleIdempotence}),
    );
    return StatutDossierKyc.depuisApi(json['statut'] as String?);
  }
}
