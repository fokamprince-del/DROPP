import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../fil/data/modeles_fil.dart';
import '../data/interactions_repository.dart';
import 'actions_connectees.dart';

/// Feuille « Partager » : WhatsApp ou copie du lien. Le partage est
/// enregistré par l'API, qui fournit le lien profond (connexion requise).
Future<void> ouvrirPartage(
  BuildContext context,
  WidgetRef ref,
  Publication publication,
) async {
  if (!exigerConnexion(context, ref)) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (_) => _FeuillePartage(publication: publication),
  );
}

class _FeuillePartage extends ConsumerStatefulWidget {
  const _FeuillePartage({required this.publication});

  final Publication publication;

  @override
  ConsumerState<_FeuillePartage> createState() => _FeuillePartageState();
}

class _FeuillePartageState extends ConsumerState<_FeuillePartage> {
  static const _vertWhatsApp = Color(0xFF25D366);

  PlateformePartage? _enCours;
  String? _erreur;

  Future<void> _partager(PlateformePartage plateforme) async {
    final l10n = context.l10n;
    final navigateur = Navigator.of(context);
    final messager = ScaffoldMessenger.of(context);
    setState(() {
      _enCours = plateforme;
      _erreur = null;
    });
    try {
      final lien = await ref
          .read(interactionsRepositoryProvider)
          .partager(widget.publication.id, plateforme);
      final texte = l10n.partageTexte(widget.publication.boutique.nom, lien);

      if (plateforme == PlateformePartage.whatsapp) {
        final ouvert = await launchUrl(
          Uri.https('wa.me', '/', {'text': texte}),
          mode: LaunchMode.externalApplication,
        );
        if (!ouvert) {
          if (mounted) setState(() => _erreur = l10n.partageWhatsAppAbsent);
          return;
        }
      } else {
        await Clipboard.setData(ClipboardData(text: lien));
        messager.showSnackBar(SnackBar(content: Text(l10n.partageLienCopie)));
      }
      navigateur.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Espacements.l,
          0,
          Espacements.l,
          Espacements.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.partageTitre,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Espacements.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Option(
                  couleur: _vertWhatsApp,
                  icone: IconesDropp.whatsapp,
                  libelle: 'WhatsApp',
                  enCours: _enCours == PlateformePartage.whatsapp,
                  surAppui: _enCours == null
                      ? () => _partager(PlateformePartage.whatsapp)
                      : null,
                ),
                _Option(
                  couleur: theme.colorScheme.onSurfaceVariant,
                  icone: IconesDropp.link,
                  libelle: l10n.partageCopierLien,
                  enCours: _enCours == PlateformePartage.copierLien,
                  surAppui: _enCours == null
                      ? () => _partager(PlateformePartage.copierLien)
                      : null,
                ),
              ],
            ),
            if (_erreur != null) ...[
              const SizedBox(height: Espacements.m),
              Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.couleur,
    required this.icone,
    required this.libelle,
    required this.enCours,
    required this.surAppui,
  });

  final Color couleur;
  final FaIconData icone;
  final String libelle;
  final bool enCours;
  final VoidCallback? surAppui;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: surAppui,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(Espacements.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: couleur,
              child: enCours
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : FaIcon(icone, color: Colors.white),
            ),
            const SizedBox(height: Espacements.xs),
            Text(libelle, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
