import 'package:flutter/material.dart';

import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';

/// Message d'erreur (`erreur`) ou d'information (sinon), annoncé par les
/// lecteurs d'écran.
class BandeauMessage extends StatelessWidget {
  const BandeauMessage({super.key, required this.message, this.erreur = true});

  final String message;
  final bool erreur;

  @override
  Widget build(BuildContext context) {
    final metier = context.couleursMetier;
    final couleur = erreur ? metier.erreur : metier.attente;
    final fond = erreur ? metier.erreurFond : metier.attenteFond;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Espacements.m),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: Rayons.borduresChamp,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              erreur ? Icons.error_outline : Icons.info_outline,
              color: couleur,
              size: 20,
            ),
            const SizedBox(width: Espacements.s),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: couleur),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
