import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../utils/format.dart';
import '../../fil/data/modeles_fil.dart';
import '../../interactions/application/interactions.dart';
import '../../interactions/ui/actions_connectees.dart';
import '../../moderation/data/moderation.dart';
import '../../moderation/ui/moderation_ui.dart';
import '../data/commentaires.dart';

/// Ouvre les commentaires d'une publication en feuille (85 % de l'écran).
Future<void> ouvrirCommentaires(
  BuildContext context,
  Publication publication,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FeuilleCommentaires(publication: publication),
);

class FeuilleCommentaires extends ConsumerStatefulWidget {
  const FeuilleCommentaires({super.key, required this.publication});

  final Publication publication;

  @override
  ConsumerState<FeuilleCommentaires> createState() =>
      _FeuilleCommentairesState();
}

class _FeuilleCommentairesState extends ConsumerState<FeuilleCommentaires> {
  /// Au-delà, « voir les réponses » s'arrête (5 pages de 20).
  static const _pagesReponsesMax = 5;

  final _liste = GlobalKey<ListePagineeState<Commentaire>>();
  final _saisie = TextEditingController();
  final _focus = FocusNode();

  /// Commentaire racine auquel on répond, sinon `null`.
  Commentaire? _reponseA;
  bool _envoi = false;
  String? _erreur;

  /// Réponses chargées ou publiées ici, par racine : remplacent l'aperçu.
  final _reponses = <String, List<Commentaire>>{};
  final _totauxReponses = <String, int>{};
  final _chargementReponses = <String>{};

  String get _publicationId => widget.publication.id;

