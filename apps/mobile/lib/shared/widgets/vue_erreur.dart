import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/l10n/contexte_l10n.dart';
import '../theme/espacements.dart';

/// Message d'erreur de l'API avec un bouton « Réessayer ».
class VueErreur extends StatelessWidget {
  const VueErreur({super.key, required this.erreur, required this.reessayer});

  final ApiException erreur;
  final VoidCallback reessayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          erreur.type == TypeErreurApi.reseau
              ? Icons.wifi_off_rounded
              : Icons.error_outline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: Espacements.s),
        Text(erreur.message, textAlign: TextAlign.center),
        const SizedBox(height: Espacements.s),
        OutlinedButton(
          onPressed: reessayer,
          child: Text(context.l10n.reessayer),
        ),
      ],
    );
  }
}
