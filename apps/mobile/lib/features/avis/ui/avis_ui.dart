import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/rayons.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/etoiles.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../auth/ui/messages_erreurs.dart';
import '../data/mes_avis.dart';

/// Articles livrés à noter ; toucher ouvre la feuille de notation.
class PageAvisANoter extends ConsumerWidget {
  const PageAvisANoter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    final etat = ref.watch(articlesANoterProvider);

    final Widget corps = switch (etat) {
      AsyncData(:final value) when value.isEmpty => ListView(
        children: [
          EtatVide(
            icone: Icons.star_outline_rounded,
            titre: l10n.avisANoterVide,
            texte: l10n.avisANoterVideTexte,
          ),
        ],
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.all(Espacements.l),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: Espacements.s),
        itemBuilder: (context, i) {
          final a = value[i];
          return Container(
            padding: const EdgeInsets.all(Espacements.m),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Rayons.borduresCarte,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nomProduit,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          ?a.variante,
                          l10n.avisCommandeLe(date.format(a.dateCommande)),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final fait = await ouvrirNotation(
                      context,
                      titre: a.nomProduit,
                      envoyer: (note, commentaire) => ref
                          .read(mesAvisRepositoryProvider)
                          .creer(
                            ligneId: a.ligneId,
                            note: note,
                            commentaire: commentaire,
                          ),
                    );
                    if (fait) ref.invalidate(articlesANoterProvider);
                  },
                  child: Text(l10n.avisNoter),
                ),
              ],
            ),
          );
        },
      ),
      AsyncError(:final error) => Center(
        child: VueErreur(
          erreur: ApiException.depuis(error),
          reessayer: () => ref.invalidate(articlesANoterProvider),
        ),
      ),
      _ => ListView(
        padding: const EdgeInsets.all(Espacements.l),
        children: const [
          Squelette(hauteur: 72, rayon: 16),
          SizedBox(height: Espacements.s),
          Squelette(hauteur: 72, rayon: 16),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.avisANoterTitre)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(articlesANoterProvider),
        child: corps,
      ),
    );
  }
}

/// Feuille de notation (création ou modification). Renvoie `true` si l'avis
/// a été envoyé.
Future<bool> ouvrirNotation(
  BuildContext context, {
  required String titre,
  required Future<void> Function(int note, String? commentaire) envoyer,
  int noteInitiale = 0,
  String? commentaireInitial,
}) async {
  final envoye = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FeuilleNotation(
      titre: titre,
      envoyer: envoyer,
      noteInitiale: noteInitiale,
      commentaireInitial: commentaireInitial,
    ),
  );
  return envoye ?? false;
}

class _FeuilleNotation extends StatefulWidget {
  const _FeuilleNotation({
    required this.titre,
    required this.envoyer,
    required this.noteInitiale,
    this.commentaireInitial,
  });

  final String titre;
  final Future<void> Function(int note, String? commentaire) envoyer;
  final int noteInitiale;
  final String? commentaireInitial;

  @override
  State<_FeuilleNotation> createState() => _FeuilleNotationState();
}

class _FeuilleNotationState extends State<_FeuilleNotation> {
  late int _note = widget.noteInitiale;
  late final _commentaire = TextEditingController(
    text: widget.commentaireInitial,
  );
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_note == 0 || _envoi) return;
    final l10n = context.l10n;
    final navigateur = Navigator.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.envoyer(_note, _commentaire.text);
      navigateur.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.interdit: l10n.avisNonModifiable,
            TypeErreurApi.conflit: l10n.avisDejaDonne,
          },
        );
        _envoi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Espacements.l,
        0,
        Espacements.l,
        MediaQuery.viewInsetsOf(context).bottom + Espacements.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.avisTonAvis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            widget.titre,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Espacements.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var n = 1; n <= 5; n++)
                IconButton(
                  tooltip: l10n.avisNote(n),
                  iconSize: 40,
                  onPressed: () => setState(() => _note = n),
                  icon: Icon(
                    n <= _note
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: n <= _note
                        ? Etoiles.couleur
                        : theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Espacements.m),
          TextField(
            controller: _commentaire,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.avisCommentaireIndice),
          ),
          if (_erreur != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacements.s),
              child: Text(
                _erreur!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          FilledButton(
            onPressed: _note == 0 || _envoi ? null : _envoyer,
            child: _envoi
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.avisPublier),
          ),
        ],
      ),
    );
  }
}

/// Pour les liens « Avis à laisser » du profil.
void ouvrirAvisANoter(BuildContext context) =>
    unawaited(context.push<void>(Routes.avisANoter));
