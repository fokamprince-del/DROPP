import 'dart:async';

import 'package:flutter/material.dart';

/// Amène l'élément repéré par [cle] à l'écran (un message d'erreur en haut de
/// page quand on a défilé jusqu'au bouton).
void defilerVers(GlobalKey cle, {required bool Function() estMonte}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final contexte = cle.currentContext;
    if (!estMonte() || contexte == null) return;
    unawaited(
      Scrollable.ensureVisible(
        contexte,
        duration: const Duration(milliseconds: 250),
        alignment: 0.1,
      ),
    );
  });
}
