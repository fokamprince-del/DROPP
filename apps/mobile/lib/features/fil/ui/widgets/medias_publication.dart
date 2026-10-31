import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/modeles/contenu.dart';
import '../../../../shared/theme/couleurs.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/widgets/image_reseau.dart';
import '../../../../utils/format.dart';
import '../../data/modeles_fil.dart';

/// Médias d'une publication : un seul, ou un carrousel avec des points.
///
/// Dans le fil ([lecture] à `false`), une vidéo n'est qu'une vignette : rien
/// ne se télécharge tant qu'on n'ouvre pas la publication.
class MediasPublication extends StatefulWidget {
  const MediasPublication({
    super.key,
    required this.medias,
    this.produit,
    this.ratio = 4 / 5,
    this.lecture = false,
  });

  final List<MediaContenu> medias;

  /// Premier produit lié, affiché en étiquette sur le média.
  final ProduitLie? produit;
  final double ratio;
  final bool lecture;

  @override
  State<MediasPublication> createState() => _MediasPublicationState();
}

class _MediasPublicationState extends State<MediasPublication> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final medias = widget.medias;
    if (medias.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.ratio,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }

    Widget vue(MediaContenu media) => media.estVideo
        ? (widget.lecture
              ? LecteurVideo(media: media)
              : VignetteVideo(media: media))
        : ImageReseau(url: media.url);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (medias.length == 1)
                vue(medias.first)
              else
                PageView.builder(
                  itemCount: medias.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => vue(medias[i]),
                ),
              if (medias.length > 1)
                Positioned(
                  top: Espacements.s,
                  right: Espacements.s,
                  child: _Pastille(
                    texte: context.l10n.mediaPosition(_page + 1, medias.length),
                  ),
                ),
              if (widget.produit != null)
                Positioned(
                  left: Espacements.s,
                  bottom: Espacements.m,
                  child: EtiquetteProduit(produit: widget.produit!),
                ),
            ],
          ),
        ),
        if (medias.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: Espacements.s),
            child: _Points(nombre: medias.length, actif: _page),
          ),
      ],
    );
  }
}

/// « 🛍 Robe wax · 25 000 FCFA » posé sur le média ; ouvre la fiche.
class EtiquetteProduit extends StatelessWidget {
  const EtiquetteProduit({super.key, required this.produit});

  final ProduitLie produit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(context.push<void>(Routes.produit(produit.id))),
        child: _etiquette(context),
      ),
    );
  }

  Widget _etiquette(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Couleurs.nuitTeinte.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                IconesDropp.shoppingBasket,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '${produit.nom} · ',
                    children: [
                      TextSpan(
                        text: formaterPrix(produit.prix),
                        style: const TextStyle(color: Couleurs.hibiscusDoux),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fond nuit, bouton lecture et durée : aucune donnée vidéo téléchargée.
class VignetteVideo extends StatelessWidget {
  const VignetteVideo({super.key, required this.media});

  final MediaContenu media;

  @override
  Widget build(BuildContext context) {
    final duree = media.duree;
    return Semantics(
      label: context.l10n.mediaVideo,
      child: ColoredBox(
        color: Couleurs.nuitTeinte,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  IconesDropp.play,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            if (duree != null)
              Positioned(
                top: Espacements.s,
                left: Espacements.s,
                child: _Pastille(texte: formaterDuree(duree), video: true),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lecture à la demande (page de détail) : on télécharge au premier appui.
class LecteurVideo extends StatefulWidget {
  const LecteurVideo({super.key, required this.media});

  final MediaContenu media;

  @override
  State<LecteurVideo> createState() => _LecteurVideoState();
}

class _LecteurVideoState extends State<LecteurVideo> {
  VideoPlayerController? _controleur;
  bool _echec = false;

  @override
  void dispose() {
    unawaited(_controleur?.dispose());
    super.dispose();
  }

  Future<void> _basculer() async {
    final actuel = _controleur;
    if (actuel != null) {
      if (!actuel.value.isInitialized) return;
      unawaited(actuel.value.isPlaying ? actuel.pause() : actuel.play());
      return;
    }
    final controleur = VideoPlayerController.networkUrl(
      Uri.parse(widget.media.url),
    );
    setState(() {
      _controleur = controleur;
      _echec = false;
    });
    try {
      await controleur.initialize();
      await controleur.setLooping(true);
      if (!mounted) return;
      setState(() {});
      await controleur.play();
    } on Object {
      if (!mounted) return;
      unawaited(controleur.dispose());
      setState(() {
        _controleur = null;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controleur = _controleur;
    if (controleur == null || !controleur.value.isInitialized) {
      return GestureDetector(
        onTap: _basculer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VignetteVideo(media: widget.media),
            if (controleur != null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_echec)
              Positioned(
                left: 0,
                right: 0,
                bottom: Espacements.l,
                child: Text(
                  context.l10n.videoIllisible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _basculer,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controleur.value.aspectRatio,
                child: VideoPlayer(controleur),
              ),
            ),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controleur,
              builder: (context, valeur, _) => valeur.isPlaying
                  ? const SizedBox.shrink()
                  : const Center(
                      child: FaIcon(
                        IconesDropp.play,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controleur,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Color(0x66FFFFFF),
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte, this.video = false});

  final String texte;
  final bool video;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Couleurs.nuitTeinte.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (video) ...[
              const FaIcon(IconesDropp.play, size: 12, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Text(
              texte,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Points extends StatelessWidget {
  const _Points({required this.nombre, required this.actif});

  final int nombre;
  final int actif;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < nombre; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: i == actif ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == actif ? schema.primary : schema.outline,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}
