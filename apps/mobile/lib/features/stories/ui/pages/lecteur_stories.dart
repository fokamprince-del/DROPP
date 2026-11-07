import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/widgets/avatar_boutique.dart';
import '../../../../shared/widgets/image_reseau.dart';
import '../../../../utils/format.dart';
import '../../application/barre_stories.dart';
import '../../data/modeles_stories.dart';

/// Lecteur plein écran : les stories d'une boutique s'enchaînent, puis celles
/// de la boutique suivante. Toucher à gauche revient en arrière, à droite
/// avance, appui long met en pause, glisser vers le bas ferme.
class LecteurStories extends ConsumerStatefulWidget {
  const LecteurStories({super.key, this.indexInitial = 0});

  /// Boutique de la barre par laquelle commencer.
  final int indexInitial;

  @override
  ConsumerState<LecteurStories> createState() => _LecteurStoriesState();
}

class _LecteurStoriesState extends ConsumerState<LecteurStories> {
  /// Copie figée à l'ouverture : marquer une story comme vue réordonne la
  /// barre, pas le lecteur.
  late final List<GroupeStories> _groupes;
  late final PageController _pages;
  late int _groupeActif;

  @override
  void initState() {
    super.initState();
    _groupes = ref.read(barreStoriesProvider).value ?? const [];
    _groupeActif = widget.indexInitial.clamp(
      0,
      math.max(0, _groupes.length - 1),
    );
    _pages = PageController(initialPage: _groupeActif);
    if (_groupes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fermer());
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _fermer() {
    if (mounted && context.canPop()) context.pop();
  }

  void _groupeSuivant() {
    if (_groupeActif + 1 >= _groupes.length) {
      _fermer();
      return;
    }
    unawaited(
      _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  void _groupePrecedent() {
    if (_groupeActif == 0) return;
    unawaited(
      _pages.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(barreStoriesProvider.notifier);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 400) _fermer();
          },
          child: PageView.builder(
            controller: _pages,
            itemCount: _groupes.length,
            onPageChanged: (i) => setState(() => _groupeActif = i),
            itemBuilder: (context, i) => _VueGroupe(
              key: ValueKey(_groupes[i].boutique.id),
              groupe: _groupes[i],
              actif: i == _groupeActif,
              surVue: notifier.marquerVue,
              surFin: _groupeSuivant,
              surDebut: _groupePrecedent,
              surFermer: _fermer,
            ),
          ),
        ),
      ),
    );
  }
}

class _VueGroupe extends StatefulWidget {
  const _VueGroupe({
    super.key,
    required this.groupe,
    required this.actif,
    required this.surVue,
    required this.surFin,
    required this.surDebut,
    required this.surFermer,
  });

  final GroupeStories groupe;

  /// Seule la boutique affichée joue ; les voisines restent en pause.
  final bool actif;
  final ValueChanged<String> surVue;
  final VoidCallback surFin;
  final VoidCallback surDebut;
  final VoidCallback surFermer;

  @override
  State<_VueGroupe> createState() => _VueGroupeState();
}

