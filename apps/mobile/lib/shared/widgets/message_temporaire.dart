import 'package:flutter/material.dart';

/// Message bref en bas d'écran (« toast »), annoncé par les lecteurs d'écran.
/// Remplace le message précédent s'il y en a un.
void afficherMessageTemporaire(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}