  @override
  void initState() {
    super.initState();
    _saisie.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _saisie.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Commentaire> _reponsesDe(Commentaire racine) =>
      _reponses[racine.id] ?? racine.reponses;

  int _totalReponsesDe(Commentaire racine) =>
      _totauxReponses[racine.id] ?? racine.totalReponses;

  void _repondreA(Commentaire racine) {
    setState(() => _reponseA = racine);
    _focus.requestFocus();
  }

  Future<void> _chargerReponses(Commentaire racine) async {
    if (!_chargementReponses.add(racine.id)) return;
    setState(() {});
    final depot = ref.read(commentairesRepositoryProvider);
    final toutes = <Commentaire>[];
    try {
      for (var page = 1; page <= _pagesReponsesMax; page++) {
        final resultat = await depot.reponses(racine.id, page);
        toutes.addAll(resultat.donnees);
        if (!resultat.pagination.aSuivante) break;
      }
      if (!mounted) return;
      setState(() {
        _reponses[racine.id] = toutes;
        _totauxReponses[racine.id] = toutes.length;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(context.l10n, e));
    } finally {
      _chargementReponses.remove(racine.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _publier() async {
    final texte = _saisie.text.trim();
    if (texte.isEmpty || _envoi) return;
    if (!exigerConnexion(context, ref)) return;

    final l10n = context.l10n;
    final parent = _reponseA;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final commentaire = await ref
          .read(commentairesRepositoryProvider)
          .publier(_publicationId, texte, parentId: parent?.id);
      if (!mounted) return;
      ref
          .read(interactionsProvider.notifier)
          .noterCommentaire(_publicationId, 1);
      _saisie.clear();
      setState(() {
        _reponseA = null;
        if (parent != null) {
          _reponses[parent.id] = [..._reponsesDe(parent), commentaire];
          _totauxReponses[parent.id] = _totalReponsesDe(parent) + 1;
        }
      });
      if (parent == null) _liste.currentState?.inserer(commentaire);
      _focus.unfocus();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _supprimer(Commentaire commentaire, Commentaire? racine) async {
    final l10n = context.l10n;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commentaireSupprimerTitre),
        content: Text(l10n.commentaireSupprimerTexte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.supprimer),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    try {
      await ref.read(commentairesRepositoryProvider).supprimer(commentaire.id);
      if (!mounted) return;
      ref
          .read(interactionsProvider.notifier)
          .noterCommentaire(_publicationId, -1);
      if (racine == null) {
        _liste.currentState?.retirer((c) => c.id == commentaire.id);
      } else {
        setState(() {
          _reponses[racine.id] = _reponsesDe(racine)
              .where((r) => r.id != commentaire.id)
              .toList();
          _totauxReponses[racine.id] = (_totalReponsesDe(racine) - 1).clamp(
            0,
            1 << 30,
          );
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = widget.publication;
    final nombre = ref.watch(
      interactionsProvider.select((e) => e.commentaires(p.id, p.commentaires)),
    );
    final moi = ref.watch(utilisateurConnecteProvider);

    bool peutSupprimer(Commentaire c) =>
        moi != null && (moi.id == c.auteurId || moi.id == p.boutique.id);

    // Messager propre à la feuille : les erreurs d'un like s'affichent ici,
    // pas derrière la feuille.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Le clavier est géré par la marge de la zone de saisie.
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              Text(
                l10n.commentairesTitre(nombre),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Espacements.s),
              const Divider(height: 1),
              Expanded(
                child: ListePaginee<Commentaire>(
                  key: _liste,
                  charger: (page) => ref
                      .read(commentairesRepositoryProvider)
                      .lister(p.id, page),
                  padding: const EdgeInsets.all(Espacements.m),
                  separateur: const SizedBox(height: Espacements.l),
                  vide: Padding(
                    padding: const EdgeInsets.all(Espacements.xxl),
                    child: Text(
                      l10n.commentairesVide,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  elementBuilder: (context, racine, _) {
                    final reponses = _reponsesDe(racine);
                    final restantes =
                        _totalReponsesDe(racine) - reponses.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LigneCommentaire(
                          commentaire: racine,
                          surRepondre: () => _repondreA(racine),
                          surSupprimer: peutSupprimer(racine)
                              ? () => _supprimer(racine, null)
                              : null,
                        ),
                        for (final reponse in reponses)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 40,
                              top: Espacements.m,
                            ),
                            child: LigneCommentaire(
                              commentaire: reponse,
                              reponse: true,
                              surRepondre: () => _repondreA(racine),
                              surSupprimer: peutSupprimer(reponse)
                                  ? () => _supprimer(reponse, racine)
                                  : null,
                            ),
                          ),
                        if (restantes > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: TextButton(
                              onPressed: _chargementReponses.contains(racine.id)
                                  ? null
                                  : () => _chargerReponses(racine),
                              child: Text(
                                l10n.commentairesVoirReponses(restantes),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              if (_erreur != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espacements.l,
                    Espacements.s,
                    Espacements.l,
                    0,
                  ),
                  child: Text(
                    _erreur!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: moi == null
                    ? Padding(
                        padding: const EdgeInsets.all(Espacements.m),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => exigerConnexion(context, ref),
                            child: Text(l10n.commentairesConnexion),
                          ),
                        ),
                      )
                    : _ZoneSaisie(
                        controleur: _saisie,
                        focus: _focus,
                        reponseA: _reponseA,
                        envoi: _envoi,
                        surAnnulerReponse: () =>
                            setState(() => _reponseA = null),
                        surEnvoyer: _publier,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auteur, badge « Créateur », texte (mentions en couleur), heure,
/// « Répondre », « Supprimer » et j'aime.
class LigneCommentaire extends ConsumerWidget {
  const LigneCommentaire({
    super.key,
    required this.commentaire,
    required this.surRepondre,
    this.surSupprimer,
    this.reponse = false,
  });

  final Commentaire commentaire;
  final bool reponse;
  final VoidCallback surRepondre;
  final VoidCallback? surSupprimer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final c = commentaire;
    final aime = ref.watch(
      interactionsProvider.select((e) => e.likesCommentaires.contains(c.id)),
    );
    final likes = ref.watch(
      interactionsProvider.select((e) => e.likesCommentaire(c.id, c.likes)),
    );
    final discret = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarBoutique(nom: c.auteur, taille: reponse ? 26 : 32),
        const SizedBox(width: Espacements.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    c.auteur,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (c.estCreateur) const _BadgeCreateur(),
                ],
              ),
              const SizedBox(height: 2),
              TexteAvecMentions(texte: c.contenu),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    tempsRelatif(l10n, c.dateCreation),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _LienDiscret(
                    texte: l10n.commentaireRepondre,
                    style: discret,
                    surAppui: surRepondre,
                  ),
                  if (surSupprimer != null)
                    _LienDiscret(
                      texte: l10n.supprimer,
                      style: discret,
                      surAppui: surSupprimer!,
                    )
                  else if (ref.watch(utilisateurConnecteProvider)?.id !=
                      c.auteurId)
                    _LienDiscret(
                      texte: l10n.signaler,
                      style: discret,
                      surAppui: () => unawaited(
                        ouvrirSignalement(
                          context,
                          ref,
                          typeCible: TypeCible.commentaire,
                          cibleId: c.id,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          toggled: aime,
          label: l10n.publicationLikes(likes),
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => actionConnectee(
              context,
              ref,
              () => ref
                  .read(interactionsProvider.notifier)
                  .basculerLikeCommentaire(c.id, likes),
            ),
            radius: 22,
            child: SizedBox(
              width: 40,
              height: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    aime ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: aime
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (likes > 0)
                    Text(
                      formaterCompteur(likes, l10n.localeName),
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Les `@pseudo` ressortent en couleur primaire.
class TexteAvecMentions extends StatelessWidget {
  const TexteAvecMentions({super.key, required this.texte});

  final String texte;

  static final _mention = RegExp(r'@[\w.]+');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final morceaux = <TextSpan>[];
    var debut = 0;
    for (final m in _mention.allMatches(texte)) {
      if (m.start > debut) {
        morceaux.add(TextSpan(text: texte.substring(debut, m.start)));
      }
      morceaux.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      debut = m.end;
    }
    if (debut < texte.length) {
      morceaux.add(TextSpan(text: texte.substring(debut)));
    }
    return Text.rich(
      TextSpan(children: morceaux),
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _BadgeCreateur extends StatelessWidget {
  const _BadgeCreateur();

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: schema.primary,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          context.l10n.commentaireCreateur,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: schema.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _LienDiscret extends StatelessWidget {
  const _LienDiscret({
    required this.texte,
    required this.style,
    required this.surAppui,
  });

  final String texte;
  final TextStyle? style;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: surAppui,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(texte, style: style),
      ),
    );
  }
}

class _ZoneSaisie extends StatelessWidget {
  const _ZoneSaisie({
    required this.controleur,
    required this.focus,
    required this.reponseA,
    required this.envoi,
    required this.surAnnulerReponse,
    required this.surEnvoyer,
  });

  final TextEditingController controleur;
  final FocusNode focus;
  final Commentaire? reponseA;
  final bool envoi;
  final VoidCallback surAnnulerReponse;
  final VoidCallback surEnvoyer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cible = reponseA;
    final peutEnvoyer = !envoi && controleur.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacements.m,
        Espacements.s,
        Espacements.s,
        Espacements.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cible != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.commentaireReponseA(cible.auteur),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.annuler,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: surAnnulerReponse,
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controleur,
                  focusNode: focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.commentairePlaceholder,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Espacements.s),
              IconButton.filled(
                tooltip: l10n.commentairePublier,
                onPressed: peutEnvoyer ? surEnvoyer : null,
                icon: envoi
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
