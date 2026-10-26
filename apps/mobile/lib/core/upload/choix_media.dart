import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/contexte_l10n.dart';
import 'service_upload.dart';

/// Types acceptés par l'API pour les photos et vidéos, par extension.
const _typesParExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
};

/// Type MIME d'un fichier d'après son nom, ou `null` s'il n'est pas accepté.
String? typeMimeDe(String nomFichier) {
  final point = nomFichier.lastIndexOf('.');
  if (point < 0) return null;
  return _typesParExtension[nomFichier.substring(point + 1).toLowerCase()];
}

/// Le fichier choisi n'a pas un format accepté ou dépasse la taille permise.
class FichierRefuse implements Exception {
  const FichierRefuse({this.tropGros = false, this.tailleMaxMo});

  final bool tropGros;
  final int? tailleMaxMo;
}

/// Propose galerie ou appareil photo (et vidéo si [video]) dans une feuille,
/// puis prépare le fichier. `null` si l'utilisateur annule.
///
/// Les photos sont recompressées en JPEG (2 048 px au plus, qualité 85) :
/// moins de données mobiles, et le HEIC de l'iPhone devient un format
/// accepté par l'API. Lève [FichierRefuse] si le fichier ne convient pas.
Future<FichierLocal?> choisirMedia(
  BuildContext context, {
  bool video = true,
  int tailleMaxImageMo = 10,
  int tailleMaxVideoMo = 100,
}) async {
  final l10n = context.l10n;
  final source = await showModalBottomSheet<_Source>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.mediaGaleriePhoto),
            onTap: () => Navigator.pop(context, _Source.galeriePhoto),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.mediaPrendrePhoto),
            onTap: () => Navigator.pop(context, _Source.cameraPhoto),
          ),
          if (video) ...[
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(l10n.mediaGalerieVideo),
              onTap: () => Navigator.pop(context, _Source.galerieVideo),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.mediaFilmer),
              onTap: () => Navigator.pop(context, _Source.cameraVideo),
            ),
          ],
        ],
      ),
    ),
  );
  if (source == null) return null;

  final selecteur = ImagePicker();
  final XFile? fichier = switch (source) {
    _Source.galeriePhoto || _Source.cameraPhoto => await selecteur.pickImage(
      source: source == _Source.galeriePhoto
          ? ImageSource.gallery
          : ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    ),
    _Source.galerieVideo || _Source.cameraVideo => await selecteur.pickVideo(
      source: source == _Source.galerieVideo
          ? ImageSource.gallery
          : ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    ),
  };
  if (fichier == null) return null;
  return preparerFichier(
    fichier,
    tailleMaxImageMo: tailleMaxImageMo,
    tailleMaxVideoMo: tailleMaxVideoMo,
  );
}

/// Vérifie type et taille, et lit les dimensions d'une image.
Future<FichierLocal> preparerFichier(
  XFile fichier, {
  int tailleMaxImageMo = 10,
  int tailleMaxVideoMo = 100,
}) async {
  final typeMime = typeMimeDe(fichier.name) ?? typeMimeDe(fichier.path);
  if (typeMime == null) throw const FichierRefuse();
  final taille = await fichier.length();
  final maxMo = typeMime.startsWith('video/')
      ? tailleMaxVideoMo
      : tailleMaxImageMo;
  if (taille > maxMo * 1024 * 1024) {
    throw FichierRefuse(tropGros: true, tailleMaxMo: maxMo);
  }

  int? largeur;
  int? hauteur;
  if (typeMime.startsWith('image/')) {
    try {
      final image = await decodeImageFromList(await fichier.readAsBytes());
      largeur = image.width;
      hauteur = image.height;
      image.dispose();
    } on Exception {
      // Dimensions facultatives pour l'API.
    }
  }
  return FichierLocal(
    fichier: fichier,
    typeMime: typeMime,
    taille: taille,
    largeur: largeur,
    hauteur: hauteur,
  );
}

enum _Source { galeriePhoto, cameraPhoto, galerieVideo, cameraVideo }
