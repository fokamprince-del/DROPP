import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/temps_reel/temps_reel.dart';
import '../../../core/upload/choix_media.dart';
import '../../../core/upload/service_upload.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/image_reseau.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../fil/ui/widgets/medias_publication.dart';
import '../../moderation/data/moderation.dart';
import '../../moderation/ui/moderation_ui.dart';
import '../application/non_lus.dart';
import '../data/messagerie.dart';

/// Relecture des nouveaux messages, seulement quand le temps réel est coupé
/// (réseau instable, serveur injoignable).
const _intervalleActualisation = Duration(seconds: 15);

/// Durée d'affichage de « … écrit » après le dernier signal reçu.
const _dureeEcrit = Duration(seconds: 4);

/// Écart minimal entre deux signaux « j'écris » envoyés.
const _intervalleEcrit = Duration(seconds: 3);

/// Message en cours d'envoi (fichiers vers R2, puis message).
class _EnvoiEnCours {
  _EnvoiEnCours({required this.texte, required this.fichiers});

  final String? texte;
  final List<FichierLocal> fichiers;

  /// Fichiers déjà dans R2 : un nouvel essai ne les renvoie pas.
  final envoyes = <FichierEnvoye>[];
  double progression = 0;
  String? erreur;
}

/// Discussion : historique chargé en remontant (curseur), envoi de texte et
/// de photos ou vidéos, accusés de lecture.
class PageDiscussion extends ConsumerStatefulWidget {
  const PageDiscussion({super.key, required this.id, this.initiale});

  final String id;

  /// Conversation venue de la liste ou tout juste ouverte.
  final Conversation? initiale;

  @override
  ConsumerState<PageDiscussion> createState() => _PageDiscussionState();
}

