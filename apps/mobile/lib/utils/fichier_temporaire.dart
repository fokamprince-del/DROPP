import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Supprime [chemin] seulement s'il est dans le dossier temporaire de l'app :
/// jamais un fichier d'origine de la galerie.
Future<void> supprimerSiTemporaire(String chemin) async {
  try {
    final cache = await getTemporaryDirectory();
    if (!chemin.startsWith(cache.path)) return;
    final fichier = File(chemin);
    if (await fichier.exists()) await fichier.delete();
  } on FileSystemException {
    // Copie du cache : le système la purgera.
  }
}
