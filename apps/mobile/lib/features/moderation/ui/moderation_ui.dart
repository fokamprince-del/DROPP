import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../interactions/ui/actions_connectees.dart';
import '../data/moderation.dart';

/// Feuille « Signaler » : motif, description (obligatoire pour « Autre »).
Future<void> ouvrirSignalement(
  BuildContext context,
  WidgetRef ref, {
  required TypeCible typeCible,
  required String cibleId,
}) async {
  if (!exigerConnexion(context, ref)) return;
  final messager = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final envoye = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FeuilleSignalement(typeCible: typeCible, cibleId: cibleId),
  );
  if (envoye == true) {
    messager.showSnackBar(SnackBar(content: Text(l10n.signalementEnvoye)));
  }
}

class _FeuilleSignalement extends ConsumerStatefulWidget {
  const _FeuilleSignalement({required this.typeCible, required this.cibleId});

  final TypeCible typeCible;
  final String cibleId;

  @override
  ConsumerState<_FeuilleSignalement> createState() =>
      _FeuilleSignalementState();
}

class _FeuilleSignalementState extends ConsumerState<_FeuilleSignalement> {
  MotifSignalement? _motif;
  final _description = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _valide =>
      _motif != null &&
      (!_motif!.exigeDescription || _description.text.trim().isNotEmpty);

  Future<void> _envoyer() async {
    final motif = _motif;
    if (motif == null || !_valide || _envoi) return;
    final l10n = context.l10n;
    final navigateur = Navigator.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(moderationRepositoryProvider)
          .signaler(
            typeCible: widget.typeCible,
            cibleId: widget.cibleId,
            motif: motif.code,
            description: _description.text,
          );
      navigateur.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = messageErreurApi(
          l10n,
          e,
          specifiques: {
            TypeErreurApi.conflit: l10n.signalementDejaFait,
            TypeErreurApi.requeteInvalide: l10n.signalementPropreContenu,
            TypeErreurApi.introuvable: l10n.erreurContenuIntrouvable,
            TypeErreurApi.interdit: l10n.erreurActionInterdite,
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final motifs = ref.watch(motifsSignalementProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Espacements.l,
          0,
          Espacements.l,
          Espacements.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.signalerTitre,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Espacements.s),
            switch (motifs) {
              AsyncData(:final value) => Column(
                children: [
                  for (final m in value)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.libelle),
                      selected: _motif?.code == m.code,
                      trailing: FaIcon(
                        _motif?.code == m.code
                            ? IconesDropp.circleDot
                            : IconesDropp.circle,
                        color: _motif?.code == m.code
                            ? schema.primary
                            : schema.outline,
                      ),
                      onTap: () => setState(() => _motif = m),
                    ),
                ],
              ),
              AsyncError(:final error) => VueErreur(
                erreur: ApiException.depuis(error),
                reessayer: () => ref.invalidate(motifsSignalementProvider),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Espacements.l),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            const SizedBox(height: Espacements.s),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _motif?.exigeDescription ?? false
                    ? l10n.signalementDescriptionObligatoire
                    : l10n.signalementDescriptionFacultative,
              ),
            ),
            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacements.s),
                child: Text(
                  _erreur!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: schema.error,
                  ),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.couleursMetier.erreur,
              ),
              onPressed: _valide && !_envoi ? _envoyer : null,
              child: _envoi
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.signalementEnvoyer),
            ),
            const SizedBox(height: Espacements.s),
            Text(
              l10n.signalementAnonyme,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: schema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demande confirmation puis bloque. Renvoie `true` si c'est fait.
Future<bool> confirmerBlocage(
  BuildContext context,
  WidgetRef ref, {
  required String utilisateurId,
  required String nom,
}) async {
  final l10n = context.l10n;
  final messager = ScaffoldMessenger.of(context);
  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.bloquerTitre(nom)),
      content: Text(l10n.bloquerTexte),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.annuler),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.bloquer),
        ),
      ],
    ),
  );
  if (confirme != true) return false;
  try {
    await ref.read(moderationRepositoryProvider).bloquer(utilisateurId);
  } on ApiException catch (e) {
    if (e.type != TypeErreurApi.conflit) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
      return false;
    }
  }
  messager.showSnackBar(SnackBar(content: Text(l10n.bloqueConfirme(nom))));
  return true;
}