class _VueGroupeState extends State<_VueGroupe>
    with SingleTickerProviderStateMixin {
  static const _dureeImage = Duration(seconds: 5);
  static const _dureeVideoInconnue = Duration(seconds: 15);

  late int _index = widget.groupe.premiereNonVue;
  late final AnimationController _progression = AnimationController(
    vsync: this,
    duration: _dureeImage,
  )..addStatusListener(_surStatut);

  VideoPlayerController? _video;
  bool _pret = false;
  bool _echec = false;
  bool _maintenu = false;

  /// Incrémenté à chaque story : une préparation d'avant est ignorée.
  int _generation = 0;

  Story get _story => widget.groupe.stories[_index];

  @override
  void initState() {
    super.initState();
    if (widget.actif) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preparer());
    }
  }

  @override
  void didUpdateWidget(_VueGroupe ancien) {
    super.didUpdateWidget(ancien);
    if (widget.actif == ancien.actif) return;
    if (!widget.actif) {
      _suspendre();
    } else if (_pret) {
      _jouer();
    } else {
      unawaited(_preparer());
    }
  }

  @override
  void dispose() {
    _generation++;
    _progression.dispose();
    unawaited(_video?.dispose());
    super.dispose();
  }

  void _surStatut(AnimationStatus statut) {
    if (statut == AnimationStatus.completed) _suivante();
  }

  Future<void> _preparer() async {
    final generation = ++_generation;
    _progression
      ..stop()
      ..value = 0;
    final ancienne = _video;
    _video = null;
    unawaited(ancienne?.dispose());
    setState(() {
      _pret = false;
      _echec = false;
    });

    final story = _story;
    widget.surVue(story.id);

    var duree = _dureeImage;
    var echec = false;
    if (story.media.estVideo) {
      final video = VideoPlayerController.networkUrl(
        Uri.parse(story.media.url),
      );
      _video = video;
      try {
        await video.initialize();
        final reelle = video.value.duration;
        duree = reelle > Duration.zero
            ? reelle
            : story.media.duree ?? _dureeVideoInconnue;
      } on Object {
        echec = true;
      }
    } else {
      await precacheImage(
        CachedNetworkImageProvider(story.media.url),
        context,
        onError: (_, _) => echec = true,
      );
    }
    if (!mounted || generation != _generation) return;

    setState(() {
      _pret = true;
      _echec = echec;
    });
    // Média illisible : on laisse le message quelques secondes puis on avance.
    _progression.duration = echec ? const Duration(seconds: 3) : duree;
    if (widget.actif && !_maintenu) _jouer();
  }

  void _jouer() {
    unawaited(_progression.forward());
    unawaited(_video?.play());
  }

  void _suspendre() {
    _progression.stop();
    unawaited(_video?.pause());
  }

  void _suivante() {
    if (_index + 1 < widget.groupe.stories.length) {
      _index++;
      unawaited(_preparer());
    } else {
      widget.surFin();
    }
  }

  void _precedente() {
    if (_index > 0) {
      _index--;
      unawaited(_preparer());
    } else {
      widget.surDebut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final story = _story;
    final nom = widget.groupe.boutique.nom;
    final video = _video;

    final Widget media;
    if (_echec) {
      media = Center(
        child: Text(
          l10n.storyIllisible,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      );
    } else if (story.media.estVideo) {
      media = video != null && video.value.isInitialized
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            )
          : const SizedBox.shrink();
    } else {
      media = ImageReseau(url: story.media.url);
    }

    return Semantics(
      label: l10n.storyDe(nom),
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.storySuivante): _suivante,
        CustomSemanticsAction(label: l10n.storyPrecedente): _precedente,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final largeur = context.size?.width ?? 1;
          if (details.localPosition.dx < largeur * 0.3) {
            _precedente();
          } else {
            _suivante();
          }
        },
        onLongPressStart: (_) {
          _maintenu = true;
          _suspendre();
        },
        onLongPressEnd: (_) {
          _maintenu = false;
          if (_pret && widget.actif) _jouer();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Couleurs.nuitTeinte),
            media,
            if (!_pret)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            // Assombrit le haut pour que l'en-tête reste lisible.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x80000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espacements.s,
                  Espacements.s,
                  Espacements.xs,
                  0,
                ),
                child: Column(
                  children: [
                    _Segments(
                      nombre: widget.groupe.stories.length,
                      index: _index,
                      progression: _progression,
                    ),
                    const SizedBox(height: Espacements.s),
                    Row(
                      children: [
                        AvatarBoutique(nom: nom, taille: 32),
                        const SizedBox(width: Espacements.s),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '  ${tempsRelatif(l10n, story.dateCreation)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.storyFermer,
                          color: Colors.white,
                          icon: const FaIcon(IconesDropp.close),
                          onPressed: widget.surFermer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une barre par story : pleine si vue, animée pour la story en cours.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.nombre,
    required this.index,
    required this.progression,
  });

  final int nombre;
  final int index;
  final Animation<double> progression;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < nombre; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: i == index
                      ? AnimatedBuilder(
                          animation: progression,
                          builder: (_, _) => _barre(progression.value),
                        )
                      : _barre(i < index ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barre(double valeur) => LinearProgressIndicator(
    value: valeur,
    minHeight: 3,
    color: Colors.white,
    backgroundColor: Colors.white.withValues(alpha: 0.35),
  );
}
