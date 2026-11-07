import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../interactions/ui/bouton_suivre.dart';

/// Logo, nom, ligne d'information et bouton Suivre ; ouvre la boutique.
class TuileBoutique extends ConsumerWidget {
  const TuileBoutique({
    super.key,
    required this.boutiqueId,
    required this.nom,
    this.logoUrl,
    this.sousTitre,
    this.abonnes = 0,
  });

  final String boutiqueId;
  final String nom;
  final String? logoUrl;
  final String? sousTitre;
  final int abonnes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final estMoi = ref.watch(utilisateurConnecteProvider)?.id == boutiqueId;
    return InkWell(
      onTap: () => unawaited(context.push<void>(Routes.boutique(boutiqueId))),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Espacements.l,
          vertical: Espacements.s,
        ),
        child: Row(
          children: [
            AvatarBoutique(nom: nom, logoUrl: logoUrl, taille: 48),
            const SizedBox(width: Espacements.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sousTitre != null)
                    Text(
                      sousTitre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (!estMoi) ...[
              const SizedBox(width: Espacements.s),
              BoutonSuivre(
                boutiqueId: boutiqueId,
                abonnesRecus: abonnes,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
