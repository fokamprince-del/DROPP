import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/upload/service_upload.dart';
import 'page_camera_selfie.dart';

/// Capture d'un selfie. Interface séparée : la caméra ne tourne pas dans les
/// tests, qui utilisent une fausse capture.
abstract interface class CaptureSelfie {
  /// `null` si l'utilisateur ferme la caméra.
  Future<FichierLocal?> capturer(BuildContext context);
}

class CaptureSelfieCamera implements CaptureSelfie {
  const CaptureSelfieCamera();

  @override
  Future<FichierLocal?> capturer(BuildContext context) =>
      Navigator.of(context).push<FichierLocal>(
        MaterialPageRoute<FichierLocal>(
          fullscreenDialog: true,
          builder: (_) => const PageCameraSelfie(),
        ),
      );
}

final captureSelfieProvider = Provider<CaptureSelfie>(
  (ref) => const CaptureSelfieCamera(),
);
