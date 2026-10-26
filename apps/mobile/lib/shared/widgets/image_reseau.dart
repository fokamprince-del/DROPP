import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'squelette.dart';

/// Image distante gardée en cache sur l'appareil : revoir le fil ne
/// retélécharge rien (chaque mégaoctet coûte).
class ImageReseau extends StatelessWidget {
  const ImageReseau({
    super.key,
    required this.url,
    this.ajustement = BoxFit.cover,
    this.largeur,
    this.hauteur,
  });

  final String url;
  final BoxFit ajustement;
  final double? largeur;
  final double? hauteur;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: ajustement,
      width: largeur,
      height: hauteur,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => const Squelette(rayon: 0),
      errorWidget: (context, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
