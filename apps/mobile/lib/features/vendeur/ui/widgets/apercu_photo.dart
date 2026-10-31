
import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/rayons.dart';

/// Aperçu d'un fichier XFile avec agrandissement au toucher.
class ApercuPhoto extends StatelessWidget {
  const ApercuPhoto({
    super.key,
    required this.fichier,
    required this.description,
    this.ratio = 85.6 / 54,
  });

  final XFile fichier;
  final String description;

  /// Proportions d'une carte d'identité par défaut.
  final double ratio;

  static Widget _erreur(
    BuildContext context,
    Object erreur,
    StackTrace? stackTrace,
  ) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, size: 40),
    );
  }

  void _agrandir(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (contexte) => Dialog.fullscreen(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(fichier.path),
                      fit: BoxFit.contain,
                      errorBuilder: _erreur,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: IconButton(
                    tooltip: contexte.l10n.kycFermer,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(contexte).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      button: true,
      label: description,
      hint: context.l10n.kycAgrandir,
      child: ClipRRect(
        borderRadius: Rayons.borduresChamp,
        child: AspectRatio(
          aspectRatio: ratio,
          child: GestureDetector(
            onTap: () => _agrandir(context),
            child: Image.file(
              File(fichier.path),
              fit: BoxFit.cover,
              cacheWidth: 900,
              gaplessPlayback: true,
              errorBuilder: _erreur,
            ),
          ),
        ),
      ),
    );
  }
}
