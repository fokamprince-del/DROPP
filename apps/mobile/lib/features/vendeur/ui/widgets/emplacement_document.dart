import 'package:flutter/material.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/upload/service_upload.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../data/modeles_kyc.dart';
import 'apercu_photo.dart';

/// Carte d'un document : statut, aperçu à valider, actions. Partagée par la
/// CNI (galerie permise) et le selfie (caméra seulement).
class EmplacementDocument extends StatelessWidget {
  const EmplacementDocument({
    super.key,
    required this.titre,
    required this.description,
    required this.photo,
    required this.document,
    required this.enAttente,
    required this.enCours,
    required this.actif,
    required this.surChoisir,
    required this.surEnvoyer,
    this.indice,
    this.ratio = 85.6 / 54,
    this.autoriserGalerie = true,
    this.iconeVide = Icons.badge_outlined,
    this.libellePrendre,
  });

  final String titre;
  final String description;
  final FichierLocal? photo;
  final DocumentKyc? document;
  final bool enAttente;
  final bool enCours;
  final bool actif;
  final String? indice;
  final double ratio;
  final bool autoriserGalerie;
  final IconData iconeVide;

  /// Libellé du bouton quand rien n'est encore envoyé.
  final String? libellePrendre;

  /// `true` : choisir dans la galerie.
  final ValueChanged<bool> surChoisir;
  final VoidCallback surEnvoyer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final refuse = document?.refuse ?? false;
    final envoye = document != null && !refuse && !enAttente;

    final IconData icone;
    final Color couleur;
    final String statut;
    if (enAttente) {
      icone = Icons.visibility_outlined;
      couleur = theme.colorScheme.primary;
      statut = l10n.kycStatutAVerifier;
    } else if (refuse) {
      icone = Icons.error_outline;
      couleur = metier.erreur;
      statut = l10n.kycRefuse;
    } else if (envoye) {
      icone = Icons.check_circle;
      couleur = metier.succes;
      statut = l10n.kycEnvoye;
    } else {
      icone = Icons.radio_button_unchecked;
      couleur = theme.colorScheme.onSurfaceVariant;
      statut = l10n.kycStatutAImporter;
    }

    final libelleBouton = enAttente
        ? l10n.kycReprendrePhoto
        : (document != null
              ? l10n.kycRemplacerPhoto
              : (libellePrendre ?? l10n.kycPrendrePhoto));

    return Container(
      margin: const EdgeInsets.only(bottom: Espacements.l),
      padding: const EdgeInsets.all(Espacements.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Rayons.borduresCarte,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur, size: 22),
              const SizedBox(width: Espacements.s),
              Expanded(child: Text(titre, style: theme.textTheme.titleSmall)),
              Text(
                statut,
                style: theme.textTheme.labelMedium?.copyWith(color: couleur),
              ),
            ],
          ),
          const SizedBox(height: Espacements.m),
          if (photo != null)
            ApercuPhoto(
              fichier: photo!.fichier,
              description: description,
              ratio: ratio,
            )
          else
            _ApercuVide(
              ratio: ratio,
              icone: iconeVide,
              texte: document != null ? l10n.kycApercuAbsent : null,
            ),
          if (indice != null) ...[
            const SizedBox(height: Espacements.s),
            Text(indice!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: Espacements.m),
          if (enCours)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Espacements.s),
                Text(l10n.kycEnvoiEnCours),
              ],
            )
          else
            Wrap(
              spacing: Espacements.s,
              runSpacing: Espacements.s,
              children: [
                if (enAttente)
                  FilledButton(
                    onPressed: surEnvoyer,
                    child: Text(l10n.kycUtiliserPhoto),
                  ),
                OutlinedButton(
                  onPressed: actif ? () => surChoisir(false) : null,
                  child: Text(libelleBouton),
                ),
                if (autoriserGalerie)
                  TextButton(
                    onPressed: actif ? () => surChoisir(true) : null,
                    child: Text(l10n.kycGalerie),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ApercuVide extends StatelessWidget {
  const _ApercuVide({required this.ratio, required this.icone, this.texte});

  final double ratio;
  final IconData icone;
  final String? texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: ratio,
      child: Container(
        padding: const EdgeInsets.all(Espacements.l),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: Rayons.borduresChamp,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: texte == null
            ? Icon(icone, size: 40, color: theme.colorScheme.outline)
            : Text(
                texte!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
      ),
    );
  }
}