class _PageDiscussionState extends ConsumerState<PageDiscussion> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();

  late Conversation? _conversation = widget.initiale;

  /// Du plus récent au plus ancien (la liste est affichée à l'envers).
  final _messages = <Message>[];
  String? _curseur;
  bool _debutAtteint = false;
  bool _chargementInitial = true;
  bool _chargementAnciens = false;
  ApiException? _erreur;

  final _envois = <_EnvoiEnCours>[];
  final _pieces = <FichierLocal>[];
  Timer? _actualisation;

  /// L'autre personne est en train d'écrire.
  bool _ecritEnFace = false;
  Timer? _finEcrit;
  DateTime? _dernierEcritEnvoye;
  final _abonnements = <StreamSubscription<Map<String, dynamic>>>[];

  late final NonLusNotifier _nonLus = ref.read(nonLusProvider.notifier);
  late final TempsReel _tempsReel = ref.read(tempsReelProvider);
  MessagerieRepository get _depot => ref.read(messagerieRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _defilement.addListener(_surDefilement);
    _saisie.addListener(_surSaisie);
    _ecouterTempsReel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _demarrer());
  }

  void _surSaisie() {
    setState(() {});
    if (_saisie.text.trim().isEmpty) return;
    final maintenant = DateTime.now();
    final dernier = _dernierEcritEnvoye;
    if (dernier != null && maintenant.difference(dernier) < _intervalleEcrit) {
      return;
    }
    _dernierEcritEnvoye = maintenant;
    _tempsReel.signalerEcriture(widget.id);
  }

  void _ecouterTempsReel() {
    final moi = ref.read(utilisateurConnecteProvider)?.id;
    bool ici(Map<String, dynamic> d) => d['conversationId'] == widget.id;

    _abonnements
      ..add(
        _tempsReel.ecouter(EvenementsTempsReel.messageNouveau).listen((d) {
          if (!ici(d) || !mounted) return;
          final message = Message.fromJson(d);
          if (_messages.any((m) => m.id == message.id)) return;
          setState(() {
            _messages.insert(0, message);
            if (message.expediteurId != moi) _ecritEnFace = false;
          });
          if (message.expediteurId != moi) _marquerLu();
        }),
      )
      ..add(
        _tempsReel.ecouter(EvenementsTempsReel.messagesLus).listen((d) {
          if (!ici(d) || !mounted) return;
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              final m = _messages[i];
              if (m.expediteurId == moi && !m.lu) _messages[i] = m.copierLu();
            }
          });
        }),
      )
      ..add(
        _tempsReel.ecouter(EvenementsTempsReel.ecrit).listen((d) {
          if (!ici(d) || d['utilisateurId'] == moi || !mounted) return;
          setState(() => _ecritEnFace = true);
          _finEcrit?.cancel();
          _finEcrit = Timer(_dureeEcrit, () {
            if (mounted) setState(() => _ecritEnFace = false);
          });
        }),
      );
  }

  @override
  void dispose() {
    _actualisation?.cancel();
    _finEcrit?.cancel();
    for (final a in _abonnements) {
      unawaited(a.cancel());
    }
    _saisie.dispose();
    _defilement.dispose();
    _nonLus.rafraichir();
    super.dispose();
  }

  Future<void> _demarrer() async {
    // Les deux en parallèle ; ignore() évite une erreur « non gérée » si la
    // première requête échoue avant qu'on attende la seconde.
    final detail = _depot.detail(widget.id)..ignore();
    try {
      final page = await _depot.messages(widget.id);
      final conversation = await detail;
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _messages
          ..clear()
          ..addAll(page.messages);
        _curseur = page.curseurSuivant;
        _debutAtteint = page.curseurSuivant == null;
        _chargementInitial = false;
        _erreur = null;
      });
      _marquerLu();
      _actualisation ??= Timer.periodic(
        _intervalleActualisation,
        (_) => _actualiser(),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e;
          _chargementInitial = false;
        });
      }
    }
  }

  /// Nouveaux messages reçus et accusés de lecture à jour.
  Future<void> _actualiser() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        _tempsReel.connecte.value) {
      return;
    }
    try {
      final page = await _depot.messages(widget.id, limite: 20);
      if (!mounted) return;
      final frais = {for (final m in page.messages) m.id: m};
      final connus = {for (final m in _messages) m.id};
      final nouveaux = page.messages.where((m) => !connus.contains(m.id));
      final moi = ref.read(utilisateurConnecteProvider)?.id;
      final recus = nouveaux.any((m) => m.expediteurId != moi);
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          final f = frais[_messages[i].id];
          if (f != null) _messages[i] = f;
        }
        _messages.insertAll(0, nouveaux);
      });
      if (recus) _marquerLu();
    } on ApiException {
      // Hors connexion : on réessaiera au prochain passage.
    }
  }

  void _marquerLu() {
    unawaited(
      _depot
          .marquerLu(widget.id)
          .then((_) => _nonLus.rafraichir())
          .catchError((Object _) {}),
    );
  }

  void _surDefilement() {
    // Liste à l'envers : les anciens messages sont en haut, en fin de liste.
    if (_defilement.position.extentAfter < 400) unawaited(_chargerAnciens());
  }

  Future<void> _chargerAnciens() async {
    final curseur = _curseur;
    if (_debutAtteint || _chargementAnciens || curseur == null) return;
    setState(() => _chargementAnciens = true);
    try {
      final page = await _depot.messages(widget.id, avant: curseur);
      if (!mounted) return;
      setState(() {
        _messages.addAll(page.messages);
        _curseur = page.curseurSuivant;
        _debutAtteint = page.curseurSuivant == null;
      });
    } on ApiException {
      // Nouvel essai au prochain défilement.
    } finally {
      if (mounted) setState(() => _chargementAnciens = false);
    }
  }

  Future<void> _ajouterPiece() async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    if (_pieces.length >= piecesJointesMax) {
      messager.showSnackBar(
        SnackBar(content: Text(l10n.messagePiecesMax(piecesJointesMax))),
      );
      return;
    }
    try {
      final fichier = await choisirMedia(
        context,
        tailleMaxImageMo: tailleMaxImageMessageMo,
        tailleMaxVideoMo: tailleMaxVideoMessageMo,
      );
      if (fichier != null && mounted) setState(() => _pieces.add(fichier));
    } on FichierRefuse catch (e) {
      messager.showSnackBar(
        SnackBar(
          content: Text(
            e.tropGros
                ? l10n.fichierTropGros(e.tailleMaxMo ?? 0)
                : l10n.fichierFormatRefuse,
          ),
        ),
      );
    }
  }

  void _envoyer() {
    final texte = _saisie.text.trim();
    if (texte.isEmpty && _pieces.isEmpty) return;
    final envoi = _EnvoiEnCours(
      texte: texte.isEmpty ? null : texte,
      fichiers: List.of(_pieces),
    );
    setState(() {
      _envois.add(envoi);
      _pieces.clear();
    });
    _saisie.clear();
    if (_defilement.hasClients) {
      unawaited(
        _defilement.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      );
    }
    unawaited(_executer(envoi));
  }

  Future<void> _executer(_EnvoiEnCours envoi) async {
    final l10n = context.l10n;
    final upload = ref.read(serviceUploadProvider);
    setState(() => envoi.erreur = null);
    try {
      for (final fichier in envoi.fichiers.skip(envoi.envoyes.length)) {
        final deja = envoi.envoyes.length;
        final envoye = await upload.televerser(
          fichier,
          demanderSignature: (type, taille) =>
              _depot.signaturePieceJointe(widget.id, type, taille),
          surProgression: (p) {
            if (mounted) {
              setState(
                () => envoi.progression = (deja + p) / envoi.fichiers.length,
              );
            }
          },
        );
        envoi.envoyes.add(envoye);
      }
      final message = await _depot.envoyer(
        widget.id,
        contenu: envoi.texte,
        piecesJointes: envoi.envoyes,
      );
      if (!mounted) return;
      setState(() {
        _envois.remove(envoi);
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.insert(0, message);
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => envoi.erreur = messageErreurApi(
            l10n,
            e,
            specifiques: {TypeErreurApi.interdit: l10n.messageEnvoiInterdit},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final interlocuteur = _conversation?.interlocuteur;
    final nom = interlocuteur?.nomAffiche ?? '';
    final peutEcrire = _conversation?.peutEcrire ?? true;
    final moi = ref.watch(utilisateurConnecteProvider)?.id;
    final boutiqueId = interlocuteur?.boutiqueId;

    final Widget contenu;
    if (_chargementInitial) {
      contenu = const Center(child: CircularProgressIndicator());
    } else if (_erreur != null && _messages.isEmpty) {
      contenu = Center(
        child: VueErreur(
          erreur: _erreur!,
          reessayer: () {
            setState(() => _chargementInitial = true);
            unawaited(_demarrer());
          },
        ),
      );
    } else {
      final nombre = _envois.length + _messages.length + 1;
      contenu = ListView.builder(
        controller: _defilement,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: Espacements.m,
          vertical: Espacements.s,
        ),
        itemCount: nombre,
        itemBuilder: (context, i) {
          if (i < _envois.length) {
            final envoi = _envois[_envois.length - 1 - i];
            return _BulleEnvoi(
              envoi: envoi,
              surReessayer: () => unawaited(_executer(envoi)),
              surAbandonner: () => setState(() => _envois.remove(envoi)),
            );
          }
          final j = i - _envois.length;
          if (j == _messages.length) {
            return Padding(
              padding: const EdgeInsets.all(Espacements.l),
              child: Center(
                child: _debutAtteint
                    ? Text(
                        l10n.discussionDebut,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            );
          }
          final m = _messages[j];
          final plusAncien = j + 1 < _messages.length ? _messages[j + 1] : null;
          final nouveauJour =
              plusAncien == null ||
              !_memeJour(plusAncien.dateCreation, m.dateCreation);
          return Column(
            children: [
              if (nouveauJour) _SeparateurJour(date: m.dateCreation),
              _Bulle(message: m, deMoi: m.expediteurId == moi),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: boutiqueId == null
              ? null
              : () =>
                    unawaited(context.push<void>(Routes.boutique(boutiqueId))),
          child: Row(
            children: [
              AvatarBoutique(
                nom: nom,
                logoUrl: interlocuteur?.imageUrl,
                taille: 36,
              ),
              const SizedBox(width: Espacements.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_ecritEnFace)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.discussionEcrit,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (interlocuteur != null)
            PopupMenuButton<bool>(
              tooltip: l10n.plusDOptions,
              onSelected: (signaler) async {
                if (signaler) {
                  final dernier = _messages
                      .where((m) => m.expediteurId == interlocuteur.id)
                      .firstOrNull;
                  await ouvrirSignalement(
                    context,
                    ref,
                    // Le dernier message reçu, sinon la boutique elle-même.
                    typeCible: dernier != null
                        ? TypeCible.message
                        : TypeCible.boutique,
                    cibleId:
                        dernier?.id ??
                        interlocuteur.boutiqueId ??
                        interlocuteur.id,
                  );
                } else {
                  final fait = await confirmerBlocage(
                    context,
                    ref,
                    utilisateurId: interlocuteur.id,
                    nom: nom,
                  );
                  if (fait && mounted) {
                    setState(() => _conversation = _conversation?.fermee());
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: true, child: Text(l10n.signaler)),
                PopupMenuItem(value: false, child: Text(l10n.bloquer)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: contenu),
          if (!peutEcrire)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Espacements.m),
              color: theme.colorScheme.surfaceContainerHighest,
              child: SafeArea(
                top: false,
                child: Text(
                  l10n.discussionFermee,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            _BarreSaisie(
              controleur: _saisie,
              pieces: _pieces,
              surAjouterPiece: _ajouterPiece,
              surRetirerPiece: (f) => setState(() => _pieces.remove(f)),
              surEnvoyer: _envoyer,
            ),
        ],
      ),
    );
  }
}

bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SeparateurJour extends StatelessWidget {
  const _SeparateurJour({required this.date});

  final DateTime date;

  static String libelle(AppLocalizations l10n, DateTime date) {
    final maintenant = DateTime.now();
    if (_memeJour(date, maintenant)) return l10n.aujourdhui;
    if (_memeJour(date, maintenant.subtract(const Duration(days: 1)))) {
      return l10n.hier;
    }
    return DateFormat.yMMMMd(l10n.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacements.s),
      child: Text(
        libelle(context.l10n, date),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bulle : à droite en indigo pour soi, à gauche sur fond clair sinon.
class _Bulle extends StatelessWidget {
  const _Bulle({required this.message, required this.deMoi});

  final Message message;
  final bool deMoi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final m = message;
    final couleurTexte = deMoi ? schema.onPrimary : schema.onSurface;
    final heure = DateFormat.Hm(l10n.localeName).format(m.dateCreation);

    return Align(
      alignment: deMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(Espacements.s),
          decoration: BoxDecoration(
            color: deMoi ? schema.primary : schema.surface,
            border: deMoi ? null : Border.all(color: schema.outline),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(deMoi ? 16 : 5),
              bottomRight: Radius.circular(deMoi ? 5 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final pj in m.piecesJointes)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacements.xs),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 220,
                      child: AspectRatio(
                        aspectRatio: (pj.ratio ?? (pj.estVideo ? 16 / 9 : 1))
                            .clamp(0.6, 1.8),
                        child: pj.estVideo
                            ? LecteurVideo(media: pj.media)
                            : GestureDetector(
                                onTap: () => _ouvrirImage(context, pj.url),
                                child: ImageReseau(url: pj.url),
                              ),
                      ),
                    ),
                  ),
                ),
              if (m.contenu != null && m.contenu!.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    m.contenu!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: couleurTexte,
                    ),
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    heure,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: couleurTexte.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  if (deMoi) ...[
                    const SizedBox(width: 4),
                    Icon(
                      m.lu ? Icons.done_all : Icons.done,
                      size: 14,
                      semanticLabel: m.lu ? l10n.messageLu : l10n.messageEnvoye,
                      color: couleurTexte.withValues(alpha: m.lu ? 1 : 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirImage(BuildContext context, String url) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: InteractiveViewer(
              child: Center(
                child: ImageReseau(url: url, ajustement: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Message en cours d'envoi : progression, ou erreur avec « Réessayer ».
class _BulleEnvoi extends StatelessWidget {
  const _BulleEnvoi({
    required this.envoi,
    required this.surReessayer,
    required this.surAbandonner,
  });

  final _EnvoiEnCours envoi;
  final VoidCallback surReessayer;
  final VoidCallback surAbandonner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final erreur = envoi.erreur;

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: 0.7,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(Espacements.s),
              decoration: BoxDecoration(
                color: schema.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (envoi.fichiers.isNotEmpty)
                    Text(
                      l10n.messageFichiers(envoi.fichiers.length),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: schema.onPrimary,
                      ),
                    ),
                  if (envoi.texte != null)
                    Text(
                      envoi.texte!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: schema.onPrimary,
                      ),
                    ),
                  if (envoi.fichiers.isNotEmpty && erreur == null)
                    Padding(
                      padding: const EdgeInsets.only(top: Espacements.xs),
                      child: SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: envoi.progression,
                          color: schema.onPrimary,
                          backgroundColor: schema.onPrimary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (erreur != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  erreur,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: schema.error,
                  ),
                ),
                TextButton(
                  onPressed: surReessayer,
                  child: Text(l10n.reessayer),
                ),
                TextButton(
                  onPressed: surAbandonner,
                  child: Text(l10n.supprimer),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                l10n.messageEnvoi,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: schema.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarreSaisie extends StatelessWidget {
  const _BarreSaisie({
    required this.controleur,
    required this.pieces,
    required this.surAjouterPiece,
    required this.surRetirerPiece,
    required this.surEnvoyer,
  });

  final TextEditingController controleur;
  final List<FichierLocal> pieces;
  final VoidCallback surAjouterPiece;
  final ValueChanged<FichierLocal> surRetirerPiece;
  final VoidCallback surEnvoyer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schema = Theme.of(context).colorScheme;
    final peutEnvoyer = controleur.text.trim().isNotEmpty || pieces.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: schema.outline)),
        ),
        padding: const EdgeInsets.fromLTRB(
          Espacements.xs,
          Espacements.s,
          Espacements.s,
          Espacements.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pieces.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espacements.s,
                  ),
                  children: [
                    for (final f in pieces)
                      Padding(
                        padding: const EdgeInsets.only(right: Espacements.s),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox.square(
                                dimension: 64,
                                child: f.estVideo
                                    ? ColoredBox(
                                        color: schema.surfaceContainerHighest,
                                        child: const FaIcon(IconesDropp.video),
                                      )
                                    : Image.file(
                                        File(f.fichier.path),
                                        fit: BoxFit.cover,
                                        cacheWidth: 192,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                tooltip: l10n.supprimer,
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                onPressed: () => surRetirerPiece(f),
                                icon: const Icon(Icons.cancel),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.messageJoindre,
                  onPressed: surAjouterPiece,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: controleur,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 4000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l10n.messageIndice,
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
                        borderSide: BorderSide(color: schema.outline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Espacements.xs),
                IconButton.filled(
                  tooltip: l10n.messageEnvoyer,
                  onPressed: peutEnvoyer ? surEnvoyer : null,
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre (ou crée) la conversation avec une boutique ou un utilisateur.
Future<void> ouvrirDiscussionAvec(
  BuildContext context,
  WidgetRef ref,
  String destinataireId,
) async {
  final routeur = GoRouter.of(context);
  final conversation = await ref
      .read(messagerieRepositoryProvider)
      .ouvrir(destinataireId);
  unawaited(
    routeur.push<void>(
      Routes.conversation(conversation.id),
      extra: conversation,
    ),
  );
}