/// Utilisateurs bloqués, avec « Débloquer ».
class PageBloques extends ConsumerWidget {
  const PageBloques({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final etat = ref.watch(bloquesProvider);

    Future<void> debloquer(UtilisateurBloque b) async {
      final messager = ScaffoldMessenger.of(context);
      try {
        await ref.read(moderationRepositoryProvider).debloquer(b.profil.id);
      } on ApiException catch (e) {
        if (e.type != TypeErreurApi.introuvable) {
          messager.showSnackBar(
            SnackBar(content: Text(messageErreurApi(l10n, e))),
          );
          return;
        }
      }
      ref.invalidate(bloquesProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bloquesTitre)),
      body: switch (etat) {
        AsyncData(:final value) when value.isEmpty => EtatVide(
          icone: IconesDropp.ban,
          titre: l10n.bloquesVide,
          texte: l10n.bloquesVideTexte,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: Espacements.s),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final b = value[i];
            return ListTile(
              leading: AvatarBoutique(
                nom: b.profil.nomAffiche,
                logoUrl: b.profil.imageUrl,
                taille: 40,
              ),
              title: Text(b.profil.nomAffiche),
              subtitle: Text(
                l10n.bloqueLe(
                  DateFormat.yMMMd(l10n.localeName).format(b.dateBlocage),
                ),
                style: theme.textTheme.bodySmall,
              ),
              trailing: OutlinedButton(
                onPressed: () => unawaited(debloquer(b)),
                child: Text(l10n.debloquer),
              ),
            );
          },
        ),
        AsyncError(:final error) => Center(
          child: VueErreur(
            erreur: ApiException.depuis(error),
            reessayer: () => ref.invalidate(bloquesProvider),
          ),
        ),
        _ => ListView(
          padding: const EdgeInsets.all(Espacements.l),
          children: const [Squelette(hauteur: 56), SizedBox(height: 8)],
        ),
      },
    );
  }
}

String libelleStatutSignalement(AppLocalizations l10n, StatutSignalement s) =>
    switch (s) {
      StatutSignalement.ouvert => l10n.signalementOuvert,
      StatutSignalement.enCours => l10n.signalementEnCours,
      StatutSignalement.traite => l10n.signalementTraite,
      StatutSignalement.rejete => l10n.signalementRejete,
    };

String libelleTypeCible(AppLocalizations l10n, TypeCible? t) => switch (t) {
  TypeCible.publication => l10n.ciblePublication,
  TypeCible.commentaire => l10n.cibleCommentaire,
  TypeCible.produit => l10n.cibleProduit,
  TypeCible.boutique => l10n.cibleBoutique,
  TypeCible.message => l10n.cibleMessage,
  null => '',
};

/// Mes signalements et leur suivi.
class PageMesSignalements extends ConsumerWidget {
  const PageMesSignalements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final metier = context.couleursMetier;
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signalementsTitre)),
      body: ListePaginee<Signalement>(
        charger: ref.read(moderationRepositoryProvider).mesSignalements,
        separateur: const Divider(height: 1),
        vide: EtatVide(
          icone: IconesDropp.solidFlag,
          titre: l10n.signalementsVide,
        ),
        elementBuilder: (context, s, _) {
          final (couleur, fond) = switch (s.statut) {
            StatutSignalement.traite => (metier.succes, metier.succesFond),
            StatutSignalement.rejete => (metier.erreur, metier.erreurFond),
            _ => (metier.attente, metier.attenteFond),
          };
          return ListTile(
            title: Text(s.libelleMotif),
            subtitle: Text(
              [
                libelleTypeCible(l10n, s.typeCible),
                date.format(s.dateCreation),
              ].where((t) => t.isNotEmpty).join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            trailing: DecoratedBox(
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                child: Text(
                  libelleStatutSignalement(l10n, s.statut),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: couleur,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
