import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/upload/choix_media.dart';
import '../../../core/upload/service_upload.dart';
import 'modeles_kyc.dart';

abstract interface class SelecteurPhoto {
  /// `null` si l'utilisateur annule.
  Future<FichierLocal?> prendre({
    required bool selfie,
    bool galerie = false,
    int tailleMaxMo = tailleMaxDocumentKyc,
  });

  /// Les photos de pièce d'identité ne doivent pas rester dans le cache.
  Future<void> supprimer(String chemin);
}

class SelecteurPhotoImagePicker implements SelecteurPhoto {
  SelecteurPhotoImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Réduit à 1600 px : lisible pour une CNI, et sous les 10 Mo de l'API
  /// sans coûter cher en données mobiles.
  static const _cote = 1600.0;

  @override
  Future<FichierLocal?> prendre({
    required bool selfie,
    bool galerie = false,
    int tailleMaxMo = 10,
  }) async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: galerie ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: _cote,
        maxHeight: _cote,
        imageQuality: 85,
      );
    } on PlatformException {
      throw const FichierRefuse(raison: FichierRefuseRaison.indisponible);
    }
    if (photo == null) return null;

    return preparerFichier(
      photo,
      tailleMaxImageMo: tailleMaxMo,
      tailleMaxVideoMo: 0,
    );
  }

  @override
  Future<void> supprimer(String chemin) async {
    try {
      final fichier = File(chemin);
      if (await fichier.exists()) await fichier.delete();
    } on FileSystemException {
      // Fichier de cache : le système le purgera.
    }
  }
}

final selecteurPhotoProvider = Provider<SelecteurPhoto>(
  (ref) => SelecteurPhotoImagePicker(),
);
